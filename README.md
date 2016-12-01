# sakura-init

さくらのレンタルサーバを借りたとき最初にすること

## SSH 用のキー・ペアを作成して登録

鍵を作成して登録しておくことで、パスワード無しで SSH ログインできるようになる。

[rinopo/sakura-ssh-setup](https://github.com/rinopo/sakura-ssh-setup) を参照。


## 管理者パスワードの変更

初期パスワードはメールで平文で送られてくる。ちゃんと推測されにくいパスワードに変更しておく。  

```sh-session
% passwd
Changing local password for XXX
Old Password:
New Password:
Retype New Password:
```

＊上記コマンドで[サーバーコントロールパネル](https://secure.sakura.ad.jp/rscontrol/)のパスワードも連動して変わる。

参考：[メールアドレスとパスワードの設定で利用できる文字列 – さくらのサポート情報](https://help.sakura.ad.jp/hc/ja/articles/206108842)


## アクセスログの設定

アクセスログは、なるべく多くの情報を残す設定にしておく。

- 「残す」
- 「エラーログも残す」
- 保存期間「24」ヶ月
- ホスト名の情報「残す」

```sh-session
% mkdir ~/log
% touch ~/log/.errorsave
% echo '24' > ~/log/month
% touch ~/log/.vhostsave
```


## 国外IPアドレスフィルタの設定

デフォルトは「有効」で、海外からアクセス時、メール送信、WP／MTの更新等が不可となっている。

参考：[国外IPアドレスフィルタ – さくらのサポート情報](https://help.sakura.ad.jp/hc/ja/articles/206054272)

ステークホルダーに確認をとり、頻繁に海外からアクセスする機会があるなら、「無効」にしておく必要があるかもしれない。

なお、「有効」にしていてる場合でも、Gmail のアカウント設定でさくらのレンタルサーバーの SMTP 情報を設定してメール送信することは可能とのこと（カスタマーセンターからの回答）。


## ドメインの設定

独自ドメインをさくらインターネット以外で取得したなら、「他社ドメインの追加」にて、独自ドメインを追加する。

以下は設定の例。

本番サイトと同じ階層、同じ条件でテスト・サイトを作成したいので、デフォルトの DocumentRoot（`~/www`）は利用せず、以下のようにディレクトリを切る。

| ドメイン | DocumentRoot | 用途 |
| --- | --- | --- |
| www | `~/www/prd/public` | 本番環境（Production） |
| stg | `~/www/stg/public` | 確認環境（Staging） |
| dev | `~/www/dev/public` | 開発環境（Development） |
| ... | `~/www/.../public` | ... |

```sh-session
% mkdir -p ~/www/{prd,dev,stg}/public
```

本来の DocumentRoot 直下（`~/www`）には、空の `index.html` を置いておく。

```csh
% touch ~/www/index.html
```

サーバーコントロールパネルからのドメインの追加は、以下のようにする。

- ネイキッド・ドメイン：
  - 「wwwを付与せずマルチドメインとして使用する（上級者向け）」
  - 指定フォルダ：`/prd/public`
  - SPFを利用する：有効
- www：
  - 「wwwを付与せずマルチドメインとして使用する（上級者向け）」
  - 指定フォルダ：`/prd/public`
  - SPFを利用する：無効（デフォルト）
- stg：
  - 「wwwを付与せずマルチドメインとして使用する（上級者向け）」
  - 指定フォルダ：`/stg/public`
  - SPFを利用する：無効（デフォルト）
- dev：
  - 「wwwを付与せずマルチドメインとして使用する（上級者向け）」
  - 指定フォルダ：`/dev/public`
  - SPFを利用する：無効（デフォルト）

＊「wwwを付与せずマルチドメインとして使用する」を選択するのは、本番サイトと同じ同じ条件でテスト・サイトを作成したいため。また、 `www.dev.example.com` などの余計なドメインを存在させたくないため。


## `.htaccess` の設置

デフォルトの DocumentRoot（`~/www`）のほうに、以下のような内容の `.htaccess` を置いておく（一例）。

＊ここでの設定は、下層に設置したサイト（たとえば上記の `~/www/dev/public` ＝ http://dev.example.com ）へのアクセスに対しても有効となる。

```apache
# ディレクトリ一覧の拒否。
DirectoryIndex index.html index.htm index.shtml index.php index.cgi .ht

# XXX.sakura.ne.jp へのアクセスを拒否（404）。
RewriteEngine on
RewriteCond %{HTTP_HOST} .*\.sakura\.ne\.jp$ [nocase]
RewriteCond %{REMOTE_ADDR} !^27\.133\.139\.(3[2-9]|4[0-7])$
RewriteRule .* - [R=404]
```

ディレクトリ一覧を禁止するには、（さくらのレンタルサーバーでは `Options -Indexes` は利用できないので、）`IndexIgnore *` を利用する（エラーにならないが何も表示されない）か、上記のように `DirectoryIndex` の最後に `.ht` を記述する（403エラーになる）。

デフォルトのドメイン `XXX.sakura.ne.jp` にアクセスできる必要がないなら、拒否しておく。

＊`27.133.139.32/28` は「さくらのシンプル監視」が利用するIPなので、アクセス元を拒否対象から除外しておく。


## `.ftpaccess` の設置

ホームディレクトリ直下に以下のような `.ftpaccess` を置いておくことで、FTP/FTPS でのアクセスを防止できる（SFTP は、ひきつづき利用可能）。

＊ログインそのものはできるが、その後の操作ができない。平文のFTPでアクセスする習慣をやめさせることができるという程度の、間接的なセキュリティ対策。

```
<Limit ALL>
Order Allow,Deny
Allow from 59.106.18.131
Deny from all
</Limit>
```

＊`59.106.18.131` は、「さくらのブログ」が使用する（らしい）。

参考：[.ftpaccess でFTP接続元を制御する – さくらのサポート情報](https://help.sakura.ad.jp/hc/ja/articles/206206721)


## データベースの作成

DBが必要な場合は作成する。

以下は設定例。

DB名は以下のようにする。

| ドメイン | DB名 |
| --- | --- |
| (www) | `XXX_prd_wp` |
| dev | `XXX_dev_wp` |
| stg | `XXX_stg_wp` |
| ... | `XXX_..._wp` |

冒頭の `XXX_`（ユーザー名）はさくらレンタルサーバの既定で変えられない。そのあとの `prd` / `dev` / `stg` はドメインの設定に合わせている。末尾に DB の利用目的（利用するアプリケーション）がわかる名前（`mt` / `wp` など）を付けておく。

DB の文字コードは、（特段の理由がなければ）「UTF-8」にする（デフォルトの「EUC-JP」ではなく）。

パスワードはちゃんと推測されにくいものにする。

データベース・サーバの名前（mysqlXXX.db.sakura.ne.jp）はこの画面でしか確認できないので、メモっておく。


## 「シンプル監視」の設定

さくらのクラウドの管理画面から、[「シンプル監視」を設定](https://secure.sakura.ad.jp/cloud/iaas/#!/appliance/simplemonitor/)する。

＊管理画面へのログインは、契約時のさくらの会員IDでできる（さくらのレンタルサーバのアカウントではなく）。

「シンプル監視」は、対象がさくらのサーバー（さくらのレンタルサーバも含む）であれば無償。1分おきに HTTP や HTTPS を監視し、落ちてたらメールやslackで通知が来るようにできる。

参考：[シンプル監視 – さくらのサポート情報](https://help.sakura.ad.jp/hc/ja/articles/206217402)

- 既存の設定をコピーして、以下のような項目を適宜設定。
  - 監視対象のサーバーのIPアドレスを指定。
  - HTTP を監視対象にする（適宜、HTTPS も）。

---

## 新規ユーザー作成時のデフォルト値の指定

＊ビジネス、ビジネスプロ、マネージドのみ。

`~/.cpanelrc` として以下のようなファイルを置いておくことで、新規ユーザー作成時のデフォルト値を設定できる。

```
Mail	1
MailQuota	6144
VirusScan	1
SpamFilter	1
SpamAction	0
```

`Mail` `VirusScan` `SpamFilter` は `0|1`。

`SpamAction` は以下の値をとる。

- 0：フィルタのみ利用（ヘッダに X-Spam-Flag: YES を追加）
- 1：「迷惑メール」フォルダに保存（推奨）
- 2：メールを破棄（迷惑メールでないメールも破棄する恐れがあります）
