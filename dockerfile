FROM alpine:latest

# Install Git and OpenSSH
RUN apk add --no-cache git openssh

# Create a user to avoid running as root
RUN adduser -D -u 1000 dockeruser
USER dockeruser
WORKDIR /home/dockeruser

# Set up Git configuration
ENTRYPOINT ["/bin/sh"]
