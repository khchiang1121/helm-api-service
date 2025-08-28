# API Service Helm Chart

A production-ready Helm chart for deploying containerized APIs to Kubernetes clusters
![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square)
![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)
![AppVersion: 1.16.0](https://img.shields.io/badge/AppVersion-1.16.0-informational?style=flat-square)

## Description

This Helm chart provides a complete deployment solution for API services on Kubernetes, featuring:

- 🚀 **Production-ready deployment** - Complete Kubernetes resource templates
- 🔧 **Highly configurable** - Extensive values.yaml with sensible defaults
- 🏗️ **Multi-environment support** - Development, staging, and production configurations
- 📊 **Observability** - Built-in ServiceMonitor for Prometheus integration
- 🔒 **Security-first** - Pod Security Policies, Network Policies, and security contexts
- ⚡ **Auto-scaling** - Horizontal Pod Autoscaler (HPA) support
- 🛡️ **High availability** - Pod Disruption Budget (PDB) configuration
- 🌐 **Service mesh ready** - Optional Istio Gateway and VirtualService
- 🔐 **TLS/SSL support** - cert-manager integration for automatic certificate management
- 🗄️ **Secret management** - Built-in secret generation and HashiCorp Vault integration

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+

### Optional Dependencies

- **Istio 1.10+** (for service mesh features)
- **cert-manager 1.5+** (for automatic TLS certificate management)
- **Prometheus Operator** (for ServiceMonitor support)
- **HashiCorp Vault** (for Vault secret integration)

## Installation

### Add Helm Repository

```bash
# If this chart is published to a Helm repository
helm repo add api-service https://your-helm-repo.com
helm repo update
```

### Install from Local Chart

```bash
# Basic installation
helm install my-api-service ./

# Install with custom values
helm install my-api-service ./ -f values-production.yaml

# Install with inline values
helm install my-api-service ./ \
  --set image.repository=your-registry/your-api \
  --set image.tag=v1.0.0 \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=api.example.com
```

### Upgrade

```bash
helm upgrade my-api-service ./ -f values-production.yaml
```

### Uninstall

```bash
helm uninstall my-api-service
```

## Configuration

### Basic Configuration Examples

#### Development Environment

```yaml
# values-dev.yaml
deployment:
  replicas: 1

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 200m
    memory: 256Mi

ingress:
  enabled: true
  hosts:
    - host: api-dev.example.com
      paths:
        - path: /
          pathType: Prefix
```

#### Production Environment

```yaml
# values-prod.yaml
deployment:
  replicas: 3

resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 1000m
    memory: 1Gi

hpa:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

podDisruptionBudget:
  enabled: true
  minAvailable: 2

ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: api.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: api-tls
      hosts:
        - api.example.com
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `global.imageRegistry` | string | `""` | Global Docker image registry |
| `global.imagePullSecrets` | list | `[]` | Global Docker registry secret names as an array |
| `global.storageClass` | string | `""` | Global StorageClass for Persistent Volume(s) |
| `nameOverride` | string | `""` | Partially override api-service.fullname template |
| `fullnameOverride` | string | `""` | Fully override api-service.fullname template |
| `image.registry` | string | `""` | Docker image registry |
| `image.repository` | string | `"khchiang1121/inventory-api"` | Docker image repository |
| `image.tag` | string | `"latest"` | Docker image tag |
| `image.pullPolicy` | string | `"IfNotPresent"` | Docker image pull policy |
| `imagePullSecrets` | list | `[{"name": "gitlab-registry-secret"}]` | Docker registry secret names as an array |
| `serviceAccount.create` | bool | `true` | Specifies whether a service account should be created |
| `serviceAccount.annotations` | object | `{}` | Annotations to add to the service account |
| `serviceAccount.name` | string | `""` | The name of the service account to use |
| `podAnnotations` | object | `{}` | Annotations to add to the pod |
| `rolloutOnConfigmapChange.enabled` | bool | `true` | Automatically rollout deployment when ConfigMap changes |
| `rolloutOnSecretChange.enabled` | bool | `true` | Automatically rollout deployment when Secret changes |
| `podSecurityContext` | object | `{}` | Security context for the pod |
| `securityContext` | object | `{}` | Security context for the container |
| `service.type` | string | `"ClusterIP"` | Kubernetes service type |
| `service.annotations` | object | `{}` | Service annotations |
| `service.ports` | list | `[{"name": "http", "port": 80, "targetPort": "http", "protocol": "TCP"}]` | Service ports configuration |
| `ingress.enabled` | bool | `false` | Enable ingress controller resource |
| `ingress.className` | string | `"nginx"` | Ingress class name |
| `ingress.annotations` | object | `{}` | Ingress annotations |
| `ingress.hosts` | list | `[]` | Ingress hosts configuration |
| `ingress.tls` | list | `[]` | Ingress TLS configuration |
| `deployment.replicas` | int | `3` | Number of replicas |
| `deployment.strategy` | object | `{"type": "RollingUpdate", "rollingUpdate": {"maxSurge": "25%", "maxUnavailable": "25%"}}` | Deployment strategy |
| `resources.limits` | object | `{"cpu": "500m", "memory": "512Mi"}` | Resource limits |
| `resources.requests` | object | `{"cpu": "250m", "memory": "256Mi"}` | Resource requests |
| `hpa.enabled` | bool | `false` | Enable Horizontal Pod Autoscaler |
| `hpa.minReplicas` | int | `2` | Minimum number of replicas |
| `hpa.maxReplicas` | int | `10` | Maximum number of replicas |
| `hpa.targetCPUUtilizationPercentage` | int | `70` | Target CPU utilization percentage |
| `hpa.targetMemoryUtilizationPercentage` | int | `80` | Target memory utilization percentage |
| `podDisruptionBudget.enabled` | bool | `false` | Enable Pod Disruption Budget |
| `podDisruptionBudget.minAvailable` | int | `2` | Minimum available pods |
| `podDisruptionBudget.maxUnavailable` | int | `1` | Maximum unavailable pods |
| `healthCheck.livenessProbe.enabled` | bool | `true` | Enable liveness probe |
| `healthCheck.livenessProbe.path` | string | `"/health/"` | Liveness probe path |
| `healthCheck.livenessProbe.port` | int | `8201` | Liveness probe port |
| `healthCheck.readinessProbe.enabled` | bool | `true` | Enable readiness probe |
| `healthCheck.readinessProbe.path` | string | `"/health/"` | Readiness probe path |
| `healthCheck.readinessProbe.port` | int | `8201` | Readiness probe port |
| `secrets.create` | bool | `false` | Create secret resource |
| `secrets.data` | object | `{}` | Secret data (supports auto-generation for empty values) |
| `vaultSecret.create` | bool | `false` | Create VaultSecret resource for HashiCorp Vault integration |
| `configMap.create` | bool | `false` | Create ConfigMap resource |
| `configMap.data` | object | `{}` | ConfigMap data |
| `networkPolicy.enabled` | bool | `true` | Enable NetworkPolicy |
| `networkPolicy.ingressRules` | list | `[]` | NetworkPolicy ingress rules |
| `networkPolicy.egressRules` | list | `[]` | NetworkPolicy egress rules |
| `serviceMonitor.enabled` | bool | `false` | Enable ServiceMonitor for Prometheus |
| `serviceMonitor.interval` | string | `"30s"` | Scrape interval |
| `serviceMonitor.path` | string | `"/metrics"` | Metrics path |
| `istio.gateway.enabled` | bool | `false` | Enable Istio Gateway |
| `istio.virtualService.enabled` | bool | `false` | Enable Istio VirtualService |
| `certificate.enabled` | bool | `false` | Enable cert-manager Certificate |
| `nodeSelector` | object | `{}` | Node selector for pod assignment |
| `tolerations` | list | `[]` | Tolerations for pod assignment |
| `affinity` | object | `{}` | Affinity for pod assignment |

## Advanced Features

### Automatic Secret Generation

The chart supports automatic generation of secure passwords and keys when `secrets.create` is true. You have complete control over which fields to auto-generate and their characteristics without any naming constraints.

**Method 1: Simple Auto-Generation (Default)**
Any secret field left empty (`""`) will be automatically generated with a secure 32-character alphanumeric string:

```yaml
secrets:
  create: true
  data:
    # Any empty field will be auto-generated (32 chars by default)
    my_database_password: ""
    application_secret: ""
    custom_api_key: ""
    
    # Non-empty fields remain unchanged
    database_host: "postgres"
    database_name: "myapp"
```

**Method 2: Explicit Generation Configuration**
For more control, explicitly specify which fields to generate and their characteristics:

```yaml
secrets:
  create: true
  autoGenerate:
    # Explicitly define which fields to generate and their properties
    fields:
      my_database_password:
        length: 32
        type: "safe_special"     # Safe special characters
      application_secret:
        length: 64
        type: "mixed_case"       # Mixed case alphanumeric
      jwt_signing_key:
        length: 128
        type: "hex"              # Lowercase hex (0-9, a-f)
      api_token:
        length: 32
        type: "hex_upper"        # Uppercase hex (0-9, A-F)
      simple_code:
        length: 6
        type: "numeric"          # Numbers only
      url_token:
        length: 24
        type: "url_safe"         # URL-safe characters
      base64_key:
        length: 32
        type: "base64"           # Base64 characters
  data:
    # These will be auto-generated based on config above
    my_database_password: ""
    application_secret: ""
    jwt_signing_key: ""
    simple_token: ""
    
    # These remain as specified
    database_host: "postgres"
    database_name: "myapp"
```

**Method 3: Mixed Approach**
Combine both methods for maximum flexibility:

```yaml
secrets:
  create: true
  autoGenerate:
    # Default settings for simple auto-generation
    default:
      length: 32
      type: "safe_special"
    # Explicit settings for specific fields
    fields:
      super_secure_key:
        length: 128
        type: "hex"
  data:
    # Uses explicit config (128 char hex)
    super_secure_key: ""
    # Uses default config (32 char safe_special)
    regular_password: ""
    # No generation
    database_host: "postgres"
```

**Available Generation Types:**

| Type | Character Set | Example | Use Case |
|------|---------------|---------|----------|
| `alphanumeric` | a-z, A-Z, 0-9 | `kJ8mN2pQ4rT6` | Basic passwords (Helm default) |
| `alpha` | a-z, A-Z | `kJmNpQrT` | Name fields, identifiers |
| `numeric` | 0-9 | `582649` | PIN codes, simple tokens |
| `hex` | 0-9, a-f | `3f7a9b2c` | Hash values, hex tokens |
| `hex_upper` | 0-9, A-F | `3F7A9B2C` | Uppercase hex tokens |
| `mixed_case` | a-z, A-Z, 0-9 | `kJ8mN2pQ4rT6` | Same as alphanumeric but explicit |
| `special` | All printable ASCII | `kJ8@mN#2$pQ!` | Maximum security passwords |
| `safe_special` | Letters, numbers, safe symbols | `kJ8@mN-2_pQ=` | Database-safe passwords |
| `base64` | a-z, A-Z, 0-9, +, / | `kJ8mN2p/4rT+` | Base64-compatible strings |
| `url_safe` | a-z, A-Z, 0-9, -, _ | `kJ8mN2p-4rT_` | URL-safe tokens |

### HashiCorp Vault Integration

Enable Vault secret management:

```yaml
vaultSecret:
  create: true
  spec:
    path: "secret/prod/api-service"
    keys:
      - DATABASE_URL
      - API_SECRET_KEY
```

### Automatic Deployment Rollouts

The chart supports automatic deployment rollouts when configuration changes:

```yaml
# Rollout when ConfigMap changes (default: enabled)
rolloutOnConfigmapChange:
  enabled: true

# Rollout when Secret changes (default: enabled)  
rolloutOnSecretChange:
  enabled: true
```

**How it works:**
- When enabled, the chart calculates SHA256 checksums of ConfigMap and Secret templates
- These checksums are added as pod annotations (`checksum/configmap`, `checksum/secret`)
- When configuration changes, checksums change, triggering automatic pod rollout
- This ensures pods always use the latest configuration without manual intervention

**Benefits:**
- **Automatic Updates**: No need to manually restart pods after config changes
- **Zero Downtime**: Uses rolling update strategy for seamless deployments
- **Consistency**: Ensures all pods use the same configuration version
- **Reliability**: Prevents configuration drift between pods

### Network Security

Configure network policies for enhanced security:

```yaml
networkPolicy:
  enabled: true
  ingressRules:
    - from:
      - namespaceSelector:
          matchLabels:
            name: ingress-nginx
      - podSelector:
          matchLabels:
            app: monitoring
```

### Monitoring and Observability

Enable Prometheus monitoring:

```yaml
serviceMonitor:
  enabled: true
  namespace: monitoring
  interval: 15s
  path: /metrics
```

## Troubleshooting

### Common Issues

1. **Pod not starting**

   ```bash
   kubectl describe pod <pod-name>
   kubectl logs <pod-name>
   ```

2. **Ingress not working**

   ```bash
   kubectl describe ingress <ingress-name>
   kubectl get events --sort-by='.lastTimestamp'
   ```

3. **Certificate issues**

   ```bash
   kubectl describe certificate <cert-name>
   kubectl logs -n cert-manager deployment/cert-manager
   ```

### Useful Commands

```bash
# Check chart syntax
helm lint ./

# Render templates locally
helm template my-api-service ./ --output-dir ./rendered-templates

# Debug installation
helm install my-api-service ./ --dry-run --debug

# Check deployment status
helm status my-api-service

# View deployment history
helm history my-api-service
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `helm lint` and `helm template`
5. Submit a pull request
