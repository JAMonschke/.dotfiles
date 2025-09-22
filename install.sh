#!/usr/bin/env bash

################################################################################
# Create soft-links for .bash_profile, .bashrc, and .bash_logout to
# ${HOME} directory and also try to setup XDG related ${HOME}/.config
# directories containing soft-links from ${HOME}/.dotfiles/XDG_CONFIG_HOME.
#
# NOTE: Try to be as non-destructive as possible. Will attempt to backup any
#       pre-existing files under ${HOME}/ to ${backup_dir} or abort if there is
#       a preexisting ${backup_dir}. I.e. it is necessary to rename or remove
#       any preexisting ${backup_dir} before running this script).
#
#       This will also attempt to create an uninstall.sh script under
#       ${backup_dir} that will contain commands to reverse each command that is
#       successfully executed that also modified the environment.
#
# TODO: add an "--install-prerequisites" to install required software with
#       integration of the code currently in brew_install.sh + snaps, flatpacks,
#       `apt` and any other sources for installations, to verify the presence of
#       prerequisites and to install any missing tools (e.g. cmake, jq, etc.).
#
#       Secondarily, consider recording which brew items were installed (not
#       already present) so that we can add logic to optionally uninstall only
#       those tools that added with the generated uninstall script.
#
# TODO: Add a --backup option create a <backup.zip> file to selectiely archive
#       the individual files reflecting the current state (limited to those
#       files that would be affected by running install.sh with no options.

# TODO: Add an "--export_functions" option to export (output) the function
#       definitions so that they can be incorporated into an environment with
#       `$(eval ${HOME}/.dotfiles/install.sh --export_functions)`, without
#       executing any of the logic in this file. (i.e. for testing/debugging
#       these tools, or so that these tools can be used interactively, either
#       for installation of these scripts/configs, or for installation of other
#       scripts/configs that are not part of these .dotfiles.
#       Also consider if any of the functionality here should be copied into
#       bash.functions_util.
#
# TODO: Consider whether we need to implement additional logic to manage
#       ownership and permissions of the installation.
#
# TODO: If I implement parameters for this install.sh script, then add a
#       -h/--help parameter to explain the usage of each parameter.
#
# TODO: Consider if we should source some of our bash.* files to use within
#       this install script (like echo.warning/error/etc.)
################################################################################

################################################################################
# Implementation Notes:
# -- Use `realpath` to
#    1) determine where soft-links finally resolve to
#    2) formulate a new path relative to a specified directory given an existing
#    path.
#       `realpath -s --relative-to=${HOME} <absolute file path>`
#   NOTE: will return "." (not empty string) if the <absolute file path>
#         resolves to the relative directory.
# -- Use `dirname` to strip off the final element of a path.
#    NOTE: will strip off the last element of path, even if it is a directory.
# -- Use `basename` to return final element of a path (even if it is a directory.
# -- use `readlink` to get the path that a soft-link stores.
################################################################################

################################################################################
###############################################################################
# function definitions used in this installation script.
###############################################################################
################################################################################

################################################################################
# should be called if/when an error occurs during the execution of this script.
################################################################################
abort()
{
  # debug info.
  # TODO: output caller info using:
  #           builtin: `caller`
  #           env var: $BASH_LINENO
  #           env var: $LINENO
  #     array env var: $FUNCNAME

  echo "************************************************************"
  echo "\${dotfiles_dir}=             \"${dotfiles_dir}\""
  echo "\${config_source}=            \"${config_source}\""
  echo "\${backup_dir}=               \"${backup_dir}\""
  echo "\${pending_uninstall_script}= \"${pending_uninstall_script}\""
  echo "\${uninstall_script}=         \"${uninstall_script}\""
  echo "************************************************************"

  finalize_uninstall

  echo "To restore your environment to what it was prior to running install.sh"
  echo "run \"${uninstall_script}\""
  exit 2;
}

