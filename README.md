[![GitHub tag](https://img.shields.io/github/v/tag/xsh-lib/aws?sort=date)](https://github.com/xsh-lib/aws/tags)
[![GitHub](https://img.shields.io/github/license/xsh-lib/aws.svg?style=flat-square)](https://github.com/xsh-lib/aws/)
[![GitHub last commit](https://img.shields.io/github/last-commit/xsh-lib/aws.svg?style=flat-square)](https://github.com/xsh-lib/aws/commits/master)

[![Travis (.com)](https://img.shields.io/travis/com/xsh-lib/aws.svg?style=flat-square)](https://travis-ci.com/xsh-lib/aws)
[![GitHub issues](https://img.shields.io/github/issues/xsh-lib/aws.svg?style=flat-square)](https://github.com/xsh-lib/aws/issues)
[![GitHub pull requests](https://img.shields.io/github/issues-pr/xsh-lib/aws.svg?style=flat-square)](https://github.com/xsh-lib/aws/pulls)

# xsh-lib/aws

xsh Library - AWS.

About xsh and its libraries, check out [xsh document](https://github.com/alexzhangs/xsh)

## Requirements

1. bash

    Tested with bash:
    * 4.3.48 on Linux
    * 3.2.57 on macOS

1. awscli

    Tested with `awscli 1.17.4`.

This project is still at version 0.x, and should be considered immature.

## Dependency

1. xsh-lib/core

    This library depends on [xsh-lib/core](https://github.com/xsh-lib/core) which should be loaded first before to use this library.

    ```bash
    xsh load xsh-lib/core
    ```

## Installation

Assume [xsh](https://github.com/alexzhangs/xsh) is already installed at your local.

To load this library into `xsh` issue below command:

```bash
xsh load xsh-lib/aws
```

The loaded library can be referred as name `aws`.

## Usage

List available utilities for this library:

```bash
xsh list aws
```
