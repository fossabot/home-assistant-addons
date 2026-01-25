ARG BUILD_FROM
FROM rommapp/romm:latest as romm-base
FROM ${BUILD_FROM} AS final

# Install required packages
RUN apk add --no-cache \
    python3 \
    py3-pip \
    mariadb-connector-c

# Copy Romm application from official image
COPY --from=romm-base /romm /romm

# Copy rootfs (initialization scripts)
COPY rootfs /

# Set permissions on scripts
RUN chmod a+x /etc/cont-init.d/romm.sh \
    && chmod a+x /etc/services.d/romm/run \
    && chmod a+x /etc/services.d/romm/finish

# Set working directory
WORKDIR /romm

# Expose port (for ingress)
EXPOSE 8080
