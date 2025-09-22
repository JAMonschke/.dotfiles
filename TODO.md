TODO: potential future work on managing/implementing these dotfiles:
===========
* **TO FIX**
    * to ease headaches regarding the inheritance of environments in shells 
      based on the environment created by the original login shell. Consider
      moving more logic from bash_profile into bashrc which is always read for
      every new shell.
    * reconcile .config/.vimrc with the config file requirements for the other
      "vi" variants (and export environment variables where needed).
    * remove runtime support for not using XDG_CONFIG_HOME, or having it set to
      anything other than ${HOME}/.config (but while backing up and restoring
      to whatever the original state was before installing my .dotfiles).
    * system is configured to use /usr/bin/bash as the system bash file.
      This is an older version, I need to get the system to use the brew 
      installed bash instead (but that will have to be installed to the system)
* **ENVIRONMENT**
    * reconcile .ssh directories for different environments.
        * but without "checking in" any .ssh "secrets" into this git repo.
    * remove any potentially problematic directories from \${PATH} before 
      running brew (to avoid using an inappropriate binary or script).
    * enhance / add install script for environment initialization:
        * Towards (re)creating my preferred environment from scratch:
            * install “brew” and to then use brew to install the software I use.
     * **vi** (vimrc)
        * flesh out formatters (include formatter specific to bash)
            * enable folding on functions.
