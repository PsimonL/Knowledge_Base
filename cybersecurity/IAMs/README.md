# Identity and Access Management
IAM is a framework of policies and technologies to ensure that the right users (that are part of the ecosystem connected to or within an enterprise) have the appropriate access to technology resources.
Main functions of IAMs:
1. Identify users and devices (who/what they are).
2. Authenticate them (validate their identity).
3. Authorize their access to resources based on roles, policies, and permissions.

## Examples of technologies which implement IAM concepts
- Cloud Based Solutions:
    + AWS Identity and Access Management (AWS IAM)
    + Google Cloud IAM
    + Azure Active Directory (Azure AD)
- On-premises IAM Solutions (paid):
    + IBM Security Verify
    + Sail Point
    + CyberArk
- Open-source IAM Solutions:
    + Active Directory
    + FreeIPA (Linux equivalent of Active Directory) 
    + KeyCloak
    + Glue
    + WSO2 Identity Server
    + Apache Syncope

## Base Concepts and Technologies related to IAM issue
- Kerberos protocol -> authentication protocol designed to provide secure user and service authentication. It is used to prevent the transmission of passwords over the network. Kerberos relies on a centralized authentication service and uses a ticket-based system to validate users and grant access to network resources.  
Work Schema:
    + Initial Authentication: The user sends a request to the Authentication Server (AS) for a Ticket-Granting Ticket (TGT). If valid, AS returns the TGT.
    + Requesting Access to Services: The user sends the TGT to the Ticket-Granting Server (TGS) to request a service ticket. The TGS verifies the TGT and issues a service ticket, which later going to be used with service to authenticate access.
    + Access to service: The user then presents the service previously gained ticket. Service uses its own key to decrypt obtained service tikcet from the user and to get it's authenticity. Now service knows that user is legit and grants access.  

Base protocol for Active Directory. Passwords are not sent over network. Tickets are time-senstive (limited) to prevent replay attacks. Both the client and the service verify each other’s identity. It can be used as SSO (Single Sign On).
- RADIUS (Remote Authentication Dial-In User Service) / Free RADIUS -> is a networking protocol that provides centralized authentication, authorization, and accounting (AAA). Manages remote network access, especially to VPNs, Wi-Fi, or dial-up connections. RADIUS centralizes the authentication process, allowing network devices (e.g., routers, switches, wireless access points) to communicate with a RADIUS server to verify user credentials. 
Work Schema:
    + Authentication: User sends credentials to RADIUS client (e.g. router). The RADIUS client forwards these credentials to the RADIUS server for verification.
    + Authorization: The RADIUS server checks the credentials and determines the level of access the user has based on predefined policies (e.g., which network resources they can access).
    + Accounting (Optional): RADIUS can also track user activity, such as the duration of a connection or data usage, which is useful for billing or auditing purposes.

Mainly used in cases like: VPN, Wi-Fi (WPA2-Enterprise) access or networking infrastructure devices access.
- LDAP (Lightweight Directory Access Protocol) -> 