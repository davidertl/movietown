#!/bin/bash
set -e

# Ensure we are running with bash even if invoked via sh
if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SETUP_USER="movietown"

ensure_setup_user() {
    local USERNAME="$SETUP_USER"

    if ! id -u "$USERNAME" >/dev/null 2>&1; then
        useradd -m -s /bin/bash "$USERNAME"
    fi

    usermod -aG sudo "$USERNAME"

    if ! getent group docker >/dev/null 2>&1; then
        groupadd -f docker
    fi

    usermod -aG docker "$USERNAME"

    if [ ! -f "/etc/sudoers.d/${USERNAME}" ]; then
        echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}"
        chmod 440 "/etc/sudoers.d/${USERNAME}"
    fi
}

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}╔═══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   MovieTown Setup Script                 ║${NC}"
echo -e "${BLUE}║   Automated Debian/Ubuntu Installation    ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   ensure_setup_user

   if [ "$(stat -c '%U' "$SCRIPT_DIR")" != "$SETUP_USER" ]; then
       chown -R "$SETUP_USER":"$SETUP_USER" "$SCRIPT_DIR"
   fi

   SCRIPT_PATH="${SCRIPT_DIR}/$(basename "$0")"
   COMMAND="$SCRIPT_PATH"
   if [ "$#" -gt 0 ]; then
       for ARG in "$@"; do
           COMMAND+=" $(printf '%q' "$ARG")"
       done
   fi

   echo -e "${BLUE}Switching to ${SETUP_USER} for setup...${NC}"
   exec su - "$SETUP_USER" -c "$COMMAND"
fi

# Function to check if Docker is installed
check_docker() {
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}✓ Docker is already installed${NC}"
        docker --version
        return 0
    else
        echo -e "${YELLOW}✗ Docker is not installed${NC}"
        return 1
    fi
}

# Function to check if Git is installed
check_git() {
    if command -v git &> /dev/null; then
        echo -e "${GREEN}✓ Git is already installed${NC}"
        git --version
        return 0
    else
        echo -e "${YELLOW}✗ Git is not installed${NC}"
        return 1
    fi
}

# Function to install Git
install_git() {
    echo -e "${BLUE}Installing Git...${NC}"
    sudo apt-get update
    sudo apt-get install -y git
    echo -e "${GREEN}✓ Git installed successfully${NC}"
}

# Function to check if Docker is installed
check_docker() {
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}✓ Docker is already installed${NC}"
        docker --version
        return 0
    else
        echo -e "${YELLOW}✗ Docker is not installed${NC}"
        return 1
    fi
}

# Function to install Docker
install_docker() {
    echo -e "${BLUE}Installing Docker...${NC}"
    
    # Detect OS
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        echo -e "${RED}Cannot detect OS. Please install Docker manually.${NC}"
        exit 1
    fi
    
    # Uninstall conflicting packages
    echo "Removing conflicting packages..."
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
        sudo apt-get remove -y $pkg 2>/dev/null || true
    done
    
    # Add Docker's official GPG key
    echo "Adding Docker GPG key..."
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    
    if [ "$OS" = "ubuntu" ]; then
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    else
        sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    fi
    
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    
    # Add the repository to Apt sources
    echo "Adding Docker repository..."
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${OS} \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    sudo apt-get update
    
    # Install Docker
    echo "Installing Docker packages..."
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Add current user to docker group
    echo "Adding user to docker group..."
    sudo usermod -aG docker $USER
    
    echo -e "${GREEN}✓ Docker installed successfully${NC}"
    echo -e "${YELLOW}Note: You may need to log out and back in for group changes to take effect${NC}"
}

# Function to generate random secret
generate_secret() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-50
}

# Function to prompt for deployment type
select_deployment_type() {
    echo ""
    echo -e "${BLUE}Select deployment type:${NC}"
    echo "1) Cloud (Authentik + PostgreSQL + Valkey + Jellyfin + Plex + tsdproxy)"
    echo "2) Home (*ARR stack + Gluetun + Authentik worker)"
    echo ""
    read -p "Enter choice [1-2]: " DEPLOY_TYPE
    
    case $DEPLOY_TYPE in
        1)
            DEPLOY_MODE="cloud"
            COMPOSE_FILE="cloud-compose.yaml"
            ENV_EXAMPLE="cloud.env.example"
            ;;
        2)
            DEPLOY_MODE="home"
            COMPOSE_FILE="home-compose.yaml"
            ENV_EXAMPLE="home.env.example"
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            exit 1
            ;;
    esac
    
    echo -e "${GREEN}Selected: ${DEPLOY_MODE} deployment${NC}"
}

