# SAST (Static Application Security Testing) White Box Testing - White Box


## What is SAST?
- SAST is a method of analyzing an application’s source code to identify vulnerabilitie - it does not execute application (static analysis).
- Conducted “from the inside,” focusing on code or its representation (e.g., bytecode).
- Part of SDLC (Secure Developemnt Life Cycle).

## Characteristics of SAST
1. Feeding SAST tool with source code, bytecode, binary or executable, mostly by integrating with CI/CD pipeline context. Than performs a static analysis, meaning they analyze the code structure without running the application
    + The earlier a vulnerability is fixed in the SDLC, the cheaper it is to fix. Costs to fix in development are 10 times lower than in testing, and 100 times lower than in production.
    + Scanning many lines of code with SAST tools may result in hundreds or thousands of vulnerability warnings for a single application. It can generate many false-positives, increasing investigation time and reducing trust in such tools.
2. SAST tools perform a static analysis, meaning they analyze the code structure without running the application.  
    I. Parsing the Code, breaking code down into Abstract Syntax Tree (AST).  
    II. Control Flow Analysis, logical flow of data in code, input to output.  
    III. Data Flow Analysis, Tracks how data is processed and moved within the code to detect vulnerabilities (e.g. SQL Injection, XSS).  
    IV. Pattern Matching and Rules, use predefined patterns for identifying known vulnerabilities  (e.g. weak crypto or hardcoded secrets).   
    V. Semantic Analysis, "Analyzes the logic of the code to detect deeper issues, such as insecure design patterns or unsafe practices (e.g., recursion leading to DoS)."
3. Detection of Vulnerabilities, found issues are being compared with known vulnerabilities database and with security rules. Than it maps exact types of vulnerabilities into real code. Assesses risk and creates tier list from the least sever one to the most.  
4. Reporting, producing report with summary in readable format for humans.

## Working modes
Mostly automatic mode. Becuase static way is just by some Cybersecurity Expert in Development who can find exploits manually.

## Tools which can be used in SAST methodology
- SonarQube
- Snyk

## Other related methodologies
There is also DAST (Dynamic Application Security Testint) and IAST (Interactive Application Security Testing) which is combination of SAST and DAST.