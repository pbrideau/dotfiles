#!/bin/bash -

declare -i LOG_LEVEL=1
declare -A LOG_LEVELS=(
[0]="error"
[1]="warn "
[2]="info "
[3]="debug"
)
function log
{
	# Log to stdout or stderr
	# Usage:
	#   log N "MESSAGE"
	#   Where N is [0-3]
	#   log 0 "This is an error log"
	local level=${1}
	local color=""
	shift
	case $level in
		0)
			color="$txtred";;
		1)
			color="$txtylw";;
		2)
			color="$txtgrn";;
		3)
			color="$txtblu";;
	esac

	# shellcheck disable=SC2153 # No misspelling here
	if [ "$LOG_LEVEL" -ge "$level" ]; then
		if [ "$level" -eq 0 ]; then
			echo -e "[${color}${LOG_LEVELS[$level]}${txtrst}]" "$@" 1>&2
		else
			echo -e "[${color}${LOG_LEVELS[$level]}${txtrst}]" "$@"
		fi
	fi
}

function prompt_user_abort
{
	# Ask user if he want to continue
	# Usage:
	#   prompt_user_abort
	#       or
	#   prompt_user_abort "QUESTION"
	log 3 "========== function ${FUNCNAME[0]}"
	local question="Are you sure?"
	local response
	if [ $# -gt 0 ]; then
		question=$1
	fi
	question="${question} [y/N] "
	if [ "$ALWAYS_YES" = false ]; then
		read -r -p "$question" response
		case "$response" in
			[yY][eE][sS]|[yY])
				;;
			*)
				log 0 "Aborting..."
				exit 1
				;;
		esac
	fi
}

