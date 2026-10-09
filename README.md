# 📝 Etherpad — Editor Colaborativo Self-Hosted

Stack Docker Compose com **[Etherpad](https://etherpad.org/)** + **PostgreSQL**, pronta para produção.

Etherpad é um editor de texto colaborativo em tempo real, open-source, que permite várias pessoas editarem o mesmo documento simultaneamente.

---

## 📋 Índice

- [Requisitos](#-requisitos)
- [Estrutura do projeto](#-estrutura-do-projeto)
- [Instalação](#-instalação)
- [Configuração](#-configuração)
- [Utilização](#-utilização)
- [Manutenção](#-manutenção)
- [Backup e restauro](#-backup-e-restauro)
- [Idioma](#-idioma)
- [Segurança](#-segurança)
- [Troubleshooting](#-troubleshooting)

---

## ✅ Requisitos

- **Docker** ≥ 20.10
- **Docker Compose** ≥ 2.0 (plugin `docker compose`)
- Sistema operativo: Linux, macOS ou Windows (WSL2)
- Porta `9001` livre (ou outra à tua escolha)

Verificar:

```bash
docker --version
docker compose version
```

---

## 📁 Estrutura do projeto

```
etherpad/
├── docker-compose.yml    # Definição dos serviços
├── .env                  # Variáveis de ambiente (⚠️ NÃO versionar)
├── .gitignore            # Ignora .env e outros ficheiros sensíveis
└── README.md             # Este ficheiro
```

---

## 🚀 Instalação

### 1. Clonar / criar a pasta do projeto

```bash
mkdir -p ~/Projetos/etherpad
cd ~/Projetos/etherpad
```

### 2. Criar o `docker-compose.yml`

Copia o conteúdo do ficheiro `docker-compose.yml` (ver secção seguinte).

### 3. Criar o ficheiro `.env`

```bash
nano .env
```

Conteúdo mínimo (gera passwords fortes com `openssl rand -hex 32`):

```env
# ===== APP =====
APP_ADMIN_PASSWORD=substitui-por-password-forte
APP_PORT_PUBLISHED=9001
APP_PORT_TARGET=9001
APP_DB_CHARSET=utf8mb4
APP_DEFAULT_PAD_TEXT=
APP_DISABLE_IP_LOGGING=false
APP_SOFFICE=null
APP_TRUST_PROXY=false

# ===== POSTGRES =====
POSTGRES_DATABASE=etherpad
POSTGRES_USER=admin
POSTGRES_PASSWORD=substitui-por-outra-password-forte
POSTGRES_PORT=5432
```

> 💡 **Gerar passwords seguras:**
> ```bash
> openssl rand -hex 32
> ```
> Evita `+`, `/` e `=` nas passwords — podem causar problemas no Postgres.

### 4. Criar o `.gitignore`

```gitignore
.env
docker-compose.yml.old
*.log
```

### 5. Arrancar os contentores

```bash
docker compose up -d
```

### 6. Verificar

```bash
docker compose ps
docker compose logs -f app
```

Acede em: **http://localhost:9001**

---

## ⚙️ Configuração

### Variáveis de ambiente (`.env`)

| Variável | Descrição | Padrão |
|---|---|---|
| `APP_ADMIN_PASSWORD` | Password do admin do Etherpad | *(obrigatório)* |
| `APP_PORT_PUBLISHED` | Porta exposta no host | `9001` |
| `APP_PORT_TARGET` | Porta interna do Etherpad | `9001` |
| `APP_DB_CHARSET` | Charset da base de dados | `utf8mb4` |
| `APP_DEFAULT_PAD_TEXT` | Texto inicial de cada pad novo | *(vazio)* |
| `APP_DISABLE_IP_LOGGING` | Desativar logs de IP | `false` |
| `APP_SOFFICE` | Caminho para LibreOffice (`soffice`) | `null` |
| `APP_TRUST_PROXY` | Confiar em reverse proxy | `false` |
| `POSTGRES_DATABASE` | Nome da base de dados | `etherpad` |
| `POSTGRES_USER` | Utilizador do Postgres | `admin` |
| `POSTGRES_PASSWORD` | Password do Postgres | *(obrigatório)* |
| `POSTGRES_PORT` | Porta interna do Postgres | `5432` |

### Volumes persistentes

| Volume | Conteúdo |
|---|---|
| `postgres_data` | Dados da base de dados |
| `plugins` | Plugins instalados do Etherpad |
| `etherpad-var` | Variáveis internas e cache |

Para inspecionar:

```bash
docker volume ls
docker volume inspect etherpad_postgres_data
```

---

## 🎮 Utilização

### Comandos essenciais

```bash
# Arrancar em background
docker compose up -d

# Ver estado
docker compose ps

# Ver logs em tempo real
docker compose logs -f app
docker compose logs -f postgres

# Parar (mantém dados)
docker compose down

# Parar + apagar volumes (⚠️ apaga TUDO)
docker compose down -v

# Reiniciar
docker compose restart

# Atualizar imagens
docker compose pull
docker compose up -d --force-recreate
```

### Aceder ao Etherpad

- **URL:** http://localhost:9001
- **Admin:** http://localhost:9001/admin
- **Password de admin:** valor de `APP_ADMIN_PASSWORD` no `.env`

### Criar um pad

Basta aceder a `http://localhost:9001/p/nome-do-pad` — o pad é criado automaticamente.

---

## 🔧 Manutenção

### Atualizar o Etherpad

```bash
docker compose pull app
docker compose up -d app
```

### Instalar plugins

Acede a `http://localhost:9001/admin/plugins` como admin e instala pela interface.

Alternativa via CLI:

```bash
docker compose exec app pnpm run plugins install ep_headings2
docker compose restart app
```

### Ver uso de disco

```bash
docker system df -v
```

### Limpar imagens antigas

```bash
docker image prune -a
```

---

## 💾 Backup e restauro

### Backup da base de dados

```bash
docker compose exec -T postgres pg_dump -U admin etherpad > backup_$(date +%F).sql
```

### Restauro

```bash
cat backup_2026-01-01.sql | docker compose exec -T postgres psql -U admin etherpad
```

### Backup completo (inclui volumes)

```bash
docker run --rm \
  -v etherpad_postgres_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/postgres_data_$(date +%F).tar.gz -C /data .
```

### Automatizar com cron

```bash
# crontab -e
0 3 * * * cd /home/renato/Projetos/etherpad && docker compose exec -T postgres pg_dump -U admin etherpad > backups/backup_$(date +\%F).sql
```

---

## 🌍 Idioma

O Etherpad suporta várias línguas, incluindo **português do Brasil (`pt-br`)** e **português de Portugal (`pt`)**.

### Definir português como padrão

Adiciona ao `environment` do serviço `app` no `docker-compose.yml`:

```yaml
PAD_OPTIONS_LANG: "pt-br"
```

Depois:

```bash
docker compose up -d
```

### Alternativa — escolha do utilizador

Sem `PAD_OPTIONS_LANG`, o Etherpad deteta o idioma do navegador. O utilizador pode forçar manualmente:

```
http://localhost:9001/p/meu-pad?lang=pt-br
```

---

## 🔒 Segurança

- ⚠️ **Nunca** comitas o `.env` para o Git.
- 🔐 Usa passwords fortes (`openssl rand -hex 32`).
- 🌐 Para exposição pública, coloca um reverse proxy (Nginx / Traefik / Caddy) com **HTTPS**.
- 🛡️ Ativa `APP_TRUST_PROXY=true` se estiveres atrás de um proxy.
- 🚫 Não exponhas a porta do Postgres (`5432`) para fora.
- 🔄 Mantém as imagens atualizadas regularmente.

### Exemplo mínimo com Nginx + Let's Encrypt

Sugestão de stack adicional:

- **Nginx Proxy Manager** (`jc21/nginx-proxy-manager`)
- **Traefik** com `certresolver` Let's Encrypt
- **Caddy** (configuração mais simples)

---

## 🐛 Troubleshooting

### Erro: `required variable DOCKER_COMPOSE_APP_ADMIN_PASSWORD is missing`

Estás a usar um `docker-compose.yml` antigo. Confirma:

```bash
grep DOCKER_COMPOSE docker-compose.yml
```

Se aparecer algo, substitui o `docker-compose.yml` pela versão atual.

### Erro de autenticação no Postgres

Se a password tiver caracteres especiais (`+`, `/`, `=`), o Postgres pode falhar na primeira inicialização.

**Solução:** gera uma password só com hex:

```bash
openssl rand -hex 32
```

Depois:

```bash
docker compose down -v   # ⚠️ apaga dados antigos
docker compose up -d
```

### App arranca mas dá erro a ligar à DB

Verifica se o Postgres está `healthy`:

```bash
docker compose ps
```

O `app` só deve arrancar depois do Postgres estar pronto (controlado por `depends_on: condition: service_healthy`).

### Ver logs detalhados

```bash
docker compose logs --tail=200 app
docker compose logs --tail=200 postgres
```

### Reset total (perde dados)

```bash
docker compose down -v
docker system prune -a --volumes
docker compose up -d
```

---

## 📚 Referências

- [Etherpad — Site oficial](https://etherpad.org/)
- [Etherpad — Documentação](https://etherpad.org/doc/v1.9.0/)
- [Etherpad — Docker Hub](https://hub.docker.com/r/etherpad/etherpad)
- [PostgreSQL — Docker Hub](https://hub.docker.com/_/postgres)
- [Traduções (translatewiki)](https://translatewiki.net/wiki/Translating:Etherpad)

---

## 📄 Licença

Este projeto de configuração é disponibilizado como está. O Etherpad é licenciado sob **Apache License 2.0**.

---

**Autor:** Renato  
**Última atualização:** 2026