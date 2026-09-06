# Lyns
Lynis is an open-source tool used for conducting security audits and hardening of Linux and Unix-based systems. It is particularly useful for identifying system weaknesses and providing recommendations to address and solve them.

## How does it work?
1. System Scanning:
- Lynis runs a series of tests, analyzing various system areas such as system configuration, package status, security policies, and network settings.

2. Result Analysis:
- After completing the scan, the tool generates a report listing potential issues and recommendations for improving security.

3. Audited Areas:
- User and access management.
- Network and firewall configurations.
- Regulatory compliance (e.g., GDPR, HIPAA).
- Application and service hardening.

4. Recommendations:
- Lynis suggests specific actions, such as “enable the firewall,” “modify SSH configuration,” or “update a specific package.”

## Lyns vs Wazuh


## Config 
It must be run locally.
```
sudo apt update && sudo apt install lynis
```

```
sudo lynis audit system
```

Output should be generated in:
```
/var/log/lynis.log
```