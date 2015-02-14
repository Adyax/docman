#!/bin/bash

template_repo=$1

git clone -b master --single-branch --depth 1 ${template_repo} tmp; rm -fR tmp/.git; cp -nR tmp/. .; rm -fR tmp
