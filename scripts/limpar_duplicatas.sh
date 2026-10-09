#!/bin/bash
# Uso: ./limpar_duplicatas.sh          → dry-run (só lista)
#      ./limpar_duplicatas.sh --exec   → executa (com backup)

set -e
BASE="/root/click2call/www"
LOG="/tmp/limpeza_$(date +%Y%m%d_%H%M%S).log"
BACKUP="/root/click2call/_backup_duplicatas_$(date +%Y%m%d_%H%M%S)"

EXECUTAR=false
[ "$1" == "--exec" ] && EXECUTAR=true

echo "===========================================" | tee "$LOG"
echo " Base: $BASE"                              | tee -a "$LOG"
echo " Modo: $([ $EXECUTAR = true ] && echo EXECUTAR || echo DRY-RUN)" | tee -a "$LOG"
echo " Log:  $LOG"                               | tee -a "$LOG"
echo "===========================================" | tee -a "$LOG"

# ---- Função: mostra tamanho + decide ----
processar() {
  local alvo="$1"
  local motivo="$2"
  if [ -e "$alvo" ]; then
    local tam=$(du -sh "$alvo" 2>/dev/null | cut -f1)
    echo "[$motivo] $tam  $alvo" | tee -a "$LOG"
    if [ "$EXECUTAR" = true ]; then
      mkdir -p "$BACKUP/$(dirname "${alvo#$BASE/}")"
      mv "$alvo" "$BACKUP/${alvo#$BASE/}"
    fi
  fi
}

echo "" | tee -a "$LOG"
echo "=== 1. Cópia inteira do projeto ===" | tee -a "$LOG"
processar "$BASE/c2c/clicktocall" "DUPLICATA-PROJETO"

echo "" | tee -a "$LOG"
echo "=== 2. info.php.old ===" | tee -a "$LOG"
processar "$BASE/info.php.old" "ARQUIVO-OLD"

echo "" | tee -a "$LOG"
echo "=== 3. Arquivos '- Cópia' ===" | tee -a "$LOG"
while IFS= read -r f; do processar "$f" "COPIA"; done < <(
  find "$BASE" -type f -name "*Cópia*" 2>/dev/null
)

echo "" | tee -a "$LOG"
echo "=== 4. Arquivos .old / .old2 / -old ===" | tee -a "$LOG"
while IFS= read -r f; do processar "$f" "OLD"; done < <(
  find "$BASE" -type f \( -name "*.old" -o -name "*.old2*" -o -name "*-old.php" \) 2>/dev/null
)

echo "" | tee -a "$LOG"
echo "=== 5. config.ini duplicado (conf/) ===" | tee -a "$LOG"
if [ -f "$BASE/c2c/conf/config.ini" ] && [ -f "$BASE/c2c/classes/config.ini" ]; then
  if diff -q "$BASE/c2c/conf/config.ini" "$BASE/c2c/classes/config.ini" >/dev/null; then
    echo "[IGUAIS] config.ini — seguro remover conf/config.ini" | tee -a "$LOG"
    processar "$BASE/c2c/conf/config.ini" "CONFIG-DUP"
  else
    echo "[DIFERENTES] conf/config.ini ≠ classes/config.ini — NÃO removido" | tee -a "$LOG"
  fi
else
  echo "[SKIP] um dos config.ini não existe" | tee -a "$LOG"
fi

echo "" | tee -a "$LOG"
echo "=== 6. toCall*.php — apenas comparação ===" | tee -a "$LOG"
for f in toCall1-old.php toCall1.php.old toCall_old.php; do
  a="$BASE/c2c/paineloperadora/$f"
  b="$BASE/c2c/paineloperadora/toCall1.php"
  if [ -f "$a" ] && [ -f "$b" ]; then
    if diff -q "$a" "$b" >/dev/null; then
      echo "[IGUAL] $a == toCall1.php" | tee -a "$LOG"
      processar "$a" "TOCALL-OLD"
    else
      echo "[DIFERENTE] $a ≠ toCall1.php — revisar manualmente" | tee -a "$LOG"
    fi
  fi
done

echo "" | tee -a "$LOG"
echo "===========================================" | tee -a "$LOG"
if [ "$EXECUTAR" = true ]; then
  echo " ✅ CONCLUÍDO — backup em: $BACKUP" | tee -a "$LOG"
else
  echo " ℹ️  DRY-RUN — nada foi alterado." | tee -a "$LOG"
  echo " Para executar: $0 --exec" | tee -a "$LOG"
fi
echo "===========================================" | tee -a "$LOG"