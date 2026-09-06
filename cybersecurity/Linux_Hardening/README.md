# Linux OS Hardening  
It is the process of strengthening the Linux operating system to improve its resilience against attacks and reduce vulnerabilitie surface.
The goal is to protect the system from unauthorized access, malware, and other security threats.

---
Key Steps in the Hardening Process - to reduce attack surface:
- Software updates -> Keeping system and apps up to date.
- Minimization -> Remove unnecessary services, applications, and user accounts.
- User and Access Management -> Enforcing strong password policies, limit access rights, and monitor user activity
- Configuring a Firewall -> Only used should be open and only authorised connections.
- Kernel and Application Security -> SELinux, AppArmor, and Kernel Hardening.
- Filesystem Configuration ->
- Logging and Monitoring -> journalctl, syslog, SIEM (Wazuh, Splunk, or ELK Stack (Elasticsearch, Logstash, Kibana))