#!/bin/bash

# DockSnap - Docker Environment Snapshot Tool
# Author: Redoracle
# Date: 11 April 2024
# License: MIT License
# Description: Generates a docker-compose file that captures the state of all currently running Docker containers on the system. It's designed for backup, documentation, replication, and migration purposes.

set -euo pipefail

# Filename for the docker-compose file
COMPOSE_FILE="docker-compose-captured.yml"
DEBUG=false

# Function to check if required commands are available
check_dependencies() {
    local dependencies=("docker" "jq" "sed")
    for cmd in "${dependencies[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "Error: Required command '$cmd' is not installed." >&2
            echo "Please install it using your package manager. For example:"
            echo "  sudo apt-get install $cmd    # Debian/Ubuntu"
            echo "  sudo yum install $cmd        # CentOS/RHEL"
            echo "  brew install $cmd            # macOS with Homebrew"
            exit 1
        fi
    done
}

# Function to print debug messages
debug_print() {
    if [ "$DEBUG" = true ]; then
        echo -e "$1"
    fi
}

# Function to escape YAML special characters in environment variables
escape_yaml() {
    echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\$/\$\$/g'
}

# Function to map Docker restart policies to Docker Compose equivalents
map_restart_policy() {
    local policy="$1"
    case "$policy" in
        no|on-failure|unless-stopped|always)
            echo "$policy"
            ;;
        *)
            echo "no"
            ;;
    esac
}

# Function to generate service definition for a container
generate_service() {
    local container_id="$1"
    local compose_file="$2"
    local -n networks_ref="$3"  # Reference to networks array

    # Extract all necessary information in a single docker inspect call
    local inspect_json
    inspect_json=$(docker inspect "$container_id")

    # Extract container and image details
    local container_name image_name stdin_open tty entrypoint cmd healthcheck_test init restart_policy dns_servers networks cap_add shm_size sysctls volumes envs
    container_name=$(echo "$inspect_json" | jq -r '.[0].Name' | sed 's|^/||')
    image_name=$(echo "$inspect_json" | jq -r '.[0].Config.Image')
    stdin_open=$(echo "$inspect_json" | jq -r '.[0].Config.OpenStdin')
    tty=$(echo "$inspect_json" | jq -r '.[0].Config.Tty')
    entrypoint=$(echo "$inspect_json" | jq -c '.[0].Config.Entrypoint // empty')
    cmd=$(echo "$inspect_json" | jq -c '.[0].Config.Cmd // empty')
    healthcheck_test=$(echo "$inspect_json" | jq -c '.[0].Config.Healthcheck.Test // empty')
    init=$(echo "$inspect_json" | jq -r '.[0].HostConfig.Init')
    restart_policy=$(echo "$inspect_json" | jq -r '.[0].HostConfig.RestartPolicy.Name')
    dns_servers=$(echo "$inspect_json" | jq -r '.[0].HostConfig.Dns[]?' | paste -sd "," -)
    networks=$(echo "$inspect_json" | jq -c '.[0].NetworkSettings.Networks')
    cap_add=$(echo "$inspect_json" | jq -c '.[0].HostConfig.CapAdd // empty')
    shm_size=$(echo "$inspect_json" | jq -r '.[0].HostConfig.ShmSize')
    sysctls=$(echo "$inspect_json" | jq -c '.[0].HostConfig.Sysctls // empty')
    volumes=$(echo "$inspect_json" | jq -r '.[0].Mounts[]? | "\(.Source):\(.Destination)"' | sed "s|$escaped_home|\$HOME|g" | awk '{print "      - \"" $0 "\""}')
    envs=$(echo "$inspect_json" | jq -r '.[0].Config.Env[]?' | while IFS= read -r env; do
        key=$(echo "$env" | cut -d'=' -f1)
        value=$(echo "$env" | cut -d'=' -f2-)
        echo "      $key: \"$(escape_yaml "$value")\""
    done)

    debug_print "Container: $container_name"
    debug_print "Image: $image_name"
    debug_print "Stdin Open: $stdin_open"
    debug_print "TTY: $tty"
    debug_print "Entrypoint: $entrypoint"
    debug_print "Command: $cmd"
    debug_print "Healthcheck: $healthcheck_test"
    debug_print "Init: $init"
    debug_print "Restart Policy: $restart_policy"
    debug_print "DNS Servers: $dns_servers"
    debug_print "Networks: $networks"
    debug_print "CapAdd: $cap_add"
    debug_print "ShmSize: $shm_size"
    debug_print "Sysctls: $sysctls"

    # Begin constructing the service definition in the Docker Compose file
    {
        echo "  \"$container_name\":"
        echo "    image: \"$image_name\""
        echo "    container_name: \"$container_name\""
        echo "    hostname: \"${container_name}G\""
        echo "    stdin_open: $stdin_open"
        echo "    tty: $tty"

        if [ -n "$entrypoint" ] && [ "$entrypoint" != "null" ] && [ "$entrypoint" != "[]" ]; then
            echo "    entrypoint: $entrypoint"
        fi

        if [ -n "$cmd" ] && [ "$cmd" != "null" ] && [ "$cmd" != "[]" ]; then
            echo "    command: $cmd"
        fi

        if [ -n "$healthcheck_test" ] && [ "$healthcheck_test" != "null" ] && [ "$healthcheck_test" != "[]" ]; then
            echo "    healthcheck:"
            echo "      test: $healthcheck_test"
        fi

        if [ "$init" = "true" ]; then
            echo "    init: true"
        fi

        if [ -n "$restart_policy" ] && [ "$restart_policy" != "no" ]; then
            local mapped_policy
            mapped_policy=$(map_restart_policy "$restart_policy")
            echo "    restart: \"$mapped_policy\""
        elif [ "$restart_policy" = "no" ]; then
            echo "    restart: \"no\""
        fi

        if [ -n "$dns_servers" ]; then
            echo "    dns:"
            echo "$dns_servers" | tr ',' '\n' | sed 's/^/      - "/; s/$/"/'
        fi

        if [ -n "$cap_add" ] && [ "$cap_add" != "[]" ]; then
            echo "    cap_add:"
            echo "$cap_add" | jq -r '.[]' | while read -r cap; do
                echo "      - \"$cap\""
            done
        fi

        if [ "$shm_size" -gt 0 ]; then
            echo "    shm_size: \"$shm_size\""
        fi

        if [ -n "$sysctls" ] && [ "$sysctls" != "{}" ]; then
            echo "    sysctls:"
            echo "$sysctls" | jq -r 'to_entries[] | "      \(.key): \"\(.value)\""' 
        fi

        # Handle port mappings
        port_mappings=$(echo "$inspect_json" | jq -r '.[0].NetworkSettings.Ports | to_entries[]? | select(.value != null) | "\(.value[0].HostPort):\(.key)"')
        if [ -n "$port_mappings" ]; then
            echo "    ports:"
            echo "$port_mappings" | while read -r port; do
                echo "      - \"$port\""
            done
        fi

        # Handle volume mappings
        if [ -n "$volumes" ]; then
            echo "    volumes:"
            echo "$volumes"
        fi

        # Include environment variables
        if [ -n "$envs" ]; then
            echo "    environment:"
            echo "$envs"
        fi

        # Assign the container to networks, specifying IP addresses if available
        custom_networks=$(echo "$networks" | jq -r 'to_entries[] | select(.key != "bridge" and .key != "host") | .key')
        if [ -n "$custom_networks" ]; then
            echo "    networks:"
            # Use process substitution to avoid subshell
            while read -r net_entry; do
                net_name=$(echo "$net_entry" | jq -r '.key')
                ip_addr=$(echo "$net_entry" | jq -r '.value.IPAddress // empty')
                echo "      \"$net_name\":"
                if [ -n "$ip_addr" ]; then
                    echo "        ipv4_address: \"$ip_addr\""
                fi
                # Collect unique networks for later
                networks_ref+=("$net_name")
            done < <(echo "$networks" | jq -c 'to_entries[] | select(.key != "bridge" and .key != "host")')
        fi

        echo ""
    } >> "$compose_file"
}

