# Use debian-minimal as a base image
FROM debian:buster-slim AS base

# Second stage: get the binary from the coder/envbuilder image
FROM ghcr.io/coder/envbuilder:0.2.1 AS source

# Final stage: Set up the debian-minimal image with the envbuilder binary
FROM base

# Copy envbuilder binary from the source stage
COPY --from=source /.envbuilder/bin/envbuilder /.envbuilder/bin/envbuilder

# Set necessary environment variables
ENV KANIKO_DIR /.envbuilder
ENV DOCKER_CONFIG /.envbuilder

# Add a user `${USERNAME}` so that you're not developing as the `root` user
ARG USERID=1000
ARG GROUPID=1000
ARG USERNAME=coder
RUN groupadd -g ${GROUPID} ${USERNAME} && \
    useradd ${USERNAME} \
    --create-home \
    --uid ${USERID} \
    --gid ${GROUPID} \
    --shell=/bin/bash
    # echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers.d/nopasswd

RUN chown -R ${USERNAME}:${USERNAME} /.envbuilder

# Set entrypoint to envbuilder
ENTRYPOINT ["/.envbuilder/bin/envbuilder"]

