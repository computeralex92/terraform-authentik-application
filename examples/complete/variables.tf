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
