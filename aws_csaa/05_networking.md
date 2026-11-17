# Networking

## Route 53 & DNS

### DNS Basics

- Tree structure, read **right → left**: `.` (Root) → `.com` (TLD) → `example.com` (SLD) → `api.example.com` (subdomain).
- **FQDN** = full name ending with a dot.
- **Authoritative** NS = holds the original zone records. **Non-authoritative** = answers from cache.

| Level | Managed by | Returns |
|---|---|---|
| **Local DNS (Resolver)** | ISP / company network | Final IP, **cached for TTL** |
| **Root (.)** | ICANN | NS of the **TLD** server |
| **TLD (.com)** | IANA | NS of the **authoritative** server for the domain |
| **SLD (example.com)** | Registrar / **Route 53** | **A / AAAA** record |

### Route 53 Overview

- **100% availability SLA**: the **only** AWS service with it.
- **Authoritative DNS** (port 53 TCP/UDP) + **Domain Registrar** (register / renew domains).
- **Registrar** (e.g. GoDaddy) = owns the domain name. **DNS service** (Route 53) = stores records and answers queries.
- Route 53 only **returns an IP / name**, it does **not forward traffic** (not a load balancer).

**External registrar (GoDaddy) + Route 53**
1. Create a **Public Hosted Zone** (never Private).
2. Copy the **4 NS records** into the registrar panel (replace default NS).
3. **No domain transfer** needed. Registrar keeps billing, Route 53 handles all records.

### Hosted Zones

- Container for DNS records of a domain and its subdomains. **$0.50 / month** per zone (+ query charges).

| | Public Hosted Zone | Private Hosted Zone |
|---|---|---|
| **Scope** | Public internet | One or more **VPCs** |
| **Example** | `mypublicdomain.com` | `application1.company.internal` |
| **Targets** | Public EC2, ALB, S3, CloudFront | Private EC2, internal DBs / APIs |
| **Purpose** | Route internet users to apps | Internal communication over **private IPs** |

- Private zone requires VPC settings **`enableDnsHostnames`** and **`enableDnsSupport`**.

### Records & TTL

- Each record: **name, type, value, routing policy, TTL**. TTL is mandatory for all except **Alias**.
- **Must-know types:** **A** (IPv4), **AAAA** (IPv6), **CNAME** (name → name), **NS** (name servers).
- **Advanced:** MX (mail), TXT, SPF, SOA, PTR, SRV, CAA, DS.

| TTL | Effect |
|---|---|
| **High** (e.g. 24 h) | Fewer queries (**cheaper**), slow change propagation |
| **Low** (e.g. 60 s) | More queries (**$$**), fast switch during migration |

### CNAME vs Alias

| | CNAME | Alias |
|---|---|---|
| **Target** | Any hostname (also **outside AWS**) | **AWS resources only** (or record in same zone) |
| **Zone Apex** (`example.com`) | **NO**, only subdomains | **YES** |
| **Query cost** | Paid | **Free** |
| **Health check** | No native | **Native** |
| **TTL** | Manual | Managed by AWS |

- **Why no CNAME on Zone Apex?** DNS standard (RFC), not an AWS limit:
  - A name with CNAME can have **no other records**.
  - Apex must have **NS and SOA** (and often MX).
- Alias is always type **A / AAAA**, auto-tracks IP changes of the target.
- **Alias targets:** **ALB / NLB / CLB, CloudFront, API Gateway, Elastic Beanstalk, S3 static website, VPC Interface Endpoints, Global Accelerator**, another record in the same zone.
- **Alias to a single EC2 DNS name is NOT possible.**
- On-prem (no Alias): apex points to a fixed IP via **A record** or HTTP redirect to `www`.

### Routing Policies

| Policy | How it works | Health checks | Use case |
|---|---|---|---|
| **Simple** | 1 value or list of IPs (client picks randomly). With Alias only 1 resource | No | Single resource |
| **Weighted** | Traffic split by **weight / sum of weights**. Weight **0** = no traffic (all 0 = equal) | Yes | **A/B tests, canary** (e.g. 5%) |
| **Latency-based** | Region with **lowest latency** (region set per record) | Yes | Global apps, **best speed** |
| **Failover** | **Active-Passive**: Primary, switch to Secondary on failure | Yes (**required on Primary**) | **Disaster Recovery** |
| **Geolocation** | By user **location** (continent, country, US state). **Most specific** rule wins | Yes | Localization, **legal (GDPR)**, licensing. Add a **Default** record |
| **Geoproximity** | By location of users **and resources**. **Bias** (-99 to +99) shifts traffic | Yes | **Shift traffic between Regions** |
| **IP-based** | By client IP via **CIDR Collection** | Yes | Optimize for specific ISPs / costs |
| **Multi-Value Answer** | Up to **8 healthy** records per query | Yes | Simple DNS load balancing. **Not** a replacement for ELB |

### Health Checks

Used for **DNS Failover**. Three types:

1. **Endpoint** (public resources): global probes via **HTTP / HTTPS / TCP**, every 30 s (10 s for extra cost), default threshold **3**. Healthy = **2xx / 3xx** (+ optional string in first **5120 bytes**). Allow probe IPs (`ip-ranges.json`) in the **Security Group**.
2. **Calculated:** combines up to **255 child** checks with **AND / OR / NOT** (e.g. 2 of 3 healthy → avoids false alarms during maintenance).
3. **CloudWatch Alarm** (private resources): probes run on the internet and can't see private IPs, so: **CloudWatch metric → Alarm → Route 53 Health Check**.

### Hybrid DNS (Resolver Endpoints)

- Inside a VPC, **Route 53 Resolver** resolves names only within AWS (EC2, Private Hosted Zones, public domains).
- To connect with on-prem DNS (via **VPN / Direct Connect**) use endpoints.
- **Direction is always from the AWS side.**

| Endpoint | Direction | Flow |
|---|---|---|
| **Inbound** | **On-prem → AWS** | On-prem DNS forwards query (e.g. `app.aws.private`) over VPN / DX to the endpoint's **private IP** → Resolver checks the **Private Hosted Zone** → returns private IP |
| **Outbound** | **AWS → On-prem** | Resolver uses **Resolver Rules** to forward queries (e.g. `web.onpremise.private`) through the endpoint to **on-prem DNS servers** |

---