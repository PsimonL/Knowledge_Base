# Firewalls

## What it actually is?
> A firewall is more of a concept than a specific tool. 

It is a general term for a system or mechanism that controls the flow of network traffic between different segments of a network based on a set of security rules. How a firewall operates and what it includes depends on its implementation and purpose.

Sample definition with basic types of firewall:
![Firewall_basic_types](/xyz_resources_n_images/Firewall_basic_types.jpg)
https://www.redswitches.com/?s=A+Comprehensive+Guide+To+Different+Types+Of+Firewalls

## Diving deeper
With more insight, clearly can assume that there is a lot more to that:
![Firewall_basic_types](https://www.paloaltonetworks.com/content/dam/pan/en_US/images/cyberpedia/types-of-firewalls/types-of-firewalls.png?imwidth=1920)

https://www.paloaltonetworks.com/cyberpedia/types-of-firewalls  

https://nordlayer.com/learn/firewall/types-of-firewalls/


## Firewall division on the basis of 4 criteria:
According to Palo Alto link and Nord Layer...  

### Firewall Types and Classifications

Firewalls can be categorized based on different criteria, as outlined below:


### 1. **By Data Filtering Method**

#### **1.1 Proxy Firewall**
- **Operation:**
  - Acts as an intermediary between the client and the server, isolating them from direct communication.
  - Operates primarily at the **application layer (Layer 7)**.
- **Capabilities:**
  - Inspects data payloads for specific applications, such as HTTP, FTP, or SMTP.
  - Offers deep inspection of application-specific traffic, e.g., blocking access to certain URLs.
  - Can provide anonymity for clients by masking their IP addresses.
- **Strengths:**
  - High level of application-specific filtering.
  - Protects against application-layer attacks by thoroughly inspecting requests and responses.
- **Weaknesses:**
  - Increased latency due to data processing at the application layer.
  - Limited to supported application protocols.
- **Examples:** Squid, Blue Coat ProxySG, HAProxy.
- **Comparison with WAF:**
  - Proxy Firewall is more general-purpose and can work across various protocols, while **WAF** specializes solely in HTTP/HTTPS traffic.

#### **1.2 Web Application Firewall (WAF)**
- **Operation:**
  - Specializes in protecting **web applications** and operates primarily on **Layer 7 (application layer)**.
  - Focuses exclusively on HTTP/HTTPS traffic.
- **Capabilities:**
  - Detects and mitigates application-specific threats, particularly those listed in **OWASP Top 10**, such as:
    - SQL Injection.
    - Cross-Site Scripting (XSS).
    - Cross-Site Request Forgery (CSRF).
  - Provides granular filtering of HTTP requests, including URL parameters and headers.
- **Strengths:**
  - Excellent at defending against attacks targeting web application vulnerabilities.
  - Often integrates with machine learning to adapt to emerging threats.
- **Weaknesses:**
  - Not suitable for non-web application traffic (e.g., FTP or SMTP).
  - Requires detailed configuration for custom applications.
- **Examples:** AWS WAF, Cloudflare WAF, Imperva.
- **Comparison with Proxy Firewall:**
  - WAF is highly specialized for **web applications**, whereas Proxy Firewall has a broader scope, including email or file transfer protocols.

#### **1.3 Stateful Inspection Firewall**
- **Operation:**
  - Maintains a **state table** to track active connections.
  - Operates at **Layers 3 (Network)**, **4 (Transport)**, and partially **5 (Session)**.
  - Tracks the state of network sessions (e.g., TCP three-way handshake) and allows packets only if they belong to a known session.
- **Capabilities:**
  - Protects against unauthorized connections by verifying session states.
  - Can block non-legitimate packets even if they match the basic rules (e.g., source IP and port).
- **Strengths:**
  - Offers more security than stateless firewalls by considering connection context.
  - Effective for basic session-based threat prevention.
- **Weaknesses:**
  - Limited visibility into application-level attacks.
  - Can be resource-intensive on high-traffic networks.
- **Examples:** Cisco ASA, pfSense, Juniper SRX.
- **Comparison with Packet Filtering Firewall:**
  - **Packet Filtering Firewall** analyzes packets in isolation, while **Stateful Inspection Firewall** considers the session context.

#### **1.4 Circuit-Level Gateway**
- **Operation:**
  - Works at the **session layer (Layer 5)**.
  - Verifies the legitimacy of session handshakes (e.g., TCP or UDP) before allowing data transfer.
- **Capabilities:**
  - Ensures that connections follow legitimate protocols for session initiation.
  - Performs minimal content inspection, focusing instead on connection-level validation.
- **Strengths:**
  - Lightweight and efficient.
  - Provides security for session establishment without deeply inspecting data.
- **Weaknesses:**
  - Cannot protect against application-layer attacks.
  - Limited to validating session handshakes.
- **Examples:** SOCKS Proxy, Circuit-level modules in some NGFWs.
- **Comparison with Stateful Inspection Firewall:**
  - **Circuit-Level Gateways** focus only on establishing legitimate sessions, while **Stateful Firewalls** continuously track and validate session states.

#### **1.5 Packet Filtering Firewall**
- **Operation:**
  - Operates at **Layer 3 (Network)** and **Layer 4 (Transport)**.
  - Examines individual packet headers to decide whether to allow or block based on predefined rules.
- **Capabilities:**
  - Inspects fields such as:
    - Source and destination IP addresses.
    - Source and destination ports.
    - Protocol types (e.g., TCP, UDP, ICMP).
  - Enforces basic access control rules.
- **Strengths:**
  - Simple and fast, with minimal impact on performance.
  - Effective for basic perimeter security.
- **Weaknesses:**
  - Stateless: Does not track connection states, making it vulnerable to spoofing and other session-based attacks.
  - Cannot analyze payload data or application-layer traffic.
- **Examples:** iptables, Cisco IOS ACL.
- **Comparison with Stateful Firewall:**
  - Packet Filtering Firewall analyzes packets statically, while Stateful Firewall adds context by tracking session states.

#### **1.6 Next-Generation Firewall (NGFW)**
- **Operation:**
  - Extends traditional firewalls with advanced features and application awareness.
  - Operates at **Layers 3–7** for comprehensive traffic analysis.
- **Capabilities:**
  - Combines features like:
    - **Deep Packet Inspection (DPI):** Inspects payloads for application-specific content.
    - **Intrusion Prevention Systems (IPS):** Detects and blocks known threats.
    - Integration with threat intelligence feeds for real-time updates.
  - Identifies and controls traffic based on applications, not just ports or protocols.
- **Strengths:**
  - Comprehensive protection, combining firewalling, IPS, and application-layer control.
  - Capable of thwarting both network and application-level attacks.
- **Weaknesses:**
  - Requires more processing power, increasing latency in high-traffic environments.
  - Higher cost and complexity compared to traditional firewalls.
- **Examples:** Palo Alto Networks, Fortinet FortiGate, Check Point.
- **Comparison with Stateful Firewall:**
  - NGFW includes **stateful inspection** but adds application-awareness and advanced threat prevention.

### **Note: Hybrid Solutions**
Many firewalls combine the features of different types for more robust security. For example:
- Proxy firewalls may include stateful inspection for enhanced session tracking.
- NGFWs often integrate features of WAFs and traditional stateful firewalls.

---

#### 2. **By Form Factors**
**2.1 Hardware Firewalls**
- Dedicated physical appliances.
- High performance and reliability.
- Often used in enterprise environments.
- Example: Cisco ASA, Fortinet FortiGate.

**2.2 Software Firewalls**
- Installed on general-purpose hardware or virtual machines.
- Flexible and cost-effective.
- Example: iptables (Linux), Windows Defender Firewall.

#### 3. **By Network Placement**
**3.1 Perimeter Firewalls**
- Positioned at the network boundary.
- Protects internal networks from external threats.
- Example: Cisco ASA, pfSense.

**3.2 Internal Firewalls**
- Deployed within the network.
- Segments traffic and protects internal resources.
- Example: VLAN firewalls, host-based firewalls.

**3.3 Distributed Firewalls**
- Decentralized deployment.
- Protects resources at multiple network locations.
- Example: Cloud-based firewalls (e.g., AWS Security Groups).

#### 4. **By Systems Protected**
**4.1 Network Firewalls**
- Secures the entire network or its segments.
- Operates at Layers 3–7.
- Example: NGFWs, iptables.

**4.2 Host-Based Firewalls**
- Installed on individual devices (e.g., servers, PCs).
- Provides granular protection for a single host.
- Example: Windows Defender Firewall, ufw (Linux).


Described classification gives a structured understanding of firewall types based on: functionality, deployment, and the systems they protect.


## Worth mentioning twice
A firewall is not a single tool but often forms the foundation of a broader security strategy. It can work standalone or alongside other systems like IDS/IPS, antivirus solutions, or SIEM platforms. It can be software and hardware implementation.





WAF:  
Analizuje dane wejściowe, takie jak nagłówki, URL, parametry zapytań, dane formularzy, aby wykryć podejrzane wzorce.


Analiza ruchu:

WAF monitoruje każdy przychodzący i wychodzący ruch HTTP/S.
Analizuje dane wejściowe, takie jak nagłówki, URL, parametry zapytań, dane formularzy, aby wykryć podejrzane wzorce.

Wykrywanie i blokowanie ataków:

WAF porównuje przychodzące żądania do bazy reguł, które mogą identyfikować znane ataki, np. SQLi, XSS, CSRF.
Jeśli ruch jest uznany za złośliwy (np. zawiera kod SQL w formularzu), WAF blokuje to żądanie, zapobiegając jego przetworzeniu przez aplikację.

Podstawowe techniki WAF:

Filtrowanie bazujące na sygnaturach: Wykrywanie znanych wzorców ataków (np. ciągi znaków używane w SQL Injection).
Filtrowanie na podstawie heurystyki: Analiza niestandardowych lub nietypowych wzorców ruchu, które mogą wskazywać na atak.
Biała lista (whitelisting): Dopasowanie do zaufanych źródeł, blokowanie wszystkiego, co pochodzi z niezaufanych adresów IP.
Ochrona przed botami: Wykrywanie i blokowanie ruchu pochodzącego od botów, które mogą wykonywać ataki, np. brute-force.

Reakcja na wykryty atak:

WAF może zastosować różne reakcje w zależności od konfiguracji:

Zablokowanie – blokuje niepożądane żądanie.
Przekierowanie – np. na stronę ostrzeżenia.
Logowanie – zapisuje dane o próbie ataku do logów w celu późniejszej analizy.
