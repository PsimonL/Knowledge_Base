# DAST (Dynamic Application Security Testing) - Black Box We App Testing


## What is DAST?
- DAST is a method of testing an application’s security in its running environment (runtime).
- It **does not require** access to the application’s source code.
- It analyzes the application “from the outside,” mimicking the perspective of a user or attacker.

## Characteristics of DAST
1. Tests the application by sending real requests (e.g., HTTP) and analyzing the responses.
2. Simulates attacks such as SQL Injection, XSS, CSRF, and Directory Traversal - it can take point of view of user / attacker perspective, from to external interface side.
3. Detects vulnerabilities by actually performing attacks - by sending requests and analyzing responses.
4. Scanning with a DAST tool, data may be overwritten or malicious payloads injected into the subject site. Scans probably  should't be performed in a production-like but non-production environment.
5. It cannot cover 100% of the source code

## Working modes
Most of the most popular tools can work in **manual** as well as **automated mode**.

## Tools which can be used in DAST methodology
1. Burp Suite
2. OWASP ZAP
3. Nmap 
4. Netcat 

## Other related methodologies
There is also SAST (Static Application Security Testint) and IAST (Interactive Application Security Testing) which is combination of DAST and SAST.