################################################################################
################################################################################
# rollback logic.
# as each change is made to the environment, a corresponding "undo" commands is
# appended to ${pending_uninstall_script}. These will be used to create
# ${uninstall_script}, but the recorded undo commands will need to be executed
# in reverse order.
# NOTE: This assumes that there is one, complete command per line.
#       (no line continuations).
################################################################################
################################################################################

################################################################################
# As each change to the environment is made, a command that will "undo" that
# change is written to ${pending_uninstall_script}.
# To uninstall, these commands will need to be executed in reverse order.
# see: finalize_uninstall() below.
################################################################################
add_undo_command()
{
  printf "%s\n" "$*" >>"${pending_uninstall_script}"
}


################################################################################
# finalize uninstall()
# This will ensure that the uninstall.sh file starts with "#!/bin/env bash"
# followed by the contents of the ${pending_uninstall_script} file, reversing
# the order of the lines in that file.
################################################################################
finalize_uninstall()
{
  # NOTE: If an error occurs in this function, we call `exit ` explicitly, such
  #       that when it is called from abort() or at the bottom of this script
  #       (on success), we will preempt writing of messages referring to
  #       executing the ${uninstall_script} file that we were unable to create.

  # initialize uninstall.sh
  if [[ -f "${uninstall_script}" ]]; then
    echo "ERROR: could not create \"${uninstall_script}\" because the file "
    echo "       already exists. The existing \"${uninstall_script}\" may or "
    echo "       may not be correct."
    echo "       I.e. was finalize_uninstall() called more than once?"
    exit 2
  fi

  touch "${uninstall_script}"
  if [[ ! -f "${uninstall_script}" ]]; then
    echo "ERROR: could not create ${uninstall_script}."
    exit 2
  fi

  printf "#!/bin/env bash\n" > ${uninstall_script};

  # We need to copy the contents of ${pending_uninstall_script} to
  # ${uninstall_script}, but with the lines/commands reversed in order.
  # NOTE: /usr/bin/tac would be very straight-forward for this use case, but
  #       `tac` is part of the gnu utilities and is likely to not be installed
  #       (yet) on a Darwin/macOS (or possibly Linux) environment.
  if [[ -f "${pending_uninstall_script}" ]]; then
    # shellcheck disable=SC2327
    # shellcheck disable=SC2328
    if ! echo "$(sed '1!G;h;$!d' "${pending_uninstall_script}" >> "${uninstall_script}")" \
      || [[ ! -f "${uninstall_script}" ]]; then
      echo "ERROR : could not create \"${uninstall_script}\" from"
      echo "        \"${pending_uninstall_script}\"."
      exit 3;
    fi
  else
    printf "# no \"${pending_uninstall_script}\" was found.\n" >> "${uninstall_script}"
    printf "# presuming there is nothing to undo.\n" >> "${uninstall_script}"
  fi

  # make script readable, executable, and protect it otherwise.
  chmod 500 "${uninstall_script}"

  echo "${uninstall_script} has been created."
}


################################################################################
################################################################################
# functions to muck with the system.
################################################################################
################################################################################

