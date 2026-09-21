# PowerBankMenu リリース手順

## 公証用プロファイルの固定

公証の認証設定は [`scripts/notarize.sh`](../scripts/notarize.sh) を唯一の定義元とします。

| 項目 | 固定値 |
| --- | --- |
| プロファイル名 | `powerbankmenu-notary` |
| Developer Team ID | `23889H77KX` |
| 保存先 | `$HOME/Library/Keychains/login.keychain-db` |

登録、認証確認、送信、処理状況の取得はすべてこのスクリプトを使用します。環境変数やコマンドライン引数によるプロファイル名の変更、および他プロジェクトのプロファイルへの自動切り替えはありません。設定変更が必要な場合はスクリプトとこの手順を同時に変更してください。

### 初回登録・パスワード再発行後

Apple Developerの対象チームに所属するApple Accountでアプリ用パスワードを発行し、このリポジトリを開いた通常のターミナルで実行します。

```sh
./scripts/notarize.sh setup
./scripts/notarize.sh check
```

最初にApple IDを入力し、続いて`notarytool`の非表示プロンプトにアプリ用パスワードを入力してください。パスワードはチャット、スクリプト、環境変数、コマンド引数、リポジトリに書かず、画面録画やシェルのトレースも使用しません。認証情報はAppleによる検証後に固定プロファイルへ保存されます。既存の同名プロファイルがある場合は更新されます。

プロファイル名をコードに定義しただけではキーチェーン項目は作成されません。`setup`と`check`が成功して初めて登録完了です。現在の設定だけを確認する場合は`./scripts/notarize.sh profile`を使用します。

## アーカイブと署名

1. 変更差分・UI検証を確認し、XcodeプロジェクトのMarketing VersionとBuild Numberを更新します。
2. Releaseでアーカイブします。配布物やログはGit対象外の`build/`に置きます。
3. `developer-id`方式、`destination=export`、`signingStyle=automatic`、上記のTeam IDで書き出します。Xcode管理プロファイルをmanual signingとして指定しないでください。
4. `codesign --verify --deep --strict`、アプリ内バージョン、アーキテクチャ、entitlementsを確認します。署名検証の成功だけでは公証済みとは扱いません。

## 公証と配布物の確定

以下は1.2.1での実行例です。今後のリリースではバージョンと出力ディレクトリを置き換えます。プロファイル名は変更しません。

```sh
./scripts/notarize.sh check

ditto -c -k --sequesterRsrc --keepParent \
  build/release-1.2.1/export/PowerBankMenu.app \
  build/release-1.2.1/PowerBankMenu-1.2.1.zip

./scripts/notarize.sh submit build/release-1.2.1/PowerBankMenu-1.2.1.zip \
  > build/release-1.2.1/notarization-submit.json
```

返されたJSONの`id`を保管し、同じIDで状況を追跡します。

```sh
./scripts/notarize.sh info SUBMISSION_ID
./scripts/notarize.sh wait SUBMISSION_ID
```

`wait`は最大60秒で戻ります。タイムアウトしてもApple側の処理は継続するため、再送信せず同じIDで確認してください。`Invalid`などの結果では`./scripts/notarize.sh log SUBMISSION_ID`で原因を確認します。送信結果が不明な場合も、Apple側の受付状態を確認せず再送信しないでください。

`Accepted`を確認した後、以下を実行します。

```sh
./scripts/notarize.sh staple build/release-1.2.1/export/PowerBankMenu.app

ditto -c -k --sequesterRsrc --keepParent \
  build/release-1.2.1/export/PowerBankMenu.app \
  build/release-1.2.1/PowerBankMenu-1.2.1.zip

(cd build/release-1.2.1 && shasum -a 256 PowerBankMenu-1.2.1.zip > SHA256SUMS.txt)
```

`staple`はチケット添付、添付検証、署名検証、Gatekeeper評価を順に行い、いずれかが失敗すれば停止します。ZIPとチェックサムは必ずチケット添付後に作り直します。

## GitHub公開

1. ソースをcommit・pushし、対象コミットにバージョンタグを作成してpushします。既存の公開タグを上書きしません。
2. GitHub Releaseの草稿に最終ZIP・`SHA256SUMS.txt`・README・LICENSEを添付します。今回の1.2.1草稿には公証前のZIPがあるため、最終ZIPとチェックサムを置き換えます。
3. 公証`Accepted`、staple検証、Gatekeeper受理、添付ファイルのSHA-256一致を確認して草稿を公開します。公証保留の記述も実際の結果に合わせて更新します。
4. リリースが草稿でないこと、タグの対象コミット、remoteとの一致、作業ツリーの状態を再確認します。後続の手順書のみのコミットがある場合、mainとリリースタグの差分が意図した内容かも確認します。

参考: [Apple — Customizing the notarization workflow](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow)。実際のCLI仕様は使用するXcodeの`xcrun notarytool … --help`でも確認してください。
