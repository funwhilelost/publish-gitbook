#!/bin/sh -l

# config git
git config --local user.name "${GITHUB_ACTOR}"
git config --local user.email "${GITHUB_ACTOR}@users.noreply.github.com"

# checkout gh-pages branch
set +e
git checkout gh-pages || git checkout -b gh-pages
git fetch origin && git reset origin/gh-pages
git status
set -e

# install gitbook
npm install gitbook-cli  -g
gitbook -v
gitbook install

# build gitbook
gitbook build

# copy the static site files into the current directory
cp -R _book/* .

# remove 'node_modules' and '_book' directory
git clean -fx node_modules
git clean -fx _book

# add all files
git add .

# commit
COMMIT_MESSAGE="Update gitbook `date '+%Y-%m-%d %H:%M:%S'`"
git commit -a -m "${COMMIT_MESSAGE}"

# setup publisher
if [ -n "${GITHUB_TOKEN}" ]; then
    print_info "using automatic GITHUB_TOKEN"
    PUBLISHER_REPO="https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
elif [ -n "${INPUT_PERSONAL_TOKEN}" ]; then
    print_info "using provided PERSONAL_TOKEN"
    PUBLISHER_REPO="https://x-access-token:${INPUT_PERSONAL_TOKEN}@github.com/${PUBLISH_REPOSITORY}.git"
else
    print_error "no PERSONAL_TOKEN or GITHUB_TOKEN found"
    exit 1
fi

git remote add publisher ${PUBLISHER_REPO}

# push to the publisher
git push -q -u publisher gh-pages
