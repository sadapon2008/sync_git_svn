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

echo "git clone ${1} ."
git clone ${1} .
if [ "${?}" != 0 ]; then
  popd
  exit 1
fi

echo "git svn init ${2}"
git svn init ${2}
if [ "${?}" != 0 ]; then
  popd
  exit 1
fi

echo "git svn fetch"
git svn fetch
if [ "${?}" != 0 ]; then
  popd
  exit 1
fi

MY_SVN_REV_RECENT=$(git rev-list remotes/git-svn | head -n1)
if [ -z ${MY_SVN_REV_RECENT} ]; then
  echo "error: please increase svn repositry revision (e.g. svn propset license '' .; svn commit -m '')"
  unset MY_SVN_REV_RECENT
  popd
  exit 1
fi

MY_GIT_REV_RECENT=$(git rev-list remotes/origin/master | head -n1)
if [ -z ${MY_GIT_REV_RECENT} ]; then
  echo "error: please commit to git repositry"
  unset MY_GIT_REV_RECENT
  unset MY_SVN_REV_RECENT
  popd
  exit 1
fi

MY_SVN_REV_COUNT=$(git rev-list remotes/git-svn | wc -l)

MY_GIT_REV_COUNT=$(git rev-list remotes/origin/master | wc -l)

if [ "$(expr ${MY_SVN_REV_COUNT} - 1)" == "${MY_GIT_REV_COUNT}" ]; then
  echo "info: skipped (up to date)"
  echo "info: please remove temp_dir"
  unset MY_GIT_REV_COUNT
  unset MY_SVN_REV_COUNT
  unset MY_GIT_REV_RECENT
  unset MY_SVN_REV_RECENT
  popd
  exit 0
fi

MY_REV_DIFF=$(expr ${MY_GIT_REV_COUNT} - ${MY_SVN_REV_COUNT} + 1)
unset MY_GIT_REV_COUNT
unset MY_SVN_REV_COUNT

MY_GIT_REV_NEXT=$(git rev-list remotes/origin/master | head -n${MY_REV_DIFF} | tail -n1)
unset MY_REV_DIFF

echo "${MY_GIT_REV_NEXT} ${MY_SVN_REV_RECENT}" >.git/info/grafts

echo "git checkout -b svn remotes/git-svn"
git checkout -b svn remotes/git-svn
if [ "${?}" != 0 ]; then
  unset MY_GIT_REV_NEXT
  unset MY_GIT_REV_RECENT
  unset MY_SVN_REV_RECENT
  popd
  exit 1
fi

echo "git merge -X theirs ${MY_GIT_REV_RECENT}"
git merge -X theirs ${MY_GIT_REV_RECENT}
if [ "${?}" != 0 ]; then
  unset MY_GIT_REV_NEXT
  unset MY_GIT_REV_RECENT
  unset MY_SVN_REV_RECENT
  popd
  exit 1
fi

echo "git svn dcommit"
git svn dcommit
if [ "${?}" != 0 ]; then
  unset MY_GIT_REV_NEXT
  unset MY_GIT_REV_RECENT
  unset MY_SVN_REV_RECENT
  popd
  exit 1
fi

popd

unset MY_GIT_REV_NEXT
unset MY_GIT_REV_RECENT
unset MY_SVN_REV_RECENT

echo "info: finished"
echo "info: please remove temp_dir"
