# can't follow non-constant source error
# shellcheck disable=SC1090

# include guard (this file can appear as its actual filename or the soft-link).
filename="bash.profile"
filename2=".bash.profile"
declare -gA _sourced
if [[ -z ${_sourced[${filename}]} ]]; then
    _sourced[${filename}]="true"
    _sourced[${filename2}]="true"

################################################################################
################################################################################
# NOTES: Nominally, .bash_profile is executed/sourced only for "login" shells,
#        and NOT for secondary shells or terminals. This is why the
#        .bash_profile normally only sets (and exports) environment variables
#        that will then be visible to all other (child) shells by virtue of
#        "export".
#
#        However Mac OSx "terminal" creates a "login" shell for every terminal
#        window which runs .bash_profile which may lead to confusing bugs when
#        trying to maintain a common shell environment between Mac OSx and any
#        non Mac environment (e.g. Linux)
#
#        Because bash_profile is only read by the login shell (which is not
#        interactive) no text output to stdout from bash_profile will be visible
#        except when it is executed via re.source().
#
#        TLDR; On Linux, each newly created shell or terminal window will
#        inherit the environment as it was when the login caused the environment
#        to be initialized.
#        I do not yet have any means of re-initializing that base environment
#        (or other running shells that had inherited that environment), so the
#        only redress is to use re.source() in each newly created shell to
#        reinitialize.
#
# ALSO: /etc/profile is executed unconditionally by bash before looking for a
#       ~/.bash_profile. On macOS/Darwin /etc/profile executes:
#           `/usr/libexec/path_helper -s`
#       which will set PATH to:
#            /usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin
#
# TODO: IFF this is a non-interactive shell, then redirect [1] and [2] to a log
#       file (but only for the duration of the execution of this script.
#
# TODO: Fully decompose these files to 1 file per "class" (bash.*, git.*, etc.)
################################################################################
################################################################################

################################################################################
# This function is called exactly once, it is (almost) the first thing called,
# and only for the "login" shell (i.e. exactly once per login session).
################################################################################
_RunExactlyOnceAtLogin()
{
     #####################################
     # archive the systems environment ONLY at the initial login.
     #####################################
     # get the current (pristine) environment (at time of login),
     # replace '<esc>' with 'e',
     # sort the lines alphabetically
     # record it to (overwrite) ~/.system_env.log.
     env | tr '\033' 'e' | sort >~/.system_env.log 2>&1

     # Backup the system's PATH value to __SYSTEM_PATH before we start mucking
     # with it, to assist with debugging any PATH issues.
     if [[ -z "${__SYSTEM_PATH}" ]]; then
        __SYSTEM_PATH="$PATH"  2>/dev/null
        declare -rx __SYSTEM_PATH  # export and mark readonly
     fi

     # reduce need to continuously run $(uname) in various dynamic contexts.
     UNAME="$(uname)"
     declare -rx UNAME # export and declare readonly
}

################################################################################
# Placeholder for logic to be executed as the final action of these scripts
################################################################################
_RestoreEnvironment()
{
  :
  # TODO: Restore any changes to the environment that were intended just for the
  #       execution of these scripts (e.g. redirection of [1] and [2] to a logfile
  #       if this is run as a non-interactive shell.
  # TODO: Consider if we also need to add traps to guarantee this is still
  #       executed in the case of early exit from the script due to errors.
}


