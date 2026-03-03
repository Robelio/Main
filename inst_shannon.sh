#!/bin/bash

# =============================================================================
# Script de Instalação Automática do Shannon Lite v2.0
# Sistema: Ubuntu 22.04 (máquina local)
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
    sucesso "$1 ja esta instalado: $(command -v $1)"
    return 0
  fi
  return 1
}

# =============================================================================
echo ""
echo -e "${AZUL}=================================================${RESET}"
echo -e "${AZUL}   Instalacao Automatica do Shannon Lite v2.0    ${RESET}"
echo -e "${AZUL}=================================================${RESET}"
echo ""

# --- Aviso de uso responsavel ---
echo -e "${AMARELO}AVISO IMPORTANTE:${RESET}"
echo "   O Shannon Lite e uma ferramenta de pentest com IA."
echo "   Use SOMENTE em sistemas com autorizacao explicita."
echo "   O uso indevido pode ser ilegal."
echo ""
read -rp "Voce confirma que tem autorizacao para uso? (s/n): " CONFIRMA
if [[ "$CONFIRMA" != "s" && "$CONFIRMA" != "S" ]]; then
  erro "Instalacao cancelada pelo usuario."
fi

# =============================================================================
# ETAPA 1 - Atualizar o sistema
# =============================================================================
echo ""
info "Etapa 1/8 - Atualizando o sistema..."
sudo apt update && sudo apt upgrade -y || erro "Falha ao atualizar o sistema."
sucesso "Sistema atualizado."

# =============================================================================
# ETAPA 2 - Instalar Git e Make
# =============================================================================
echo ""
info "Etapa 2/8 - Instalando Git e Make..."

if ! verificar_comando git; then
  sudo apt install git -y || erro "Falha ao instalar o Git."
  sucesso "Git instalado."
fi

if ! verificar_comando make; then
  sudo apt install make -y || erro "Falha ao instalar o Make."
  sucesso "Make instalado."
fi

# =============================================================================
# ETAPA 3 - Instalar Docker
# =============================================================================
echo ""
info "Etapa 3/8 - Instalando o Docker..."

if verificar_comando docker; then
  aviso "Docker ja esta instalado. Pulando esta etapa."
else
  sudo apt install ca-certificates curl gnupg -y || erro "Falha ao instalar dependencias do Docker."

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

# --- Adicionar usuario ao grupo docker ---
info "Configurando permissoes do Docker para o usuario atual..."
sudo usermod -aG docker "$USER"
newgrp docker
sucesso "Usuario adicionado ao grupo docker."

# =============================================================================
# ETAPA 4 - Clonar o repositorio do Shannon
# =============================================================================
echo ""
info "Etapa 4/8 - Clonando o repositorio do Shannon Lite..."

if [ -d "shannon" ]; then
  aviso "Pasta 'shannon' ja existe. Pulando clone."
  cd shannon || erro "Nao foi possivel acessar a pasta 'shannon'."
else
  git clone https://github.com/KeygraphHQ/shannon.git || erro "Falha ao clonar o repositorio."
  cd shannon || erro "Nao foi possivel acessar a pasta 'shannon'."
  sucesso "Repositorio clonado com sucesso."
fi

# =============================================================================
# ETAPA 5 - Configurar o arquivo .env
# =============================================================================
echo ""
info "Etapa 5/8 - Configurando o arquivo .env..."

if [ ! -f ".env.example" ]; then
  erro "Arquivo .env.example nao encontrado. Verifique se o repositorio foi clonado corretamente."
fi

cp .env.example .env || erro "Falha ao criar o arquivo .env."
sucesso "Arquivo .env criado a partir do .env.example."

# =============================================================================
# ETAPA 6 - Configurar a chave de API
# =============================================================================
echo ""
info "Etapa 6/8 - Configurando a chave de API..."
echo ""
echo "Escolha o provedor de LLM:"
echo "  1) Anthropic (Claude)"
echo "  2) OpenAI (GPT)"
echo "  3) OpenRouter (Gratuito via Gemini)"
echo ""
read -rp "Digite 1, 2 ou 3: " PROVEDOR