function spinner
{
	# Start a notification while task is running in background
	# Usage:
	#   sleep 10 &
	#   .sleeper $! job_name
	log 3 "========== function ${FUNCNAME[0]}"
	local job=$1
	local process_name
	if [ $# -gt 1 ]; then
		process_name=$2
	else
		process_name=$(ps -q "$job" -o comm=)
	fi
	local spinstr='\|/-'
	local start_time=$SECONDS
	local temp

	log 3 "background job pid: $job"
	if [ "$PARSEABLE" = true ]; then
		log 1 "running: $process_name"
	fi
	while ps -q "$job" &>/dev/null; do
		if [ "$LOG_LEVEL" -ne 0 ]; then
			if [ "$PARSEABLE" = true ]; then
				echo -n '.'
			else
				temp="${spinstr#?}"
				printf "${txtcr}[${txtylw}warn ${txtrst}] running: %s (%ds) %c" "$process_name" "$((SECONDS-start_time))" "${spinstr}"
				spinstr=${temp}${spinstr%"$temp"}
			fi
		fi
		sleep 1
	done
	if [ "$LOG_LEVEL" -ne 0 ]; then
		echo
	fi
}

if tty -s; then
	txtund=$(tput smul)             # Underline
	txtbld=$(tput bold)             # Bold
	txtrst=$(tput sgr0)             # Reset
	txtcr=$(tput cr)                # Carriage return (start of line)
else
	txtund=; txtbld=; txtrst=; txtcr=;
fi
txtblk=; txtred=; txtgrn=; txtylw=; txtblu=; txtpur=; txtcyn=; txtwht=;
bakblk=; bakred=; bakgrn=; bakylw=; bakblu=; bakpur=; bakcyn=; bakwht=;
bldblk=${txtbld};
bldred=${txtbld};
bldgrn=${txtbld};
bldylw=${txtbld};
bldblu=${txtbld};
bldpur=${txtbld};
bldcyn=${txtbld};
bldwht=${txtbld};
undblk=${txtund};
undred=${txtund};
undgrn=${txtund};
undylw=${txtund};
undblu=${txtund};
undpur=${txtund};
undcyn=${txtund};
undwht=${txtund};
function set_colors
{
	# Make sure we run as interractive shell, disable colors otherwise
	if ! tty -s; then
		PARSEABLE=true
		COLORS=false
		return
	fi

	if ! command -v tput &>/dev/null; then
		log 1 "tput command not found, no colors will be displayed"
		COLORS=false
		return
	fi

	if [ "$COLORS" = true ]; then
		local ncolors
		ncolors=$(tput colors)
		if [ -n "$ncolors"  ] && [ "$ncolors" -ge 8 ]; then
			txtblk=$(tput setaf 0)
			txtred=$(tput setaf 1)
			txtgrn=$(tput setaf 2)
			txtylw=$(tput setaf 3)
			txtblu=$(tput setaf 4)
			txtpur=$(tput setaf 5)
			txtcyn=$(tput setaf 6)
			txtwht=$(tput setaf 7)
			bakblk=$(tput setab 0)
			bakred=$(tput setab 1)
			bakgrn=$(tput setab 2)
			bakylw=$(tput setab 3)
			bakblu=$(tput setab 4)
			bakpur=$(tput setab 5)
			bakcyn=$(tput setab 6)
			bakwht=$(tput setab 7)
			bldblk=${txtbld}${txtblk}
			bldred=${txtbld}${txtred}
			bldgrn=${txtbld}${txtgrn}
			bldylw=${txtbld}${txtylw}
			bldblu=${txtbld}${txtblu}
			bldpur=${txtbld}${txtpur}
			bldcyn=${txtbld}${txtcyn}
			bldwht=${txtbld}${txtwht}
			undblk=${txtund}${txtblk}
			undred=${txtund}${txtred}
			undgrn=${txtund}${txtgrn}
			undylw=${txtund}${txtylw}
			undblu=${txtund}${txtblu}
			undpur=${txtund}${txtpur}
			undcyn=${txtund}${txtcyn}
			undwht=${txtund}${txtwht}
		fi
	fi
	export txtund txtbld txtrst txtcr
	export txtblk txtred txtgrn txtylw txtblu txtpur txtcyn txtwht
	export bakblk bakred bakgrn bakylw bakblu bakpur bakcyn bakwht
	export bldblk bldred bldgrn bldylw bldblu bldpur bldcyn bldwht
	export undblk undred undgrn undylw undblu undpur undcyn undwht
}

# shellcheck disable=SC2120
function load_config
{
	declare -i linenum=1
	for f in "${CONFIG_FILES[@]}"; do
		if [ -r "$f" ]; then
			local regex="^#"
			while read -r line; do
				if [[ ! "$line" =~ $regex ]]; then
					eval set -- "--${line}"
					load_arg "$@"
					if [ "${#END_LOAD_ARG[@]}" -gt 0 ]; then
						log 0 "Could not parse config file ($f) correctly"
						log 0 "Error on line ${linenum}:"
						log 0 "> $line"
						exit "$EX_USAGE"
					fi
				fi
				(( linenum++ ))
			done < "$f"
			# Load only the first config we can find, not every config files
			break
		fi
	done
}

# Reserved return codes
export EX_OK=0           # No error
export EX_ERROR=1        # General error
export EX_BLTIN=2        # Misuse of shell builtins
export EX_TMOUT=124      # Command times out
export EX_FAIL=125       # Command itself fail
export EX_NOEXEC=126     # Command is found but cannot be invoked
export EX_NOTFOUND=127   # Command not found
export EX_INVAL=128      # Invalid argument

# 128+signal (Specific x86)
# see kill -l or man 7 signal
export EX_SIGHUP=129     # Hangup detected on controlling terminal
export EX_SIGINT=130     # Interrupt from keyboard
export EX_SIGQUIT=131    # Quit from keyboard
export EX_SIGILL=132     # Illegal instruction
export EX_SIGTRAP=133    # Trace/breakpoint trap
export EX_SIGABRT=134    # Abort signal from abort(3)
export EX_SIGBUS=135     # Bus error (bad memory access)
export EX_SIGFPE=136     # Floating point exception
export EX_SIGKILL=137    # Kill signal
export EX_SIGUSR1=138    # User-defined signal 1
export EX_SIGSEGV=139    # Invalid memory reference
export EX_SIGUSR2=140    # User-defined signal 2
export EX_SIGPIPE=141    # Broken pipe: write to pipe with no readers
export EX_SIGALRM=142    # Timer signal from alarm(2)
export EX_SIGTERM=143    # Termination signal
export EX_SIGCHLD=145    # Child stopped or terminated
export EX_SIGCONT=146    # Continue if stopped
export EX_SIGSTOP=147    # Stop process
export EX_SIGTSTP=148    # Stop typed at terminal
export EX_SIGTTIN=149    # Terminal input for background process
export EX_SIGTTOU=150    # Terminal output for background process
export EX_SIGURG=151     # Urgent condition on socket (4.2BSD)
export EX_SIGXCPU=152    # CPU time limit exceeded (4.2BSD)
export EX_SIGXFSZ=153    # File size limit exceeded (4.2BSD)
export EX_SIGVTALRM=154  # Virtual alarm click (4.2BSD)
export EX_SIGPROF=155    # Profiling timer expired
export EX_SIGWINCH=156   # Window resize signal (4.3BSD, Sun)
export EX_SIGIO=157      # I/O now possible (4.2BSD)
export EX_SIGPWR=158     # Power failure (System V)
export EX_SIGSYS=159     # Bad system call (SVr4)