* **BASH**
    * investigate interactive/command-line improvements with the following:
        * builtin enable
        * builtin shopts
        * builtin: set
        * builtin bind.  (keyboard bindings)
        * /usr/bin/open
    * enhance the "class." method list to take an optional parameter that can be
      used to filter the list of all methods via grep.
    * scripts:
        * mapfile (take stdin and parse into a shell array variable
    * getopts. (help in parsing options arguments to shell scripts)
* **Cleanup:**
    * ✅refactor this git repository to be rooted at “.dotfiles”
* **refactoring:**
    * consider if I should copy my git-prompt.sh file into my .dotfiles.
    * create clean model for incorporating my utility functions into stand-alone
      shell scripts (for using the functions when they have not been 
      incorporated into the current bash environment)
    * extend **bash.show_functions()** to support an optional filename parameter to
      show all functions defined in that file. advantage: could show function 
      definitions that are in any shell file. Could be based on **grep** through
      the file for things that look like function definitions
  * current ls.functions() functionality and matching the definition locations
    against the specified filename (or potentially directory name) parameter. 
      * would only show functions in the current environment that are in the 
        file.
    * refactor namespaces:
  * better logical separation based on target usages:
      * command line
          * prefer <existing exec>.<my_extension> where appropriate.E.g. cd.*, 
            echo.*, find.*, git.*, man.*, ...
      * for use within other bash scripts.
          * sh.*.* namespace ?
          * make sure dependencies are minimized and managed correctly for use
            with stand-alone *.sh scripts.
      * online help for my functions 
  * <namespace>.help() function for each namespace.
  * .help() to list all \<namespaces>
  * possibly extract from comments in source files?
      * possibly create my own doxygen like/lite comment format?
  * adopt a convention of an embedded "usage" function scoped within my 
    functions
    <br> **\<namespace>.\<function>.help()**
  * include with 'show "function_name"' functionality ?
* **Optimize:** 
  <br> (The complexity of my scripts seems to cause some things to slow-down, 
  See where / what / how  I need to optimize / simplify…)
    * use function definition / re-definition (memoization) to avoid redundant
      re-evaluation of tests where the results should be “invariant” in an 
      environment.
    * add an "edit" variant of show.function function to open the appropriate 
      file and jump to the appropriate lines.
    * discriminate unchecked versions of calls prepended with '_' with "checked"
      variants with the base-name which perform checks before calling the 
      version with '_'.
        * use the '_' unchecked versions internally where we have already 
          validated the parameters.
    * Make use of other "languages" python, tcl-tk, .c/.cpp, etc. where 
      appropriate…
    * Where appropriate, move functionality into stand-alone bash files (under
      **~/usr/bin)**
        * create a **/bin** or **/scripts** directory under **~/.dotfiles** and
          modify **install.sh** to create links for those files in my
          **~/bin** or **~/usr/bin** directory.
* **Fix / robustness / debugging:**
    * Make install.sh more robust by checking any existing files to:
        * be silent if existing files are already soft-links to our intended 
          targets
        * be more noisy when they are not and possibly offer remediation after
          confirmation…
            * (or automatically move to a backup directory)
    * FIX: io-redirection in my build functions.
    * FIX: git.merge_from_parent
    * FIX: add "git remote prune origin" before all "git fetch" commands in 
      git.* functions.
    * FIX: cursor positioning with non-zero ansi return code on prompt and/or 
      w/ multi-line input.
    * add short-circuit logic to **ansi.functions** for piped output (output is
      messed up with “| less” and likely some other tools)
    * add robustness features (traps, etc.)
    * add debugging support
* **New functionality / installed tools to incorporate / use:**
    * [Programming]
        * hexyl (pretty hexdump)
        * highlight (formatting and syntax highlighting of code)
        * abcl (formatting and syntax highlighting of code)
        * cpp-gsl (Microsoft C++ Guidelines Support Library)
        * cscope (tool for browsing source code)
        * deheader (analyze c/c++ files for unnecessary headers)
        * google-benchmark
        * gperftools
        * pre-commit (python framework for pre-commit checks/scripts)
        * git-quick-stats (statistics on remote repository (probably EXPENSIVE)
    * [Bash]
        * bash-git-prompt
        * bashish (theme environment for terminals)
        * liquidprompt (scriptable (re)generation of bash prompts)
        * direnv (control bash environment based on working directory)
        * [ansi dialog box tools]
            * dialog
            * whiptail (brew "newt" package) - generate text mode dialog boxes 
              from shell scripts
            * zenity
    * [Find / Grep / ls / cat]
        * rg (fast find+grep)
        * fd (fast find but with simpler / incompatible command line)
        * mdcat (`cat` for markdown files)
        * sk ("fuzzy finder" i.e. grep / find / filter / nvim for interactively 
          finding and selecting files)
        * exa (replacement for ls)
        * gtksourceview4 (text view with syntax, unto/redo, and text marks)
    * [graphics generation]
        * plantuml
        * graphviz (e.g. generate git branch graphs ? )
        * mscgen (plantuml like tool for generating protocol message sequence
          diagrams)
        * gnuplot (function plotting)
    * [Man pages / docs]
        * tldr (simplified man pages)
        * dash
        * help2man
    * [Misc]
        * aspell (spell checker alternative to ispell)
        * htop (enhanced top)
* **New Functions:**
    * General / new: 
        * update / maintentance
            * auto-update (NOTE: OS updates are automatic with Ubuntu)
               * app store updates 
               * brew-update
            * tools on top of "brew list" and "brew info" to show:
                * all installed packages with description and URL
                * dependency graph of all installed packages
        * bash completion
            * my shell function options (branch-names, etc.)
                * 1st, show and show.*
                * 2nd, *. (to complete commands in each group)
                * 3rd, each individual function's parameters.
        * compilation / build 
            * add timing information for build
            * track differential "ccache --print-stats" statistics for build.
        * Add class.help() functions for all methods to show help for all 
          functions in a class.
            * for every method add a _class.method.help() method to display 
              usage that can then be used for class.help() and also for each 
              methods errors when they are misused.
    * ansi.*
        * add color/attribute functions to bash.ansi 
    * prompt.*
        * when in a git repository, use a 2-line prompt 
          <br>**<color by env> [repo | worktree] \[~/git/branch/main/src/…]
          \[parentbranch] \[branchname (branch status)] \[ status] 
          <br>@/directory/ $** 
        * indicate depth of shells in prompt 
            * know what level you want to "exit" back to later,
            * "exit" back to the base shell without closing the shell completely.
                * consider adding a special exit.function() to exit to a "level"
                  and stop (with a positive number), or exist a specific number
                  of shells with a negative number.
        * function to indicate current git status: (dirty / clean) 
          (ahead / behind #commits)
            * local repo vs.
                * current branch 
                * parent branch 
                * develop
            * current branch vs.
                * parent branch
                * develop
            * parent branch vs.
                * develop
    * pathvar.*
        * create pathvar.append / prepend functions to operate on values instead
          of variables and refactor appropriately to consolidate logic.
    * git.*
        * “git branch -vv” gives much more information for each local branch, 
          including:
            * https://stackoverflow.com/questions/6456546/how-can-i-tell-which-remote-parent-branch-my-branch-is-based-on
            * the “origin”
            * the “hash”
            * the last commit
            * how many commits the branch is ahead and behind…
            * need to create appropriate functionality around this.
        * “git status” options “-v, -b, —ahead-behind, etc. also give much more
          information to make use of.
            * https://stackoverflow.com/questions/2016901/viewing-unpushed-git-commits?rq=1
        * NOTE: **@{u}** is a git short-hand for “the upstream branch”
    * development
        * parallel execution of “cmake” configuration with displayed output,
          possibly through “coproc” and pipes, or redirections of files / 
          file-descriptors, or “tail -f” on the log file that it is writing.
            * https://wiki.bash-hackers.org/syntax/keywords/coproc
            * http://mywiki.wooledge.org/BashFAQ/024
    * show.*
        * add "Show" functions with filters and colors
        * add functionality to show.which (or create an alternative method) that
          will allow executing each instance with an option that will return the
          version (e.g. --version).
    * util.*
        * create debug() [on/off] function to take steps to modify environment 
          for debugging of shell scripts
            * turn off command line prompt code that creates noise
            * set -x / +x
            * enable / disable validation checks & assertions (by redefining 
              validate/assert functions)
        * create / find utilities to remove need for bash hacks around quoting,
          managing environment variables, etc.
        * create a “call()” function to make a “sane” / safe function invocation
          like: <br>
          **util.call function-name 
            [[first-parameter ],[ second-parameter],[etc..]]**
            * take the first argument as the function name,
            * combine all subsequent parameters into a “string”
            * look for subsequent “[[“, “],[“, and “]]” tokens to delineate the
              function parameters (asserting that “]]” terminates the complete 
              evaluation list)
            * properly handle quoting and escaping as needed to create a robust
              (sane) grouping/quoting of parameters on function calls.
        * consider creating a utility to wrap/unwrap values into a json string
          for use in  parameter passing and returning (dealing appropriately
          with quotes).
        * make use of “getopts” to add command-line arguments/options to 
          functions(where appropriate / useful)
    * commands
        * document() function/command to:
            * find available documentation based on man, info, help, 
              “command —help”
            * and also provide a means to show more info on my functions and
              aliases:
                * comments preceding and embedded in implementation
                * consistent provision of —help option ?(possibly with a 
                  “global” associative array containing the help messages that
                  can be populated at the definition of each function?)
                * command completion? [ command compgen complete compopt ]
                * man / help / info?
                * location (file:line)
    *  util.dialog_* functions to manage and abstract dialog based script 
       interaction via:
        * kdialog : [Dev-Cluster] KDE / Qt based X-Windows dialog boxes
        * zenity : [Mac via Brew] GTK+ based X-Windows dialog boxes
        * whiptail : [Dev-Cluster] ANSI based (but ugly)
        * dialog : [Dev-Cluster / Mac via Brew]
        * xdialog : 
        * tcl-tk
        * bash shell (fallback / fallthrough if others aren't available)
            * bash: printf / read / readarray / select / case, etc.
            * http://tldp.org/LDP/abs/html/internal.html#READR
            * https://serverfault.com/questions/144939/multi-select-menu-in-bash-script

