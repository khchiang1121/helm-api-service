{{/*
Expand the name of the chart.
*/}}
{{- define "api-service.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "api-service.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "api-service.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "api-service.labels" -}}
helm.sh/chart: {{ include "api-service.chart" . }}
{{ include "api-service.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "api-service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "api-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "api-service.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "api-service.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the config map
*/}}
{{- define "api-service.configMapName" -}}
{{- printf "%s-config" (include "api-service.fullname" .) }}
{{- end }}

{{/*
Create the name of the secret
*/}}
{{- define "api-service.secretName" -}}
{{- printf "%s-secrets" (include "api-service.fullname" .) }}
{{- end }}

{{/*
Get the image name
*/}}
{{- define "api-service.image" -}}
{{- $registryName := .Values.image.registry -}}
{{- $repositoryName := .Values.image.repository -}}
{{- $tag := .Values.image.tag | toString -}}
{{- if $registryName }}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
{{- else -}}
{{- printf "%s:%s" $repositoryName $tag -}}
{{- end -}}
{{- end -}}

{{/*
Generate random string based on type and length
*/}}
{{- define "api-service.generateSecret" -}}
{{- $type := .type | default "alphanumeric" -}}
{{- $length := .length | default 32 | int -}}
{{- if eq $type "alphanumeric" -}}
{{- randAlphaNum $length -}}
{{- else if eq $type "alpha" -}}
{{- randAlpha $length -}}
{{- else if eq $type "numeric" -}}
{{- randNumeric $length -}}
{{- else if eq $type "hex" -}}
{{- $bytes := div $length 2 | int -}}
{{- if mod $length 2 -}}{{- $bytes = add $bytes 1 | int -}}{{- end -}}
{{- $hexString := randBytes $bytes | b64enc | sha256sum | trunc $length -}}
{{- printf "%s" $hexString -}}
{{- else if eq $type "hex_upper" -}}
{{- $bytes := div $length 2 | int -}}
{{- if mod $length 2 -}}{{- $bytes = add $bytes 1 | int -}}{{- end -}}
{{- $hexString := randBytes $bytes | b64enc | sha256sum | trunc $length | upper -}}
{{- printf "%s" $hexString -}}
{{- else if eq $type "mixed_case" -}}
{{- $chars := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" -}}
{{- include "api-service.generateFromCharset" (dict "charset" $chars "length" $length) -}}
{{- else if eq $type "special" -}}
{{- $chars := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=[]{}|;:,.<>?" -}}
{{- include "api-service.generateFromCharset" (dict "charset" $chars "length" $length) -}}
{{- else if eq $type "safe_special" -}}
{{- $chars := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*-_=+" -}}
{{- include "api-service.generateFromCharset" (dict "charset" $chars "length" $length) -}}
{{- else if eq $type "base64" -}}
{{- $chars := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789+/" -}}
{{- include "api-service.generateFromCharset" (dict "charset" $chars "length" $length) -}}
{{- else if eq $type "url_safe" -}}
{{- $chars := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_" -}}
{{- include "api-service.generateFromCharset" (dict "charset" $chars "length" $length) -}}
{{- else -}}
{{- randAlphaNum $length -}}
{{- end -}}
{{- end }}

{{/*
Generate random string from custom character set
*/}}
{{- define "api-service.generateFromCharset" -}}
{{- $charset := .charset -}}
{{- $length := .length | int -}}
{{- $charsetLen := len $charset | int -}}
{{- $result := "" -}}
{{- range $i := until $length -}}
{{- $randomIndex := randNumeric 3 | int -}}
{{- $randomIndex = mod $randomIndex $charsetLen | int -}}
{{- $char := substr $randomIndex (add $randomIndex 1 | int) $charset -}}
{{- $result = printf "%s%s" $result $char -}}
{{- end -}}
{{- $result -}}
{{- end }}

{{/*
Get secret value with auto-generation support
*/}}
{{- define "api-service.getSecretValue" -}}
{{- $fieldName := .fieldName -}}
{{- $fieldValue := .fieldValue -}}
{{- $context := .context -}}
{{- if ne $fieldValue "" -}}
{{- $fieldValue | b64enc -}}
{{- else if $context.Values.secrets.autoGenerate.enabled -}}
{{- $config := dict -}}
{{- if hasKey $context.Values.secrets.autoGenerate "fields" -}}
{{- if hasKey $context.Values.secrets.autoGenerate.fields $fieldName -}}
{{- $config = index $context.Values.secrets.autoGenerate.fields $fieldName -}}
{{- else if hasKey $context.Values.secrets.autoGenerate "default" -}}
{{- $config = $context.Values.secrets.autoGenerate.default -}}
{{- else -}}
{{- $config = dict "length" 32 "type" "alphanumeric" -}}
{{- end -}}
{{- else -}}
{{- $config = dict "length" 32 "type" "alphanumeric" -}}
{{- end -}}
{{- $generated := include "api-service.generateSecret" $config -}}
{{- $generated | b64enc -}}
{{- else -}}
{{- "" | b64enc -}}
{{- end -}}
{{- end }}

{{/*
Generate environment variables from configInjection.env configuration
*/}}
{{- define "api-service.envVars" -}}
{{- $context := . -}}

{{/* Individual environment variables */}}
{{- range .Values.configInjection.env.individual }}
- name: {{ .name }}
  {{- if .value }}
  value: {{ .value | quote }}
  {{- else if .valueFrom }}
  valueFrom:
    {{- toYaml .valueFrom | nindent 4 }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Generate envFrom for secrets and configmaps
*/}}
{{- define "api-service.envFrom" -}}
{{- $context := . -}}

{{/* Secrets envFrom */}}
{{- if .Values.configInjection.env.secrets.enabled }}
{{- if .Values.configInjection.env.secrets.sources }}
{{/* Use specified sources */}}
{{- range .Values.configInjection.env.secrets.sources }}
- secretRef:
    name: {{ .secretName }}
    {{- if .optional }}
    optional: {{ .optional }}
    {{- end }}
{{- end }}
{{- else }}
{{/* Auto-detect secrets to inject */}}
{{- if .Values.secrets.create }}
- secretRef:
    name: {{ include "api-service.secretName" $context }}
{{- end }}
{{- if .Values.vaultSecret.create }}
- secretRef:
    name: {{ include "api-service.fullname" $context }}-vault
    optional: true
{{- end }}
{{- end }}
{{- end }}

{{/* ConfigMaps envFrom */}}
{{- if .Values.configInjection.env.configMaps.enabled }}
{{- if .Values.configInjection.env.configMaps.sources }}
{{/* Use specified sources */}}
{{- range .Values.configInjection.env.configMaps.sources }}
- configMapRef:
    name: {{ .configMapName }}
    {{- if .optional }}
    optional: {{ .optional }}
    {{- end }}
{{- end }}
{{- else }}
{{/* Auto-detect configmaps to inject */}}
{{- if .Values.configMap.create }}
- configMapRef:
    name: {{ include "api-service.configMapName" $context }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Generate volumes for file-based injection
*/}}
{{- define "api-service.configVolumes" -}}
{{- $context := . -}}

{{/* Secret volumes */}}
{{- range .Values.configInjection.files.secrets }}
- name: {{ printf "secret-%s" (.secretName | replace "-" "") | trunc 63 | trimSuffix "-" }}
  secret:
    secretName: {{ .secretName }}
    {{- if .defaultMode }}
    defaultMode: {{ .defaultMode }}
    {{- end }}
    {{- if .items }}
    items:
      {{- toYaml .items | nindent 6 }}
    {{- end }}
{{- end }}

{{/* ConfigMap volumes */}}
{{- range .Values.configInjection.files.configMaps }}
- name: {{ printf "configmap-%s" (.configMapName | replace "-" "") | trunc 63 | trimSuffix "-" }}
  configMap:
    name: {{ .configMapName }}
    {{- if .defaultMode }}
    defaultMode: {{ .defaultMode }}
    {{- end }}
    {{- if .items }}
    items:
      {{- toYaml .items | nindent 6 }}
    {{- end }}
{{- end }}
{{- end }}

{{/*
Generate volume mounts for file-based injection
*/}}
{{- define "api-service.configVolumeMounts" -}}
{{- $context := . -}}

{{/* Secret volume mounts */}}
{{- range .Values.configInjection.files.secrets }}
- name: {{ printf "secret-%s" (.secretName | replace "-" "") | trunc 63 | trimSuffix "-" }}
  mountPath: {{ .mountPath }}
  {{- if .readOnly }}
  readOnly: {{ .readOnly }}
  {{- else }}
  readOnly: true
  {{- end }}
  {{- if .subPath }}
  subPath: {{ .subPath }}
  {{- end }}
{{- end }}

{{/* ConfigMap volume mounts */}}
{{- range .Values.configInjection.files.configMaps }}
- name: {{ printf "configmap-%s" (.configMapName | replace "-" "") | trunc 63 | trimSuffix "-" }}
  mountPath: {{ .mountPath }}
  {{- if .readOnly }}
  readOnly: {{ .readOnly }}
  {{- else }}
  readOnly: true
  {{- end }}
  {{- if .subPath }}
  subPath: {{ .subPath }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Create the name of the role to use
*/}}
{{- define "api-service.roleName" -}}
{{- if .Values.rbac.role.create }}
{{- default (printf "%s-role" (include "api-service.fullname" .)) .Values.rbac.role.name }}
{{- else }}
{{- default "" .Values.rbac.role.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the role binding to use
*/}}
{{- define "api-service.roleBindingName" -}}
{{- if .Values.rbac.roleBinding.create }}
{{- default (printf "%s-rolebinding" (include "api-service.fullname" .)) .Values.rbac.roleBinding.name }}
{{- else }}
{{- default "" .Values.rbac.roleBinding.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the cluster role to use
*/}}
{{- define "api-service.clusterRoleName" -}}
{{- if .Values.rbac.clusterRole.create }}
{{- default (printf "%s-clusterrole" (include "api-service.fullname" .)) .Values.rbac.clusterRole.name }}
{{- else }}
{{- default "" .Values.rbac.clusterRole.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the cluster role binding to use
*/}}
{{- define "api-service.clusterRoleBindingName" -}}
{{- if .Values.rbac.clusterRoleBinding.create }}
{{- default (printf "%s-clusterrolebinding" (include "api-service.fullname" .)) .Values.rbac.clusterRoleBinding.name }}
{{- else }}
{{- default "" .Values.rbac.clusterRoleBinding.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account secret to use
*/}}
{{- define "api-service.serviceAccountSecretName" -}}
{{- if .Values.serviceAccountSecret.create }}
{{- default (printf "%s-token" (include "api-service.fullname" .)) .Values.serviceAccountSecret.name }}
{{- else }}
{{- default "" .Values.serviceAccountSecret.name }}
{{- end }}
{{- end }}

{{/*
Get the service account name for RBAC resources
*/}}
{{- define "api-service.rbacServiceAccountName" -}}
{{- if .Values.serviceAccountSecret.serviceAccountName }}
{{- .Values.serviceAccountSecret.serviceAccountName }}
{{- else }}
{{- include "api-service.serviceAccountName" . }}
{{- end }}
{{- end }}

{{/*
Generate subjects for role binding
*/}}
{{- define "api-service.roleBindingSubjects" -}}
{{- if .Values.rbac.roleBinding.subjects }}
{{- range .Values.rbac.roleBinding.subjects }}
- kind: {{ .kind }}
  {{- if eq .kind "ServiceAccount" }}
  name: {{ .name | default (include "api-service.rbacServiceAccountName" $) }}
  namespace: {{ .namespace | default $.Release.Namespace }}
  {{- else }}
  name: {{ .name }}
  {{- if .apiGroup }}
  apiGroup: {{ .apiGroup }}
  {{- end }}
  {{- end }}
{{- end }}
{{- else }}
- kind: ServiceAccount
  name: {{ include "api-service.rbacServiceAccountName" . }}
  namespace: {{ .Release.Namespace }}
{{- end }}
{{- end }}

{{/*
Generate subjects for cluster role binding
*/}}
{{- define "api-service.clusterRoleBindingSubjects" -}}
{{- if .Values.rbac.clusterRoleBinding.subjects }}
{{- range .Values.rbac.clusterRoleBinding.subjects }}
- kind: {{ .kind }}
  {{- if eq .kind "ServiceAccount" }}
  name: {{ .name | default (include "api-service.rbacServiceAccountName" $) }}
  namespace: {{ .namespace | default $.Release.Namespace }}
  {{- else }}
  name: {{ .name }}
  {{- if .apiGroup }}
  apiGroup: {{ .apiGroup }}
  {{- end }}
  {{- end }}
{{- end }}
{{- else }}
- kind: ServiceAccount
  name: {{ include "api-service.rbacServiceAccountName" . }}
  namespace: {{ .Release.Namespace }}
{{- end }}
{{- end }}


