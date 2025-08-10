# UFW (Uncomplicated Firewall) Commands

## Basic Commands

### Check UFW Status
```bash
sudo ufw status
```

### Enable/Disable UFW
```bash
# Enable UFW
sudo ufw enable

# Disable UFW
sudo ufw disable
```

## Managing Rules

### Allow SSH (Port 22)
```bash
# Allow SSH from anywhere
sudo ufw allow 22/tcp

# Allow SSH from specific IP
sudo ufw allow from 192.168.1.100 to any port 22
```

### Allow HTTP/HTTPS
```bash
# Allow HTTP
sudo ufw allow 80/tcp

# Allow HTTPS
sudo ufw allow 443/tcp
```

### Allow Specific Ports
```bash
# Allow specific port
sudo ufw allow 8080/tcp

# Allow port range
sudo ufw allow 8000:8080/tcp
```

### Allow Specific IP Addresses
```bash
# Allow all traffic from specific IP
sudo ufw allow from 192.168.1.100

# Allow specific port from specific IP
sudo ufw allow from 192.168.1.100 to any port 3306
```

## IPFS Cluster Specific Rules

### Bootstrap Node (211.239.117.217)
```bash
# Allow Peer-01
sudo ufw allow from 218.38.136.33 to any port 4001,5001,8080,9094,9096 proto tcp

# Allow Peer-02
sudo ufw allow from 218.38.136.34 to any port 4001,5001,8080,9094,9096 proto tcp

# Allow HostCenter IPs
sudo ufw allow from 110.10.81.170 to any  # Monitoring
sudo ufw allow from 121.125.68.226 to any  # Management
```

### Peer-01 (218.38.136.33)
```bash
# Allow Bootstrap Node
sudo ufw allow from 211.239.117.217 to any port 4001,5001,8080,9094,9096 proto tcp

# Allow Peer-02
sudo ufw allow from 218.38.136.34 to any port 4001,5001,8080,9094,9096 proto tcp

# Allow HostCenter IPs
sudo ufw allow from 110.10.81.170 to any  # Monitoring
sudo ufw allow from 121.125.68.226 to any  # Management
```

### Peer-02 (218.38.136.34)
```bash
# Allow Bootstrap Node
sudo ufw allow from 211.239.117.217 to any port 4001,5001,8080,9094,9096 proto tcp

# Allow Peer-01
sudo ufw allow from 218.38.136.33 to any port 4001,5001,8080,9094,9096 proto tcp

# Allow HostCenter IPs
sudo ufw allow from 110.10.81.170 to any  # Monitoring
sudo ufw allow from 121.125.68.226 to any  # Management
```

### Additional Whitelisted IPs
```bash
# Team Member IPs
sudo ufw allow from 169.150.218.66 to any  # JB's IP
sudo ufw allow from 157.20.143.170 to any  # Franz's IP
sudo ufw allow from 49.145.0.190 to any    # Aldric's IP
sudo ufw allow from 119.94.162.43 to any   # Alex's IP
sudo ufw allow from 112.200.100.154 to any # Bong's IP

# Backend Server
sudo ufw allow from 52.77.36.120 to any    # bongaquino Staging Backend
```

## Removing Rules

### Remove Rules by Number
```bash
# List rules with numbers
sudo ufw status numbered

# Remove rule by number
sudo ufw delete 1
```

### Remove Rules by Specification
```bash
# Remove allow rule for port 22
sudo ufw delete allow 22/tcp

# Remove allow rule for specific IP
sudo ufw delete allow from 192.168.1.100

# Remove IPFS cluster rule
sudo ufw delete allow from 218.38.136.33 to any port 4001,5001,8080,9094,9096 proto tcp
```

## Advanced Rules

### Deny Rules
```bash
# Deny specific port
sudo ufw deny 8080/tcp

# Deny specific IP
sudo ufw deny from 192.168.1.100
```

### Limit Rules (Prevent Brute Force)
```bash
# Limit SSH connections
sudo ufw limit 22/tcp
```

### Logging
```bash
# Enable logging
sudo ufw logging on

# Disable logging
sudo ufw logging off
```

## Best Practices

1. **Always allow SSH first** before enabling UFW
2. **Use specific IP addresses** when possible instead of allowing from anywhere
3. **Use limit rules** for services like SSH to prevent brute force attacks
4. **Check status** after making changes
5. **Test connectivity** after applying new rules
6. **Document all rules** with comments for easy management
7. **Keep a backup** of your rules before making changes

## Example Workflow

1. Enable UFW:
   ```bash
   sudo ufw enable
   ```

2. Allow SSH:
   ```bash
   sudo ufw allow 22/tcp
   ```

3. Allow IPFS Cluster Ports:
   ```bash
   sudo ufw allow from <peer_ip> to any port 4001,5001,8080,9094,9096 proto tcp
   ```

4. Check status:
   ```bash
   sudo ufw status
   ```

5. If you need to remove a rule:
   ```bash
   sudo ufw status numbered
   sudo ufw delete <rule_number>
   ```

## Troubleshooting

If you get locked out:
1. Connect to the server through the cloud provider's console
2. Disable UFW:
   ```bash
   sudo ufw disable
   ```
3. Fix your rules
4. Re-enable UFW:
   ```bash
   sudo ufw enable
   ```

## Notes

- Rules are applied in order
- Later rules take precedence over earlier ones
- Default policies can be set for incoming/outgoing traffic
- Always test rules before applying them in production
- Keep a backup of your rules:
  ```bash
  sudo ufw status > ufw-rules-backup.txt
  ```
- For IPFS cluster, ensure all required ports (4001, 5001, 8080, 9094, 9096) are open between nodes
- Use comments to document the purpose of each rule

## Additional Notes

- If you're using UFW on a server that's part of an IPFS cluster, you'll need to allow traffic between the nodes. This involves allowing traffic between the IPFS cluster peers and the host center.
- The IPFS cluster rules are designed to allow traffic between the nodes and the host center. If you're not part of an IPFS cluster, you can remove these rules.
- Always test rules before applying them in production to ensure they work as expected.
- Keep a backup of your rules before making changes to easily revert if something goes wrong.
- If you're not part of an IPFS cluster, you can remove the IPFS cluster rules and the additional whitelisted IPs. 