#!/bin/bash

# requirements: xmlstarlet

if [ -z "${1}" -o -z "${2}" -o -z "${3}" ]; then
  echo "usage:"
  echo "  ${0} svn_url git_url temp_dir"
  exit 1
fi

if [ ! -d "${3}" ]; then
  echo "error: temp_dir is not directory"
  exit 1
fi

if [ $(ls -aU1 "${3}" |wc -l) -gt 2 ]; then
  echo "error: temp_dir is not empty"
  exit 1
fi

pushd ${3}
if [ "${?}" != 0 ]; then
  exit 1
fi

echo "svn propget license ${1}"
MY_SVN_GIT_REV=$(svn propget license ${1})
if [ "${?}" != 0 ]; then
  popd
  exit 1
fi

echo "git clone ${2} ."
git clone ${2} .
if [ "${?}" != 0 ]; then
  unset MY_SVN_GIT_REV
  popd
  exit 1
fi

echo "git svn init ${1}"
git svn init ${1}
if [ "${?}" != 0 ]; then
  unset MY_SVN_GIT_REV
  popd
  exit 1
fi

echo "git svn fetch"
git svn fetch
if [ "${?}" != 0 ]; then
  unset MY_SVN_GIT_REV
  popd
  exit 1
fi

MY_SVN_REV_CURRENT=$(svn log --xml ${1} | xmlstarlet sel -t -v "//logentry[./msg/text()='${MY_SVN_GIT_REV}']/@revision")
if [ -z "${MY_SVN_REV_CURRENT}" ]; then
  unset MY_SVN_REV_CURRENT
  unset MY_SVN_GIT_REV
  popd
  exit 1
fi

MY_SVN_REV_LATEST=$(svn log --xml ${1} | xmlstarlet sel -t -v "//logentry/@revision")
if [ -z "${MY_SVN_REV_LATEST}" ]; then
  unset MY_SVN_REV_LATEST
  unset MY_SVN_REV_CURRENT
  unset MY_SVN_GIT_REV
  popd
  exit 1
fi

if [ "${MY_SVN_REV_CURRENT}" == "${MY_SVN_REV_LATEST}" ]; then
  echo "info: skipped (up to date)"
  unset MY_SVN_REV_LATEST
  unset MY_SVN_REV_CURRENT
  unset MY_SVN_GIT_REV
  popd
  exit 0
fi

MY_SVN_HASH_CURRENT=$(git log remotes/git-svn --grep "git-svn-id.*@${MY_SVN_REV_CURRENT}" --pretty=%H)
if [ -z "${MY_SVN_HASH_CURRENT}" ]; then
  echo "error: not found commit for svn r${MY_SVN_REV_CURRENT}"
  unset MY_SVN_HASH_CURRENT
  unset MY_SVN_REV_LATEST
  unset MY_SVN_REV_CURRENT
  unset MY_SVN_GIT_REV
  popd
  exit 1
fi
unset MY_SVN_REV_CURRENT

MY_SVN_HASH_NEXT=$(git rev-list remotes/git-svn | grep -B1 ${MY_SVN_HASH_CURRENT} | head -n1)
if [ -z "${MY_SVN_HASH_NEXT}" -o "${MY_SVN_HASH_CURRENT}" == "${MY_SVN_HASH_NEXT}" ]; then
  echo "error: not found commit next to ${MY_SVN_HASH_CURRENT}"
  unset MY_SVN_HASH_NEXT
  unset MY_SVN_HASH_CURRENT
  unset MY_SVN_REV_LATEST
  unset MY_SVN_GIT_REV
  popd
  exit 1
fi

echo "${MY_SVN_HASH_NEXT} ${MY_SVN_GIT_REV}" >.git/info/grafts
unset MY_SVN_HASH_NEXT
unset MY_SVN_HASH_CURRENT
unset MY_SVN_REV_CURRENT

echo "git merge -X theirs --no-ff -m \"merge svn r${MY_SVN_REV_LATEST}\" remotes/git-svn"
git merge -X theirs --no-ff -m "merge svn r${MY_SVN_REV_LATEST}" remotes/git-svn
if [ "${?}" != 0 ]; then
  unset MY_SVN_REV_LATEST
  unset MY_SVN_GIT_REV
  popd
  exit 1
fi
unset MY_SVN_REV_LATEST

rm -f .git/info/grafts

echo "git push -u origin master"
git push -u origin master
if [ "${?}" != 0 ]; then
  unset MY_SVN_GIT_REV
  popd
  exit 1
fi

MY_GIT_REV_RECENT=$(git rev-list remotes/origin/master | head -n1)
if [ "${?}" != 0 ]; then
  unset MY_GIT_REV_RECENT
  unset MY_SVN_GIT_REV
  popd
  exit 1
fi

echo "svn propedit license ${1} --editor-cmd \"echo -n '${MY_GIT_REV_RECENT}' >\" -m \"${MY_GIT_REV_RECENT}\""
svn propedit license ${1} --editor-cmd "echo -n '${MY_GIT_REV_RECENT}' >" -m "${MY_GIT_REV_RECENT}"
if [ "${?}" != 0 ]; then
  unset MY_GIT_REV_RECENT
  unset MY_SVN_GIT_REV
  popd
  exit 1
fi

popd

unset MY_GIT_REV_RECENT
unset MY_SVN_GIT_REV

echo "info: finished"
echo "info: please remove temp_dir"
