# Route 53 Module

This Terraform module creates and manages Route 53 resources for the koneksi.co.kr domain.

## Features

- Creates a Route 53 hosted zone
- Configures A records for root domain and www subdomain
- Sets up MX records for email routing
- Configures SPF and DKIM records for email authentication
- Supports CNAME records for subdomains
- Configurable TTL for all records

## Usage

```hcl
module "route53" {
  source = "./route53"

  domain_name = "koneksi.co.kr"
  ttl        = 300  # 5 minutes in seconds
  
  root_domain_records = ["1.2.3.4"]  # Replace with your actual IP addresses
  www_domain_records  = ["1.2.3.4"]  # Replace with your actual IP addresses
  
  mx_records = [
    "10 mail.koneksi.co.kr"  # Replace with your actual MX records
  ]
  
  spf_records = [
    "v=spf1 include:_spf.koneksi.co.kr ~all"  # Replace with your actual SPF record
  ]
  
  dkim_selector = "default"
  dkim_records  = [
    "v=DKIM1; k=rsa; p=YOUR_PUBLIC_KEY"  # Replace with your actual DKIM record
  ]

  # CNAME records for subdomains
  cname_records = {
    "api"    = "api.koneksi.co.kr"
    "blog"   = "blog.koneksi.co.kr"
    "mail"   = "mail.koneksi.co.kr"
  }
  
  tags = {
    Environment = "production"
    Project     = "koneksi"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| domain_name | The domain name for the Route 53 hosted zone | `string` | `"koneksi.co.kr"` | no |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |
| ttl | The TTL (Time To Live) for all DNS records in seconds | `number` | `300` | no |
| root_domain_records | List of IP addresses for the root domain A record | `list(string)` | `[]` | no |
| www_domain_records | List of IP addresses for the www subdomain A record | `list(string)` | `[]` | no |
| mx_records | List of MX records for email routing | `list(string)` | `[]` | no |
| spf_records | List of SPF records for email authentication | `list(string)` | `[]` | no |
| dkim_selector | DKIM selector for the domain | `string` | `"default"` | no |
| dkim_records | List of DKIM records for email authentication | `list(string)` | `[]` | no |
| cname_records | Map of CNAME records where key is the subdomain and value is the target | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| zone_id | The ID of the Route 53 hosted zone |
| name_servers | The name servers for the hosted zone |
| domain_name | The domain name of the hosted zone |

## Notes

- After applying this module, you'll need to update your domain registrar's name servers with the values from the `name_servers` output.
- Make sure to replace the example IP addresses and DNS records with your actual values.
- The TTL for all records is configurable through the `ttl` variable, defaulting to 300 seconds (5 minutes).
- Records are only created if their corresponding variable has values (empty lists/maps will not create records).
- For CNAME records, the key should be the subdomain name (e.g., "api" for api.koneksi.co.kr) and the value should be the target domain. 