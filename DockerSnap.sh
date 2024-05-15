#!/bin/bash

# DockSnap - Docker Environment Snapshot Tool
# Author: Redoracle
# Date: 11 April 2024
# License: MIT License
# Description: Generates a docker-compose file that captures the state of all currently running Docker containers on the system. It's designed for backup, documentation, replication, and migration purposes.

# Filename for the docker-compose file
COMPOSE_FILE=docker-compose-captured.yml
DEBUG=false

# Check if --debug flag is passed
if [[ "$1" == "--debug" ]]; then
    DEBUG=true
fi

# Debug function to print grabbed values
debug_print() {
    if [ "$DEBUG" == true ]; then
        echo -e "$1"
    fi
}

# Start of the docker-compose file with Docker Compose version
echo "version: '3.7'" > $COMPOSE_FILE
echo "services:" >> $COMPOSE_FILE

# Prepare the user's home directory path for inclusion in the Docker Compose file
escaped_home=$(echo $HOME | sed 's|/|\\/|g')

# Loop through each running Docker container to capture its configuration
docker ps -q | while read container_id; do
    # Extract container and image details
    container_name=$(docker inspect --format '{{.Name}}' $container_id | sed 's/^\///')
    image_name=$(docker inspect --format '{{.Config.Image}}' $container_id)
    # Extract configurations like STDIN openness, TTY status, entrypoint, and command
    stdin_open=$(docker inspect --format '{{.Config.OpenStdin}}' $container_id)
    tty=$(docker inspect --format '{{.Config.Tty}}' $container_id)
    entrypoint=$(docker inspect --format '{{json .Config.Entrypoint}}' $container_id | sed 's/^null$//')
    cmd=$(docker inspect --format '{{json .Config.Cmd}}' $container_id | sed 's/^null$//')
    # Extract healthcheck configuration, init status, and restart policy
    healthcheck_test=$(docker inspect --format '{{if .Config.Healthcheck}}{{json .Config.Healthcheck.Test}}{{else}}""{{end}}' $container_id | sed 's/^null$//')
    init=$(docker inspect --format '{{.HostConfig.Init}}' $container_id)
    restart_policy=$(docker inspect --format '{{.HostConfig.RestartPolicy.Name}}' $container_id)
    # Extract network settings like network mode and DNS servers
    dns_servers=$(docker inspect --format '{{range .HostConfig.Dns}}{{.}} {{end}}' $container_id)
    # Extract network details
    networks=$(docker inspect --format '{{json .NetworkSettings.Networks}}' $container_id)

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

    # Begin constructing the service definition in the Docker Compose file
    echo "  $container_name:" >> $COMPOSE_FILE
    echo "    image: $image_name" >> $COMPOSE_FILE
    echo "    container_name: $container_name" >> $COMPOSE_FILE
    # Include configurations such as STDIN openness, TTY status, entrypoint, and command
    echo "    hostname: ${container_name}G" >> $COMPOSE_FILE
    echo "    stdin_open: $stdin_open" >> $COMPOSE_FILE
    echo "    tty: $tty" >> $COMPOSE_FILE
    [ ! -z "$entrypoint" ] && echo "    entrypoint: $entrypoint" >> $COMPOSE_FILE
    [ ! -z "$cmd" ] && echo "    command: $cmd" >> $COMPOSE_FILE
    # Include healthcheck, init status, restart policy, and DNS servers if applicable
    if [ ! -z "$healthcheck_test" ] && [ "$healthcheck_test" != "[]" ] && [ "$healthcheck_test" != '""' ]; then
        echo "    healthcheck:" >> $COMPOSE_FILE
        echo "      test: $healthcheck_test" >> $COMPOSE_FILE
    fi
    [ "$init" == "true" ] && echo "    init: true" >> $COMPOSE_FILE
    if [ "$restart_policy" == "no" ]; then
        echo "    restart: unless-stopped" >> $COMPOSE_FILE
    else
        [ ! -z "$restart_policy" ] && echo "    restart: $restart_policy" >> $COMPOSE_FILE
    fi
    [ ! -z "$dns_servers" ] && echo "    dns: [$dns_servers]" >> $COMPOSE_FILE

    # Handle port mappings
    ports=$(docker inspect --format '{{range $p, $conf := .NetworkSettings.Ports}}{{if $conf}}{{(index $conf 0).HostPort}}:{{$p}}{{"\n"}}{{end}}{{end}}' $container_id)
    if [ ! -z "$ports" ]; then
        echo "    ports:" >> $COMPOSE_FILE
        echo "$ports" | while read port; do
            echo "      - \"$port\"" >> $COMPOSE_FILE
        done
    fi

    # Handle volume mappings, substituting the actual home directory path with a placeholder
    volumes=$(docker inspect --format '{{range .Mounts}}{{printf "      - \"%s:%s\"\n" .Source .Destination}}{{end}}' $container_id | sed "s|$escaped_home|\$HOME|g")
    if [ ! -z "$volumes" ]; then
        echo "    volumes:" >> $COMPOSE_FILE
        echo "$volumes" >> $COMPOSE_FILE
    fi

    # Include environment variables
    envs=$(docker inspect --format '{{range .Config.Env}}{{printf "      - \"%s\"\n" .}}{{end}}' $container_id)
    if [ ! -z "$envs" ]; then
        # Use sed to process the envs variable
        envs=$(echo "$envs" | sed -E '
            s/^(.*=)/\1/;                    # Match everything up to the first "=" and leave it as is
            s/([^\\])"/\1\\"/g;              # Replace every unescaped " with \"
            s/\\\\"/"/g;                     # Undo double escaping of already escaped quotes
            s/(.*\\"[^"]*)\\"$/\1"/;         # Leave the last double quote unchanged
            s/\$/\\\$/g;                      # Escape any dollar signs
            s/^(.*- \\")/      - "/;     # Unescape the first double quote if needed
        ')
        echo "    environment:" >> $COMPOSE_FILE
        echo "$envs" >> $COMPOSE_FILE
    fi


    # Assign the container to networks, specifying IP addresses if available
    custom_networks=$(echo "$networks" | jq -r 'to_entries[] | select(.key != "bridge" and .key != "host") | "\(.key)"')
    if [ ! -z "$custom_networks" ]; then
        echo "    networks:" >> $COMPOSE_FILE
        echo "$networks" | jq -r 'to_entries[] | select(.key != "bridge" and .key != "host") | "      \(.key):\n        ipv4_address: \(.value.IPAddress)"' >> $COMPOSE_FILE
    fi

    # Add a newline for readability between service definitions
    echo "" >> $COMPOSE_FILE

done

# Extract unique network names and append them to the end of the file
unique_networks=$(grep -A 1 "networks:" $COMPOSE_FILE | grep -v "networks:" | grep -v "^--$" | awk '{print $1}' | sort -u)

if [ ! -z "$unique_networks" ]; then
    echo "networks:" >> $COMPOSE_FILE
    for net in $unique_networks; do
        echo "  $net" >> $COMPOSE_FILE
        echo "    external: true" >> $COMPOSE_FILE
    done
fi

echo "Generated docker-compose file: $COMPOSE_FILE"