# Function to create .env file
create_env_file() {
    local ENV_FILE="${SCRIPT_DIR}/.env"
    
    if [ -f "$ENV_FILE" ]; then
        echo -e "${YELLOW}.env file already exists${NC}"
        read -p "Overwrite? [y/N]: " OVERWRITE
        if [[ ! $OVERWRITE =~ ^[Yy]$ ]]; then
            echo "Keeping existing .env file"
            return
        fi
    fi
    
    echo -e "${BLUE}Creating .env file from ${ENV_EXAMPLE}...${NC}"
    cp "${SCRIPT_DIR}/${ENV_EXAMPLE}" "$ENV_FILE"
    
    # Generate secrets
    echo "Generating secrets..."
    AUTHENTIK_SECRET=$(generate_secret)
    POSTGRES_PASSWORD=$(generate_secret)
    
    # Prompt for basic configuration
    echo ""
    echo -e "${BLUE}Basic Configuration:${NC}"
    
    read -p "Timezone [Europe/Berlin]: " TIMEZONE
    TIMEZONE=${TIMEZONE:-Europe/Berlin}
    
    read -p "User ID (PUID) [1000]: " PUID
    PUID=${PUID:-1000}
    
    read -p "Group ID (PGID) [1000]: " PGID
    PGID=${PGID:-1000}
    
    read -p "Data directory [/srv/movietown/data]: " DATA_DIR
    DATA_DIR=${DATA_DIR:-/srv/movietown/data}
    
    if [ "$DEPLOY_MODE" = "cloud" ]; then
        read -p "Media directory [/srv/movietown/media]: " MEDIA_DIR
        MEDIA_DIR=${MEDIA_DIR:-/srv/movietown/media}
        
        read -p "Cloud external subnet [10.10.0.0/24]: " CLOUD_SUBNET
        CLOUD_SUBNET=${CLOUD_SUBNET:-10.10.0.0/24}
        
        read -p "Cloud external gateway [10.10.0.1]: " CLOUD_GATEWAY
        CLOUD_GATEWAY=${CLOUD_GATEWAY:-10.10.0.1}
        
        echo ""
        echo -e "${YELLOW}Traefik / Domain Configuration (for HTTPS):${NC}"
        read -p "Main domain for your stack (e.g., yourdomain.com, leave empty to skip): " MAIN_DOMAIN
        
        if [ ! -z "$MAIN_DOMAIN" ]; then
            read -p "Authentik subdomain [auth]: " AUTH_SUBDOMAIN
            AUTH_SUBDOMAIN=${AUTH_SUBDOMAIN:-auth}
            
            read -p "Jellyfin subdomain [jellyfin]: " JELLYFIN_SUBDOMAIN
            JELLYFIN_SUBDOMAIN=${JELLYFIN_SUBDOMAIN:-jellyfin}
            
            read -p "Plex subdomain [plex]: " PLEX_SUBDOMAIN
            PLEX_SUBDOMAIN=${PLEX_SUBDOMAIN:-plex}
            
            read -p "Email for Let's Encrypt [admin@example.com]: " LETSENCRYPT_EMAIL
            LETSENCRYPT_EMAIL=${LETSENCRYPT_EMAIL:-admin@example.com}
            
            read -p "Enable Let's Encrypt ACME [false]: " ACME_ENABLED
            ACME_ENABLED=${ACME_ENABLED:-false}
            
            # Construct full domains
            AUTH_DOMAIN="${AUTH_SUBDOMAIN}.${MAIN_DOMAIN}"
            JELLYFIN_DOMAIN="${JELLYFIN_SUBDOMAIN}.${MAIN_DOMAIN}"
            PLEX_DOMAIN="${PLEX_SUBDOMAIN}.${MAIN_DOMAIN}"
        fi
    else
        read -p "Media directory (NFS mount recommended) [/mnt/media]: " MEDIA_DIR
        MEDIA_DIR=${MEDIA_DIR:-/mnt/media}
        
        read -p "Docker subnet [172.23.0.0/16]: " DOCKER_SUBNET
        DOCKER_SUBNET=${DOCKER_SUBNET:-172.23.0.0/16}
        
        read -p "Docker gateway [172.23.0.1]: " DOCKER_GATEWAY
        DOCKER_GATEWAY=${DOCKER_GATEWAY:-172.23.0.1}
        
        read -p "Internal subnet [172.24.0.0/16]: " INTERNAL_SUBNET
        INTERNAL_SUBNET=${INTERNAL_SUBNET:-172.24.0.0/16}
        
        read -p "Internal gateway [172.24.0.1]: " INTERNAL_GATEWAY
        INTERNAL_GATEWAY=${INTERNAL_GATEWAY:-172.24.0.1}
        
        read -p "Local subnet (for VPN) [192.168.0.0/16]: " LOCAL_SUBNET
        LOCAL_SUBNET=${LOCAL_SUBNET:-192.168.0.0/16}
        
        echo ""
        echo -e "${YELLOW}Authentik worker configuration (connects to cloud):${NC}"
        read -p "Authentik Redis host (e.g., cloud-server.ts.net): " REDIS_HOST
        read -p "Authentik PostgreSQL host (e.g., cloud-server.ts.net): " POSTGRES_HOST
        
        echo ""
        echo -e "${YELLOW}VPN Configuration:${NC}"
        read -p "VPN service provider [custom]: " VPN_PROVIDER
        VPN_PROVIDER=${VPN_PROVIDER:-custom}
        read -p "VPN username: " VPN_USER
        read -sp "VPN password: " VPN_PASS
        echo ""
    fi
    
    echo ""
    echo -e "${YELLOW}Tailscale Configuration:${NC}"
    read -p "Tailscale auth key (required for tsdproxy): " TAILSCALE_KEY
    
    # Apply values to .env
    echo "Writing configuration..."
    
    sed -i "s|TIMEZONE=.*|TIMEZONE=${TIMEZONE}|g" "$ENV_FILE"
    sed -i "s|PUID=.*|PUID=${PUID}|g" "$ENV_FILE"
    sed -i "s|PGID=.*|PGID=${PGID}|g" "$ENV_FILE"
    sed -i "s|FOLDER_FOR_DATA=.*|FOLDER_FOR_DATA=${DATA_DIR}|g" "$ENV_FILE"
    sed -i "s|FOLDER_FOR_MEDIA=.*|FOLDER_FOR_MEDIA=${MEDIA_DIR}|g" "$ENV_FILE"
    sed -i "s|AUTHENTIK_SECRET_KEY=.*|AUTHENTIK_SECRET_KEY=${AUTHENTIK_SECRET}|g" "$ENV_FILE"
    sed -i "s|POSTGRESQL_PASSWORD=.*|POSTGRESQL_PASSWORD=${POSTGRES_PASSWORD}|g" "$ENV_FILE"
    sed -i "s|TAILSCALE_AUTH_KEY=.*|TAILSCALE_AUTH_KEY=${TAILSCALE_KEY}|g" "$ENV_FILE"
    
    if [ "$DEPLOY_MODE" = "cloud" ]; then
        sed -i "s|CLOUD_EXTERNAL_SUBNET=.*|CLOUD_EXTERNAL_SUBNET=${CLOUD_SUBNET}|g" "$ENV_FILE"
        sed -i "s|CLOUD_EXTERNAL_GATEWAY=.*|CLOUD_EXTERNAL_GATEWAY=${CLOUD_GATEWAY}|g" "$ENV_FILE"
        
        # Add domain configuration if provided
        if [ ! -z "$MAIN_DOMAIN" ]; then
            sed -i "s|# DOMAIN=.*|DOMAIN=${MAIN_DOMAIN}|g" "$ENV_FILE"
            sed -i "s|# AUTHENTIK_SUBDOMAIN=.*|AUTHENTIK_SUBDOMAIN=${AUTH_SUBDOMAIN}|g" "$ENV_FILE"
            sed -i "s|# JELLYFIN_SUBDOMAIN=.*|JELLYFIN_SUBDOMAIN=${JELLYFIN_SUBDOMAIN}|g" "$ENV_FILE"
            sed -i "s|# PLEX_SUBDOMAIN=.*|PLEX_SUBDOMAIN=${PLEX_SUBDOMAIN}|g" "$ENV_FILE"
            sed -i "s|# LETSENCRYPT_EMAIL=.*|LETSENCRYPT_EMAIL=${LETSENCRYPT_EMAIL}|g" "$ENV_FILE"
            sed -i "s|# TRAEFIK_ACME_ENABLED=.*|TRAEFIK_ACME_ENABLED=${ACME_ENABLED}|g" "$ENV_FILE"
            
            # Write full domain variables
            echo "AUTHENTIK_DOMAIN=${AUTH_DOMAIN}" >> "$ENV_FILE"
            echo "JELLYFIN_DOMAIN=${JELLYFIN_DOMAIN}" >> "$ENV_FILE"
            echo "PLEX_DOMAIN=${PLEX_DOMAIN}" >> "$ENV_FILE"
        fi
        sed -i "s|CLOUD_EXTERNAL_GATEWAY=.*|CLOUD_EXTERNAL_GATEWAY=${CLOUD_GATEWAY}|g" "$ENV_FILE"
    else
        sed -i "s|DOCKER_SUBNET=.*|DOCKER_SUBNET=${DOCKER_SUBNET}|g" "$ENV_FILE"
        sed -i "s|DOCKER_GATEWAY=.*|DOCKER_GATEWAY=${DOCKER_GATEWAY}|g" "$ENV_FILE"
        sed -i "s|INTERNAL_SUBNET=.*|INTERNAL_SUBNET=${INTERNAL_SUBNET}|g" "$ENV_FILE"
        sed -i "s|INTERNAL_GATEWAY=.*|INTERNAL_GATEWAY=${INTERNAL_GATEWAY}|g" "$ENV_FILE"
        sed -i "s|LOCAL_SUBNET=.*|LOCAL_SUBNET=${LOCAL_SUBNET}|g" "$ENV_FILE"
        sed -i "s|AUTHENTIK_REDIS_HOST=.*|AUTHENTIK_REDIS_HOST=${REDIS_HOST}|g" "$ENV_FILE"
        sed -i "s|AUTHENTIK_POSTGRESQL_HOST=.*|AUTHENTIK_POSTGRESQL_HOST=${POSTGRES_HOST}|g" "$ENV_FILE"
        sed -i "s|VPN_SERVICE_PROVIDER=.*|VPN_SERVICE_PROVIDER=${VPN_PROVIDER}|g" "$ENV_FILE"
        sed -i "s|VPN_USERNAME=.*|VPN_USERNAME=${VPN_USER}|g" "$ENV_FILE"
        sed -i "s|VPN_PASSWORD=.*|VPN_PASSWORD=${VPN_PASS}|g" "$ENV_FILE"
    fi
    
    echo -e "${GREEN}✓ .env file created successfully${NC}"
    echo -e "${YELLOW}Generated secrets have been written to .env${NC}"
}

