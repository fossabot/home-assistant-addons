# Troubleshooting Guide

Common issues and solutions for wrapped Docker add-ons.

## Binary Issues

**Problem:** Binary not found or won't execute

**Solutions:**
- Verify binary path in upstream image first
- Check architecture matches (amd64/aarch64)
- Ensure executable permissions
- Install missing interpreter (bash, python3)

## Library Issues  

**Problem:** Missing shared libraries

**Solutions:**
- Copy libraries from source image
- Install packages providing libraries
- Check LD_LIBRARY_PATH

## Permission Issues

**Problem:** Cannot write to /data

**Solutions:**
- Create user in Dockerfile matching upstream UID
- Fix ownership in init script
- Run as root if safe

## Configuration Issues

**Problem:** Config file not generated

**Solutions:**
- Check S6 service dependencies
- Verify init-config ran successfully  
- Add config existence check in run script
- Provide defaults for all template variables

## Network Issues

**Problem:** Cannot connect to services

**Solutions:**
- Add wait loops for service readiness
- Check host_network setting
- Add DNS servers if needed

## Add-on Stops Immediately

**Problem:** Starts then quickly stops

**Solutions:**
- Use exec in run scripts
- Test binary manually
- Check finish script returns 0
- Review logs for actual error

See full workflow documentation for detailed debugging steps.
