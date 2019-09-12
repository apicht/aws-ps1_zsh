#!/bin/zsh

# Copyright 2019 Aaron Picht
# Copyright 2018 Jon Mosco (kube-ps1)
#
#  Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Debug
[[ -n $DEBUG ]] && set -x

setopt PROMPT_SUBST
autoload -U add-zsh-hook
add-zsh-hook precmd _aws_ps1_update_cache
zmodload zsh/stat
zmodload zsh/datetime

# Default values for the prompt
# Override these values in ~/.zshrc
AWS_PS1_BINARY="${AWS_PS1_BINARY:-aws}"
AWS_PS1_SYMBOL_ENABLE="${AWS_PS1_SYMBOL_ENABLE:-true}"
AWS_PS1_SYMBOL_DEFAULT="${AWS_PS1_SYMBOL_DEFAULT:-\u2601}"
AWS_PS1_ACCOUNTALIAS_ENABLE="${AWS_PS1_ACCOUNTALIAS_ENABLE:-true}"
AWS_PS1_ROLENAME_ENABLE="${AWS_PS1_ROLENAME_ENABLE:-true}"
AWS_PS1_SESSIONNAME_ENABLE="${AWS_PS1_SESSIONNAME_ENABLE:-true}"
AWS_PS1_SEPARATOR="${AWS_PS1_SEPARATOR- }"
AWS_PS1_DIVIDER="${AWS_PS1_DIVIDER-:}"
AWS_PS1_PREFIX="${AWS_PS1_PREFIX-(}"
AWS_PS1_SUFFIX="${AWS_PS1_SUFFIX-)}"
AWS_PS1_ENABLED=true

AWS_PS1_COLOR_SYMBOL="%{$FG[208]%}"
AWS_PS1_COLOR_ACCOUNTALIAS="%{$FG[208]%}"
AWS_PS1_COLOR_ROLENAME="%{$fg[magenta]%}"
AWS_PS1_COLOR_SESSIONNAME="%{$fg[cyan]%}"

AWS_PS1_LAST_TIME=0

_aws_ps1_binary_check() {
    command -v "$1" >/dev/null
}

_aws_ps1_symbol() {
  [[ "${AWS_PS1_SYMBOL_ENABLE}" == false ]] && return

  AWS_PS1_SYMBOL="${AWS_PS1_SYMBOL_DEFAULT}"

  echo "${AWS_PS1_SYMBOL}"
}

_aws_ps1_split() {
  type setopt >/dev/null 2>&1 && setopt SH_WORD_SPLIT
  local IFS=$1
  echo $2
}

_aws_ps1_file_newer_than() {
  local mtime
  local file=$1
  local check_time=$2

  zmodload -e "zsh/stat"
  if [[ "$?" -eq 0 ]]; then
    mtime=$(stat +mtime "${file}")
  elif stat -c "%s" /dev/null &> /dev/null; then
    # GNU stat
    mtime=$(stat -c %Y "${file}")
  else
    # BSD stat
    mtime=$(stat -f %m "$file")
  fi

  [[ "${mtime}" -gt "${check_time}" ]]
}

_aws_ps1_update_cache() {
    AWSCREDENTIALS="${AWSCREDENTIALS:=$HOME/.aws/credentials}"
    if ! _aws_ps1_binary_check "${AWS_PS1_BINARY}"; then
        # No ability to fetch session info; display N/A.
        AWS_PS1_ACCOUNTALIAS="BINARY-N/A"
        AWS_PS1_ROLENAME="N/A"
        AWS_PS1_SESSIONNAME="N/A"
        return
    fi
    
    if [[ "${AWSCREDENTIALS}" != "${AWS_PS1_AWSCREDENTIALS_CACHE}" ]]; then
        # User changed AWSCREDENTIALS; refetch.
        AWS_PS1_AWSCREDENTIALS_CACHE=${AWSCREDENTIALS}
        _aws_ps1_get_session
        return
    fi

    if [[ "${AWS_PROFILE}" != "${AWS_PS1_AWS_PROFILE_CACHE}" ]]; then
        # User changed AWS_PROFILE; refetch.
        AWS_PS1_AWS_PROFILE_CACHE=${AWS_PROFILE}
        _aws_ps1_get_session
        return
    fi

    if [[ "${AWS_ACCESS_KEY_ID}" != "${AWS_PS1_AWS_ACCESS_KEY_ID_CACHE}" ]]; then
        # User changed AWS_ACCESS_KEY_ID; refetch.
        AWS_PS1_AWS_ACCESS_KEY_ID_CACHE=${AWS_ACCESS_KEY_ID}
        _aws_ps1_get_session
        return
    fi
    
    for conf in $(_aws_ps1_split : "${AWSCREDENTIALS:-${HOME}/.aws/credentials}"); do
        [[ -r "${conf}" ]] || continue 
        if _aws_ps1_file_newer_than "${conf}" "${AWS_PS1_LAST_TIME}"; then
            _aws_ps1_get_session
            return
        fi
    done
}

