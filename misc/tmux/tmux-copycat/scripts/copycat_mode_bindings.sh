#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/helpers.sh"
AWK_CMD='awk'
if command_exists gawk; then
	AWK_CMD='gawk'
fi

# Extends a keyboard key.
# Benefits: tmux won't report errors and everything will work fine even if the
# script is deleted.
extend_key() {
	local key="$1"
	local script="$2"
	local cmd

	# 1. 'cmd' or 'key' is sent to tmux. This ensures the default key action is done.
	# 2. Script is executed.
	# 3. `true` command ensures an exit status 0 is returned. This ensures a
	#	 user never gets an error msg - even if the script file from step 2 is
	#	 deleted.
	# We fetch the current behavior of the 'key' mapping in
	# variable 'cmd'
	cmd=$(tmux list-keys -T $(tmux_copy_mode_string) | $AWK_CMD '$4 == "'$key'"' | $AWK_CMD '{ $1=""; $2=""; $3=""; $4=""; sub("  ", " "); print }')
	# If 'cmd' is already a copycat command, we do nothing
	if echo "$cmd" | grep -q copycat; then
		return
	fi
	# We save the previous mapping to a file in order to be able to recover
	# the previous mapping when we unbind
	tmux list-keys -T $(tmux_copy_mode_string) | $AWK_CMD '$4 == "'$key'"' >> /tmp/copycat_$(whoami)_recover_keys
	tmux bind-key -T $(tmux_copy_mode_string) "$key" run-shell "tmux $cmd; $script; true"
}

copycat_cancel_bindings() {
	# keys that quit copy mode are enhanced to quit copycat mode as well.
	local cancel_mode_bindings=$(copycat_quit_copy_mode_keys)
	local key
	for key in $cancel_mode_bindings; do
		extend_key "$key" "$CURRENT_DIR/copycat_mode_quit.sh"
	done
}

copycat_mode_bindings() {
	extend_key "$(copycat_next_key)" "$CURRENT_DIR/copycat_jump.sh 'next'"
	extend_key "$(copycat_prev_key)" "$CURRENT_DIR/copycat_jump.sh 'prev'"
}

main() {
	copycat_mode_bindings
	copycat_cancel_bindings
}
main
