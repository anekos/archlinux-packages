#!/bin/bash


cd src/vim-repo
hg pull -u
tag=$(hg tags | asort -k2 -o 1 -rn | grep '^v' | head -1 | tr '-' '.' | sed 's/^v//')
cd - > /dev/null

topver=$(echo "$tag" | awk -F. 'BEGIN{OFS="."} {print $1,$2}')
patchlevel=$(echo "$tag" | awk -F. 'BEGIN{OFS="."} {print $3}')

sed -i "s/^_topvar=.*/_topvar=$topver/" PKGBUILD
sed -i "s/^_patchlevel=.*/_patchlevel=$patchlevel/" PKGBUILD

sysver=$(LC_ALL=C pacman -Qi gvim-python3 | grep Version | sed 's/.*: //' | sed 's/-.*//')

# 変更があるか？
changed=$(git diff | wc -l)
if [ "$changed" -eq 0 ] && [ "$sysver" = "$tag" ]
then
  echo -e '\e[41mUp to date\e[0m'
  exit 0
fi


echo "Current version: $topvar.$patchlevel"
git diff --stat

rm *.tar.xz

makepkg -f

sudo pacman -U gvim-python3-$topvar.$patchlevel-*.tar.xz vim-runtime-$topvar.$patchlevel*.tar.xz

git commit PKGBUILD -m 'Automatic'

echo 'push? (YES/no): '
read q
if [ ! "$q" = 'no' ] || [ "$q" = 'yes' ]
then
  git push
fi
