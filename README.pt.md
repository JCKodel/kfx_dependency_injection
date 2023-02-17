# kfx_dependency_injection

[![Dart](https://github.com/JCKodel/kfx_dependency_injection/actions/workflows/dart.yml/badge.svg)](https://github.com/JCKodel/kfx_dependency_injection/actions/workflows/dart.yml) | [English version](README.md)

Um injetor de dependências e localizador de serviços simples inspirado pelo service provider do .net.

Na engenharia de software, injeção de dependência é um padrão de desenvolvimento onde um objeto ou função recebe outros objetos ou funções das quais depende, então você
pode passar algumas classes abstratas (o mais perto que você pode chegar de interfaces em Dart) e deixar este package decidir qual classe você irá obter quando da
instanciação.

Também funciona como um localizador de serviços (onde você tem uma definição abstrata/interface e deseja escolher uma implementação concreta durante o registro).

## Recursos

1) Permite o registro de dependencias transientes e singleton
2) Cobre má configuração das opções do analizador lingüístico (tal como usar metodos com argumentos genéricos sem prover um tipo genérico)
3) O injetor tem um `PlatformInfo` disponível, para que você possa decidir o que injetar baseado na mídia (web, desktop ou mobile) e no host (window, linux, macos, android ou ios)
4) Seguro para uso com Flutter web, incluindo `PlatformInfo`
5) Sem dependências externas
6) Serviços podem dizer se são transientes ou singleton implementando `IMustBeTransient` ou `IMustBeSingleton`

## Uso

Por exemplo, você pode definir um sistema de autenticação como um conjunto de métodos comuns vazios (em uma classe abstrata, que é o mais perto que você consegue chegar
a uma interface no Dart no momento). Então, você implementa a autenticação em si em outra class, digamos, usando autenticação Firebase. Quer user o AWS Incognito? Apenas
reimplemente aquela classe abstrata usando o Incognito e mude o registro para apontar para ele. Pronto, sem quebrar outras partes de tua app.

Log é importante e você pode fazer o mesmo para logging. Talvez usando `dart:developer` para implementá-lo.

Durante o registro do serviço de autenticação, você poderá injetar o serviço de log (que, neste momento, é uma classe abstrata que não se importa como será implementada).
Mude o registro de log para outro tipo (quem sabe um log remoto?) e tudo continua funcionando perfeitamente e você nem precisa tocar nos serviços de autenticação (já que
tudo se baseia em interfaces/classes abstratas, que serve apenas como um contrato da implementação concreta)

Então, o registro no `main` é algo assim:

```dart
ServiceProvider.registerSingleton<IAuthenticationService>(
  (optional, required, platform) => FirebaseAuthenticationService(
    logService: serviceProvider.optional<ILogService>()
  )
);

ServiceProvider.registerSingleton<ILogService>(
  (optional, required, platform) => DartDeveloperLogService(isWeb: platformInfo.platformMedia == PlatformMedia.web)
);
```

Você pode chamar `optional<TService>()` para obter um serviço opcional (que irá retornar `null` se o tipo não foi registrado) ou `required<TService>()` para obter uma
implementação concreta do `TService` desejado. Isso é o mesmo que chamar `ServiceProvider.optional<TService>()` ou `ServiceProvider.required<TService>()`.

Note que a oredem de registro não importa, desde que você registre todas as dependências antes de utilizá-las (um bom lugar seria o método `main`, antes da tua app rodar).