###########################################
# move_targets_to_backup()
#
# NOTE: We must allow for backing up many potential targets, to reflect that
#       each application may allow for configuration files to exist in many
#       possible locations, with each application providing its own order of
#       precedence for the allowed locations.
#
# takes a list of paths to target files or directories (all must be under
# "${HOME}" but at any depth) and for each target file or directory that exists,
# moves (does NOT copy) them to the ${backup_directory} in a relative path that
# preserves the original location relative to ${HOME} (as well as preserving
# ownership and permissions).
# I.e. as if ${backup_directory} was a parallel directory tree to ${HOME}.
#
# In order to allow flexibility in computed lists of targets when calling this,
# 0 arguments/targets is allowed. It is also not necessary that any of the
# target path parameters evaluate to an existing file or directory.
# I.e. if no arguments are passed, or if no target_path parameter points to an
# existing file/dir then this function will return successfully with no action
# taken.
#
# move_targets_to_backup [target_path_1] [target_path_2]...
###########################################
move_targets_to_backup()
{
   # NOTES:
   # 1) each target_path value will be quoted by the expansion "$@", so double
   #    quotes on the usage of ${target_path} will not be needed.
   #    SC2086: Double quote to prevent globbing and word splitting.
   # 2) `dirname` will strip off the last element of path, even if it is a
   #    directory.
   # 3) `basename` will return the last element of path even if it
   #    is a directory.
   # 4) `realpath -s --relative-to=${HOME} <absolute file path>`
   #    will return "." (not empty string) if the <absolute file path> resolves
   #    to ${HOME}.

    local target_dir
    local target_name
    local target_path
    local relative_target_dir
    local backup_file_dir
    local backup_file_path

    for target_path in "$@"; do
        # if the target exists (whether it is a file, link or directory) then
        # move that target to the backup directory.
        if [[ -e "${target_path}" ]]; then
            # shellcheck disable=SC2086
            target_dir="$(dirname ${target_path})"

            # shellcheck disable=SC2086
            target_name="$(basename ${target_path})"

            relative_target_dir="$(realpath --no-symlinks --relative-to="${HOME}"\
              "${target_dir}" )"

            backup_file_dir="${backup_dir}/${relative_target_dir}"
            backup_file_path="${backup_file_dir}/${target_name}"

            # make the subdirectory (under the backup directory) if it does not
            # already exist.
            if [[ ! -d "${backup_file_dir}" ]] ; then
                if $(mkdir --parents "${backup_file_dir}"); then
                  echo "created directory \"${backup_file_dir}\"."
                  # NOTE: Currently no undo for the directories made under the
                  #       backup directory.
                  # TODO: [low priority] add logic to cleanup the created backup
                  #      directory by adding commands to add_undo_command. Will
                  #      require that we manually traverse the directory tree
                  #      when creating directories (rather than using the
                  #      --parents option) in order to build the corresponding
                  #      list of single (empty) directory `rm` or `rmdir`
                  #      commands.
                  # NOTE: would `rm --dir` be an option here?
                  #       (--dir: remove empty directories)
                else
                  echo "ERROR: Failed to mkdir --parents ${backup_dir}."
                  abort
                fi
            fi

            # move the file/directory/soft-link to the backup directory.
            if $(mv --no-clobber "${target_path}" "${backup_file_path}"); then
              add_undo_command "\$(mv --no-clobber \"${backup_file_path}\" \"${target_path}\")"
              echo "moved \"${backup_file_path}\" to"
              echo "      \"${target_path}\"."
            else
              echo "ERROR: could not move \"${target_path}\" to "
              echo "       \"${backup_file_path}\""
              abort
            fi
        fi

  done #for loop
}