# Function to create directories
create_directories() {
    echo -e "${BLUE}Creating data directories...${NC}"
    
    # Read data directory from .env
    DATA_DIR=$(grep "^FOLDER_FOR_DATA=" "${SCRIPT_DIR}/.env" | cut -d'=' -f2)
    
    if [ -z "$DATA_DIR" ]; then
        echo -e "${RED}Could not read FOLDER_FOR_DATA from .env${NC}"
        return
    fi
    
    sudo mkdir -p "$DATA_DIR"
    sudo chown -R $USER:$USER "$DATA_DIR"
    
    if [ "$DEPLOY_MODE" = "cloud" ]; then
        sudo mkdir -p "${DATA_DIR}"/{postgresql,valkey,authentik,jellyfin,plex,traefik,tsdproxy_hetzner,certs}
        sudo mkdir -p "${DATA_DIR}/authentik/media" "${DATA_DIR}/authentik/templates"
    else
        sudo mkdir -p "${DATA_DIR}"/{gluetun,authentik,bazarr,jellyseerr,filebot,lidarr,mylar,prowlarr,radarr,readarr,sabnzbd,sonarr,qbittorrent,tsdproxy_arr,certs}
    fi
    
    sudo chown -R $USER:$USER "$DATA_DIR"
    echo -e "${GREEN}✓ Directories created${NC}"
}

