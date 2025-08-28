# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added - Major Configuration Injection System Overhaul

#### 🚀 New Flexible Configuration Injection System
- **Dynamic envFrom Support**: Automatically inject all secret/configmap keys using `envFrom` without pre-defining field names
- **File-based Injection**: Mount secrets and configmaps as files with full control over paths, permissions, and file names
- **External Resource Support**: Full support for Vault secrets, External Secrets Operator, and other external secret management tools
- **Mixed Injection Modes**: Combine environment variables and file mounting in the same deployment
- **Auto-detection**: Automatically detect and inject available secrets/configmaps without manual configuration

#### 📝 New Values Schema
```yaml
configInjection:
  env:
    secrets:
      enabled: true          # Auto-inject all secrets via envFrom
      sources: []            # Optional: specify external secrets
    configMaps:
      enabled: true          # Auto-inject all configmaps via envFrom
      sources: []            # Optional: specify external configmaps
    individual: []           # Individual environment variables
  files:
    secrets: []              # Mount secrets as files
    configMaps: []           # Mount configmaps as files
```

#### 🔧 Enhanced Secret Generation System
- **10 Generation Types**: `alphanumeric`, `alpha`, `numeric`, `hex`, `hex_upper`, `mixed_case`, `special`, `safe_special`, `base64`, `url_safe`
- **Flexible Configuration**: No naming constraints, any field name supported
- **Custom Generation Rules**: Per-field length and type specification
- **Pattern-based Generation**: Automatic type detection based on field names (optional)

### Changed

#### 🔄 Breaking Changes
- **Deployment Template**: Replaced hardcoded `env` section with dynamic `envFrom` and conditional `env`
- **Helper Functions**: Deprecated `api-service.secretEnvVars` and `api-service.configEnvVars` in favor of new injection system
- **ConfigMap Template**: Added conditional creation check (`{{- if .Values.configMap.create }}`)

#### 📈 Improvements
- **Decoupled Architecture**: Secret/ConfigMap definition completely separated from usage
- **Dynamic Key Discovery**: No need to pre-define secret keys in deployment templates
- **External Integration**: Seamless integration with Vault, External Secrets, and other external tools
- **Backward Compatibility**: Existing configurations continue to work with new system

### Technical Details

#### 🛠️ New Template Functions
- `api-service.envVars`: Generate individual environment variables
- `api-service.envFrom`: Generate envFrom configurations for dynamic injection
- `api-service.configVolumes`: Generate volumes for file-based injection
- `api-service.configVolumeMounts`: Generate volume mounts for file-based injection
- `api-service.generateSecret`: Enhanced secret generation with multiple types
- `api-service.generateFromCharset`: Custom charset-based generation
- `api-service.getSecretValue`: Intelligent secret value handling with auto-generation

#### 📊 Test Coverage
Comprehensive testing across 7 scenarios:

1. **✅ Basic envFrom Auto-injection**: Automatic injection of internal secrets/configmaps
2. **✅ File Mount Injection**: Mounting secrets/configmaps as files with custom paths
3. **✅ External Secrets Injection**: Integration with external secret management tools
4. **✅ Mixed Injection Mode**: Combining environment variables and file mounting
5. **✅ Vault Secret Dynamic Injection**: Automatic detection and injection of VaultSecret resources
6. **✅ Disabled Auto-injection**: Manual control with individual environment variables only
7. **✅ Edge Cases**: Handling empty configurations and missing resources gracefully

### Migration Guide

#### From Old System (v0.1.x)
```yaml
# OLD: Hardcoded environment variables
secrets:
  data:
    DATABASE_URL: "postgres://..."
    API_KEY: "secret"

# Deployment automatically injected these as individual env vars
```

#### To New System (v0.2.x)
```yaml
# NEW: Flexible injection system
secrets:
  create: true
  data:
    DATABASE_URL: "postgres://..."
    API_KEY: ""  # Auto-generated

configInjection:
  env:
    secrets:
      enabled: true  # Auto-inject ALL keys via envFrom
    individual:
      - name: "CUSTOM_VAR"
        value: "custom_value"
  files:
    secrets:
      - secretName: "tls-secret"
        mountPath: "/etc/ssl/certs"
```

### Use Cases Enabled

#### 🔐 Vault Integration
```yaml
vaultSecret:
  create: true
  spec:
    path: "secret/prod/api-service"
    keys: ["DYNAMIC_KEY_1", "DYNAMIC_KEY_2"]  # Unknown at chart time

configInjection:
  env:
    secrets:
      enabled: true  # Automatically injects all Vault-managed keys
```

#### 📁 TLS Certificate Mounting
```yaml
configInjection:
  files:
    secrets:
      - secretName: "tls-certificates"
        mountPath: "/etc/ssl/certs"
        defaultMode: 0400
        items:
          - key: "tls.crt"
            path: "server.crt"
          - key: "tls.key"
            path: "server.key"
```

#### 🌐 External Secret Operator
```yaml
configInjection:
  env:
    secrets:
      sources:
        - secretName: "external-secret-operator-managed"
          optional: true
        - secretName: "another-external-secret"
```

### Performance Impact
- **Positive**: Reduced template complexity and rendering time
- **Positive**: Eliminated need for manual environment variable management
- **Positive**: Better resource utilization with envFrom bulk injection
- **Neutral**: No impact on runtime performance

### Security Enhancements
- **Enhanced Secret Generation**: 10 different generation types with proper character sets
- **File Permission Control**: Granular control over mounted file permissions (defaultMode)
- **Optional Resource Handling**: Graceful handling of missing external secrets
- **Secure Defaults**: Read-only file mounts and proper permission settings

---

## [0.1.0] - Previous Version

### Added
- Basic Helm chart structure
- Secret and ConfigMap templates
- Django-specific secret generation
- Basic deployment configuration

### Issues Resolved in v0.2.0
- ❌ **Limited Injection Methods**: Only supported environment variables
- ❌ **Hardcoded Dependencies**: Required pre-defining all secret keys in templates  
- ❌ **External Tool Incompatibility**: Could not work with Vault, External Secrets, etc.
- ❌ **Inflexible Secret Generation**: Limited to Django-specific field names
- ❌ **Tight Coupling**: Secret definition and usage were tightly coupled

---

## Migration Notes

### Immediate Action Required
- **None**: The new system is backward compatible

### Recommended Actions
1. **Update values.yaml**: Migrate to new `configInjection` configuration for enhanced features
2. **Review Secret Generation**: Take advantage of new generation types and flexibility
3. **Consider File Mounting**: Evaluate if any secrets/configs would benefit from file-based injection
4. **External Integration**: If using external secret management, configure appropriate sources

### Support
For questions about migration or new features, please refer to the updated README.md or create an issue in the repository.
