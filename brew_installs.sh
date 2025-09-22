#!/usr/bin/env bash

################################################################################
# TODO: add code to check for presence of brew and install it if it does not
#       already exist.
#
# TODO: add support for snap/flatpack/apt/etc.. Decide which source to use for
#       each application we want to add (potentially falling back to another
#       source on failure of the primary source.
#       Secondarily, consider checking for installations already installed via
#       secondary installation methods when the application is available from
#       the primary one, and remove installations from those secondary sources.
#       (Consider the edge case (unlikely) of tools that were built from source)
#
# TODO: check for availability for each and report which install
#       targets are unavailable (before starting any installations).
#       (specific targets may be dropped by brew or not available for both
#       linux and Darwin/MacOS)
#
# TODO: check for an existing installation of each of these before attempting
#       a new installation (so that this file can be easily used for ongoing
#       maintenance).
#
# TODO: Record to a logfile if any of these are found to no longer be available.
################################################################################

# required by my bash functions
#    httpie     # User-friendly cURL replacement (command-line HTTP client)
#    jq         # Lightweight and flexible command-line JSON processor.
#    kubectl    # Kubernetes command-line interface.
#    bash       # Bourne-Again Shell, a UNIX command interpreter.
brew install \
    httpie \
    jq \
    kubectl \
    bash

## bash related stuff
#    bash-completion@2 # programmable completion for Bash 4.2+
#    bash-git-prompt   # Informative, fancey bash prompt for Git users.
#    bashish           # theme environment for text terminals
#    dialog            # display user-friendly message boxes from shell scripts
#    direnv            # load/unload environment variables based on $PWD
#    liquidprompt      # adaptive prompt for bash and zsh shells.
#   _shellcheck        # static analysis and lint tool for (ba)sh scripts.
#    shellharden       # Bash syntax highlighter that encourages/fixes variables quoting.
#    shfmt             # autoformat shell script source code
#    zenity            # GTK+ dialog boxes for the command-line (and  scripting).
brew install \
    bash-completion@2 \
    bash-git-prompt \
    bashish \
    dialog \
    direnv \
    liquidprompt \
    shellcheck \
    shellharden \
    shfmt \
    zenity

# command line utils
#    bat     # extended `pager` (like less/more)
#    eza     # extended `ls`
#    fd      # find entries in the filesystem
#    gawk    # GNU pattern scanning and processing language.
#    htop    # extended `top
#    neovim  # improved VIM which is an improved VI
#    pigz    # compress or expand files.
#    ripgrep # (rg) recursively search directory files for contents matching.
brew install \
    bat \
    eza \
    fd \
    gawk \
    htop \
    neovim \
    pigz \
    ripgrep

# programming utilities
#    cmake                # cross platform make
#    cppcheck             # Static analysis of C and C++ code.
#    cpp-gsl              # MS C++ Guidelines Support Library
#    deheader             # analyze C/C++ files for unnecessary headers.
#    doxygen              # inline documentation for source files
#    gdb                  # Gnu debugger
#    git                  # file versioning.
#    gitg                 # Gnome GUI client to view git repositories.
#    git-gui              # Tcl/Tk UI for the git revision control system
#    go                   # golang
#    google-benchmark     # C++ microbenchmark support library
#    gperftools           # multithreaded malloc() and performance analysis tools.
#    graphviz             # Graph visualization software from AT&T and Bell labs.
#    include-what-you-use # tool to analyze #includes in C and C++ source files.
#    plantuml             # Draw UML files from text input.
#    python3              # Python 3 language.
#    xsimd                # Portable C++ wrappers for SIMD intrinsics
#    stdman               # Formatted C++ stdlib man pages from cppreference.com
brew install \
     cmake \
     cppcheck \
     cpp-gsl \
     deheader \
     doxygen \
     gdb \
     git \
     gitg \
     git-gui \
     go \
     google-benchmark \
     gperftools \
     graphviz \
     include-what-you-use \
     plantuml \
     python3 \
     xsimd \
     stdman