###########################################
# Environment (Linux / Darwin / etc) specific settings
# NOTE: Bash's use of colors
#       -- FreeBSD and MacOS use CLICOLOR and LSCOLORS.
#       -- Linux uses LS_COLORS and has no equivalent to CLICOLOR.
###########################################
_RunIfDarwin()
{
    #####################################
    # IF "brew" is installed, then add the environment variables that "brew"
    # would normally add itself, but do it manually (selectively).
    # I.e. we don't want PATH, or MANPATH to be altered.
    #####################################
    #  "eval $(/usr/local/bin/brew shellenv)"
    #    export HOMEBREW_PREFIX="/usr/local"
    #    export HOMEBREW_CELLAR="/usr/local/Cellar"
    #    export HOMEBREW_REPOSITORY="/usr/local/Homebrew"
    #    export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
    #    export MANPATH="/usr/local/share/man:$MANPATH"
    #    export INFOPATH="/usr/local/share/info:$INFOPATH"
    if [[ -z "${HOMEBREW_PREFIX}" ]]; then
        if [[ -x /usr/local/bin/brew ]]; then
            export HOMEBREW_PREFIX="/usr/local"
        fi

        if [[ -n "${HOMEBREW_PREFIX}" ]]; then
            export HOMEBREW_CELLAR="${HOMEBREW_PREFIX}/Cellar"
            export HOMEBREW_REPOSITORY="${HOMEBREW_PREFIX}/Homebrew"
            pathvar.prepend_dir_if_exists INFOPATH "${HOMEBREW_PREFIX}/share/info"
        fi
    fi

    # This should only be needed on macos platform,
    # NOTE: only when more than one SDK is installed, but XCode now installs
    #       multiple SDKs by default.
    SDKROOT=$(xcrun --sdk macosx --show-sdk-path)
    export SDKROOT

    CPU_COUNT="$( sysctl -n hw.ncpu )"
    JOBS="${CPU_COUNT}"
    export CPU_COUNT JOBS

    # "man" seems to do better if it is allowed to find the pages
    # (at least on MacOS/Darwin)
    unset MANPATH

    # NOTE: `java_home` will return a value for JAVA_HOME but is inadequate
    #       by itself since it will fail if it can't find a jvm.
    if [[ -x /usr/libexec/java_home ]] && \
       [[ $( which java ) ]] ; then
        JAVA_HOME="$(/usr/libexec/java_home)"
        export JAVA_HOME
    fi

    CLICOLOR=1   # to enable 'ls' colors, but only for FreeBSD or MacOS
    LSCOLORS=GxFxCxDxBxegedabagaced
    export LSCOLORS
    export CLICOLOR

    test -e "${HOME}/.iterm2_shell_integration.bash" &&
       source "${HOME}/.iterm2_shell_integration.bash"

    # complete -C : command is executed in a subshell environment, and its
    # output is used as the possible completions.
    # 'mc' is GNU "Midnight Commander" terminal based file manager.
    if [[ -x /usr/local/bin/mc ]]; then
        complete -C /usr/local/bin/mc mc
    fi

    pathvar.append_dir_if_exists  PATH \
          "/Library/Frameworks/Python.framework/VersionsCurrent/bin"
}

_RunIfLinux()
{
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

    CPU_COUNT="$( awk '/^processor/{n+=1}END{print n}' /proc/cpuinfo )"
    JOBS="${CPU_COUNT}"
    export CPU_COUNT JOBS

    #TODO add logic for determining JAVA_HOME on linux.
    if which java >/dev/null; then  #java is present
      # java_path="$(which java)"
      # JAVA_HOME=???
      :
    fi

    if [[ -x /usr/bin/dircolors ]]; then
        # sets LS_COLORS based on contents of .dircolors file.
        if [[ -r "${XDG_CONFIG_HOME}/.dircolors" ]]; then
            eval "$(dircolors -b "${XDG_CONFIG_HOME}/.dircolors")"
            if [[ -r "${HOME}/.dircolors" ]]; then
                # TODO: use echo.warning / printf.warning and make sure that
                #       output is redirected to log file for non-interactive
                #       shells.
                printf "[WARNING:] Found two .dircolors files in\n"
                printf "\"%s\" and \"%S\".\n" "${HOME}" "${XDG_CONFIG_HOME}"
                printf "Initializing from \"%s\"\n" "${XDG_CONFIG_HOME}"
            fi
        elif [[ -r "${HOME}/.dircolors" ]]; then
            eval "$(dircolors -b "${HOME}/.dircolors")"
        fi
    fi

    # colored GCC warnings and errors
    export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'
}




################################################################################
################################################################################
# Execution begins here:
################################################################################
################################################################################

# execute _RunExactlyOnceAtLogin exactly once.
if [[ -z "${__RunOnlyOnce}" ]]; then
    _RunExactlyOnceAtLogin
    __RunOnlyOnce="has run";
    declare -rx __RunOnlyOnce;
