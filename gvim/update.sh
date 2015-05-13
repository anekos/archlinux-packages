#!/bin/bash

set -e

if [ -d src/vim-repo ]
then
  cd src/vim-repo
  hg pull -u
else
  mkdir src
  cd src
  hg clone 'https://vim.googlecode.com/hg' vim-repo
fi

tag=$(hg tags | asort -k2 -o 1 -rn | grep '^v' | head -1)
lastver=$(echo "$tag" | tr '-' '.' | sed 's/^v//')

hg checkout "$tag"

cd - > /dev/null

topver=$(echo "$lastver" | awk -F. 'BEGIN{OFS="."} {print $1,$2}')
patchlevel=$(echo "$lastver" | awk -F. 'BEGIN{OFS="."} {print $3}')

sed -i "s/^_topver=.*/_topver=$topver/" PKGBUILD
sed -i "s/^_patchlevel=.*/_patchlevel=$patchlevel/" PKGBUILD

sysver=$(LC_ALL=C pacman -Qi gvim-python3 | grep Version | sed 's/.*: //' | sed 's/-.*//')

# 変更があるか？
if [ "$sysver" = "$lastver" ]
then
  echo -e '\e[41mUp to date\e[0m'
  exit 0
fi


echo "Current version: $topver.$patchlevel"
git diff --stat

rm *.tar.xz ||:

makepkg -f

sudo pacman -U gvim-python3-$topver.$patchlevel-*.tar.xz vim-runtime-$topver.$patchlevel*.tar.xz

git commit PKGBUILD -m 'Automatic'

echo 'push? (YES/no): '
read q
if [ ! "$q" = 'no' ] || [ "$q" = 'yes' ]
then
  git push
fi
