terraform {
  required_version = ">= 1.7.0"

  required_providers {
    idsec = {
      source  = "cyberark/idsec"
      version = ">= 0.4.0"
    }
  }
}

provider "idsec" {
  auth_method   = "identity_service_user"
  service_user  = var.cyberark_client_id
  service_token = var.cyberark_client_secret
  subdomain     = var.cyberark_subdomain
}

# ── Tenant-wide SIA settings ──────────────────────────────────────────────────
# These are SINGLETON objects per CyberArk tenant — apply this once (via the
# cyberark-sia-settings workflow_dispatch), NOT per vended account. Ported
# verbatim from murphys_lab terraform_code/05_cyberark_config/sia_settings.

resource "idsec_sia_settings_adb_mfa_caching" "adb_mfa_caching" {
  client_ip_enforced      = true
  is_mfa_caching_enabled  = true
  key_expiration_time_sec = 3600
}

resource "idsec_sia_settings_certificate_validation" "sia_cert_validation" {
  enabled = false
}

resource "idsec_sia_settings_k8s_mfa_caching" "k8s_mfa_caching" {
  client_ip_enforced      = true
  key_expiration_time_sec = 3600
}

resource "idsec_sia_settings_logon_sequence" "ssh_logon_sequence" {
  always_use_sia = false
  logon_sequence = "\\[.*\\@.*~]\\$>exec su - {Username}\nPassword:>{Password}"
}

resource "idsec_sia_settings_rdp_file_transfer" "rdp_file_transfer" {
  enabled = true
}

resource "idsec_sia_settings_rdp_kerberos_auth_mode" "kerberos_auth_mode" {
  auth_mode = "DO_NOT_USE"
}

resource "idsec_sia_settings_rdp_keyboard_layout" "keyboard_layout" {
  layout = "en-us-qwerty"
}

resource "idsec_sia_settings_rdp_mfa_caching" "rdp_mfa_caching" {
  client_ip_enforced      = true
  is_mfa_caching_enabled  = true
  key_expiration_time_sec = 60
}

resource "idsec_sia_settings_rdp_recording" "rdp_recording" {
  enabled = true
}

resource "idsec_sia_settings_rdp_token_mfa_caching" "rdp_token_mfa_caching" {
  client_ip_enforced      = true
  is_mfa_caching_enabled  = true
  key_expiration_time_sec = 3600
}

resource "idsec_sia_settings_rdp_transcription" "rdp_transcription" {
  enabled = true
}

resource "idsec_sia_settings_ssh_command_audit" "ssh_command_audit" {
  is_command_parsing_for_audit_enabled = true
  shell_prompt_for_audit               = "(.*)[>#\\$]$"
}

resource "idsec_sia_settings_ssh_mfa_caching" "ssh_mfa_caching" {
  client_ip_enforced      = true
  is_mfa_caching_enabled  = true
  key_expiration_time_sec = 3600
}

resource "idsec_sia_settings_standing_access" "standing_access" {
  standing_access_available     = true
  adb_standing_access_available = true
  rdp_standing_access_available = true
  ssh_standing_access_available = true
  session_max_duration          = 240
  session_idle_time             = 60
  fingerprint_validation        = true
}