# Function to validate configuration
validate_config() {
    echo -e "${BLUE}Validating Docker Compose configuration...${NC}"
    
    cd "$SCRIPT_DIR"
    if docker compose -f "$COMPOSE_FILE" --env-file .env config > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Configuration is valid${NC}"
        return 0
    else
        echo -e "${RED}✗ Configuration validation failed${NC}"
        echo "Run: docker compose -f $COMPOSE_FILE --env-file .env config"
        return 1
    fi
}

# Function to display next steps
show_next_steps() {
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   Setup Complete!                         ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ "$DEPLOY_MODE" = "cloud" ]; then
        echo -e "${BLUE}Next steps for CLOUD deployment:${NC}"
        echo "1. Copy Traefik config files to data directory:"
        echo "   cp traefik.yaml ${DATA_DIR}/traefik/"
        echo "   cp traefik-config.yaml ${DATA_DIR}/traefik/config.yaml"
        echo ""
        echo "2. Create acme.json for Let's Encrypt:"
        echo "   touch ${DATA_DIR}/traefik/acme.json"
        echo "   chmod 600 ${DATA_DIR}/traefik/acme.json"
        echo ""
        echo "3. Review and edit .env if needed:"
        echo "   nano .env"
        echo ""
        echo "4. Configure your DNS records to point to this server:"
        echo "   auth.yourdomain.com → $(hostname -I | awk '{print $1}')"
        echo "   jellyfin.yourdomain.com → $(hostname -I | awk '{print $1}')"
        echo "   plex.yourdomain.com → $(hostname -I | awk '{print $1}')"
        echo ""
        echo "5. Start the stack:"
        echo "   docker compose -f cloud-compose.yaml up -d"
        echo ""
        echo "6. Check logs:"
        echo "   docker compose -f cloud-compose.yaml logs -f traefik"
        echo ""
        echo "7. Access services via HTTPS:"
        echo "   https://<your-domain-for-authentik>"
        echo "   https://<your-domain-for-jellyfin>"
        echo "   https://<your-domain-for-plex>"
        echo ""
        echo "8. Complete Authentik initial setup:"
        echo "   Navigate to: http://<your-server-ip>:9000/if/flow/initial-setup/"
        echo "   IMPORTANT: Include the trailing forward slash at the end of the URL"
        echo "   The URL must be exactly: http://<your-server-ip>:9000/if/flow/initial-setup/"
        echo ""
        echo "9. Configure Tailscale and connect home server"
    else
        echo -e "${BLUE}Next steps for HOME deployment:${NC}"
        echo "1. Ensure cloud stack is running first"
        echo ""
        echo "2. Review and edit .env if needed:"
        echo "   nano .env"
        echo ""
        echo "3. Add OpenVPN config if using custom VPN:"
        echo "   Place your .ovpn file in ${DATA_DIR}/gluetun/"
        echo ""
        echo "4. Mount your NAS (if using external storage):"
        echo "   Edit /etc/fstab for NFSv4 mount to ${MEDIA_DIR}"
        echo ""
        echo "5. Start the stack:"
        echo "   docker compose -f home-compose.yaml up -d"
        echo ""
        echo "6. Check logs:"
        echo "   docker compose -f home-compose.yaml logs -f"
        echo ""
        echo "7. Access services via Tailscale or local ports"
    fi
    
    echo ""
    echo -e "${YELLOW}Important:${NC}"
    echo "- Keep your .env file secure (contains secrets)"
    echo "- Regular backups recommended for ${DATA_DIR}"
    echo "- Review compose file ports and adjust firewall rules"
}

