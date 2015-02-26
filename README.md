# sync_git_svn

## 概要

gitのリポジトリのremotes/origin/masterブランチをsvnのリポジトリに同期させます。

## 前提

* svnのリポジトリは新たに作成して準備するものとします。
* svnのリポジトリにはブランチやタグなどの情報を同期させません。
* svnのリポジトリの同期対象のルートディレクトリのlicense属性を利用して同期をとります。
* svnのリポジトリを新たに作成した場合は以下のように初期化してください。

```shell
svn propedit license file:///home/svn/svnrepos --editor-cmd "echo '' >" -m ""
```

## 例のパラメータ

* svnのリポジトリのURL
 * file:///home/svn/svnrepos
* gitのリポジトリのURL
 * ssh://github.com/sadapon2008/myproject.git

## 例：svnのリポジトリの準備

svnのリポジトリを新たに作成します。svnにコミットがないと動作しないので空コミットを行います。

ここでは例としてローカルに作成します。

```shell
svnadmin create /home/svn/svnrepos
svn co file:///home/svn/svnrepos
cd svnrepos
svn propset license '' .
svn commit -m ''
```

## 例：gitのリポジトリとの同期

作業用の空ディレクトリを準備してからスクリプトを実行します。

```shell
mkdir work
curl -LO https://github.com/sadapon2008/sync_git_svn/raw/master/sync_git_svn.sh
/bin/bash sync_git_svn.sh ssh://github.com/sadapon2008/myproject.git file:///home/svn/svnrepos ./work
rm -rf work
```

svnのリポジトリにtrunkがある場合は以下のようになります。

```shell
mkdir work
curl -LO https://github.com/sadapon2008/sync_git_svn/raw/master/sync_git_svn.sh
/bin/bash sync_git_svn.sh ssh://github.com/sadapon2008/myproject.git file:///home/svn/svnrepos/trunk ./work
rm -rf work
```
