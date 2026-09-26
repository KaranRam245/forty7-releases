# forty7-releases

Public release artifacts for [forte-7](https://github.com/KaranRam245/wednesday):
the `forty7-cli` and `forty7-server` binary tarballs and the `forty7-engine` and
`forty7-runner` image tarballs. This repo is public so `curl | sh` installs work
without auth to the private source repo.

## Install the CLI

macOS, Apple Silicon only for now:

```sh
curl -fsSL https://raw.githubusercontent.com/KaranRam245/forty7-releases/main/install.sh | sh
```

## Do not edit install.sh here

`install.sh` is generated. Its source of truth is `forte-7/scripts/install.sh`
in the private wednesday repo, and the release job of `release-forte-7.yml`
overwrites the copy here on every `forty7-v*` tag. Edits made directly to this
repo are silently reverted by the next release — change it upstream instead.
