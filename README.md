# gen2fa

generate 2FA codes helper utility

## About

We want to use [pass](https://www.passwordstore.org/) to securely store 2FA secrets, and [onetimepass](https://pypi.org/project/onetimepass/) to generate the 2FA codes. We want a nice Bash script to tie the two together. This will:

- allow for automation
- provide a fast workflow for generating 2FA codes for any service which requires 2FA

## Rationale

Why did I create the `gen2fa` helper utility? Because pulling out my mobile phone every time I needed a 2FA code got deeply frustrating. Also, because I needed to automate some CI workflows, which required manual intervention by the operator (inserting a 2FA code generated by a mobile phone).

## Requirements

- [pass](https://www.passwordstore.org/)
- [Python](https://www.python.org/) v3.3+
- [Bash](https://www.gnu.org/software/bash/)
- [grep](https://www.gnu.org/software/grep/)
- [xclip](https://github.com/astrand/xclip)
- [sed](https://www.gnu.org/software/sed/)

You also need to install the Python module [onetimepass](https://pypi.org/project/onetimepass/). You can do so by running:

```shell
pip3 install onetimepass
```

## How this works

Fundamentally, you need two things. First, is an entry in pass called `two_fa`. For example, running:

```shell
$ pass two_fa
```

should produce:

```text
acc1: provider1/user_name
acc2 name: provider2/other_username
acc3: provider3
```

`gen2fa` utility will parse this output and will interpret everything up to the semicolon (`:`) as the account name. What comes after, is the pass entry for that account. It should contain the 2FA secret.

Second, you need 2FA secrets stored in pass under each account entry. For example, running:

```shell
$ pass provider2/other_username
```

should produce:

```text
... some stuff
2FA secret: UDHFJH6756HJGKJF786KJGFDGH675KHGHG
... some more stuff
```

`gen2fa` utility will parse this output, and will extract the 2FA secret from the line that starts with `2FA secret: `.

## Usage

For the standard case when you just need to get a 2FA code, and login to some website:

```shell
$ gen2fa -c
Enter the account to generate 2FA: acc2 name 

2FA code '123456' was copied to clipboard. Will clear in 6 seconds...
```

If you need to get a 2FA code as part of some automation script, you can use:

```shell
$ TWO_FA_CODE=$(gen2fa -q <<< "acc2 name")
$ echo $TWO_FA_CODE
123456
```

## Optional arguments

Available CLI arguments, understood by the script:

```text
  -l | --list       List available accounts to generate 2FA for.
  -c | --clipboard  Copy the 2FA code to clipboard using xclip.
  -q | --quiet      Try to be less verbose.
  -d | --debug      Print extra debugging information - contents of the script variables.
  -h | --help       Print help information; CLI usage.
       --version    Print version.
```

## Useful alias

To be able to run `gen2fa` using just the script name, you can add an alias to your `.bashrc`:

```shell
alias gen2fa="/home/user/path/to/project/gen2fa/gen2fa.sh"
```

Reload your `.bashrc` (one way is to close & open your terminal). Then you can do:

```shell
$ gen2fa --version
gen2fa v1.0
```

## License

This project is licensed under the MIT license. See [LICENSE](./LICENSE) for more details. Copyright (c) 2022 [Valera Rozuvan](https://valera.rozuvan.net/).