fi

# TODO: validate that the ${HOME}/.dotfiles exists and assume that the .config
#       directory exists (i.e. don't try to handle using ${HOME} as the
#       DOTFILES_DIR since that will introduce too many cases that would have to
#       be handled throughout this script (and probably result in many errors).

if [[ ! -v DOTFILES_DIR ]] && [[ -d ${HOME}/.dotfiles ]]; then
    DOTFILES_DIR="${HOME}/.dotfiles"
    export DOTFILES_DIR
fi

#####################################
# source.* functions are defined in bash.functions_util
#####################################
source "${DOTFILES_DIR:?}/bash.functions_util"
source.once "${DOTFILES_DIR:?}/bash.functions_pathvar"

#####################################
# manage XDG config environment variables.
#####################################
if [[ -d "${HOME}/.config" ]]; then
   # set base XDG directory environment variables.
   XDG_CONFIG_HOME="${HOME}/.config"
   [[ -d "${HOME}/.local/share" ]] && XDG_DATA_HOME="${HOME}/.local/share"
   [[ -d "${HOME}/.local/state" ]] && XDG_STATE_HOME="${HOME}/.local/state"
   export XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME
elif [[ ! -R XDG_CONFIG_HOME ]]; then # if XDG_CONFIG_HOME is not set.
   # TODO: is this appropriate, or should I be introducing logic to test
   #       XDG_CONFIG_HOME wherever I use it in these script?
   XDG_CONFIG_HOME="${HOME}";
   # TODO: what about XDG_DATA_HOME and XDG_STATE_HOME?
   export XDG_CONFIG_HOME
fi

#####################################
# environment settings that must be discriminated based on Linux vs. Darwin
# environment.
#####################################
if [[ "${UNAME}" == "Linux" ]]; then
    _RunIfLinux
elif [[ "${UNAME}" == "Darwin" ]]; then
    _RunIfDarwin
fi

#####################################
# Amend paths as appropriate.
# NOTE: the pathvar.* utility functions (from bash.functions_util) are designed
#       to easily give fine-grained control over any PATH environment variable
#       especially the order in which they appear. Also each pathvar.append*()
#       or pathvar.prepend*() function will ensure that any preexisting entries
#       that match the entry being added will be removed from the PATH variable.
#
# NOTE: directories that don't exist will be ignored, so we don't need to
#       discriminate between Darwin/MacOS and Linux here (unless we encounter a
#       case of a directory that may be present that should NOT be included in
#       one of the environments).
#####################################

# these directories are appended (not prepended) so they will go on the end.
pathvar.append_dir_if_exists PATH /snap/bin        # should already be present
pathvar.append_dir_if_exists PATH /bin             # should already be present
pathvar.append_dir_if_exists PATH /usr/bin         # should already be present
pathvar.append_dir_if_exists PATH /usr/sbin        # should already be present
pathvar.append_dir_if_exists PATH /sbin            # should already be present
pathvar.append_dir_if_exists PATH /usr/games
pathvar.append_dir_if_exists PATH /usr/local/games
pathvar.append_dir_if_exists PATH /opt/X11/bin     # for MacOsx

# These directories are prepended so they will appear in the PATH in the reverse
# order that they are added (last added will be first in the path).
pathvar.prepend_dir_if_exists PATH /usr/local/sbin
pathvar.prepend_dir_if_exists PATH /home/linuxbrew/.linuxbrew/sbin
pathvar.prepend_dir_if_exists PATH /usr/local/bin
pathvar.prepend_dir_if_exists PATH /home/linuxbrew/.linuxbrew/bin
pathvar.prepend_dir_if_exists PATH "${HOME}/.local/bin"
pathvar.prepend_dir_if_exists PATH "${HOME}/bin"
pathvar.prepend_dir_if_exists PATH "${HOME}/usr/bin"
pathvar.prepend_dir_if_exists PATH "${DOTFILES_DIR}/bin"


# on Darwin/Macos, "man" does better if it is left to itself to find the pages.
# pathvar.append_dir_if_exists  MANPATH  "${HOME}/usr/share/man"