# Function to generate networks section
generate_networks_section() {
    local compose_file="$1"
    shift
    local networks=("$@")

    if [ "${#networks[@]}" -eq 0 ]; then
        return
    fi

    # Get unique networks
    local unique_networks
    unique_networks=($(printf "%s\n" "${networks[@]}" | sort -u))

    echo "networks:" >> "$compose_file"
    for net in "${unique_networks[@]}"; do
        echo "  \"$net\":" >> "$compose_file"
        echo "    external: true" >> "$compose_file"
    done
}

# Parse arguments
if [[ "${1-}" == "--debug" ]]; then
    DEBUG=true
fi

# Check dependencies
check_dependencies

# Start of the docker-compose file with Docker Compose version
{
    echo "version: '3.7'"
    echo "services:"
} > "$COMPOSE_FILE"

# Prepare the user's home directory path for inclusion in the Docker Compose file
escaped_home=$(echo "$HOME" | sed 's|/|\\/|g')

# Initialize an array to collect network names
declare -a networks_list

# Loop through each running Docker container to capture its configuration
while read -r container_id; do
    generate_service "$container_id" "$COMPOSE_FILE" networks_list
done < <(docker ps -q)

# Debug: Print collected networks
debug_print "Collected Networks: ${networks_list[@]}"

# Extract unique network names and append them to the end of the file
generate_networks_section "$COMPOSE_FILE" "${networks_list[@]}"

echo "Generated docker-compose file: $COMPOSE_FILE"
