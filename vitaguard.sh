#!/bin/bash

# Variable initialization here
CYAN="\033[0;36m"
GREEN="\033[0;32m"
RED="\033[0;31m"
WHITE="\033[1;37m"

# Progress bar func :))
progress_bar() {
	local PERCENT=$1
	local WIDTH=30
	local FILLED=$(( PERCENT * WIDTH / 100 ))
	local EMPTY=$(( WIDTH - FILLED ))

	printf "["

	# Filled bar (green=ok, red=bad if higher than 80)
	if [ "$PERCENT" -gt 80 ]; then
		printf "%b" "$RED"
	else
		printf "%b" "$GREEN"
	fi

	# Print the blocks!!
	for (( i = 0; i < FILLED; i++ )); do
		printf "█"
	done

	printf "%b" "$WHITE"
	for (( i = 0; i < EMPTY; i++ )); do
		printf "░"
	done
	
	printf "%b" "$CYAN"
	printf "] %3d%%\n" "$PERCENT"
}

while true; do
	# Cyan Color
	echo -e $CYAN 

	# Print text "VitaGuard"
	cat << 'EOF'
____   _______  __           ________                       ____
\   \ /   /|__|/  |______   /  _____/ __ _______ _______  __| _/
 \   Y   / |  \   __\__  \ /   \  ___|  |  \__  \\_  __ \/ __ | 
  \     /  |  ||  |  / __ \\    \_\  \  |  // __ \|  | \/ /_/ | 
   \___/   |__||__| (____  /\______  /____/(____  /__|  \____ | 
                         \/        \/           \/           \/ 
EOF
	# Reset the color
	echo -e $WHITE
	echo "==============================================================="
	
	# Uptime here
	echo -e "${WHITE}Uptime:${CYAN} $(uptime | awk '{print $3,$4}' | sed 's/,//')"
	echo

	# CPU usage
	CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}' | cut -d. -f1)
	echo -e "${WHITE}CPU Usage:${CYAN} $(progress_bar "$CPU")"
	if [ "$CPU" -gt 80 ]; then
		echo -e "${RED}		!!! WARNING : HIGH CPU LOAD DETECTED !!!${WHITE}"
	fi
	echo

	# Memory usage
	MEM_PERCENT=$(free | awk 'NR==2 {printf "%.0f", $3*100/$2}')
	MEM_USED=$(free -h | awk 'NR==2 {print $3}')
	MEM_TOTAL=$(free -h | awk 'NR==2 {print $2}')
	echo -e "${WHITE}Memory:${CYAN} $(progress_bar "$MEM_PERCENT") ($MEM_USED/$MEM_TOTAL)"
	if [ "$MEM_PERCENT" -gt 80 ]; then
		echo -e "${RED}		!!! WARNING : HIGH MEMORY USAGE !!!${WHITE}"
	fi
	echo

	# Disk usage
	DISK_PERCENT=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
	DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
	DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
	echo -e "${WHITE}Disk:${CYAN} $(progress_bar "$DISK_PERCENT") ($DISK_USED/$DISK_TOTAL)"
	if [ "$DISK_PERCENT" -gt 90 ]; then
		echo -e "${RED}		!!! WARNING : LOW DISK SPACE !!!${WHITE}"
	fi
	echo

	# List the top processes :P
	echo -e "${WHITE}Top 5 Processes by CPU:"
	echo -e "${CYAN}  PID    USER     COMMAND               %CPU    %MEM${WHITE}"
	ps -eo pid,user,comm,%cpu,%mem --sort=-%cpu | head -n 6 | tail -n 5 | \
	awk '{
	        printf "  %-6s %-8s %-18s ", $1, $2, substr($3,1,18)
		printf "'"$CYAN"'%6s '"$WHITE"' ", $4
		printf "'"$CYAN"'%6s'"$WHITE"'\n", $5   
	}'

	echo
	echo -e "${WHITE}Recent Critical Errors (last 3 lines):"

	# Filter errors
	ERRORS=$(tail -n 50 /var/log/syslog | \
		grep -i -E "error|failed|panic|oom|kernel" | \
		grep -v "workqueue" | grep -v "drm" | grep -v "FuEngine" | grep -v "unattended" | \
		tail -n 3)
	if [ -n "$ERRORS" ]; then
		echo -e "${RED}$ERRORS"
	else
		echo -e "${GREEN}No critical errors detected!${WHITE}"
	fi

	# Network and service status
	echo
    	echo "Network Interfaces:"
        ip link show up | grep -v "lo:" | grep "state UP" | awk -F': ' '{print "  " $2}' || echo "  No active interfaces"

	echo
	echo -e "${WHITE}Service Status:"
	for service in sshd docker nginx; do
		if systemctl is-active --quiet "$service" 2>/dev/null; then
			echo -e "  $service: ${GREEN}running${WHITE}"
		else
			echo -e "  $service: ${RED}stopped/not installed${WHITE}"
		fi
	done

	echo
	echo "==============================================================="
	echo -e "${CYAN}Refreshing in 5 seconds... (Press CTRL+C to exit!)${WHITE}"

	sleep 5
	clear
done
