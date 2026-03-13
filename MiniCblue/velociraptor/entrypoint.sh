#!/bin/bash

echo "[*] Ensuring Velociraptor binary is executable..."
chmod +x /usr/local/bin/velociraptor

# Patch the server config with the real host IP so the GUI redirect URL and
# the agent enrollment hostname both point to the correct machine.
if [ -n "${HOST_IP}" ] && [ "${HOST_IP}" != "127.0.0.1" ] && [ "${HOST_IP}" != "localhost" ] && [ "${HOST_IP}" != "::1" ]; then
    echo "[*] Patching Velociraptor config with HOST_IP=${HOST_IP}..."
    # Update browser-facing GUI public_url (the URL the dashboard redirects to after login)
    sed -i "s|  public_url: https://.*:7000/|  public_url: https://${HOST_IP}:7000/|" /velociraptor/server.config.yaml
    # Update Frontend hostname so agent enrollment URLs point to the real host
    sed -i "/^Frontend:/,/^[A-Z]/{s/^  hostname:.*/  hostname: ${HOST_IP}/}" /velociraptor/server.config.yaml
    echo "[*] Config patched."
fi

echo "[*] Adding admin user from environment variables..."
/usr/local/bin/velociraptor --config /velociraptor/server.config.yaml user add --role=administrator "$VEL_USER" "$VEL_PASSWORD" || echo "[!] User may already exist."

echo "[*] Starting Velociraptor frontend..."
exec /usr/local/bin/velociraptor --config /velociraptor/server.config.yaml frontend
