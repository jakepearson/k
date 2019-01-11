# Automatically run the correct version of kubectl every time

This script will read the version of the Kubernetes server you are running. It will then download a new version of kubectl if needed and run your command with new kubectl. I named it `k` since most everyone appears to alias `kubectl` to `k` anyway.

![So Simple](https://media.giphy.com/media/3o6Zt16nOfEI0C9sPu/giphy.gif)

## Getting Started

Download the file to somewhere in your path. Any time you would call `kubectl ...`, call `k ...` instead.

`curl -OL https://raw.githubusercontent.com/jakepearson/k/master/k && chmod +x k`
