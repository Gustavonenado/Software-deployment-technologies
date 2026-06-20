#!/bin/bash
# Скрипт для видалення ВМ та очистки ресурсів

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}╔════════════════════════════════════════════╗${NC}"
echo -e "${RED}║  ВИДАЛЕННЯ ВМ та Ресурсів                 ║${NC}"
echo -e "${RED}╚════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}⚠️  ПОПЕРЕДЖЕННЯ: Це видалить ВСІ ВМ та дані!${NC}"
echo ""
read -p "Ви впевнені? (type 'yes' для підтвердження): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Скасовано"
    exit 0
fi

echo ""
echo -e "${RED}Видалення ВМ...${NC}"

cd terraform

echo "Запуск: terraform destroy"
terraform destroy -auto-approve

echo ""
echo -e "${GREEN}✓ ВМ видалені${NC}"

echo ""
echo "Видалення локальних файлів..."
rm -f inventory.tfstate inventory.tfstate.backup .terraform.lock.hcl

echo -e "${GREEN}✓ Очистка завершена${NC}"
echo ""
echo "Для повного видалення Terraform state:"
echo "  rm -rf .terraform/"
echo ""
