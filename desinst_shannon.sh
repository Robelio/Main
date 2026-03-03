#!/bin/bash

# =============================================================================
# Script de Desinstalacao Completa do Shannon Lite
# Sistema: Ubuntu 22.04 (maquina local)
# Remove: containers, imagens, volumes, redes, arquivos e dados
# =============================================================================

# --- Cores para mensagens no terminal ---
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
AZUL='\033[0;34m'
RESET='\033[0m'

# --- Funcoes auxiliares ---
info()    { echo -e "${AZUL}[INFO]${RESET} $1"; }
sucesso() { echo -e "${VERDE}[OK]${RESET} $1"; }
aviso()   { echo -e "${AMARELO}[AVISO]${RESET} $1"; }
erro()    { echo -e "${VERMELHO}[ERRO]${RESET} $1"; exit 1; }

# =============================================================================
echo ""
echo -e "${VERMELHO}=================================================${RESET}"
echo -e "${VERMELHO}   Desinstalacao Completa do Shannon Lite        ${RESET}"
echo -e "${VERMELHO}=================================================${RESET}"
echo ""

# --- Confirmacao do usuario ---
echo -e "${AMARELO}ATENCAO:${RESET}"
echo "   Esta acao ira remover PERMANENTEMENTE:"
echo "   - Todos os containers do Shannon"
echo "   - Todas as imagens Docker do Shannon"
echo "   - Todos os volumes e dados de sessoes"
echo "   - Todos os arquivos do repositorio shannon/"
echo "   - Redes Docker criadas pelo Shannon"
echo ""
echo -e "${VERMELHO}Esta acao NAO pode ser desfeita!${RESET}"
echo ""
read -rp "Tem certeza que deseja continuar? (digite 'sim' para confirmar): " CONFIRMA
if [[ "$CONFIRMA" != "sim" ]]; then
  echo ""
  aviso "Desinstalacao cancelada pelo usuario."
  exit 0
fi

# =============================================================================
# ETAPA 1 - Parar o Shannon se estiver rodando
# =============================================================================
echo ""
info "Etapa 1/6 - Parando o Shannon Lite..."

if [ -d "$HOME/shannon" ]; then
  cd "$HOME/shannon" || true
  if [ -f "./shannon" ]; then
    sudo ./shannon stop CLEAN=true 2>/dev/null && sucesso "Shannon parado com sucesso." || aviso "Shannon ja estava parado ou nao foi possivel parar normalmente."
  fi
else
  aviso "Pasta shannon/ nao encontrada. Pulando etapa."
fi

# =============================================================================
# ETAPA 2 - Parar e remover containers relacionados ao Shannon
# =============================================================================
echo ""
info "Etapa 2/6 - Removendo containers Docker do Shannon..."

CONTAINERS=$(sudo docker ps -a --filter "name=shannon" --format "{{.ID}}" 2>/dev/null)
if [ -n "$CONTAINERS" ]; then
  sudo docker stop $CONTAINERS 2>/dev/null
  sudo docker rm -f $CONTAINERS 2>/dev/null
  sucesso "Containers removidos."
else
  aviso "Nenhum container do Shannon encontrado."
fi

# =============================================================================
# ETAPA 3 - Remover imagens Docker do Shannon
# =============================================================================
echo ""
info "Etapa 3/6 - Removendo imagens Docker do Shannon..."

IMAGENS=$(sudo docker images --filter "reference=*shannon*" --format "{{.ID}}" 2>/dev/null)
if [ -n "$IMAGENS" ]; then
  sudo docker rmi -f $IMAGENS 2>/dev/null
  sucesso "Imagens removidas."
else
  aviso "Nenhuma imagem do Shannon encontrada."
fi

# Remover imagens sem tag (dangling) geradas pelo Shannon
sudo docker image prune -f 2>/dev/null
sucesso "Imagens temporarias limpas."

# =============================================================================
# ETAPA 4 - Remover volumes Docker do Shannon
# =============================================================================
echo ""
info "Etapa 4/6 - Removendo volumes e dados do Shannon..."

VOLUMES=$(sudo docker volume ls --filter "name=shannon" --format "{{.Name}}" 2>/dev/null)
if [ -n "$VOLUMES" ]; then
  sudo docker volume rm -f $VOLUMES 2>/dev/null
  sucesso "Volumes removidos."
else
  aviso "Nenhum volume do Shannon encontrado."
fi

# Remover volumes nao utilizados
sudo docker volume prune -f 2>/dev/null
sucesso "Volumes orfaos limpos."

# =============================================================================
# ETAPA 5 - Remover redes Docker do Shannon
# =============================================================================
echo ""
info "Etapa 5/6 - Removendo redes Docker do Shannon..."

REDES=$(sudo docker network ls --filter "name=shannon" --format "{{.ID}}" 2>/dev/null)
if [ -n "$REDES" ]; then
  sudo docker network rm $REDES 2>/dev/null
  sucesso "Redes removidas."
else
  aviso "Nenhuma rede do Shannon encontrada."
fi

# =============================================================================
# ETAPA 6 - Remover arquivos do Shannon
# =============================================================================
echo ""
info "Etapa 6/6 - Removendo arquivos do Shannon..."

if [ -d "$HOME/shannon" ]; then
  rm -rf "$HOME/shannon"
  sucesso "Pasta shannon/ removida com sucesso."
else
  aviso "Pasta shannon/ nao encontrada. Nada a remover."
fi

# =============================================================================
# CONCLUSAO
# =============================================================================
echo ""
echo -e "${VERDE}=================================================${RESET}"
echo -e "${VERDE}   Shannon Lite removido completamente!          ${RESET}"
echo -e "${VERDE}=================================================${RESET}"
echo ""
echo "O que foi removido:"
echo "   - Containers Docker do Shannon"
echo "   - Imagens Docker do Shannon"
echo "   - Volumes e dados de sessoes"
echo "   - Redes Docker do Shannon"
echo "   - Arquivos do repositorio shannon/"
echo ""
echo -e "${AMARELO}Observacao:${RESET} O Docker em si NAO foi removido do sistema."
echo "Se deseja remover o Docker tambem, execute:"
echo -e "${AZUL}  sudo apt purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y${RESET}"
echo -e "${AZUL}  sudo rm -rf /var/lib/docker /etc/docker${RESET}"
echo ""
