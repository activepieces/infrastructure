packer {
  required_plugins {
    digitalocean = {
      version = "1.1.1"
      source  = "github.com/digitalocean/digitalocean"
    }
  }
}

source "digitalocean" "one_click" {
  api_key       = env("DIGITAL_OCEAN_TOKEN")
  image         = "ubuntu-22-04-x64"
  region        = "fra1"
  size          = "s-1vcpu-512mb-10gb"
  ssh_username  = "root"
  snapshot_name = "one-click-install-{{timestamp}}"
}

build {
  name = "one_click"
  sources = [
    "source.digitalocean.one_click",
  ]

  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive",
    ]
    inline = [
      "cloud-init status --wait",
      "sudo apt-get update",
      "sudo apt-get install -y ca-certificates curl gnupg lsb-release",
      "sudo mkdir -p /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
      <<-EOF
      echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
      EOF
      ,
      "sudo apt-get update",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin",
      "git clone https://github.com/activepieces/activepieces",
      "docker compose -f ./activepieces/docker-compose.yml up -d --wait --quiet-pull",
      "git clone https://github.com/digitalocean/marketplace-partners",
      "ufw default allow outgoing",
      "ufw default deny incoming",
      "ufw allow ssh",
      "ufw allow 8080/tcp",
      "ufw --force enable",
      "sudo rm /var/log/dpkg.log /var/log/auth.log",
      "./marketplace-partners/scripts/90-cleanup.sh",
      "sudo apt-get purge -y droplet-agent",
      "./marketplace-partners/scripts/99-img-check.sh",
    ]
  }
}
