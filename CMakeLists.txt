cmake_minimum_required(VERSION 3.5)
project(_dotfiles)

set(CMAKE_CXX_STANDARD 17)

add_executable(_dotfiles main.cpp
        XDG_CONFIG_HOME/ccache.conf
        XDG_CONFIG_HOME/clang-tidy
        XDG_CONFIG_HOME/gitconfig
        XDG_CONFIG_HOME/gitignore_local
        XDG_CONFIG_HOME/inputrc
        XDG_CONFIG_HOME/vimrc)