case "$PROVEDOR" in
  1)
    read -rp "Cole sua chave Anthropic (sk-ant-...): " API_KEY
    sed -i "s|ANTHROPIC_API_KEY=.*|ANTHROPIC_API_KEY=$API_KEY|" .env 2>/dev/null || \
      echo "ANTHROPIC_API_KEY=$API_KEY" >> .env
    sucesso "Chave Anthropic salva no arquivo .env"
    ;;
  2)
    read -rp "Cole sua chave OpenAI (sk-proj-...): " API_KEY
    sed -i "s|OPENAI_API_KEY=.*|OPENAI_API_KEY=$API_KEY|" .env 2>/dev/null || \
      echo "OPENAI_API_KEY=$API_KEY" >> .env
    sucesso "Chave OpenAI salva no arquivo .env"
    ;;
  3)
    read -rp "Cole sua chave OpenRouter (sk-or-v1-...): " API_KEY
    sed -i "s|OPENROUTER_API_KEY=.*|OPENROUTER_API_KEY=$API_KEY|" .env 2>/dev/null || \
      echo "OPENROUTER_API_KEY=$API_KEY" >> .env
    echo "OPENROUTER_MODEL=google/gemini-flash-1.5" >> .env
    sucesso "Chave OpenRouter + Gemini Flash salva no arquivo .env"
    ;;
  *)
    erro "Opcao invalida. Execute o script novamente e escolha 1, 2 ou 3."
    ;;
esac

# =============================================================================
# ETAPA 7 - Criar pasta repos e clonar projeto alvo (opcional)
# =============================================================================
echo ""
info "Etapa 7/8 - Configurando pasta de repositorios..."

mkdir -p repos
sucesso "Pasta 'repos' criada."

echo ""
echo "Deseja clonar agora o repositorio do projeto que sera testado?"
read -rp "Digite a URL do repositorio (ou pressione Enter para pular): " REPO_URL

if [ -n "$REPO_URL" ]; then
  read -rp "Digite o nome da pasta (ex: meu-projeto): " REPO_NOME
  git clone "$REPO_URL" "./repos/$REPO_NOME" || aviso "Falha ao clonar o repositorio alvo. Clone manualmente depois em ./repos/"
  sucesso "Repositorio '$REPO_NOME' clonado em ./repos/"
  REPO_CONFIGURADO=$REPO_NOME
else
  aviso "Pulando clone do repositorio alvo. Clone manualmente em ./repos/ antes de iniciar."
  REPO_CONFIGURADO=""
fi

# =============================================================================
# ETAPA 8 - Iniciar o Shannon Lite
# =============================================================================
echo ""
info "Etapa 8/8 - Iniciando o Shannon Lite..."
aviso "Na primeira execucao, o Docker vai baixar as imagens necessarias."
aviso "Isso pode demorar alguns minutos dependendo da sua conexao."
echo ""

if [ -n "$REPO_CONFIGURADO" ]; then
  read -rp "Digite a URL do app a ser testado (ex: https://meu-app.com): " APP_URL
  echo ""
  info "Iniciando Shannon com: URL=$APP_URL REPO=$REPO_CONFIGURADO"
  ./shannon start "URL=$APP_URL" "REPO=$REPO_CONFIGURADO" || erro "Falha ao iniciar o Shannon Lite."
else
  aviso "Shannon nao iniciado automaticamente pois nenhum repositorio foi configurado."
  echo ""
  echo "Quando estiver pronto, inicie manualmente com:"
  echo -e "${VERDE}  ./shannon start URL=https://seu-app.com REPO=nome-da-pasta-em-repos${RESET}"
fi

# =============================================================================
echo ""
echo -e "${VERDE}=================================================${RESET}"
echo -e "${VERDE}   Shannon Lite instalado com sucesso!           ${RESET}"
echo -e "${VERDE}=================================================${RESET}"
echo ""
echo -e "Comandos uteis:"
echo "   Iniciar:        ./shannon start URL=https://app.com REPO=nome-repo"
echo "   Ver logs:       ./shannon logs"
echo "   Parar:          ./shannon stop"
echo "   Parar e limpar: ./shannon stop CLEAN=true"
echo ""
echo -e "${AMARELO}Lembre-se:${RESET} Use apenas em ambientes autorizados."
echo ""
