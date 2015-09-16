#!/usr/bin/env bash

default_pane_resize="5"

get_keymap() {
	if [ -z ${DISPLAY+x} ]; then
		path_to_localectl=$(which localectl)
		if [ -x "$path_to_localectl" ]; then
			KEYMAP=$(localectl status | awk '/VC/{print $3}')
		elif [ -f "/etc/sysconfig/keyboard" ]; then
			KEYMAP=$(cat /etc/sysconfig/keyboard | awk -F '"' '/LAYOUT/{print $2}')
		elif [ -f "/etc/vconsole.conf" ]; then
			KEYMAP=$(cat /etc/vconsole.conf | awk -F '"' '/KEYMAP/{print $2}')
		elif [ -f "/etc/default/keyboard" ]; then
			KEYMAP=$(cat /etc/default/keyboard | awk -F '"' '/XKBLAYOUT/{print $2}')
		else
			KEYMAP="us"
		fi
	else
		KEYMAP=$(setxkbmap -query | awk '/layout/{print $2}')
	fi
}

set_keys() {
	if [ $KEYMAP == "dvorak" ]; then
		LEFT="d"
		DOWN="h"
		UP="t"
		RIGHT="n"
	else
		LEFT="h"
		DOWN="j"
		UP="k"
		RIGHT="l"
	fi

	CAP_LEFT=$(echo ${LEFT} | awk '{print toupper($0)}')
	CAP_DOWN=$(echo ${DOWN} | awk '{print toupper($0)}')
	CAP_UP=$(echo ${UP} | awk '{print toupper($0)}')
	CAP_RIGHT=$(echo ${RIGHT} | awk '{print toupper($0)}')
}

# tmux show-option "q" (quiet) flag does not set return value to 1, even though
# the option does not exist. This function patches that.
get_tmux_option() {
	local option=$1
	local default_value=$2
	local option_value=$(tmux show-option -gqv "$option")
	if [ -z $option_value ]; then
		echo $default_value
	else
		echo $option_value
	fi
}

pane_navigation_bindings() {
	tmux bind-key $LEFT   select-pane -L
	tmux bind-key C-$LEFT select-pane -L
	tmux bind-key $DOWN   select-pane -D
	tmux bind-key C-$DOWN select-pane -D
	tmux bind-key $UP   select-pane -U
	tmux bind-key C-$UP select-pane -U
	tmux bind-key $RIGHT   select-pane -R
	tmux bind-key C-$RIGHT select-pane -R
}

window_move_bindings() {
	tmux bind-key -r "<" swap-window -t -1
	tmux bind-key -r ">" swap-window -t +1
}

pane_resizing_bindings() {
	local pane_resize=$(get_tmux_option "@pane_resize" "$default_pane_resize")
	tmux bind-key -r $CAP_LEFT resize-pane -L "$pane_resize"
	tmux bind-key -r $CAP_DOWN resize-pane -D "$pane_resize"
	tmux bind-key -r $CAP_UP resize-pane -U "$pane_resize"
	tmux bind-key -r $CAP_RIGHT resize-pane -R "$pane_resize"
}

pane_split_bindings() {
	tmux bind-key "|" split-window -h -c "#{pane_current_path}"
	tmux bind-key "-" split-window -v -c "#{pane_current_path}"
}

improve_new_window_binding() {
	tmux bind-key "c" new-window -c "#{pane_current_path}"
}

main() {
	get_keymap
	set_keys
	pane_navigation_bindings
	window_move_bindings
	pane_resizing_bindings
	pane_split_bindings
	improve_new_window_binding
}
main
