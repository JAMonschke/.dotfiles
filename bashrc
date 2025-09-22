# can't follow non-constant source error
# shellcheck disable=SC1090

################################################################################
# .bashrc is explicitly sourced by .profile for login shells
# and is loaded unconditionally by bash for non-login shells.
################################################################################

# include guard (this file can appear as its actual filename or the soft-link).
filename="bashrc"
filename2=".bashrc"
declare -gA _sourced
if [[ -z ${_sourced[${filename}]} ]]; then
    _sourced[${filename}]="true"
    _sourced[${filename2}]="true"


# Duplicated from bash_profile to ensure that it will be set when ~.bashrc is
# read with "env -i bash -i"
if [[ -d ${HOME}/.dotfiles ]] ; then
    export DOTFILES_DIR="${HOME}/.dotfiles" 
else
    # we cannot use colors here because we are missing the bash.ansi file.
    printf "\n\n[ERROR]: %s\n\n" "No Directory ${HOME}/.dotfiles"
    exit 2;
fi


###########################################
# load other alias and functions
###########################################
# source.*() functions are defined in bash.functions_util
source "${DOTFILES_DIR:?}/bash.functions_util"
source.required "${DOTFILES_DIR:?}/bash.ansi"
source.required "${DOTFILES_DIR:?}/bash.functions_pathvar"


###########################################
# return now if this shell is NOT interactive.
###########################################
[[ ! $- == *i* ]] && return

################################################################################
################################################################################
# The rest of this file is for things that are ONLY used for interactive shells.
################################################################################
################################################################################

source.required "${DOTFILES_DIR:?}"/bash.aliases    # aliases
source.required "${DOTFILES_DIR:?}"/bash.functions_git
source.required "${DOTFILES_DIR:?}"/bash.functions_commands


###########################################
# `bind` commands (manage key bindings for readln library).
###########################################

if [[ -f "${HOME}/.inputrc" ]]; then
    bind -f "${HOME}/.inputrc"
elif [[ -f "/etc/inputrc" ]]; then #fallback to system's default inputrc.
    # TODO: is there a different directory on Darwin for the system's default
    #       inputrc that should be added here as a fallback?
    bind -f "/etc/inputrc"
    set -o vi
else
    set -o vi
fi


###########################################
# `shopt` commands (enable/disable Bash options)
###########################################


###########################################
# load other bash completion functions.
#
# On Mac (if installed via brew)
# -- /usr/local/share/bash-completion/completions/*
#    contains soft-links to the completions installed with bash-completion@2
# -- /usr/local/share/bash-completion/bash_completion
#    is a soft-link to the brew installed script that will load the
#    completions that are linked from:
#    /usr/local/share/bash-completion/completions/*
# -- /usr/local/etc/bash_completion.d/* contains soft-links to bash
#    completions that are installed in conjunction with other specific
#    brew installations.
# -- /usr/local/etc/profile.d/bash_completion.sh is a script that will try
#    to source bash_completion scripts at ${HOME}/.config/bash_completion
#    and /usr/local/share/bash-completion/bash_completion (above).
#
# NOTE: Scripts in /profile.d/ directories are normally expected to be
#       automatically loaded by /etc/profile but the mac version does not
#       do that, so it will need to be source manually for Darwin.
#
# NOTE: Because source.optional() takes no action when a file does not exist,
#       we don't need to worry about discriminating between Darwin and Linux.
#
# TODO: determine whether /usr/local/share/bash-completion/bash_completion
#       is also loading the completions from /usr/local/etc/bash_completion.d
###########################################
source.optional "/usr/local/etc/profile.d/bash_completion.sh" #Darwin only.
source.dir      "/etc/bash_completion.d"
# This should also include bash completions@2 if installed via brew on Linux.
source.dir      "/home/linuxbrew/.linuxbrew/etc/profile.d"


###########################################
# set prompts / prompt_command
###########################################
source.required "${DOTFILES_DIR:?}"/bash.functions_prompt

# NOTE: If PS0 is set, PS0 will be displayed before each command line is
#       executed.
# export PS0="\t\n"  # will display the time a program is started
PS2="▶️ "            # secondary prompt (tell me more)
PS3="❓"              # select prompt (selecting from a list of options)
PS4="▶︎ debugging> "  # only used for xtrace debugging.

################################################################################
# ${PS1} will be set via ${PROMPT_COMMAND} to execute functions to be run after
# every command line execution which will include running prompt.set_prompt()
# which will set ${PS1}.
################################################################################

# 'direnv' utility hooks ${PROMPT_COMMAND} and allows customization of the
# environment based on the current working directory when a ".direnv" file is
# present in the upstream path.
command which direnv >/dev/null 2>&1 && eval "$(direnv hook bash)"
true  # ensure any error status is cleared.

#
#    ==> bash-git-prompt
#    You should add the following to your .bashrc (or .bash_profile):
#      if [ -f "/home/linuxbrew/.linuxbrew/opt/bash-git-prompt/share/gitprompt.sh" ]; then
#        __GIT_PROMPT_DIR="/home/linuxbrew/.linuxbrew/opt/bash-git-prompt/share"
#        source "/home/linuxbrew/.linuxbrew/opt/bash-git-prompt/share/gitprompt.sh"
#      fi
#
#    ==> liquidprompt
#    Add the following lines to your bash or zsh config (e.g. ~/.bash_profile):
#      if [ -f /home/linuxbrew/.linuxbrew/share/liquidprompt ]; then
#        . /home/linuxbrew/.linuxbrew/share/liquidprompt
#      fi
#    If you'd like to reconfigure options, you may do so in ~/.liquidpromptrc.

# "prompt.set_prompt" is defined in bash.functions_prompt
# NOTE: Because prompt.set_prompt will set ${PS1} to indicate the status of the
#       last command executed, we must ensure that it is executed first before
#       any other command in PROMPT_COMMAND has a chance to change the execution
#       status.
#       I.e. it will need to be added last by prepending to ${PROMPT_COMMAND}.
PROMPT_COMMAND="prompt.set_prompt;${PROMPT_COMMAND}"

fi  # end of include guard


