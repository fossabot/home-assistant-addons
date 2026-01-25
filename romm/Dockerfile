ARG BUILD_FROM
FROM rommapp/romm:latest as romm-base
FROM ${BUILD_FROM} AS final

# Copy Romm application from official image
COPY --from=romm-base /romm /romm

# Copy Python environment and dependencies
COPY --from=romm-base /usr/local/lib/python3.12 /usr/local/lib/python3.12
COPY --from=romm-base /usr/local/bin /usr/local/bin

# Install Python (HA base doesn't include it)
RUN apk add --no-cache \
    python3 \
    py3-pip \
    mariadb-connector-c

# Copy rootfs (s6 service scripts)
COPY rootfs /

# Set permissions
RUN chmod a+x /etc/cont-init.d/*.sh \
    && chmod a+x /etc/services.d/romm/run \
    && chmod a+x /etc/services.d/romm/finish

WORKDIR /romm
EXPOSE 8095