O argumento `platformInfo` é uma instância de `PlatformInfo`, para que você possa instantaneamente saber que tipo de mídia você está usando (Flutter Web, Flutter Desktop ou Flutter Mobile)
e o host que você está rodando (Android, iOS, Windows, MacOS or Linux). Esta informação é separada entre mídia e host para que você possa saber quando está rodando Flutter Web em um celular Android, por exemplo (talvez para escolher o sistema de design apropriado (i.e.: Material, Apple ou Fluent). No exemplo acima, eu pude dizer à minha implementação concreta de log se eu estou rodando no Flutter Web ou nativo.

Agora, para obter teu serviço de autenticação, com as coisas de log definidas no registro injetadas, você só precisa de:

```dart
final authenticationService = ServiceProvider.required<IAuthenticationService>();
```

E é isso. Você não precisa conhecer as implementações concretas nem saber que tipo de log está sendo usado (ou sequer se isso existe).

### Singleton vs Transiente

A diferença entre os registros são: toda vez que você chamar `optional`, `required` ou algo é injetado em outro construtor, singletons sempre retornam a mesma
instância de uma classe, enquanto registros transientes sempre retornam uma nova instância daquela classe (na maioria dos casos, você quer um singleton).

### optional vs required

A diferença entre estes métodos é que `optional` pode retornar `null` caso o serviço especificado não tenha sido registrado, enquanto que `required` irá
lançar uma exceção do tipo `ServiceNotRegisteredException` se o serviço não foi registrado. Você deveria usar `required` para certificar-se de que tudo tenha
sido registrado corretamente durante a inicialização da app.

## Mocking

Após registrar um tipo, você pode sobreescrevê-lo usando `ServiceProvider.override<TService>((optional, required, platform) => MockClass(), key: "some key")`.

Isso é útil quando você usa um serviço de API remoto registrado no teu app, mas quer "mockar" este serviço em testes de unidade (onde "mockar" é o ato de criar uma classe
falsa que não faz chamadas remotas, acesso a banco de dados, etc. exclusivamente para fins de testes). Neste caso, a app continua com o mesmo código (nenhuma mudança é
requerida). No teu teste de unidade, você sobreescreve o registro da tua chamada de api para alguma classe mock e está pronto.

Esta sobreescrita pode ser feita antes ou depois do registro normal (i.e.: você pode sobreescrever antes de iniciar a tua app e registrar os teus tipos ou depois disso,
não importa a ordem)

## Informações adicionais

Há alguns métodos para checar se um tipo foi registrado (`isRegistered<T>()`) e métodos para permitir o desregistro (isso é útil para liberar instâncias singleton ou em testes
de unidade para limpar o gerenciador do `ServiceProvider`).

Como Dart é incapaz de retornar nomes únicos de tipos, todos os métodos no `ServiceProvider` aceitam uma chage, que será usada para diferenciar tipos.

Por exemplo: o package `firebase_authentication` contém uma classe `User`. É provável que você também tenha uma classe `User` em seu código, que não tem nada a ver com
a implementação provida pelo Firebase. O problema é que o Dart irá retornar `User` em ambos os casos quando perguntarmos o nome do tipo. Este é o mesmo motivo que você
deve utilizar as palavras chaves `as`, `hide` e `show` durante o `import` para evitar conflitos com nomes de classes ou funções.

Então, se você tem duas classes com o mesmo nome e deseja registrar ambas (já que não é possível registrar o mesmo tipo mais do que uma vez), você pode diferenciá-los
usando o argumento `key`:

```dart
import 'some_class.dart';
import 'package:some_package:some_class.dart' as SomePackage;

ServiceProvider.registerSingleton<SomeClass>(
  (serviceProvider) => SomeClass()
);

ServiceProvider.registerSingleton<SomePackage.SomeClass>(
  (serviceProvider) => SomePackage.SomeClass(),
  key: "SomePackage"
);
```

O segundo registro deve usar o argumento `key` porque `SomeClass` existe em múltiplas localidades e já foi registrado antes.

Para obter cada versão do registro, use a mesma chave:

```dart
import 'some_class.dart';

final someClass = ServiceProvider.required<SomeClass>();
```

Isso irá retornar o primeiro registro (porque `key` é `null` em ambos os casos).

```dart
import 'package:some_package:some_class.dart';

final someClass = ServiceProvider.required<SomeClass>(key: "SomePackage");
```

Note que o código acima não tem mais um alias, mas ainda assim irá retornar a versão correta de `SomeClass` por que o mesmo argumento `key` foi utilizado.

## Exceções

Há três exceções disponíveis lançadas por este package:

### `ServiceAlreadyRegisteredException`

Esta exceção é lançada quando você tenta registrar um tipo com a mesma `key` (ou sem ela).

### `ServiceNotRegisteredException`

Esta exceção é lançada por `required` quando um serviço é requisitado e o mesmo não foi registrado. Também pelo método `unregister`, se o argumento
`throwsExceptionIfNotRegistered` for `true` (ele é `false` por padrão).

### `ServiceInvalidInferenceException`

Dart, por padrão, não irá lhe avisar quando você não prover um argumento genérico onde um é esperado, então `ServiceProvider.optional()` é um código válido,
porém é impossível determinar que tipo de serviço devemos retornar (já que `TService` seria `dynamic` neste caso). O uso correto seria
`ServiceProvider.optional<SomeTypeHere>()`.

O mesmo ocorre durante o registro de um tipo nulo: `ServiceProvider.registerSingleton((sp) => null)`, que é código válido, porém o tipo retornado seria `Null`.

Para ser avisado sobre estes casos, você deve ligar o `strict-inference` no analizador lingüístico em seu arquivo `analysis_options.yaml`:

```yaml
analyzer:
  language:
    strict-inference: true
```

Esta configuração irá lhe prover avisos como este:

```dart
ServiceProvider.optional();
```

```text
The type argument(s) of the function 'optional' can't be inferred. 
Use explicit type argument(s) for 'optional'.

(O(s) argumento(s) de tipo da função 'optional' não podem ser inferidos.
Use argumento(s) de tipo explicitamente para 'optional'.)
```

### `InvalidRegistrationModalForTypeException`

Esta exceção abstrata é implementada por `RegistryMustBeTransientException` ou `RegistryMustBeSingletonException` e são lançadas quando um serviço que implement
`IMustBeTransient` é registrado usando `ServiceProvider.registerSingleton` ou vice-versa.
