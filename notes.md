# Terraform

## Index

1. [Why terraform exists?](#1-why-terraform-exists)
2. [Terraform & Infrastructure as Code](#2-terraform--infrastructure-as-code)
3. [Terraform Providers](#3-terraform-providers)
4. [Terraform Resources](#4-terraform-resources)
5. [The Terraform Workflow](#5-the-terraform-workflow)
6. [Declarative Infrastructure](#6-declarative-infrastructure)
7. [Referencing Resources](#7-referencing-resources)
8. [Terraform Directory structure, Files & State](#8-terraform-directory-structure-files--state)
9. [AWS Syntax](#9-aws-syntax)
10. [Boot strapping](#10-boot-strapping)
11. [Outputs & State Inspection](#11-outputs--state-inspection)
12. [Targeting Resources](#12-targeting-resources)
13. [Terraform Variables](#13-terraform-variables)
14. [Useful Commands & Quick Reference](#14-useful-commands--quick-reference)

<details>
  <summary><strong>Resources</strong></summary>

1. [Terraform Course freeCodeCamp](https://youtu.be/SLB_c_ayRMo)
2. [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
3. [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

</details>

<details>
  <summary><strong>Notes</strong></summary>

1. First finish, the basic [tutorial](https://youtu.be/SLB_c_ayRMo)
2. Use [docs](https://developer.hashicorp.com/terraform/docs) when needed, or just enter "terraform" in the cli, suggestions will appear.Don't need to remember everything :)
3. **Terraform** uses declarative language. Just describe the infrastructure, and Terraform determines how to create or change it.

</details>

---

## 1. Why terraform exists

Terraform is an IaC tool. Before it infrastructures were usually created by hand through a cloud console (often called **ClickOps**), or through custom scripts calling cloud APIs directly. The problems were:

- Hard to reproduce: recreating the same environment meant manually repeating dozens of clicks.

- Slow and error-prone: provisioning complex, multi-resource infrastructure by hand doesn't scale to teams or large systems.

**Infrastructure as Code (IaC)** solves this by transforming the infrastructure in code that can be:

- **Versioned**: stored in Git, reviewed via pull requests, rolled back if needed.
- **Repeatable**: the same configuration can spin up identical environments on demand.
- **Automatable**: infrastructure changes can run in CI/CD pipelines instead of manual steps.

Terraform specifically stands out because it's **cloud-agnostic** (via providers) and **declarative** ( describe the desired end state). It also maintains **state**, so it always knows the difference between target and current state. It always calculates the minimal set of changes to reconcile this two.

---

## 2. Terraform & Infrastructure as Code

Terraform lets you describe infrastructure using code instead of manually creating every resource through a cloud console (clickops).


Terraform is primarily **declarative**.

Instead of:

```text
1. Create a VPC.
2. Create a subnet.
3. Create a route table.
4. Attach the route table.
5. Create an EC2 instance.
```

we do:

```bash
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}
```

Terraform automatically builds a dependency graph and determines an appropriate order of operations.

---

## 3. Terraform Providers

A provider is a plugin that translates Terraform configuration into API calls.

### AWS Provider

Provider configuration:

```bash
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
provider "aws" {
  region     = "region"
  profile    = "aws-profile"
}
```

### Credentials

Don't hard-code credentials:

```bash
provider "aws" {
  access_key = "..."
  secret_key = "..."
}
```

Prefer an AWS CLI profile, environment variables, or another supported credential mechanism.

Using AWS CLI profile:

```bash
aws configure --profile <name>
```

then:

```bash
provider "aws" {
  region  = "us-east-1"
  profile = "<name>"
}
```

---

## 4. Terraform Resources

A resource block represents an object Terraform manages.

### Basic Syntax

```bash
resource "<RESOURCE_TYPE>" "<LOCAL_NAME>" {
  # arguments
}
```

Example:

EC2 instance:
```bash
resource "aws_instance" "web" {
  ami           = "ami_id"
  instance_type = "t2.micro"

  tags = {
    Name = "web_server"
  }
}
```
VPC & subnet:
```bash
resource "aws_vpc" "demo_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "production"
  }
}

resource "aws_subnet" "demo_subnet" {
  vpc_id     = aws_vpc.demo_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "prod-subnet"
  }
}
```

### Address

The local Terraform address:

```bash
<type>.<local-name>
```

Example:

```text
aws_instance.web
aws_vpc.demo_vpc
aws_subnet.demo_subnet
```

### Tags

AWS resources commonly use tags:

```bash
tags = {
  Name        = "web-server"
  Environment = "dev"
  Project     = "terraform-demo"
}
```

### Extra blocks

Data block:

```bash
data "aws_security_group" "launch_wizard_1" {
  name = "launch-wizard-1"
  vpc_id = "vpc-0ac5d6eb0f165b7fd"
}
```

depends on block:

If a resource needs to wait for another resource, use:

```bash
depends_on = [
  aws_internet_gateway.main
]
```

The value must be a list.

---

## 5. The Terraform Workflow

### Workflow

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
terraform destroy
```

### 1. Initialize

```bash
terraform init
# prepares the working directory
```

- Install provider plugins.
- Initialize the backend.
- Download required modules.
- creates the `.terraform` directory,`terraform.lock.hcl` file.


### 2. Format

```bash
terraform fmt
# formats code's style and readability,
# fixes alignment

terraform fmt -recursive
# format all Terraform files,
# in the current directory
```

### 3. Validate

```bash
terraform validate
# checks if config is valid
```
- Syntax: Verifies code uses valid HashiCorp Configuration Language (HCL).
- Structure: Ensures resource blocks, modules, variables, and outputs are structured correctly.
- Consistency: Confirms that attribute names and value types match expected schemas without connecting to real cloud providers

### 4. Plan

```bash
terraform plan
# previews the changes Terraform wants to make
```

Common plan symbols:

```text
create "+" ; color: green
destroy "-" ; color: red
update "~" ; color: yellow
-/+ replace(destroy, create) ; color: red, green
```

### 5. Apply

```bash
terraform apply
# shows proposed changes, requires confirmation

terraform apply -auto-approve
# for automation
```

### 6. Destroy

```bash
terraform destroy
# removes tf managed resources

terraform destroy -target="aws_instance.web"
# removes targeted tf managed resources
```

---

## 6. Declarative Infrastructure

Terraform continuously compares between: <br>`Desired-state`, `Known-state` and `Actual-state`

For example:

### Scenario 1: No change

```bash
resource "aws_instance" "web" {
  ami           = "ami-xxx"
  instance_type = "t2.micro"
}
```

Running "terraform apply", creates the instance. But Running it again without any change, produces no changes.

Terraform first refreshes it's known state with actual-state, then compares it with desires-state. In this case the desired and known state would be the same so there will be no change made.

### Scenario 2: Changing a Resource

```bash
instance_type = "t2.micro" >> "t3.micro"
```
Running "terraform apply", destroys the previous instance and makes a new one with instance_type "t3.micro". 

In this case terraform sees the desired-state is different than known-state and it makes the changes necessary.

### Scenario 3: Removing a Resource from Config

If a resource is removed from the configuration. 

Running "terraform apply", destroys the corresponding resource.


---

## 7. Referencing Resources

Terraform resources can reference other resources. With this syntax: 

```bash
<resource_type>.<resource_name>.id
```

### Example

```bash
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}
```

The subnet references the vpc as:

```bash
aws_vpc.main.id 
```


Note that resource order usually doesn't matter, because terraform is declarative. So, it would be the same:


```bash
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}
```

Terraform sees the reference and constructs the dependency graph.

---

## 8. Terraform Directory structure, files & state

Terraform automatically loads all `.tf` files in the current working directory.

Common organization:

```bash
main.tf        # resources / primary configs
variables.tf   # input variables
terraform.tfvars # variable values
outputs.tf     # outputs
providers.tf   # providers and required providers
terraform.tf   # Terraform settings
```
---
### Terraform files:

### .terraform folder

Created by initialization: "terraform init"

In this directory Terraform stores cached provider plugins, downloaded modules, and diagnostic data

> *It should generally not be committed to Git.*

### .terraform.lock.hcl

Official dependency lock file generated automatically by Terraform during initialization to track and freeze the exact versions and cryptographic checksums of third-party providers.

> *It should generally be committed to Git.*

### terraform.tfstate

Acts as Terraform's memory. It keeps track of everything Terraform built in the cloud. It is the official representator of known-state.

> *It should generally not be commited to Git.*

### State in Teams

For collaborative environments, local state is usually not sufficient.

Use a supported remote backend with appropriate:

- Access control
- Encryption
- Locking/concurrency protection
- Backup/recovery strategy

Examples: Amazon s3 + locking, HCP terraform

---

### .gitignore

A typical project should ignore local Terraform artifacts:

```gitignore
.terraform/
*.tfstate
*.tfstate.*
```

Be careful with `*.tfvars`: variable files may or may not contain sensitive values

---

## 9. AWS syntax

Basic AWS web-server topology:

```text
Internet -> IGW -> Route table -> Public subnet -> Network interface -> Instance
```

Check more [Aws-Networking-Fundamentals](https://github.com/mohammad-ismail-hossen/Learned/blob/main/Aws-networking-fundamentals.md)

---

### VPC

A VPC is an isolated virtual network in AWS.

Example:

```bash
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}
```
---

### Subnet

A subnet divides the VPC address space:

```bash
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "public-subnet"
  }
}
```
---

### Internet Gateway

```bash
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}
```
---

### Route Table

A default IPv4 route is commonly:

```text
0.0.0.0/0 → Internet Gateway
```

Example:

```bash
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public-route-table"
  }
}
```

---

### Associate Subnet with Route Table

```bash
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
```

---


### Security Group

Security groups control traffic allowed to/from AWS resources.

For a simple web server, typical inbound ports are:

```text
22  → SSH
80  → HTTP
443 → HTTPS
```

Example:

```bash
resource "aws_security_group" "web" {
  name   = "allow-web"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["<your_ip>/32"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTPS IPv4"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTPS IPv6"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

---

### Network Interface

A network interface in aws (ENI) provides network connectivity for AWS resources such as EC2 instances.

It is associated with: a subnet, private ip, one or more security groups.

Create a network interface:

```bash
resource "aws_network_interface" "web" {
  subnet_id = aws_subnet.public.id
  private_ips = ["10.0.1.10"]

  security_groups = [
    aws_security_group.web.id
  ]

  tags = {
    Name = "web-eni"
  }
}
```

Attach the network interface to an EC2 instance:

```bash
resource "aws_instance" "web" {
  ami           = "ami-xxxxxxxx"
  instance_type = "t3.micro"

  network_interface {
    network_interface_id = aws_network_interface.web.id
    device_index         = 0
  }
}
```

Relationship:
```
EC2 Instance
     │
     ▼
Network Interface (ENI)
     │
     ├── Subnet
     ├── Private IP
     └── Security Groups
```

---

## 10. Boot strapping

### User Data

User data script, or boot strapping can run commands during initial instance setup.

Example:

```bash
resource "aws_instance" "web" {
  ami           = "ami-xxxxxxxxxxxxxxxxx"
  instance_type = "t2.micro"

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y apache2
              systemctl enable apache2
              systemctl start apache2
              echo "Hello" > /var/www/html/index.html
              EOF

  tags = {
    Name = "terraform-web-server"
  }
}
```

### What User Data Does

At first boot, the EC2 instance run these commands.

With boot strapping we can:

- Update packages
- Install software
- Start services
- Write configuration files
- Prepare the server for use



---

## 11. Outputs & State Inspection

### List Resources in State

```bash
terraform state list
# lists currently created resources by tf
```

Example output:

```text
aws_vpc.main
aws_subnet.public
aws_route_table.public
aws_security_group.web
aws_instance.web
```

### Inspect a Resource

```bash
terraform state show aws_instance.web
```

This will show information about the resource, stored in state.

### Outputs

Instead of manually inspecting state for values, we can define outputs.

```bash
output "server_public_ip" {
  value = aws_instance.web.public_ip
}
```

Then:

```bash
terraform output
```

Or:

```bash
terraform output server_public_ip
```

### Sensitive Outputs

For sensitive values:

```bash
output "example_secret" {
  value     = var.example_secret
  sensitive = true
}
```

Marking an output sensitive helps prevent accidental display in normal CLI output. Treat state as sensitive.

### Refreshing State

```bash
terraform refresh
# it refreshes the terraform.tfstate
```
It is deprecated. Modern Terraform workflows generally prefer:

```bash
terraform plan -refresh-only
```

or, when appropriate:

```bash
terraform apply -refresh-only
```

---

## 12. Targeting Resources

Terraform supports resource targeting with `-target`.

Example:

```bash
terraform apply -target=aws_instance.web
```

or:

```bash
terraform destroy -target=aws_instance.web
```

---

## 13. Terraform Variables

Variables make Terraform configurations reusable. It will ask for input for that variable.

### Basic Variable

```bash
variable "subnet_prefix" {
  description = "CIDR block for the subnet"
  type        = string
}
```

Use it:

```bash
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.subnet_prefix  
  # var.<resource_name>
}
```

### Default Value

```bash
variable "subnet_prefix" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}
```

If no other value is provided, Terraform uses the default.

### terraform.tfvars

Terraform automatically loads values from:

```text
terraform.tfvars
```

Example: Inside "terraform.tfvars" file,

```bash
subnet_prefix = "10.0.200.0/24"
```

Now terraform will use this value for subnet_prefix variable.

### Custom Variable File

```text
dev.tfvars
```

Apply it:

```bash
terraform apply -var-file="dev.tfvars"
```

### Variable Precedence

Terraform can receive variable values from multiple places. When designing a project, make the source of each value clear and avoid accidentally overriding important settings.

### Type Constraints

String:

```bash
variable "region" {
  type = string
}

# e.g. input: us-east-1
```

Number:

```bash
variable "instance_count" {
  type = number
}

# e.g. input: 4
```

Boolean:

```bash
variable "enable_monitoring" {
  type = bool
}

# e.g. input: true
```

List:

```bash
variable "availability_zones" {
  type = list(string)
}

# e.g. input: ["us-east-1a", "us-east-1b", "us-east-1c"]
```

Map:

```bash
variable "tags" {
  type = map(string)
}

# e.g. input:
# {
#   Environment = "production"
#   Project     = "my-app"
#   Owner       = "dev"
# }
```

Object:

```bash
variable "server" {
  type = object({
    name          = string
    instance_type = string
  })
}

# e.g. input:
# {
#   name          = "web-server"
#   instance_type = "t3.micro"
# }
```

### Lists

```bash
variable "subnets" {
  type = list(string)
}
```

Example value:

```bash
subnets = [
  "10.0.1.0/24",
  "10.0.2.0/24",
  "10.0.3.0/24"
]
```

Access an element:

```bash
var.subnets[0]
# access 10.0.1.0/24
# list indexes start at "0"
```

### Objects

Objects group related values:

```hcl
variable "web_server" {
  type = object({
    name          = string
    instance_type = string
    environment   = string
  })
}
```

Access properties:

```hcl
var.web_server.name
var.web_server.instance_type
var.web_server.environment
```

### Reuse Values

Instead of repeating:

```hcl
cidr_block = "10.0.1.0/24"
```

throughout many files, define it once:

```hcl
variable "subnet_prefix" {
  type = string
  default = "10.0.1.0/24"
}
```

and reuse:

```hcl
cidr_block = var.subnet_prefix
```

---

## 14. Useful Commands & Quick Reference

### Setup

```bash
terraform version
terraform init
terraform fmt
terraform validate
```

### Planning & Applying

```bash
terraform plan
terraform apply
terraform apply -auto-approve
```

### Destroying

```bash
terraform destroy
terraform destroy -auto-approve
```

### Providers

```bash
terraform providers
# shows the providers required by
# the current configuration and modules
```

### Dependency Graph

```bash
terraform graph
```

Generates Terraform's dependency graph. It can be useful for understanding resource relationships and visualizing architecture.

### State

```bash
terraform state list
terraform state show <resource>
```

### Outputs

```bash
terraform output
terraform output <name>
```

### Refresh-only Operations

```bash
terraform plan -refresh-only
terraform apply -refresh-only
```

### Targeting

```bash
terraform apply -target=<resource>
terraform destroy -target=<resource>
```

Use only when there is a specific reason.

### Formatting

```bash
terraform fmt
terraform fmt -recursive
```

### Validation

```bash
terraform validate
```

---

## Practical Workflow

A clean development loop:

```bash
# 1. Initialize the project
terraform init

# 2. Format files
terraform fmt

# 3. Check configuration
terraform validate

# 4. Preview changes
terraform plan

# 5. Apply changes
terraform apply

# 6. Inspect useful information
terraform state list
terraform output

# 7. Make configuration changes
# then repeat fmt → validate → plan → apply

# 8. destroy the infra
terraform destroy
```

---