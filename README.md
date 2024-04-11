# DockerSnap
This Bash script generates a docker-compose file (docker-compose-captured.yml) that replicates the settings of all currently running Docker containers on the host. It is a method for capturing the state of Docker containers and replicating them elsewhere or rebuilding the system as it is currently configured. This is especially useful when numerous containers have been launched using the basic "docker run..." command and it is difficult to recollect the particular commands for each container without inspecting them individually.

<div style="text-align: center;">
<img src="https://raw.githubusercontent.com/redoracle/DockerSnap/main/DockerSnap%20logo.webp" width="300" height="300" align="center">
</div>

### How it Works
1. **Initialization**: The script starts by defining the filename for the Docker Compose file and initializing it with a version header.
2. **Capture Container Details**: For each running container, it captures various details including container name, image name, whether STDIN is open, TTY status, entrypoint, command, health check configuration, init status, restart policy, network mode, DNS servers, network name, and IP address.
3. **Escape Home Directory**: It escapes the user's home directory in paths for compatibility.
4. **Handle Dynamic Configuration**: It dynamically handles the presence of configurations like entrypoints, commands, health checks, initialization status, restart policies, DNS servers, ports, volumes (with the user's home directory path masked for privacy and portability), environment variables, and network assignments.
5. **Avoid Duplicate Network Definitions**: It ensures networks are defined once and excludes the default bridge network from being explicitly defined in the Docker Compose file.
6. **Compose File Generation**: The generated `docker-compose-captured.yml` includes detailed service definitions for each container, making it possible to recreate the containers' state using Docker Compose.

### Why It's Useful
- **Backup and Replication**: Allows for easy backup of container configurations for disaster recovery or replication of environments (e.g., from development to production).
- **Documentation**: Provides a snapshot of the current state of containers for documentation purposes.
- **Migration**: Facilitates migration of Docker containers between hosts or cloud environments by capturing their configurations in a portable format.

### Example
Imagine you have two containers running on your machine; one for a web application and another for a database. Running this script would generate a `docker-compose-captured.yml` file that defines both containers, including their images, volumes, ports, and any custom configurations. This file can then be used to start the same containers with Docker Compose on another machine, replicating the original environment.

For instance, if you had a MySQL database running in one container and a PHP application in another, the script would capture details like the MySQL version, the volume used for data persistence, the PHP image, linked environment variables, and network settings. By using the generated Docker Compose file, you can recreate the exact setup on a new host, ensuring that the application environment is consistent across different stages of development, testing, or production.