########################################
# try to safely create a soft-link from a file in the .dotfiles directory into
# the appropriate target location.
# install_link [target path that soft-link will point to] [path for the creating the soft-link]
########################################
install_link()
{
    local source_file_path
    local target_path

    if [[ ${#} -ne 2 ]]; then
        echo "ERROR: \"${0}\" takes exactly 2 arguments."
        # SC2145: Argument mixes string and array. Use * or separate arguments
        # shellcheck disable=SC2145
        echo "   ${0} ${@}"
        abort
    fi

    source_file_path="${1}"
    if [[ ! -f "${source_file_path}" ]]; then
        echo "ERROR: Invalid source_file_path \"${source_file_path}\""
        abort
    fi

    target_path="${2}"
    if [[ -f "${target_path}" ]]; then
      echo "ERROR: Pre-existing target file: \"${target_path}\"."
      echo "       It should have been backed up and removed prior to calling \"$0\""
      abort
    fi

    target_dir="$(dirname ${target_path})"
    if [[ ! -d "${target_path}" ]]; then
      # shellcheck disable=SC2086   #convert to quoted string.
      mkdir --parents "${target_dir}"
      # we intentionally are not removing directories created during the install
      # in case the user has added additional files within the directory or
      # directory path that we are creating here.
    fi

    if $(ln -s "${source_file_path}" "${target_path}"); then
        echo "link made: \"${target_path}\" ==> \"${source_file_path}\""
        add_undo_command "\$(rm \"${target_path}\")"
    else
        echo "ERROR : COULD NOT MAKE LINK: \"${target_path}\" ==>" \
             " \"${source_file_path}\""
        abort
    fi
}


###############################################################################
# function for gathering pre-installation tests to ensure as many preconditions
# as possible are tested and verified before we start mucking with things.
# (no rollback required on errors at this point).
###############################################################################
installation_precheck()
{
  echo "${FUNCNAME}" "$*"
  if [[ -d "${backup_dir}" ]]; then
    echo "ERROR: \"${backup_dir}\" exists. "
    echo "       Directory must be renamed or removed before executing this script."
    echo "       Nothing to undo / uninstall."
    exit 1
  fi

  # ensure that sources for XDG_CONFIG_HOME are present.
  if [[ ! -d ${config_source} ]]; then
    echo "ERROR: Missing \"${config_source}\" directory"
    echo "       Nothing to undo / uninstall."
    exit 3
  fi
}


###############################################################################
###############################################################################
###############################################################################
###############################################################################

###############################################################################
# initialize the install.sh local variables used by the functions defined above
# and by the logic below.
###############################################################################
dotfiles_dir="${DOTFILES_DIR:-${HOME}/.dotfiles}"
config_source="${dotfiles_dir}/config"
backup_dir="${HOME}/.dotfiles-backup"
uninstall_script="${backup_dir}/uninstall.sh"
pending_uninstall_script="${backup_dir}/reversed_uninstall.sh"

###############################################################################
# pre-installation checks.
###############################################################################
installation_precheck

###############################################################################
# Now we start mucking with things...
# We will start with the backup directory and initializing the $uninstall_script
# script file.
###############################################################################

# installation_precheck should guarantee that ${backup_dir} does not currently
# exist.
if $(mkdir --parents "${backup_dir}"); then
  echo "Created directory \"${backup_dir}\""
else
  echo "Failed to mkdir --parents ${backup_dir}."
  echo "Nothing to undo / uninstall."
  exit 2
fi



# NOTE: from this point on, we must only abort execution (due to an error) by
#       calling `abort` and never by calling `exit` or `return`.
###############################################################################
# We will start with the core ${HOME}.bash* files.
###############################################################################

move_targets_to_backup "${HOME}/.bashrc"
install_link "${dotfiles_dir}/bashrc" "${HOME}/.bashrc"

move_targets_to_backup "${HOME}/.bash_profile" \
                       "${HOME}/.profile" \
                       "${HOME}/.bash_login"
install_link "${dotfiles_dir}/bash_profile" "${HOME}/.bash_profile"

move_targets_to_backup "${HOME}/.bash_logout"
install_link "${dotfiles_dir}/bash_logout" "${HOME}/.bash_logout"

################################################################################
# Make links to the .config files ( into ${XDG_CONFIG_HOME} ).
#
# NOTE: many applications will check the ${XDG_CONFIG_HOME} directory for their
#       configuration files, but will frequently allow many other possible
#       directories for their configuration and there may be an order of
#       precedence where a configuration file at another location, may be used
#       in preference to the file in ${XDG_CONFIG_HOME} (e.g. git if
#       ${HOME}/.gitconfig is present).
#
# TODO: for some of these config files, appropriate environment variables may
#       need to be set to help the application find its configuration files.
#       those settings must be added to the ${dotfiles_dir}/bash_profile file.
#
# TODO: consider adding logic to loop over the files and directories in the
#       XDG_CONFIG_HOME directory, with logic to introduce exception cases for
#       specific files.
#       E.g. the link to ccache.conf doesn't get a prepended '.' and
#       .dircolors should be linked only on a Linux environment.
#       NOTE: the first case might be handled by making the names of the files
#             in ${xdg_config_home} reflect the names for the links (i.e.
#             renaming those files to have a prepended '.' when the link should
#             also have a prepended '.'.
#       NOTE: the second case could be handled by allowing for 3
#             ${xdg_config_home} directories, one for common files, one for
#             files exclusive to Darwin/macOS and one for files exclusive to
#             Linux.
################################################################################

# if XDG_CONFIG_HOME is not set, then set it to ${HOME}/.config
if [[ ! -v XDG_CONFIG_HOME ]]; then
  XDG_CONFIG_HOME="${HOME}/.config"
fi

# if the directory ${XDG_CONFIG_HOME} does not exist, then create it.
if [[ ! -d ${XDG_CONFIG_HOME} ]]; then
  if mkdir --parents "${XDG_CONFIG_HOME}"; then
    # DO NOT use -f option, so that the .config directory will only succeed if
    # the config directory is empty after we have removed the links that we
    # installed there. I.e. abort if any other files were added to ~/.config.
    add_undo_command "\$(rmdir --ignore-fail-on-empty \"${XDG_CONFIG_HOME}\" 2>/dev/null; true)"
  else
    echo "ERROR: could note create \"${XDG_CONFIG_HOME}\"."
    abort
  fi
fi

# ccache.conf
move_targets_to_backup "${XDG_CONFIG_HOME}/ccache/ccache.conf" \
                       "${HOME}/.config/ccache/ccache.conf" \
                       "${HOME}/.ccache/ccache.conf"
install_link   "${config_source}/ccache.conf" \
               "${XDG_CONFIG_HOME}/ccache/ccache.conf"

# clang-tidy (does not currently support XDG_CONFIG_HOME)
move_targets_to_backup "${XDG_CONFIG_HOME}/.clang-tidy" \
                       "${HOME}/.clang-tidy"
install_link "${config_source}/clang-tidy" "${HOME}/.clang-tidy"

# dircolors
move_targets_to_backup "${XDG_CONFIG_HOME}/dircolors" \
                       "${HOME}/.dircolors"
# NOTE: .dircolors is only used by Linux, and is NOT used by Darwin/MacOS
if [[ "$(uname)" == "Linux" ]]; then
  install_link "${config_source}/dircolors" "${XDG_CONFIG_HOME}/dircolors"
fi

# gitconfig
move_targets_to_backup "${XDG_CONFIG_HOME}/.gitconfig" \
                       "${HOME}/.gitconfig"
install_link "${config_source}/gitconfig" "${XDG_CONFIG_HOME}/git/config"

# inputrc  (BASH does not use ${XDG_CONFIG_HOME}
move_targets_to_backup "${HOME}/.inputrc"
install_link "${config_source}/inputrc" "${HOME}/.inputrc"

# vimrc
# TODO: For which 'vi' variants can .vimrc be used? Do we need any additional
#       logic or additional configuration files (or soft links with another name
#       pointing to the same file) to support other variants?
#
# ~/.vim directory for vim?
move_targets_to_backup "${HOME}/.vimrc"\
                       "${XDG_CONFIG_HOME}/nvim/init.nvim"

# The vimrc file is used as the config file for both/either `vim` and `nvim`.
# `nvim` uses XDG_CONFIG_HOME, but `vim` does not (uses ${HOME})
install_link   "${config_source}/vimrc" "${HOME}/.vimrc"
install_link   "${config_source}/vimrc" "${XDG_CONFIG_HOME}/nvim/init.nvim"

###################################
# create the ${uninstall_script} file.
###################################
finalize_uninstall

echo "*************************************************************************"
echo "Success (apparently). When you are satisfied with the correctness of the"
echo "installation, you may remove the directory \"${backup_dir}\" if you wish,"
echo "or save it so that the environment can be restored to its state prior to"
echo "running \"${0}\" in the future."
echo "*************************************************************************"

true; # return status success.
