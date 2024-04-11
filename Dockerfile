# Use Docker's official image as the base
FROM docker:latest

# Install dependencies required for your script (if any)
RUN apk add --no-cache bash sed

# Copy the DockerSnap.sh script into the container
COPY DockerSnap.sh /usr/local/bin/DockerSnap.sh

# Make sure the script is executable
RUN chmod +x /usr/local/bin/DockerSnap.sh

# This is a placeholder command; the container will be used interactively
CMD ["bash"]
