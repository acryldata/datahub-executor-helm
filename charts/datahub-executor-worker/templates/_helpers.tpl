{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "datahub-executor-worker.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "datahub-executor-worker.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "datahub-executor-worker.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "datahub-executor-worker.labels" -}}
helm.sh/chart: {{ include "datahub-executor-worker.chart" . }}
{{ include "datahub-executor-worker.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "datahub-executor-worker.selectorLabels" -}}
app.kubernetes.io/name: {{ include "datahub-executor-worker.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "datahub-executor-worker.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "datahub-executor-worker.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
PAT file-mount settings. When enabled, the chart projects the GMS token Secret
and any extraEnvs secretKeyRef entries onto one volume, then exports them at
startup instead of using secretKeyRef on the Pod spec.
*/}}
{{- define "datahub-executor-worker.gms.tokenFile" -}}
{{- $gms := ((.Values.global).datahub).gms | default dict -}}
{{- $tf := $gms.tokenFile | default dict -}}
{{- $secretName := $tf.secretName | default $gms.secretRef -}}
{{- $secretKey := $tf.secretKey | default $gms.secretKey -}}
{{- $enabled := $tf.enabled | default false -}}
{{- if and $enabled (not $secretName) -}}
{{- fail "global.datahub.gms.tokenFile.enabled requires tokenFile.secretName or global.datahub.gms.secretRef" -}}
{{- end -}}
{{- if and $enabled (not $secretKey) -}}
{{- fail "global.datahub.gms.tokenFile.enabled requires tokenFile.secretKey or global.datahub.gms.secretKey" -}}
{{- end -}}
{{- if $enabled -}}
{{- range $.Values.extraEnvs | default list -}}
{{- $sk := dig "valueFrom" "secretKeyRef" dict . -}}
{{- if $sk.name }}
{{- if not .name -}}
{{- fail "extraEnvs secretKeyRef entries require name when tokenFile.enabled is true" -}}
{{- end -}}
{{- if not $sk.key -}}
{{- fail (printf "extraEnvs %q secretKeyRef requires key when tokenFile.enabled is true" .name) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
enabled: {{ $enabled }}
secretName: {{ $secretName | quote }}
secretKey: {{ $secretKey | quote }}
mountPath: {{ $tf.mountPath | default "/mnt/secrets" | quote }}
fileName: {{ $tf.fileName | default "token" | quote }}
{{- end -}}