pathvar.append_dir_if_exists  INFOPATH "${HOME}/usr/share/info"
pathvar.prepend_dir_if_exists INFOPATH /home/linuxbrew/.linuxbrew/share/info
pathvar.prepend_dir_if_exists INFOPATH /usr/local/share/info
pathvar.prepend_dir_if_exists INFOPATH /usr/share/info

#####################################
# Directories in this path are automagically searched on every "cd" command
# regardless of the current working directory.
# NOTE: if a directory name used with `cd  occurs in multiple directories in
#       CDPATH the first will be used (can cause confusion).
#####################################
# pathvar.append_dir_if_exists CDPATH "${HOME}/git"

#####################################
# Select between available tools with util.which_of_these().
# The listed candidate programs are filtered by availability, and ordered by
# preference. I.e. the first program of the listed programs that is also present
# on the system is the one returned.
# TODO: based on which vi variant is selected, set environment variables if
#       possible to direct it to use the .vimrc file.
#####################################

####################
# nvim: (Neovim) fork of vim (vi improved) refactored and with even more
#       functionality
# mvim: mac port of vim
# vim:  "vi improved" vi re-implementation with extensions
# nvi:  vi re-implementation shipped with BSD"
#  vi:  the classic
#
# NOTES: `gvim` is `vim` with a gui interface that runs in its own window.
#        I.e. it is not appropriate as a candidate for ${EDITOR}.
#
#         on many Linux distributions, what appears to be one of these vi
#         implementations, may actually be a soft-link to a different vi
#         implementation. E.g. Ubuntu 24.04 'vi' and 'vim' are both links to
#         'nvim'
####################
EDITOR="$(util.which_of_these nvim mvim vim nvi vi )"
VISUAL="${EDITOR}"

# NOTE: `bat` in another pager, but it triggers problems with "infinite
#       recursion" in many contexts.
PAGER="$(util.which_of_these less pg more most )"
if [[ "${PAGER}" == "less" ]]; then
    # --ignore-case: ignore case for searches
    # --color=xcolor: set colors for different character types
    # --squeeze-blank-lines: causes consecutive blank lines to be condensed to 1
    # --quit-if-one-screen: exit after displaying text if it fits on one screen.
    PAGER="/usr/bin/less --ignore-case --squeeze-blank-lines --quit-if-one-screen"
fi

# NOTE: /usr/bin/man does not play nice with "bat" as a pager. If `bat` is
#       included in the list of pagers above, then a separate selection from
#       the same set of programs except for `bat` should be used here.
MANPAGER="${PAGER}"

export EDITOR VISUAL PAGER MANPAGER


pathvar.prepend_dir_if_exists GOPATH "${HOME}/go"
pathvar.append_dir_if_exists  PATH   "${HOME}/go/bin"

# incorporate bash completions for packages installed by brew.
if type brew &>/dev/null
then
  HOMEBREW_PREFIX="$(brew --prefix)"
  if [[ -r "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh" ]]
  then
    source "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh"
  else
    for COMPLETION in "${HOMEBREW_PREFIX}/etc/bash_completion.d/"*
    do
      [[ -r "${COMPLETION}" ]] && source "${COMPLETION}"
    done
  fi
fi

###########################################
# the  directory ${DOTFILES_DIR}/profile.d/ contains any additional
# shell scripts to be sourced each time .bash_profile is executed.
# NOTE: To view the profile.d directory, use `ls -A` because there may be some
#       ".*" files.
###########################################
source.dir "${DOTFILES_DIR:?}/profile.d"


###########################################
# load rest of common/general environment from .bashrc:
# TODO: add warning/error if .bashrc does not exist.
###########################################
[[ -r ~/.bashrc ]] && [ -n "${BASH_VERSION}" ] && source.once ~/.bashrc

###########################################
# Restore any changes to the environment that were intended just for the
# execution of these scripts. E.g. i/o redirection to a log file.
#
# NOTE: This must be the very last thing we execute before exiting these files.
###########################################
_RestoreEnvironment

fi  # end of include guard


