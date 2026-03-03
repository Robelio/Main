#!/bin/bash

# =============================================================================
# Script de Instalação Automática do Shannon Lite
# Sistema: Ubuntu / Debian
# =============================================================================

# --- Cores para mensagens no terminal ---
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
AZUL='\033[0;34m'
RESET='\033[0m'

# --- Funções auxiliares ---
info()    { echo -e "${AZUL}[INFO]${RESET} $1"; }
sucesso() { echo -e "${VERDE}[OK]${RESET} $1"; }
aviso()   { echo -e "${AMARELO}[AVISO]${RESET} $1"; }
erro()    { echo -e "${VERMELHO}[ERRO]${RESET} $1"; exit 1; }

verificar_comando() {
  if command -v "$1" &>/dev/null; then
    sucesso "$1 já está instalado: $(command -v $1)"
    return 0
  fi
  return 1
}

# =============================================================================
echo ""
echo -e "${AZUL}=================================================${RESET}"
echo -e "${AZUL}   Instalação Automática do Shannon Lite         ${RESET}"
echo -e "${AZUL}=================================================${RESET}"
echo ""

# --- Aviso de uso responsável ---
echo -e "${AMARELO}⚠️  AVISO IMPORTANTE:${RESET}"
echo "   O Shannon Lite é uma ferramenta de pentest com IA."
echo "   Use SOMENTE em sistemas com autorização explícita."
echo "   O uso indevido pode ser ilegal."
echo ""
read -rp "Você confirma que tem autorização para uso? (s/n): " CONFIRMA
if [[ "$CONFIRMA" != "s" && "$CONFIRMA" != "S" ]]; then
  erro "Instalação cancelada pelo usuário."
fi

# =============================================================================
# ETAPA 1 — Atualizar o sistema
# =============================================================================
echo ""
info "Etapa 1/8 — Atualizando o sistema..."
sudo apt update && sudo apt upgrade -y || erro "Falha ao atualizar o sistema."
sucesso "Sistema atualizado."

# =============================================================================
# ETAPA 2 — Instalar Git e Make
# =============================================================================
echo ""
info "Etapa 2/8 — Instalando Git e Make..."

if ! verificar_comando git; then
  sudo apt install git -y || erro "Falha ao instalar o Git."
  sucesso "Git instalado."
fi

if ! verificar_comando make; then
  sudo apt install make -y || erro "Falha ao instalar o Make."
  sucesso "Make instalado."
fi

# =============================================================================
# ETAPA 3 — Instalar Docker
# =============================================================================
echo ""
info "Etapa 3/8 — Instalando o Docker..."

if verificar_comando docker; then
  aviso "Docker já está instalado. Pulando esta etapa."
else
  sudo apt install ca-certificates curl gnupg -y || erro "Falha ao instalar dependências do Docker."

  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt update
  sudo apt install docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin -y || erro "Falha ao instalar o Docker."

  sucesso "Docker instalado."
fi

# --- Adicionar usuário ao grupo docker ---
info "Configurando permissões do Docker para o usuário atual..."
sudo usermod -aG docker "$USER"
sucesso "Usuário adicionado ao grupo docker."

# =============================================================================
# ETAPA 4 — Clonar o repositório do Shannon
# =============================================================================
echo ""
info "Etapa 4/8 — Clonando o repositório do Shannon Lite..."

if [ -d "shannon" ]; then
  aviso "Pasta 'shannon' já existe. Pulando clone."
  cd shannon || erro "Não foi possível acessar a pasta 'shannon'."
else
  git clone https://github.com/KeygraphHQ/shannon.git || erro "Falha ao clonar o repositório."
  cd shannon || erro "Não foi possível acessar a pasta 'shannon'."
  sucesso "Repositório clonado com sucesso."
fi

# =============================================================================
# ETAPA 5 — Configurar o ambiente
# =============================================================================
echo ""
info "Etapa 5/8 — Configurando o ambiente (make setup)..."
make setup || erro "Falha ao executar 'make setup'."
sucesso "Ambiente configurado."

# =============================================================================
# ETAPA 6 — Configurar a chave de API
# =============================================================================
echo ""
info "Etapa 6/8 — Configurando a chave de API..."
echo ""
echo "Escolha o provedor de LLM:"
echo "  1) OpenAI"
echo "  2) Anthropic"
echo ""
read -rp "Digite 1 ou 2: " PROVEDOR

case "$PROVEDOR" in
  1)
    read -rp "Cole sua chave OpenAI (sk-...): " API_KEY
    echo "OPENAI_API_KEY=$API_KEY" >> .env
    sucesso "Chave OpenAI salva no arquivo .env"
    ;;
  2)
    read -rp "Cole sua chave Anthropic (sk-ant-...): " API_KEY
    echo "ANTHROPIC_API_KEY=$API_KEY" >> .env
    sucesso "Chave Anthropic salva no arquivo .env"
    ;;
  *)
    erro "Opção inválida. Por favor, execute o script novamente e escolha 1 ou 2."
    ;;
esac

# =============================================================================
# ETAPA 7 — Baixar interpretador Python WASI
# =============================================================================
echo ""
info "Etapa 7/8 — Baixando o interpretador Python WASI..."
./scripts/setup_python_wasi.sh || erro "Falha ao configurar o Python WASI."
sucesso "Python WASI configurado."

# =============================================================================
# ETAPA 8 — Iniciar o Shannon Lite
# =============================================================================
echo ""
info "Etapa 8/8 — Iniciando o Shannon Lite..."
aviso "Na primeira execução, o Docker vai baixar as imagens necessárias."
aviso "Isso pode demorar alguns minutos dependendo da sua conexão."
echo ""
make dev || erro "Falha ao iniciar o Shannon Lite."

# =============================================================================
echo ""
echo -e "${VERDE}=================================================${RESET}"
echo -e "${VERDE}   ✅ Shannon Lite instalado e iniciado!          ${RESET}"
echo -e "${VERDE}=================================================${RESET}"
echo ""
echo -e "${AMARELO}Lembre-se:${RESET} Use apenas em ambientes autorizados."
echo ""
