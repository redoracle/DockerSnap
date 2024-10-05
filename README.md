![GitHub Repo Stars](https://img.shields.io/github/stars/redoracle/DockerSnap.svg?style=social&label=Star)
![GitHub Forks](https://img.shields.io/github/forks/redoracle/DockerSnap.svg?style=social&label=Fork)
![GitHub Issues](https://img.shields.io/github/issues/redoracle/DockerSnap.svg)
![GitHub License](https://img.shields.io/github/license/redoracle/DockerSnap.svg)
![Docker Image Size](https://img.shields.io/docker/image-size/redoracle/dockersnap/latest)
![Docker Pulls](https://img.shields.io/docker/pulls/redoracle/dockersnap.svg)
![Build Status](https://github.com/redoracle/DockerSnap/actions/workflows/docker-image.yml/badge.svg)

# DockSnap

![DockSnap Logo](https://raw.githubusercontent.com/redoracle/DockerSnap/main/DockerSnap%20logo.webp)

**DockSnap** is a powerful Docker Environment Snapshot Tool engineered to generate a comprehensive `docker-compose-captured.yml` file. This file meticulously replicates the configurations of all currently running Docker containers on your host system. Whether your goal is backup, documentation, replication, or migration, DockSnap streamlines the process of capturing and reproducing your Docker environment with precision and ease.

## Table of Contents

- [Features](#features)
- [How It Works](#how-it-works)
- [Benefits](#benefits)
- [Installation](#installation)
  - [Prerequisites](#prerequisites)
  - [Building the Docker Image](#building-the-docker-image)
  - [Pushing to Docker Registries](#pushing-to-docker-registries)
- [Usage](#usage)
  - [Running DockSnap](#running-dockersnap)
  - [Debug Mode](#debug-mode)
- [Example](#example)
- [Recommendations](#recommendations)
- [License](#license)

## Features

- **Comprehensive Snapshot**: Captures detailed configurations of all running Docker containers, including environment variables, volumes, ports, networks, and more.
- **Dependency Verification**: Ensures all required tools (`docker`, `jq`, `sed`) are installed prior to execution.
- **Robust Error Handling**: Implements strong error handling mechanisms to prevent unexpected failures.
- **Modular Architecture**: Organized into distinct functions for enhanced readability and maintainability.
- **YAML Compliance**: Generates properly formatted and indented YAML files compatible with Docker Compose.
- **Customizable Output**: Facilitates easy customization and extension to suit specific needs.
- **Docker Registry Integration**: Seamlessly integrates with Docker Hub and GitHub Container Registry for image distribution.
- **Automated CI/CD Pipeline Support**: Easily incorporate DockSnap into your CI/CD workflows for automated environment snapshots.

## How It Works

1. **Initialization**: Defines the output filename (`docker-compose-captured.yml`) and initializes it with the Docker Compose version header.
2. **Dependency Verification**: Checks for the presence of essential tools (`docker`, `jq`, `sed`) to ensure smooth execution.
3. **Container Inspection**: Iterates through each running Docker container, extracting critical details such as:
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

## Benefits

- **Backup and Replication**: Effortlessly back up container configurations for disaster recovery or replicate environments across different systems.
- **Documentation**: Generate a snapshot of your current Docker setup for documentation and auditing purposes.
- **Migration**: Simplify the migration of Docker containers between hosts or cloud environments by exporting configurations in a portable format.
- **Consistency**: Ensure consistent environments across development, testing, and production stages by using identical Docker Compose configurations.
- **Streamlined Deployment**: Utilize DockSnap within CI/CD pipelines to automate environment setups, enhancing deployment speed and reliability.

## Installation

### Prerequisites

Before utilizing DockSnap, ensure that the following tools are installed on your system:

- **Docker**: To manage Docker containers.
- **jq**: A lightweight and flexible command-line JSON processor.
- **sed**: A stream editor for filtering and transforming text.

You can install these dependencies using your package manager. For example, on Debian-based systems:

```bash
sudo apt update
sudo apt install -y docker.io jq sed
```

### Building the Docker Image

1. **Clone the Repository**: Begin by cloning the DockSnap repository to your local machine.

    ```bash
    git clone https://github.com/redoracle/DockerSnap.git
    cd DockerSnap
    ```

2. **Build the Docker Image**: Utilize the provided `Dockerfile` to build the DockSnap Docker image. You can replace `dockersnap` with your preferred image name if desired.

    ```bash
    docker build -t dockersnap .
    ```

### Pushing to Docker Registries

DockSnap can be published to both Docker Hub and GitHub Container Registry (GHCR) for easy distribution and integration.

#### Docker Hub

1. **Login to Docker Hub**:

    ```bash
    docker login
    ```

2. **Tag the Image**:

    Replace `your-dockerhub-username` with your actual Docker Hub username.

    ```bash
    docker tag dockersnap your-dockerhub-username/dockersnap:latest
    ```

3. **Push the Image**:

    ```bash
    docker push your-dockerhub-username/dockersnap:latest
    ```

#### GitHub Container Registry (GHCR)

1. **Authenticate to GHCR**:

    Generate a [Personal Access Token (PAT)](https://github.com/settings/tokens) with at least the `read:packages`, `write:packages`, and `delete:packages` scopes.

    ```bash
    echo $CR_PAT | docker login ghcr.io -u USERNAME --password-stdin
    ```

    Replace `USERNAME` with your GitHub username and `CR_PAT` with your PAT.

2. **Tag the Image**:

    ```bash
    docker tag dockersnap ghcr.io/your-github-username/dockersnap:latest
    ```

3. **Push the Image**:

    ```bash
    docker push ghcr.io/your-github-username/dockersnap:latest
    ```

## Usage

### Running DockSnap

To execute DockSnap and generate the `docker-compose-captured.yml` file, run the following command. This command mounts the Docker socket to allow DockSnap to interact with the Docker daemon on the host.

```bash
docker run -it --rm --name dockersnap-instance -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd):/output dockersnap
```

**Explanation of Flags:**

- `-it`: Runs the container in interactive mode with a pseudo-TTY.
- `--rm`: Automatically removes the container once it exits.
- `--name dockersnap-instance`: Names the container instance for easier reference.
- `-v /var/run/docker.sock:/var/run/docker.sock`: Mounts the Docker socket to allow DockSnap to communicate with the Docker daemon.
- `-v $(pwd):/output`: Mounts the current directory to `/output` inside the container to save the generated `docker-compose-captured.yml` file.
- `dockersnap`: Specifies the DockSnap Docker image to use.

Upon successful execution, a `docker-compose-captured.yml` file will be generated in the current directory, containing the configurations of all running Docker containers.

### Debug Mode

For detailed logs and insights into the script's execution, you can enable debug mode by passing the `--debug` flag:

```bash
docker run -it --rm --name dockersnap-instance -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd):/output dockersnap --debug
```

In debug mode, DockSnap will output additional information about the captured values and processing steps, aiding in troubleshooting and verification.

## Example

Consider a scenario where you have two running Docker containers: one for a web application and another for a database. Running DockSnap will generate a `docker-compose-captured.yml` file that defines both containers with their respective configurations.

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

## Recommendations

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

- **Security Best Practices**: Ensure that sensitive information such as environment variables containing passwords are handled securely. Consider using Docker secrets or environment variable masking where appropriate.

- **Regular Updates**: Keep DockSnap and its dependencies updated to leverage new features, security patches, and performance improvements.

- **Contribute**: If you have ideas for improvements or encounter issues, consider contributing to the project by submitting issues or pull requests on the [GitHub repository](https://github.com/redoracle/DockerSnap).

## Docker Registries Integration

DockSnap supports seamless integration with both Docker Hub and GitHub Container Registry (GHCR), enabling efficient distribution and deployment of Docker images.

### Docker Hub

**Docker Hub** is a widely-used Docker registry that allows you to store and share container images.

#### Pushing DockSnap to Docker Hub

1. **Login to Docker Hub**:

    ```bash
    docker login
    ```

2. **Tag the Image**:

    Replace `your-dockerhub-username` with your actual Docker Hub username.

    ```bash
    docker tag dockersnap your-dockerhub-username/dockersnap:latest
    ```

3. **Push the Image**:

    ```bash
    docker push your-dockerhub-username/dockersnap:latest
    ```

4. **Pulling the Image**:

    To use DockSnap from Docker Hub, pull the image using:

    ```bash
    docker pull your-dockerhub-username/dockersnap:latest
    ```

### GitHub Container Registry (GHCR)

**GitHub Container Registry (GHCR)** allows you to host and manage Docker images alongside your GitHub repositories.

#### Pushing DockSnap to GHCR

1. **Authenticate to GHCR**:

    Generate a [Personal Access Token (PAT)](https://github.com/settings/tokens) with at least the `read:packages`, `write:packages`, and `delete:packages` scopes.

    ```bash
    echo $CR_PAT | docker login ghcr.io -u USERNAME --password-stdin
    ```

    Replace `USERNAME` with your GitHub username and `CR_PAT` with your PAT.

2. **Tag the Image**:

    ```bash
    docker tag dockersnap ghcr.io/your-github-username/dockersnap:latest
    ```

3. **Push the Image**:

    ```bash
    docker push ghcr.io/your-github-username/dockersnap:latest
    ```

4. **Pulling the Image**:

    To use DockSnap from GHCR, pull the image using:

    ```bash
    docker pull ghcr.io/your-github-username/dockersnap:latest
    ```

### Using DockSnap from Registries

Regardless of the registry you choose, running DockSnap follows the same pattern. Ensure you pull the latest image from your chosen registry before execution to benefit from the latest updates.

**Example with Docker Hub:**

```bash
docker pull your-dockerhub-username/dockersnap:latest
docker run -it --rm --name dockersnap-instance -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd):/output your-dockerhub-username/dockersnap:latest
```

**Example with GHCR:**

```bash
docker pull ghcr.io/your-github-username/dockersnap:latest
docker run -it --rm --name dockersnap-instance -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd):/output ghcr.io/your-github-username/dockersnap:latest
```

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT). See the [LICENSE](LICENSE) file for details.

---

*Created with ❤️ by [Redoracle](https://github.com/redoracle)*
