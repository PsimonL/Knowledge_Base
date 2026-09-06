# General Cybersecurity Concepts

## CIA Triad
- Confidentiality - preserving authorized restrictions on information access and disclosure, including means for protecting personal privacy and proprietary information. It can be put into practice through:
encryption/decryption, access control (RBAC and leat privileg principle), authentication like MFA (Multi-Factor Authentication), data masking (tokenization) and network security.
- Integrity - guarding against improper information modification or destruction and ensuring information non-repudiation and authenticity. It can be implemented as: Checksums and Hashing, Digital Signature and also Access control. 
- Availability - ensuring timely and reliable access to and use of information. It guaranties that resources are available to authorized users whenever needed, without delays or interruptions. It can be implemented through: Redundancy during Failovers (backups), QoS networks, Load Balancing, DDoS Mitigation and backups.

https://www.nccoe.nist.gov/publication/1800-26/VolA/index.html

## STRIDE 
A model for identifying computer security threats developed by Microsoft:
- Spoofing (e.g. IP, DNS, ARP (MAC))
- Tampering
- Repudiation
- Information disclosure (privacy breach or data leak)
- Denial of service
- Elevation of privilege

## Principle of least privilege (PLP)
Concept which states that user or entity should only have enough priviliges to access specific data, resources
and apps to execute given task. 
It significantly reduces attack surface and risk of malware spread. 

https://www.paloaltonetworks.com/cyberpedia/what-is-the-principle-of-least-privilege
https://en.wikipedia.org/wiki/Principle_of_least_privilege

## Binary classification in Cybersecurity
Given a classification of a specific data set, there are four basic combinations of actual data category and assigned category: true positives TP (correct positive assignments), true negatives TN (correct negative assignments), false positives FP (incorrect positive assignments), and false negatives FN (incorrect negative assignments).

|               | **Test outcome positive**      | **Test outcome negative**      |
| ------------- | ----------------- | ----------------- |
| **Condition positive**| True Positive (TP) | False Negative (FN)|
| **Condition negative**     | False Positive (FP)| True Negative (TN) |


Example based on Threat identification, let's for IDS/IPS.
|               | **Detection Triggered**      | **Behavior Present**      |
| ------------- | ----------------- | ----------------- |
| **True Positive (TP)**    | Yes | Yes|
| **False Positive (FP)**     | Yes | No |
| **False Negative (FN)**    | No | Yes |
| **True Negative (TN)**     | No | No |


It can be analogically applied for instance to vulnerability scanning.

## OWASP TOP 10
For year 2021:
1. A01:2021 - Broken Access Control
2. A02:2021 - Cryptographic Failures
3. A03:2021 - Injection
4. A04:2021 - Insecure Design
5. A05:2021 - Security Misconfiguration
6. A06:2021 - Vulnerable and Outdated Components
7. A07:2021 - Identification and Authentication Failures
8. A08:2021 - Software and Data Integrity Failures
9. A09:2021 - Security Logging and Monitoring Failures 
10. A10:2021 - Server-Side Request Forgery 

For year 2017:
1. A01:2017 - Injection
2. A02:2017 - Broken Authentification
3. A03:2017 - Sensitive Data Exposure
4. A04:2017 - XML External Entities (XXE)
5. A05:2017 - Broken Access Control
6. A06:2017 - Security Misconfiguration
7. A07:2017 - Cross-Site Scripting (XSS)
8. A08:2017 - Insecure Deserialization
9. A09:2017 - Using Components with Known Vulnerabilities
10. A10:2017 - Insufficient Logging & Monitoring

https://owasp.org/www-project-top-ten/

Selected attacks description:  
- SQL Injection
Atakujący identyfikuje formularz, URL lub inny punkt wejścia, który wprowadza dane użytkownika do zapytania SQL w sposób, który nie jest odpowiednio walidowany lub oczyszczany.
```
SELECT * FROM users WHERE username = 'admin' AND password = 'hasło';
```
```
SELECT * FROM users WHERE username = 'admin' AND password = '' OR '1'='1';
```
Zabezpieczenia przed SQLi:  
Używanie przygotowanych zapytań (Prepared Statements): Zamiast dynamicznego tworzenia zapytań SQL.  

Walidacja i oczyszczanie danych wejściowych:   
Upewnienie się, że dane wejściowe użytkownika są bezpieczne.

Używanie ORM (Object-Relational Mapping): 
Pomaga unikać ręcznego tworzenia zapytań SQL.

Minimalne uprawnienia:  
Konta baz danych powinny mieć ograniczone uprawnienia.

- DDoS
Przygotowanie botnetu:

Atakujący infekuje wiele komputerów lub urządzeń (zwykle przez złośliwe oprogramowanie), tworząc botnet. Te urządzenia stają się "zombie" i mogą być kontrolowane przez atakującego.
Wysyłanie dużej ilości ruchu:

Atakujący wykorzystuje botnet do wysyłania ogromnej ilości żądań do celu (serwera, aplikacji, sieci). W wyniku tego celu nie jest w stanie obsłużyć tak dużej liczby żądań.
Przeciążenie zasobów:

Celem ataku jest przeciążenie zasobów (np. serwera, łącza internetowego lub aplikacji), aby uniemożliwić dostęp do usługi.

Zabezpieczenia przed DDoS:
Firewall i WAF (Web Application Firewall): Używanie zapór ogniowych i zapór aplikacji webowych w celu filtrowania niepożądanych żądań.
Load balancing i rozproszenie zasobów: Rozpraszanie ruchu przez wiele serwerów, aby zwiększyć odporność na atak.

- XSS 
Attacker wprowadza kod (skrypt JS) kótry jest zaciągany przez serwer
I serwer serwuje strone użytkownikom z zainfekowanym kodem. Co moze prowadzić do:
Kradzież danych użytkowników, w tym haseł czy danych sesyjnych.
Zmiana zawartości strony internetowej.
Zainfekowanie komputerów użytkowników złośliwym oprogramowaniem (np. poprzez redirekcję do złośliwego linku).

Obrona:
Walidacja i oczyszczanie danych wejściowych: Wszystkie dane użytkownika powinny być walidowane i oczyszczane przed wyświetleniem na stronie.

Używanie nagłówków CSP (Content Security Policy): Umożliwia zdefiniowanie, skąd mogą pochodzić skrypty na stronie.

Escape'owanie danych w HTML, JavaScript: Zapewnienie, że dane użytkownika są traktowane jako dane, a nie jako kod do wykonania.

## Most common attacks
- Phising
- Man-in-the-Middle
- DDoS
- Spoofing
- OWASP TOP 10 vulnerabilities
- Malware (Viruses, Worms, Trojans, Ransomware, Spyware, Adware, RootKit, Botnets, Keyloggers)
- RootKit

## DNS Security TODO
https://www.cloudflare.com/pl-pl/learning/email-security/dmarc-dkim-spf/

## Types of Penetration Testing methodologies:
- Network Pen Testing 
- Web Application Pen Testing
- Physical Pen Testing
- Wireless Pen Testing
- Mobile Pen Testing
- Social Engineering Pen Testing

![HTB_Pen_Testings](/xyz_resources_n_images/HackTheBoxPentests.jpg)
https://www.hackthebox.com/blog/an-aspiring-hackers-web-application-penetration-testing-guide-for-2024

## Glosary
- a exploit
- a vulnerability
- to mitigate security risk
- an authentication
- to authorize
- a payload
- an enumeration