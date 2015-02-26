#!/bin/bash

if [ -z "${1}" -o -z "${2}" -o -z "${3}" ]; then
  echo "usage:"
  echo "  ${0} git_url svn_url temp_dir"
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

echo "svn propget license ${2}"
MY_SVN_GIT_REV=$(svn propget license ${2})
if [ "${?}" != 0 ]; then
  popd
  exit 1
fi

echo "git clone ${1} ."
git clone ${1} .
if [ "${?}" != 0 ]; then
  unset MY_SVN_GIT_REV
  popd
  exit 1
fi

echo "git svn init ${2}"
git svn init ${2}
if [ "${?}" != 0 ]; then
  unset MY_SVN_GIT_REV
  popd
  exit 1
fi

echo "git svn fetch -r HEAD"
git svn fetch -r HEAD
if [ "${?}" != 0 ]; then
  unset MY_SVN_GIT_REV
  popd
  exit 1
fi

MY_SVN_REV_RECENT=$(git rev-list remotes/git-svn | head -n1)
if [ -z ${MY_SVN_REV_RECENT} ]; then
  echo "error: please increase svn repositry revision (e.g. svn propset license '' .; svn commit -m '')"
  unset MY_SVN_REV_RECENT
  unset MY_SVN_GIT_REV
  popd
  exit 1
fi

MY_GIT_REV_RECENT=$(git rev-list remotes/origin/master | head -n1)
if [ -z ${MY_GIT_REV_RECENT} ]; then
  echo "error: please commit to git repositry"
  unset MY_GIT_REV_RECENT
  unset MY_SVN_REV_RECENT
  unset MY_SVN_GIT_REV
  popd
  exit 1
fi

if [ -n "${MY_SVN_GIT_REV}" -a "${MY_SVN_GIT_REV}" == "${MY_GIT_REV_RECENT}" ]; then
  echo "info: skipped (up to date)"
  echo "info: please remove temp_dir"
  unset MY_GIT_REV_RECENT
  unset MY_SVN_REV_RECENT
  unset MY_SVN_GIT_REV
  popd
  exit 0
fi

if [ -n "${MY_SVN_GIT_REV}" ]; then
  MY_GIT_REV_NEXT=$(git rev-list remotes/origin/master | grep -B1 ${MY_SVN_GIT_REV} | head -n1)
else
  MY_GIT_REV_NEXT=$(git rev-list --reverse remotes/origin/master | head -n1)
fi
if [ -z "${MY_GIT_REV_NEXT}" -o "${MY_GIT_REV_NEXT}" == "${MY_SVN_GIT_REV}" ]; then
  echo "error: not found commit next to ${MY_SVN_GIT_REV}"
  unset MY_GIT_REV_NEXT
  unset MY_GIT_REV_RECENT
  unset MY_SVN_REV_RECENT
  unset MY_SVN_GIT_REV
  popd
  exit 1
fi
echo "${MY_GIT_REV_NEXT} ${MY_SVN_REV_RECENT}" >.git/info/grafts
unset MY_GIT_REV_NEXT

echo "git checkout -b svn remotes/git-svn"
git checkout -b svn remotes/git-svn
if [ "${?}" != 0 ]; then
  unset MY_GIT_REV_RECENT
  unset MY_SVN_REV_RECENT
  unset MY_SVN_GIT_REV
  popd
  exit 1
fi

echo "git merge -X theirs ${MY_GIT_REV_RECENT}"
git merge -X theirs ${MY_GIT_REV_RECENT}
if [ "${?}" != 0 ]; then
  unset MY_GIT_REV_RECENT
  unset MY_SVN_REV_RECENT
  unset MY_SVN_GIT_REV
  popd
  exit 1
fi

echo "git svn dcommit"
git svn dcommit
if [ "${?}" != 0 ]; then
  unset MY_GIT_REV_RECENT
  unset MY_SVN_REV_RECENT
  unset MY_SVN_GIT_REV
  popd
  exit 1
fi

echo "svn propedit license ${2} --editor-cmd \"echo -n '${MY_GIT_REV_RECENT}' >\" -m \"${MY_GIT_REV_RECENT}\""
svn propedit license ${2} --editor-cmd "echo -n '${MY_GIT_REV_RECENT}' >" -m "${MY_GIT_REV_RECENT}"
if [ "${?}" != 0 ]; then
  unset MY_GIT_REV_RECENT
  unset MY_SVN_REV_RECENT
  unset MY_SVN_GIT_REV
  popd
  exit 1
fi

popd

unset MY_GIT_REV_RECENT
unset MY_SVN_REV_RECENT
unset MY_GIT_REV_NEXT

echo "info: finished"
echo "info: please remove temp_dir"
