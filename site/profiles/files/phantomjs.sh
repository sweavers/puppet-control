#!/bin/bash

echo "Installing Phantomjs"
curl -O https://s3-eu-west-1.amazonaws.com/digital-register/packages/phantomjs-1.9.1-linux-i686.tar.bz2
tar xvf phantomjs-1.9.1-linux-i686.tar.bz2
cp phantomjs-1.9.1-linux-i686/bin/phantomjs /usr/local/bin