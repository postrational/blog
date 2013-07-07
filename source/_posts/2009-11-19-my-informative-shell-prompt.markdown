---
layout: post
title: "My informative shell prompt"
date: "2009-11-19"
permalink: "/blog/2009/11/19/my-informative-shell-prompt/"
comments: true
categories: tech
published: true
tags: 
---

The [Bash](http://en.wikipedia.org/wiki/Bash) shell prompt in your Terminal is very highly customizable and can display a wide variety of useful information. This is what my prompt looks like and how to create it.

<code>[09:10:11] <span style="color:#6dcd2f">user@host</span> <span style="color:#d5ca38">~/Desktop</span> <span style="color:#6dcd2f">+</span></code>

<!-- more -->

### Explanation
The following information is presented at the prompt:

* <code>[09:10:11]</code> : the current time  
* <code><span style="color:#6dcd2f">user@host</span></code> : the name of the logged in user and the host machine  
* <code><span style="color:#d5ca38">~/Desktop</span></code> : the current working directory
* <code><span style="color:#6dcd2f">+</span></code> or
<span style="color:#bf311a">`-_-`</span> : this part presents the exit status of the most recently executed command. If the command executes correctly the prompt shows a green <code><span style="color:#6dcd2f">+</span></code>. If the command returns an error, then the prompt shows an unhappy <span style="color:#bf311a">`-_-`</span>.



### Bash version
In order to recreate this prompt, you should add the following code to your `~/.bash_profile` file. On some systems this file may need to be created, or you'll need to edit the `~/.bashrc` file instead.

#### Linux version

```bash
##
# Color codes
##
DULL=0
BRIGHT=1

FG_BLACK=30
FG_RED=31
FG_GREEN=32
FG_YELLOW=33
FG_BLUE=34
FG_VIOLET=35
FG_CYAN=36
FG_WHITE=37

FG_NULL=00

BG_BLACK=40
BG_RED=41
BG_GREEN=42
BG_YELLOW=43
BG_BLUE=44
BG_VIOLET=45
BG_CYAN=46
BG_WHITE=47

BG_NULL=00

##
# ANSI Escape Commands
##
ESC="\033"
NORMAL="\[$ESC[m\]"
RESET="\[$ESC[${DULL};${FG_WHITE};${BG_NULL}m\]"

##
# Shortcuts for Colored Text ( Bright and FG Only )
##

# DULL TEXT

BLACK="\[$ESC[${DULL};${FG_BLACK}m\]"
RED="\[$ESC[${DULL};${FG_RED}m\]"
GREEN="\[$ESC[${DULL};${FG_GREEN}m\]"
YELLOW="\[$ESC[${DULL};${FG_YELLOW}m\]"
BLUE="\[$ESC[${DULL};${FG_BLUE}m\]"
VIOLET="\[$ESC[${DULL};${FG_VIOLET}m\]"
CYAN="\[$ESC[${DULL};${FG_CYAN}m\]"
WHITE="\[$ESC[${DULL};${FG_WHITE}m\]"

# BRIGHT TEXT
BRIGHT_BLACK="\[$ESC[${BRIGHT};${FG_BLACK}m\]"
BRIGHT_RED="\[$ESC[${BRIGHT};${FG_RED}m\]"
BRIGHT_GREEN="\[$ESC[${BRIGHT};${FG_GREEN}m\]"
BRIGHT_YELLOW="\[$ESC[${BRIGHT};${FG_YELLOW}m\]"
BRIGHT_BLUE="\[$ESC[${BRIGHT};${FG_BLUE}m\]"
BRIGHT_VIOLET="\[$ESC[${BRIGHT};${FG_VIOLET}m\]"
BRIGHT_CYAN="\[$ESC[${BRIGHT};${FG_CYAN}m\]"
BRIGHT_WHITE="\[$ESC[${BRIGHT};${FG_WHITE}m\]"


function proml {
case $TERM in
    xterm*|rxvt*)
        TITLEBAR='\[\033]0;\u@\h:\w\007\]'
        ;;
    *)
        TITLEBAR=""
        ;;
esac

PS1="${TITLEBAR}\
$NO_COLOUR[\t]\
 $GREEN\u@\h$YELLOW \w$NORMAL \
 \`if [ \$? = 0 ]; then echo '$GREEN+$NORMAL'; else echo '$RED-_-$NORMAL'; fi\` \
\n$ "
PS2='> '
PS4='+ '
}
proml
```


#### Mac version, which also provides the error code value:

```bash
function proml {
local BLUE="\[\033[0;34m\]"
local RED="\[\033[0;31m\]"
local LIGHT_RED="\[\033[1;31m\]"
local WHITE="\[\033[1;37m\]"
local GREEN="\033[32m\]"
local YELLOW="\033[33m\]"
local NO_COLOUR="\[\033[0m\]"
case $TERM in
    xterm*|rxvt*)
        TITLEBAR='\[\033]0;\u@\h:\w\007\]'
        ;;
    *)
        TITLEBAR=""
        ;;
esac

PS1="${TITLEBAR}\
$NO_COLOUR[\t]\
 $GREEN\u@\h$YELLOW \w$NO_COLOUR $BLUE(\
\` echo \$?;\`\
)$NO_COLOUR
\$ "

PS2='> '
PS4='+ '
}
proml
```

### Theme for [Zsh](http://www.zsh.org/)

```sh
PROMPT=$'%D{[%I:%M:%S]} %{$fg_bold[green]%}%n@%m %{$reset_color%}%{$fg[yellow]%}%~%{$reset_color%} $(git_prompt_info) %{$fg[blue]%}[%?]%{$reset_color%}\
%{$fg_bold[blue]%}%(!.#.$)%{$reset_color%} '

ZSH_THEME_GIT_PROMPT_PREFIX="("
ZSH_THEME_GIT_PROMPT_SUFFIX=")%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[red]%}*%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN=""
```


### A version for [Fish](http://fishshell.org/)

```sh
function fish_prompt --description 'Write out the prompt'
    #Save the return status of the previous command
    set stat $status


    # Just calculate these once, to save a few cycles when displaying the prompt
    if not set -q __fish_prompt_hostname
        set -g __fish_prompt_hostname (hostname|cut -d . -f 1)
    end

    if not set -q __fish_prompt_normal
        set -g __fish_prompt_normal (set_color normal)
    end

    if not set -q __fish_color_blue
        set -g __fish_color_blue (set_color -o blue)
    end

    #Set the color for the status depending on the value
    set __fish_color_status (set_color -o green)
    if test $stat -gt 0
        set __fish_color_status (set_color -o red)
    end

    switch $USER

        case root

        if not set -q __fish_prompt_cwd
            if set -q fish_color_cwd_root
                set -g __fish_prompt_cwd (set_color $fish_color_cwd_root)
            else
                set -g __fish_prompt_cwd (set_color $fish_color_cwd)
            end
        end

        printf '%s@%s %s%s%s# ' $USER $__fish_prompt_hostname "$__fish_prompt_cwd" (prompt_pwd) "$__fish_prompt_normal"

        case '*'

        if not set -q __fish_prompt_cwd
            set -g __fish_prompt_cwd (set_color $fish_color_cwd)
        end

        printf '[%s] %s%s@%s %s%s %s(%s)%s \f\r> ' (date "+%H:%M:%S") "$__fish_color_blue" $USER $__fish_prompt_hostname "$__fish_prompt_cwd" (pwd) "$__fish_color_status" "$stat" "$__fish_prompt_normal"

    end
end
```