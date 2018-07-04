#!/usr/bin/env bash

# Fail on command errors and unset variables.
set -e -u -o pipefail

# Prevent commands misbehaving due to locale differences.
export LC_ALL=C

# Ensure permissions of created files to be 600.
umask 177


#### Preparation.

## Arguments.

readonly User=$1


## Audits.

# さくらのレンタルサーバのユーザー名として正当か？
#
# > ・半角英数字とハイフン(-)が使えます。
# > ・3～16文字でご設定ください。
# > ・数字のみの文字列、最初および末尾のハイフン(-)は利用できません。
# cf. https://secure.sakura.ad.jp/signup2/rentalserver.php

readonly Regex1="^[0-9a-z]{1}[0-9a-z-]{1,14}[0-9a-z]{1}$"
readonly Regex2="^[0-9]+$"
if [[ ! ${User} =~ ${Regex1} || ${User} =~ ${Regex2} ]]; then
  echo "❌️ さくらのレンタルサーバのユーザー名を正しく入力してください。"
  exit 1
fi

# SSH ログインできるか？
if ( ssh $User "exit" ); then
  echo "SSH OK"
else
  echo "❌️ ${User}.sakura.ne.jp に SSH ログインできませんでした。"
  echo "  SSH 用のキーペアをセットアップして、"
  echo "  ssh $User というコマンドでログインできる状態となっていることを確認してください。"
  exit 1
fi


## Constants

# Settings.
readonly Log_months="24"
readonly Docroots="{prd,stg,dev}/public"
readonly Repo="https://github.com/rinopo/sakura-init/raw/master"


# Flag if on Mac.
if [[ $OSTYPE == "darwin"* ]]; then
  readonly Os="Mac"
else
  readonly Os=""
fi



#### Actually do something.

## Open server control panel.

if [ ${Os} == "Mac" ]; then

  read -p "ブラウザでサーバコントロールパネルを開く [y/n] " -n 1 -r
  echo ""
  if [[ ${REPLY} =~ ^[Yy]$ ]]; then
    open -g "https://secure.sakura.ad.jp/rscontrol/?domain=${User}.sakura.ne.jp"
  fi

fi


## Change password.

echo "--"
read -p "管理者パスワードを変更 [y/n] " -n 1 -r
echo ""
if [[ ${REPLY} =~ ^[Yy]$ ]]; then
  ssh ${User} -t "passwd"
fi


## Log settings.

echo "--"
read -p "アクセスログを設定 [y/n] " -n 1 -r
echo ""
if [[ ${REPLY} =~ ^[Yy]$ ]]; then

  ssh ${User} "mkdir -v -p ~/log"
  ssh ${User} "echo ${Log_months} > ~/log/month" \
    && echo "  保存期間：${Log_months}ヶ月"
  ssh ${User} "touch ~/log/.errorsave" \
    && echo "  エラーログ：残す"
  ssh ${User} "touch ~/log/.vhostsave" \
    && echo "  ホスト名の情報：残す"

fi


## Create doc-roots.

echo "--"
read -p "DocumentRoot ディレクトリの作成 [y/n] " -n 1 -r
echo ""
if [[ ${REPLY} =~ ^[Yy]$ ]]; then

  echo "  新規に作成されたディレクトリが以下に表示されます。"
  ssh ${User} "mkdir -v -p ~/www/${Docroots}" \
    && echo "  サーバーコントロールパネルの「ドメイン設定 ＞ 新しいドメインの追加」にて、独自ドメインを追加してください。"

fi


## Create `.htaccess`.

echo "--"
read -p ".htaccess の設置 [y/n] " -n 1 -r
echo ""
if [[ ${REPLY} =~ ^[Yy]$ ]]; then

  echo ""
  ssh ${User} "umask 177; cd ~/www; curl -fsSL -O ${Repo}/.htaccess && cat .htaccess"

fi


## Create `.ftpaccess`.

echo "--"
read -p ".ftpaccess の設置 [y/n] " -n 1 -r
echo ""
if [[ ${REPLY} =~ ^[Yy]$ ]]; then

  echo ""
  ssh ${User} "umask 177; curl -fsSL -O ${Repo}/.ftpaccess && cat .ftpaccess"

fi


## Create `.my.cnf`.

echo "--"
read -p ".my.cnf の設置 [y/n] " -n 1 -r
echo ""
if [[ ${REPLY} =~ ^[Yy]$ ]]; then

  read -p "DBのユーザー名 [${User}]: " -r
  if [ "${REPLY}" == "" ]; then
    readonly Db_user=${User}
    echo ${User}
  else
    readonly Db_user=${REPLY}
  fi
  echo ""

  read -p "DBのパスワード: " -r -s
  readonly Db_password=${REPLY}
  echo ""

  read -p "DBのホスト名: " -r
  if [[ ${REPLY} =~ ^mysql ]]; then
    readonly Db_host=${REPLY}
  fi
  echo ""

  echo ""
  ssh ${User} "umask 177; curl -fsSL -O ${Repo}/.my.cnf &&\
    sed -i '' -e 's|%%DB_USER%%|${Db_user}|g' .my.cnf &&\
    sed -i '' -e 's|%%DB_PASSWORD%%|${Db_password}|g' .my.cnf &&\
    sed -i '' -e 's|%%DB_HOST%%|${Db_host}|g' .my.cnf &&\
    cat .my.cnf"

fi


exit 0
