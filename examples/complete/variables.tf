variable "grafana_client_secret" {
  description = "OAuth2 client secret for the Grafana app."
  type        = string
  sensitive   = true
}

variable "jenkins_scim_token" {
  description = "Bearer token Authentik uses to authenticate to the Jenkins SCIM endpoint."
  type        = string
  sensitive   = true
}

variable "radius_shared_secret" {
  description = "RADIUS shared secret for the FreeRADIUS app."
  type        = string
  sensitive   = true
}

variable "entra_client_secret" {
  description = "Microsoft Entra client secret for the Office 365 app."
  type        = string
  sensitive   = true
}

variable "entra_tenant_id" {
  description = "Microsoft Entra tenant ID for the Office 365 app."
  type        = string
}

variable "google_workspace_credentials" {
  description = "Google Workspace service-account credentials (JSON object)."
  type        = map(any)
  default     = {}
  sensitive   = true
}
