# DockSnap

![DockSnap Logo](https://raw.githubusercontent.com/redoracle/DockerSnap/main/DockerSnap%20logo.webp)

**DockSnap** is a robust Docker Environment Snapshot Tool designed to generate a comprehensive `docker-compose-captured.yml` file. This file accurately replicates the configurations of all currently running Docker containers on your host system. Whether you're aiming for backup, documentation, replication, or migration, DockSnap streamlines the process of capturing and reproducing your Docker environment with ease.

## Table of Contents

- [Features](#features)
- [How It Works](#how-it-works)
- [Why It's Useful](#why-its-useful)
- [Installation](#installation)
  - [Prerequisites](#prerequisites)
  - [Building the Docker Image](#building-the-docker-image)
- [Usage](#usage)
  - [Running DockSnap](#running-dockersnap)
  - [Debug Mode](#debug-mode)
- [Example](#example)
- [Additional Recommendations](#additional-recommendations)
- [License](#license)

## Features

- **Comprehensive Snapshot**: Captures detailed configurations of all running Docker containers, including environment variables, volumes, ports, networks, and more.
- **Dependency Checks**: Ensures all required tools (`docker`, `jq`, `sed`) are installed before execution.
- **Error Handling**: Robust error handling to prevent unexpected failures.
- **Modular Design**: Organized into functions for better readability and maintenance.
- **YAML Compliance**: Generates properly formatted and indented YAML files compatible with Docker Compose.
- **Customizable Output**: Allows for easy customization and extension.

## How It Works

1. **Initialization**: Defines the output filename (`docker-compose-captured.yml`) and initializes it with the Docker Compose version header.
2. **Dependency Verification**: Checks for the presence of required tools (`docker`, `jq`, `sed`) to ensure smooth execution.
3. **Container Inspection**: Iterates through each running Docker container, extracting essential details such as:
   - Container name and image
   - STDIN openness and TTY status
   - Entrypoint and command configurations
   - Health check settings
   - Initialization and restart policies
   - Network configurations, including DNS servers and IP addresses
   - Volume and environment variable mappings
4. **Configuration Handling**: Dynamically includes configurations based on their presence, ensuring flexibility and accuracy.
5. **Network Management**: Collects and defines unique networks, excluding default ones like `bridge` and `host`, to avoid duplication.
6. **YAML Generation**: Constructs a well-formatted `docker-compose-captured.yml` file with detailed service definitions for each container, facilitating easy recreation of the Docker environment using Docker Compose.

## Why It's Useful

- **Backup and Replication**: Easily back up container configurations for disaster recovery or replicate environments across different systems.
- **Documentation**: Generate a snapshot of your current Docker setup for documentation and auditing purposes.
- **Migration**: Simplify the migration of Docker containers between hosts or cloud environments by exporting configurations in a portable format.
- **Consistency**: Ensure consistent environments across development, testing, and production stages by using the same Docker Compose configurations.

## Installation

### Prerequisites

Before using DockSnap, ensure that the following tools are installed on your system:

- **Docker**: To manage Docker containers.
- **jq**: A lightweight and flexible command-line JSON processor.
- **sed**: A stream editor for filtering and transforming text.

You can install these dependencies using your package manager. For example, on Debian-based systems:

```bash
sudo apt update
sudo apt install -y docker.io jq sed
```

### Building the Docker Image

1. **Clone the Repository**: First, clone the DockSnap repository to your local machine.

    ```bash
    git clone https://github.com/redoracle/DockerSnap.git
    cd DockerSnap
    ```

2. **Build the Docker Image**: Use the provided `Dockerfile` to build the DockSnap Docker image. Replace `dockersnap` with your desired image name if needed.

    ```bash
    docker build -t dockersnap .
    ```

## Usage

### Running DockSnap

To execute DockSnap and generate the `docker-compose-captured.yml` file, run the following command. This command mounts the Docker socket to allow DockSnap to interact with the Docker daemon on the host.

```bash
docker run -it --rm --name dockersnap-instance -v /var/run/docker.sock:/var/run/docker.sock dockersnap
```

Upon successful execution, a `docker-compose-captured.yml` file will be generated in the current directory, containing the configurations of all running Docker containers.

### Debug Mode

For detailed logs and insights into the script's execution, you can enable debug mode by passing the `--debug` flag:

```bash
docker run -it --rm --name dockersnap-instance -v /var/run/docker.sock:/var/run/docker.sock dockersnap --debug
```

In debug mode, DockSnap will output additional information about the captured values and processing steps, aiding in troubleshooting and verification.

## Example

Imagine you have two running Docker containers: one for a web application and another for a database. Running DockSnap will generate a `docker-compose-captured.yml` file that defines both containers with their respective configurations.

**Before Running DockSnap:**

- **Web Application Container**:
  - Image: `nginx:latest`
  - Ports: `80:80`
  - Volumes: `/var/www/html:/usr/share/nginx/html`
  - Environment Variables: `ENV=production`
  
- **Database Container**:
  - Image: `mysql:5.7`
  - Ports: `3306:3306`
  - Volumes: `/var/lib/mysql:/var/lib/mysql`
  - Environment Variables: `MYSQL_ROOT_PASSWORD=secret`

**After Running DockSnap:**

A `docker-compose-captured.yml` file is generated with the following content:

```yaml
version: '3.7'
services:
  web_app:
    image: "nginx:latest"
    container_name: "web_app"
    hostname: "web_appG"
    stdin_open: false
    tty: false
    ports:
      - "80:80"
    volumes:
      - "/var/www/html:/usr/share/nginx/html"
    environment:
      - "ENV=production"
    networks:
      "bridge":
        ipv4_address: "null"

  database:
    image: "mysql:5.7"
    container_name: "database"
    hostname: "databaseG"
    stdin_open: false
    tty: false
    ports:
      - "3306:3306"
    volumes:
      - "/var/lib/mysql:/var/lib/mysql"
    environment:
      - "MYSQL_ROOT_PASSWORD=secret"
    networks:
      "bridge":
        ipv4_address: "null"

networks:
  "bridge":
    external: true
```

You can now use this `docker-compose-captured.yml` file to recreate the same environment on another machine:

```bash
docker-compose -f docker-compose-captured.yml up -d
```

This ensures that both the web application and database containers are set up with identical configurations, facilitating seamless environment replication.

## Additional Recommendations

- **YAML Validation**: After generating the `docker-compose-captured.yml` file, validate its syntax using tools like [`yamllint`](https://github.com/adrienverge/yamllint) to ensure correctness.

    ```bash
    yamllint docker-compose-captured.yml
    ```

- **Backup Existing Compose File**: To prevent accidental overwriting of existing `docker-compose-captured.yml` files, consider backing them up before generation.

    ```bash
    if [ -f "docker-compose-captured.yml" ]; then
        cp docker-compose-captured.yml "docker-compose-captured.yml.bak_$(date +%F_%T)"
    fi
    ```

- **Customization**: Enhance DockSnap by adding options to specify the output filename, exclude certain containers, or include additional configurations based on user preferences.

- **Automation**: Integrate DockSnap into your CI/CD pipelines to automate environment snapshots during deployment processes.

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT). See the [LICENSE](LICENSE) file for details.

---

*Created with ❤️ by [Redoracle](https://github.com/redoracle)*