# Main execution
main() {
    echo "Starting setup process..."
    echo ""
    
    # Check/Install Git
    if ! check_git; then
        read -p "Install Git now? [Y/n]: " INSTALL_GIT
        if [[ ! $INSTALL_GIT =~ ^[Nn]$ ]]; then
            install_git
        else
            echo -e "${RED}Git is required. Exiting.${NC}"
            exit 1
        fi
    fi
    
    # Check/Install Docker
    if ! check_docker; then
        read -p "Install Docker now? [Y/n]: " INSTALL_DOCKER
        if [[ ! $INSTALL_DOCKER =~ ^[Nn]$ ]]; then
            install_docker
        else
            echo -e "${RED}Docker is required. Exiting.${NC}"
            exit 1
        fi
    fi
    
    # Check Docker Compose plugin or standalone binary
    if docker compose version &> /dev/null; then
        :
    elif docker-compose version &> /dev/null; then
        echo -e "${YELLOW}Using docker-compose standalone binary${NC}"
        alias docker="docker-compose"
    else
        echo -e "${RED}Docker Compose not found${NC}"
        exit 1
    fi
    
    # Select deployment type
    select_deployment_type
    
    # Create .env file
    create_env_file
    
    # Create directories
    create_directories
    
    # Validate configuration
    validate_config
    
    # Show next steps
    show_next_steps
    
    echo ""
    read -p "Start the stack now? [y/N]: " START_NOW
    if [[ $START_NOW =~ ^[Yy]$ ]]; then
        cd "$SCRIPT_DIR"
        docker compose -f "$COMPOSE_FILE" up -d
        echo ""
        echo -e "${GREEN}Stack started successfully!${NC}"
        docker compose -f "$COMPOSE_FILE" ps
    fi
}

# Run main function
main
