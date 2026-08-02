# Implantação segura

O backend e os índices podem ser implantados antes da nova versão, mas as
regras restritivas e a limpeza de dados Premium só devem ser ativadas depois
que o cliente atualizado tiver sido publicado e sua adoção estiver validada.
Isso evita interromper versões antigas e preserva os dados dos usuários durante
a migração.

## Estado verificado do projeto

- Projeto: `smart-market-list-82bf7`.
- Firestore `(default)`: Native/Standard em `southamerica-east1`.
- Authentication, Storage e o Hosting padrão já existem.
- Apps Android e iOS estão registrados e os arquivos locais foram alinhados
  com esses registros.
- As Cloud Functions, o webhook do RevenueCat e a tarefa agendada de
  reconciliação foram implantados.
- Os secrets `REVENUECAT_SECRET_API_KEY` e `REVENUECAT_WEBHOOK_AUTH` foram
  criados no Secret Manager.
- A proteção contra exclusão do Firestore está ativa e existe um agendamento
  de backup diário com retenção de sete dias. O primeiro backup ainda precisa
  ser confirmado antes da migração.
- Os índices de Firestore necessários já foram implantados.
- O Hosting e os arquivos de associação de links Android/iOS foram implantados
  e verificados no domínio padrão do projeto.
- O App Check está integrado ao Flutter e os apps Android/iOS estão registrados
  com Play Integrity, App Attest e DeviceCheck. Não habilite enforcement antes
  de publicar e medir uma versão que envie tokens válidos.

## Pré-requisitos

1. O projeto Firebase deve estar no plano Blaze, com Cloud Functions,
   Cloud Scheduler, Firestore, Storage e Hosting habilitados.
2. No RevenueCat, confirme os entitlements exatos:
   `premium_individual` e `premium_family`.
3. Use uma chave secreta RevenueCat v1 com acesso ao projeto. Ela é necessária
   para consultar a assinatura e excluir o assinante quando a conta é apagada.
4. Confirme no Play Console se o SHA-256 publicado corresponde ao valor em
   `public/.well-known/assetlinks.json`.

## Segredos

Execute sem colocar os valores no repositório:

```sh
firebase functions:secrets:set REVENUECAT_SECRET_API_KEY \
  --project smart-market-list-82bf7

firebase functions:secrets:set REVENUECAT_WEBHOOK_AUTH \
  --project smart-market-list-82bf7
```

O valor de `REVENUECAT_WEBHOOK_AUTH` deve ser uma credencial longa e aleatória,
por exemplo com o prefixo `Bearer `. O header `Authorization` configurado no
webhook do RevenueCat deve ser exatamente igual ao valor salvo no secret.

## Migração de um app que já está nas lojas

Não implante imediatamente as regras restritivas: versões antigas do app ainda
não chamam o novo backend e podem deixar de sincronizar ou restaurar compras.

1. Ative o plano Blaze, defina alertas/orçamentos e habilite proteção contra
   exclusão do Firestore.
2. Antes de migrar dados, configure um backup diário ou PITR conforme o custo e
   a retenção desejados.
3. Crie os secrets e implante somente Functions e índices.
4. Antes das Functions, registre qualquer acesso administrativo ou vitalício
   que não exista no RevenueCat em `subscription_grants/{firebaseUid}`.
5. Configure RevenueCat, execute `refreshActiveSubscriptions` uma vez e valide
   uma amostra de titulares, convidados e usuários Free.
6. Publique a nova versão do app com o backend e App Check em modo de
   monitoramento, ainda sem enforcement.
7. Depois de medir a adoção e resolver clientes antigos, implante as regras
   Firestore/Storage. O Hosting pode permanecer publicado independentemente.
8. Habilite enforcement do App Check gradualmente apenas quando as métricas
   mostrarem que praticamente todo o tráfego legítimo já está verificado.

### Acesso administrativo ou vitalício

Uma concessão manual nunca deve depender apenas dos campos `isPremium` e
`planType` do usuário, porque o sincronizador precisa distinguir esse acesso
legítimo de uma assinatura RevenueCat expirada.

Crie o documento `subscription_grants/{firebaseUid}` somente pelo Console ou
Admin SDK, com:

```text
active: true
planType: "premium_family"        # ou "premium_individual"
expiresAt: null                  # null significa vitalício
```

O aplicativo não possui acesso de leitura ou gravação nessa coleção. O backend
materializa a concessão nos campos autoritativos do usuário com
`purchaseSource: "administrative_grant"`. Uma concessão Família vitalícia
preserva também o acesso herdado do convidado.

## Implantação técnica

Implante primeiro o backend e os índices:

```sh
firebase deploy \
  --project smart-market-list-82bf7 \
  --only firestore:indexes,functions
```

No Cloud Scheduler, execute uma vez a tarefa criada para
`refreshActiveSubscriptions`. Ela migra os titulares Premium antigos para os
campos autoritativos novos antes de as regras restritivas entrarem em vigor.
Confirme em uma amostra de usuários que `purchasePremium`,
`purchasePlanType`, `purchaseExpiresAt`, `effectiveExpiresAt` e, para
convidados Família, `familyAccessExpiresAt` foram gravados.

Depois da validação e adoção da nova versão, implante as regras:

```sh
firebase deploy \
  --project smart-market-list-82bf7 \
  --only firestore:rules,storage
```

Versões antigas não possuem o fluxo de convites por Cloud Functions e,
corretamente, não conseguirão mais alterar Premium ou membros diretamente
depois que as regras restritivas forem ativadas.

Depois do deploy, configure no RevenueCat um webhook para:

```text
https://southamerica-east1-smart-market-list-82bf7.cloudfunctions.net/revenueCatWebhook
```

Confirme primeiro se o plano RevenueCat contratado inclui webhooks. As
notificações fazem a revogação rapidamente. A função agendada
`refreshActiveSubscriptions` também revisa assinaturas ativas a cada seis
horas como contingência, e o app sincroniza o status ao iniciar e após compras.

## Verificação obrigatória

Teste em um projeto de homologação:

1. Usuário Free não consegue escrever `isPremium`, plano, família ou membros.
2. Premium Individual compartilha uma lista com um usuário Free; esse usuário
   não lê notas, receitas favoritas nem outras listas.
3. Ao expirar o Premium do titular, a lista compartilhada deixa de abrir.
4. Premium Família compartilha o espaço completo com uma pessoa.
5. Ao cancelar, expirar ou trocar Família por Individual, o convidado volta ao
   espaço pessoal e perde o Premium herdado.
6. Se o convidado tiver Premium próprio, ele mantém somente a assinatura
   própria e perde imediatamente o espaço e o cache do titular.
7. Exclusão de conta remove Auth, Firestore, Storage e o assinante RevenueCat.
8. Links universais abrem o app em Android e iOS.

Antes de tráfego público, também habilite Firebase App Check no console e faça
uma implantação gradual da exigência para Firestore, Storage e Functions. Não
ative a exigência antes de registrar as versões Android/iOS, pois clientes
legítimos seriam bloqueados.

Referências: [segredos em Cloud Functions](https://firebase.google.com/docs/functions/config-env),
[regras de campos do Firestore](https://firebase.google.com/docs/firestore/security/rules-fields),
[webhooks RevenueCat](https://www.revenuecat.com/docs/integrations/webhooks).
