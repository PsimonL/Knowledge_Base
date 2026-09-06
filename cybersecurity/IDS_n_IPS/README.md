# IDS and IPS

- IDS (Intrusion Detection System):  
It refers to a set of tools and best practices for computer systems to detect malicious activities or security policy violations. It helps in identifying potential threats by monitoring traffic and notifying administrators about necessary actions through appropriate alerts. However, it does not take any actions to block malicious traffic. It operates completely passively in real-time mode.

- IPS (Intrusion Prevention System):  
This is a system designed to prevent intrusions in information systems. It is a direct extension of the IDS concept. It takes steps to block unwanted actions. It operates actively in real-time mode.

Both IDS and IPS can perform a technique called DPI (Deep Packet Inspection), which involves inspecting the entire data packet (not just the header but also its content) to identify potential threats.

There are several types of IDS/IPS systems, but the two most popular are:
- Network Detection / Prevention System
- Host-based Detection / Prevention System


### NIDS (Network Intrusion Detection System) and NIPS (Network Intrusion Prevention System)
1. NIDS 
2. NIPS 
3. Sample tools NIDS:
- Snort 
- Suricata (successor of Snort)
- Bro/Zeek
4. Sample tools NIPS:
- Suricata (when configuered in prevention mode)
- Cisco Firepower
- Palo Alto Networks NGFW

### HIDS (Host-based Intrusion Detection System) and HIPS (Host-based Intrusion Prevention System)
1. HIDS
2. HIPS
3. Sample tools HIDS:
- OSSEC
- Tripwire
- AIDE
- Wazuh (which is succesor and extension of OSSEC) - WORTH MENTIONIG: Wazuh is an advanced HIDS that combines file integrity monitoring, log analysis, and compliance checks with centralized management and integration with SIEM platforms for robust threat detection and response in distributed environments. 
4. Sample tools HIPS:
- McAfee Host ???
- Symantec ???

## IDS detection 
Main two methods:  
- Signature-based -> Monitors network and compares packet with pre-configured and pre-determined attack patterns which are stored in signature databased.   
Pros: Very good for known attacks and low number of false positives. Cons: Cannot detect 0-day attacks, or variation of already known attacks. It requiers frequent updates of signature database. Low number of false-positives.
- Anomaly-based -> System analysis historical data of network traffic with the purpose of creating normal profile -  which is called "baseline". Which describes healthy system state. Than system compares baseline with current state. If data deviates strongly from baseline, system marks it, as anomaly, as a potential threat. Anomalies are detected in several ways: ML models, data mining and statistics, grammar based methods or heuristic methods.  
Pros: Can detect unknown threats and attacks.   
Cons: High percentage of false positives, especially in dynamically changing network environment. Can be fooled by a correctly delivered attack. Requires time and experts in network-mathematical fields.


## IPS prevention methods
Depending on what exactly distribution is some IPS it have different functionalities in prevention steps, but most common ones are:
- Blocking Network Traffic - which includes blacklisting potentially mallicious IPs or closing firewall ports used in examplary connection.
- Terminatin Session - this can include dropping packets related to mallicious traffic by stop sending or receiving packets related to the session. For TCP connection it can send TCP Reset (RST) to one or both endpoints of the connection.
- Traffic Throttling - A sudden spike in the number of requests from a single IP address or range (a sign of DDoS or brute-force attacks). It can cope with this using: limiting the number of requests per IP per second, introducing delays by adding latency or finally reducing the amount of available bandwidth.
- Modifying Firewall Rules - IPS can automatically update or add firewall rules through: blocking specific IP addresses or ranges, blocking specific ports or even blocking traffic based on protocol or signature.




