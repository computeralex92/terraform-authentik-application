variable "oauth2_client_secret" {
  description = "OAuth2 client secret for the Vault app."
  type        = string
  sensitive   = true
}

variable "scim_token" {
  description = "Bearer token Authentik uses to authenticate to the Keycloak SCIM endpoint."
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
