# AWS prompt for zsh

An AWS zsh prompt that displays the current account alias, role, and session name.

Inspired by and borrowed heavily from [oh-my-zsh/plugins/kube-ps1](https://github.com/robbyrussell/oh-my-zsh/tree/master/plugins/kube-ps1)

## Requirements

The default prompt assumes you have the aws command line utility installed.  It
can be obtained here:

[Installling AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)

## Prompt Structure

The prompt layout is:

When logged in via an assumed role (i.e. via SSO)
```
(<symbol> <account alias>:<role name>:<session name>)
```

When logged in as an IAM user
```
(<symbol> <account alias>:user:<iam user name>)
```

## Enabling

In order to use aws-ps1 with Oh My Zsh, you'll need to enable them in the
.zshrc file. You'll find the zshrc file in your $HOME directory. Open it with
your favorite text editor and you'll see a spot to list all the plugins you
want to load.

```shell
vim $HOME/.zshrc
```

Add aws-ps1 to the list of enabled plugins and enable it on the prompt:

```shell
plugins=(
  git
  aws-ps1
)

# After the "source Oh My Zsh" line
PROMPT=$PROMPT'$(aws_ps1) '
```

Note: The `PROMPT` example above was tested with the theme `robbyrussell`.

## Enabling / Disabling on the current shell

Sometimes the information can be annoying, you can easily 
switch it on and off with the following commands:

```shell
awson
```

```shell
awsoff
```

## Colors

Orange was used as the prefix to match the AWS logo color as closely as
possible. Magenta was chosen for the role name to stand out, and cyan
for the session/user name. Check the customization section for changing them.

## Customization

The default settings can be overridden in ~/.zshrc

| Variable | Default | Meaning |
| :------- | :-----: | ------- |
| `AWS_PS1_BINARY` | `aws` | Default aws cli binary |
| `AWS_PS1_PREFIX` | `(` | Prompt opening character  |
| `AWS_PS1_SYMBOL_ENABLE` | `true ` | Display the prompt Symbol. If set to `false`, this will also disable `AWS_PS1_SEPARATOR` |
| `AWS_PS1_SYMBOL_DEFAULT` | `☁ ` | Default prompt symbol. Unicode `\u2601` |
| `AWS_PS1_ACCOUNTALIAS_ENABLE` | `true` | Display the account alias. |
| `AWS_PS1_ROLENAME_ENABLE` | `true` | Display the assumed role. |
| `AWS_PS1_SESSIONNAME_ENABLE` | `true` | Display the session/user name. |
| `AWS_PS1_SEPARATOR` | ` ` | Separator between symbol and cluster name |
| `AWS_PS1_DIVIDER` | `:` | Separator between cluster and namespace |
| `AWS_PS1_SUFFIX` | `)` | Prompt closing character |
| `AWS_PS1_COLOR_SYMBOL` | `"%{$FG[208]%}"` | Custom color for the symbol |
| `AWS_PS1_COLOR_ACCOUNTALIAS` | `"%{$FG[208]%}"` | Custom color for the account alias |
| `AWS_PS1_COLOR_ROLENAME` | `"%{$fg[magenta]%}"` | Custom color for the role name |
| `AWS_PS1_COLOR_SESSIONNAME` | `"%{$fg[cyan]%}"` | Custom color for the session name |
| `AWS_PS1_ENABLED` | `true` | Set to false to start disabled on any new shell, `awson`/`awsoff` will flip this value on the current shell |

## Props

- [oh-my-zsh/plugins/kube-ps1](https://github.com/robbyrussell/oh-my-zsh/tree/master/plugins/kube-ps1)
