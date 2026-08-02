# Smart Market List

Aplicativo Flutter de listas de compras com Firebase e RevenueCat.

## Regras dos planos

- Premium Individual: pode compartilhar listas específicas com qualquer
  pessoa autenticada. O convidado recebe somente a lista aceita e não recebe
  Premium.
- Premium Família: o titular pode convidar uma pessoa para o espaço completo.
  O convidado herda Premium enquanto a assinatura Família do titular estiver
  ativa.
- Expiração, cancelamento ou downgrade revoga no servidor os recursos e
  compartilhamentos que dependiam daquele plano.

As permissões são validadas pelas regras Firebase e pelas Cloud Functions; o
cliente não pode conceder Premium, alterar membros ou consumir convites
diretamente.

## Desenvolvimento

```sh
flutter pub get
flutter test
flutter run
```

Antes de publicar, siga integralmente o
[guia de segurança e implantação](SECURITY_DEPLOYMENT.md).
