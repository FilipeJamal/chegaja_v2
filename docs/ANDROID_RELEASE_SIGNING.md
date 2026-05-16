# Android Release Signing

Data: 2026-05-16

## Estado

O projeto ja tem suporte Gradle para signing release em
`android/app/build.gradle.kts`, lendo `android/key.properties`.

Os ficheiros sensiveis estao protegidos por `android/.gitignore`:

```text
key.properties
**/*.keystore
**/*.jks
```

Nao commitar:

- `android/key.properties`;
- `android/app/upload-keystore.jks`;
- passwords;
- backups da keystore.

## Criar keystore local

Exemplo para gerar uma upload key local:

```powershell
keytool -genkey -v -keystore android/app/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Guardar a keystore e passwords num cofre. Se esta chave for usada na Play
Store, perder a keystore pode bloquear updates futuros caso Play App Signing
nao esteja configurado corretamente.

## Criar android/key.properties

Criar `android/key.properties` com este formato:

```properties
storePassword=CHANGE_ME
keyPassword=CHANGE_ME
keyAlias=upload
storeFile=app/upload-keystore.jks
```

No Windows, evitar criar este ficheiro em UTF-16. O Gradle usa
`java.util.Properties` e pode nao ler as chaves se o ficheiro estiver em
UTF-16. Usar ASCII/UTF-8 simples. Exemplo seguro no PowerShell:

```powershell
Set-Content -Path android/key.properties -Encoding ascii -Value @(
  'storePassword=CHANGE_ME',
  'keyPassword=CHANGE_ME',
  'keyAlias=upload',
  'storeFile=app/upload-keystore.jks'
)
```

Substituir `CHANGE_ME` localmente. Nao colar passwords em logs, issues, PRs ou
commits.

## Verificar signing

```powershell
cd android
.\gradlew.bat :app:signingReport
cd ..
```

Resultado esperado para `Variant: release`:

```text
Store: C:\...\chegaja_v2\android\app\upload-keystore.jks
Alias: upload
```

Se aparecer `Store: null`, verificar:

- se `android/key.properties` existe;
- se `storeFile` aponta para `app/upload-keystore.jks`;
- se o ficheiro nao esta em UTF-16;
- se passwords e alias batem com a keystore.

## Gerar artefatos release

```powershell
flutter build apk --release
flutter build appbundle --release
```

Artefatos esperados:

```text
build/app/outputs/flutter-apk/app-release.apk
build/app/outputs/bundle/release/app-release.aab
```

## Rotina antes de commit

Antes de commitar, confirmar:

```powershell
git status --short --ignored
```

O Git pode mostrar `android/key.properties` e `android/app/upload-keystore.jks`
como ignorados. Eles devem continuar fora do commit.
