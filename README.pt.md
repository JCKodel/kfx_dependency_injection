# kfx_dependency_injection

[![Dart](https://github.com/JCKodel/kfx_dependency_injection/actions/workflows/dart.yml/badge.svg)](https://github.com/JCKodel/kfx_dependency_injection/actions/workflows/dart.yml) | [English version](README.md)

Um injetor de dependências e localizador de serviços simples inspirado pelo service provider do .net.

Na engenharia de software, injeção de dependência é um padrão de desenvolvimento onde um objeto ou função recebe outros objetos ou funções das quais depende, então você
pode passar algumas classes abstratas (o mais perto que você pode chegar de interfaces em Dart) e deixar este package decidir qual classe você irá obter quando da
instanciação.

Também funciona como um localizador de serviços (onde você tem uma definição abstrata/interface e deseja escolher uma implementação concreta durante o registro).

## Recursos

1) Premite o registro de dependências transientes e singleton
2) 100% de cobertura de código em testes de unidade
3) Cobre configuração incorreta das opções lint (como utilizar métodos genéricos sem prover um tipo genérico)

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
ServiceProvider.instance.registerSingleton<IAuthenticationService>(
  (serviceProvider) => FirebaseAuthenticationService(
    logService: serviceProvider.getService<ILogService>()
  )
);

ServiceProvider.instance.registerSingleton<ILogService>(
  (serviceProvider) => DartDeveloperLogService()
);
```

Note que a oredem de registro não importa, desde que você registre todas as dependências antes de utilizá-las (um bom lugar seria o método `main`, antes da tua app rodar).

Agora, para obter teu serviço de autenticação, com as coisas de log definidas no registro injetadas, você só precisa de:

```dart
final authenticationService = ServiceProvider.instance.getRequiredService<IAuthenticationService>();
```

E é isso. Você não precisa conhecer as implementações concretas nem saber que tipo de log está sendo usado (ou sequer se isso existe).

### Singleton vs Transiente

A diferença entre os registros são: toda vez que você chamar `getService`, `getRequiredService` ou algo é injetado em outro construtor, singletons sempre retornam a mesma
instância de uma classe, enquanto registros transientes sempre retornam uma nova instância daquela classe (na maioria dos casos, você quer um singleton).

### getService vs getRequiredService

A diferença entre estes métodos é que `getService` pode retornar `null` caso o serviço especificado não tenha sido registrado, enquanto que `getRequiredService` irá
lançar uma exceção do tipo `ServiceNotRegisteredException` se o serviço não foi registrado. Você deveria usar `getRequiredService` para certificar-se de que tudo tenha
sido registrado corretamente durante a inicialização da app.

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

ServiceProvider.instance.registerSingleton<SomeClass>(
  (serviceProvider) => SomeClass()
);

ServiceProvider.instance.registerSingleton<SomePackage.SomeClass>(
  (serviceProvider) => SomePackage.SomeClass(),
  key: "SomePackage"
);
```

O segundo registro deve usar o argumento `key` porque `SomeClass` existe em múltiplas localidades e já foi registrado antes.

Para obter cada versão do registro, use a mesma chave:

```dart
import 'some_class.dart';

final someClass = ServiceProvider.instance.getRequiredService<SomeClass>();
```

Isso irá retornar o primeiro registro (porque `key` é `null` em ambos os casos).

```dart
import 'package:some_package:some_class.dart';

final someClass = ServiceProvider.instance.getRequiredService<SomeClass>(key: "SomePackage");
```

Note que o código acima não tem mais um alias, mas ainda assim irá retornar a versão correta de `SomeClass` por que o mesmo argumento `key` foi utilizado.

## Exceções

Há três exceções disponíveis lançadas por este package:

### `ServiceAlreadyRegisteredException`

Esta exceção é lançada quando você tenta registrar um tipo com a mesma `key` (ou sem ela).

### `ServiceNotRegisteredException`

Esta exceção é lançada por `getRequiredService` quando um serviço é requisitado e o mesmo não foi registrado. Também pelo método `unregister`, se o argumento
`throwsExceptionIfNotRegistered` for `true` (ele é `false` por padrão).

### `ServiceInvalidInferenceException`

Dart, por padrão, não irá lhe avisar quando você não prover um argumento genérico onde um é esperado, então `ServiceProvider.instance.getService()` é um código válido,
porém é impossível determinar que tipo de serviço devemos retornar (já que `TService` seria `dynamic` neste caso). O uso correto seria
`ServiceProvider.instance.getService<SomeTypeHere>()`.

O mesmo ocorre durante o registro de um tipo nulo: `ServiceProvider.instance.registerSingleton((sp) => null)`, que é código válido, porém o tipo retornado seria `Null`.

Para ser avisado sobre estes casos, você deve ligar o `strict-inference` no analizador lingüístico em seu arquivo `analysis_options.yaml`:

```yaml
analyzer:
  language:
    strict-inference: true
```

Esta configuração irá lhe prover avisos como este:

```dart
ServiceProvider.instance.getService();
```

```text
The type argument(s) of the function 'getService' can't be inferred. 
Use explicit type argument(s) for 'getService'.

(O(s) argumento(s) de tipo da função 'getService' não podem ser inferidos.
Use argumento(s) de tipo explicitamente para 'getService'.)
```