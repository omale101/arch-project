# Cloud-Native Django Architecture: DevSecOps Automation Pipeline

A production-grade, containerized Django web application integrated into a secure, scalable, and fully automated cloud infrastructure pipeline. This project demonstrates a comprehensive implementation of modern DevSecOps principles, cloud infrastructure management, microservice orchestration, and real-time system observability.

---

## 🏛️ Repository Layout & Architecture Layers

```text
arch-project/
├── myproject/                  # Application Core Layout (Pure Django Codebase)
├── terraform-infra/            # Infrastructure Layer (Terraform AWS Code)
├── .dockerignore               # Build Optimization (Excludes files from Docker image)
├── .gitignore                  # Source Control Protection (Excludes sensitive/heavy files)
├── Dockerfile                  # Application Packaging (Gunicorn & Non-Root Setup)
├── docker-compose.yml          # Local Sandbox Multi-Service Testing
├── Jenkinsfile                 # Automation Pipeline (Continuous Integration/Deployment)
├── deployment.yaml             # Kubernetes Core Workload Scaling
├── service.yml                 # Kubernetes Service Routing Fabric
├── k8s-istio-security.yaml     # Zero-Trust Service Mesh Traffic Isolation
├── k8s-opa-policy.yaml         # Open Policy Agent Admission Controller Config
├── opa-policy.rego             # Rego Security Compliance Authorization Rules
├── k8sprometheus-config.yaml   # Prometheus Time-Series Scraper Targets
├── k8sprometheus-rbac.yaml     # Role-Based Access Control for Scraper Agents
├── k8smonitoring-deployment.yaml # Telemetry Collection Engine Core
└── k8sgrafana-deployment.yaml  # Observability Dashboard Visualization Engine
