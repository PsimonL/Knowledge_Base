# Penetration testing
An authorized simulated cyberattack on a computer system, performed to evaluate the security of the system. Also know colloquially as pentest.

## Characteristics:
- This is not to be confused with a vulnerability assessment. Penetration testing focuses on actively exploiting vulnerabilities to simulate real-world attacks. Basically it means that after gaining access to system, exploits can be used to:
    + privilige escalation
    + access to sensitive data
    + leave some backdors
    + perfotm any system disruption

    While vulnerability assessment periodically identifies and catalogs potential vulnerabilities without exploiting (using) them to perform futher actions.

    | Criterion   |      Penetration Testing      |  Vulnerability Assessment |
    |----------|:-------------:|------:|
    | Purpose |  Simulates real-world attacks | Identifies potential vulnerabilities |
    | Approach |    Manual and creative |   Automated and systematic   |
    | Scope | Narrow and detailed   |	Broad and general   |
    | Intervention | Active | Passive |
    | Report | Detailed explanation of exploited vulnerabilities | List of vulnerabilities with risk classification |
    | Frequency | Less frequent (e.g. annually)    | 	More frequent (e.g. monthly) |

- Performed to identify weaknesses, including the potential for unauthorized parties to gain access to the system's features and data.
- A penetration test can help identify a system's vulnerabilities to attack and estimate how vulnerable it is. 
> Security issues that the penetration test uncovers should be reported to the system owner!!!

## Types of Penetration Testing

### 1. Based on Access to Information
#### 1.1 Black Box Testing
- The tester has no prior knowledge of the system, infrastructure, or application.
- Simulates an external attack by a real-world adversary.
- Focuses on identifying vulnerabilities visible without insider knowledge.
#### 1.2 White Box Testing
- The tester has full access to documentation, source code, and system configurations.
- Simulates an insider or trusted entity's perspective.
- Allows for a detailed assessment of both internal and external vulnerabilities.
#### 1.3 Grey Box Testing
- Combination of Black Box and Whit Box Testing. The tester has partial knowledge of the system, such as limited user credentials or network diagrams.
- Simulates an attacker with some level of insider access.
- Strikes a balance between realism and efficiency.

### 2. Based on Purpose
There can be differentiate multiple types based on this criterium, but mains are:
- Web Application Penetration Testing - focuses on web apps to uncover issues like SQL Injection, Cross-Site Scripting (XSS), and authentication flaws, mainly OWASP stuff.
- Mobile Application Penetration Testing - iOS and Android to identify vulnerabilities in app logic, APIs, and data storage.
- Network Penetration Testing - internal and external networks to detect open ports, misconfigured devices, and vulnerable services.
- Operating System Application Penetration Testing - examines operating systems and looking for stuff like: e.g. outdated software, misconfigurations, and weak passwords.
- Physical Penetration Testing - Tests physical security measures, such as access to server rooms or hardware. Which is also very real and serious stuff.

### 3. Based on Methodology
- Manual - conducted by experts, with setup complex scenarios and focusing on and non-standard vulnerabilities.  
- Automatic - Utilizes automated tools like scanners for known vulnerabilities and weak points.
- Hybrid - combination of both.

### 4. Based on Attacker Perspective
 - External - an attack from an outside perspective.
 - Internal - an attack from within the organization.
 - Social Engineering - Focuses on human as main factor of security threats.Vulnerabilities, such as phishing, tailgating, or vishing (voice phishing).

## Related stuff:
- DAST folder - Contains stuff for Dynamic Application Security Testing (Black Box Web Apps Testing), covering this topics and tools like Burp Suite and Owasp Zap.

- SAST folder - Contains stuff for Static Application Security Testing (White Box Web Apps Testing), covering this topics and tools like Sonar Qube and Snyk.

- System Pentest folder - Contains stuff related to system, mainlys server and network penstesting and tools like Metasploit etc.