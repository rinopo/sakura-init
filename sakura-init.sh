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

# Flag if on Mac.
if [[ $OSTYPE == "darwin"* ]]; then
  readonly Os="Mac"
else
  readonly Os=""
fi



#### Actually do something.

## Open control panel.

if [ ${Os} == "Mac" ]; then
  echo "ブラウザでサーバーコントロールパネルを開きます。"
  open -g "https://secure.sakura.ad.jp/rscontrol/?domain=${User}.sakura.ne.jp"
fi


## Change password.

read -p "管理者パスワードを変更 [y/n] " -n 1 -r
echo # Move to a new line.
if [[ $REPLY =~ ^[Yy]$ ]]; then
  ssh ${User} -t "passwd"
fi


## Log settings.

echo "アクセスログを設定"

echo "if [ ! -d '/home/${User}/log' ]; then mkdir ~/log; echo '  ~/log ディレクトリを作成。'; fi" | ssh ${User} bash
ssh ${User} "echo ${Log_months} > ~/log/month"  && echo "  保存期間：${Log_months}ヶ月"
ssh ${User} "touch ~/log/.errorsave" && echo "  エラーログ：残す"
ssh ${User} "touch ~/log/.vhostsave" && echo "  ホスト名の情報：残す"



exit 0
