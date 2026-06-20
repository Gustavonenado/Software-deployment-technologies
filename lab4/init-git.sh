#!/bin/bash
# Ініціалізація Git репозиторію для Lab4

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Ініціалізація Git Репозиторію            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""

# Перевірити чи вже ініціалізовано
if [ -d .git ]; then
    echo -e "${YELLOW}Git репозиторій вже існує${NC}"
    git status
    exit 0
fi

# Ініціалізувати Git
echo "Ініціалізація Git..."
git init

echo ""
echo "Налаштування Git користувача..."
read -p "Введіть ваше ім'я для Git: " git_name
read -p "Введіть ваш email для Git: " git_email

git config user.name "$git_name"
git config user.email "$git_email"

echo ""
echo "Додавання файлів..."
git add .

echo ""
echo "Перший коміт..."
git commit -m "Lab4: IaC with Terraform and Ansible - Initial commit

- Terraform конфіги для 2 ВМ (worker + db)
- Ansible playbook з 3 ролями
- Документація та скрипти розгортання
- Студент: Варіант N=10"

echo ""
echo -e "${GREEN}✓ Git репозиторій готовий${NC}"
echo ""
echo "Наступні кроки:"
echo "  1. Створити репозиторій на GitHub (Settings → Create repository)"
echo "  2. Скопіювати URL"
echo "  3. Додати remote:"
echo "     git remote add origin <URL>"
echo "  4. Відправити на GitHub:"
echo "     git branch -M main"
echo "     git push -u origin main"
echo ""
echo "Статус репозиторію:"
git status