_aws_ps1_get_session() {
    AWS_PS1_LAST_TIME=$EPOCHSECONDS

    if [[ "${AWS_PS1_ACCOUNTALIAS_ENABLE}" == "true" ]]; then
        AWS_PS1_ACCOUNTALIAS="$(${AWS_PS1_BINARY} iam list-account-aliases --output=json 2>/dev/null | jq -r '.AccountAliases[0]')"
        if [[ -z "${AWS_PS1_ACCOUNTALIAS}" ]]; then
            AWS_PS1_ACCOUNTALIAS="N/A"
        fi
    fi

    export AWS_PS1_SESSIONINFO="$(${AWS_PS1_BINARY} sts get-caller-identity --output json | jq -r .Arn)"
    AWS_PS1_SESSIONTYPE="$(echo ${AWS_PS1_SESSIONINFO} | cut -d':' -f 6 | cut -d'/' -f 1)"
    if [[ "${AWS_PS1_SESSIONTYPE}" == "user" ]]; then
        AWS_PS1_ROLENAME="user"
        AWS_PS1_SESSIONNAME="$(echo ${AWS_PS1_SESSIONINFO} | cut -d':' -f 6 | cut -d'/' -f 2)"
    else
        AWS_PS1_ROLENAME="$(echo ${AWS_PS1_SESSIONINFO} | cut -d':' -f 6 | cut -d'/' -f 2)"
        AWS_PS1_SESSIONNAME="$(echo ${AWS_PS1_SESSIONINFO} | cut -d '/' -f 3)"
    fi

    if [[ -z "${AWS_PS1_ROLENAME}" ]]; then
        AWS_PS1_ROLENAME="N/A"
    fi

    if [[ -z "${AWS_PS1_SESSIONNAME}" ]]; then
        AWS_PS1_SESSIONNAME="N/A"
    fi
    unset AWS_PS1_SESSIONINFO
}

awson() {
    AWS_PS1_ENABLED=true
}

awsoff() {
    AWS_PS1_ENABLED=false
}

aws_ps1() {
    local reset_color="%{$reset_color%}"
    [[ "${AWS_PS1_ENABLED}" != "true" ]] && return

    AWS_PS1="${reset_color}${AWS_PS1_PREFIX}"
    AWS_PS1+="${AWS_PS1_COLOR_SYMBOL}$(_aws_ps1_symbol)"
    AWS_PS1+="${reset_color}${AWS_PS1_SEPARATOR}"
    if [[ "${AWS_PS1_ACCOUNTALIAS_ENABLE}" == "true" ]]; then
        AWS_PS1+="${AWS_PS1_COLOR_ACCOUNTALIAS}${AWS_PS1_ACCOUNTALIAS}${reset_color}"
    fi
    if [[ "${AWS_PS1_ROLENAME_ENABLE}" == "true" ]]; then
        AWS_PS1+="${AWS_PS1_DIVIDER}"
        AWS_PS1+="${AWS_PS1_COLOR_ROLENAME}${AWS_PS1_ROLENAME}${reset_color}"
    fi
    if [[ "${AWS_PS1_SESSIONNAME_ENABLE}" == "true" ]]; then
        AWS_PS1+="${AWS_PS1_DIVIDER}"
        AWS_PS1+="${AWS_PS1_COLOR_SESSIONNAME}${AWS_PS1_SESSIONNAME}${reset_color}"
    fi
    AWS_PS1+="${AWS_PS1_SUFFIX}"

    echo "${AWS_PS1}"
}
