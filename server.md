# Deploy en Gigalixir

## Requisitos previos

1. Tener Python instalado (para el CLI de Gigalixir)
2. Tener Git configurado

## Instalación del CLI

```bash
pip install gigalixir
```

## Pasos para deploy

### 1. Login en Gigalixir

```bash
gigalixir login
```

### 2. Crear la app

```bash
gigalixir create
```

Esto te dará un nombre aleatorio como `bold-red-butterfly`. Guárdalo.

### 3. Crear la base de datos (free tier)

```bash
gigalixir pg:create --free
```

Esto configura `DATABASE_URL` automáticamente.

### 4. Configurar variables de entorno

```bash
# Generar y configurar SECRET_KEY_BASE
gigalixir config:set SECRET_KEY_BASE=$(mix phx.gen.secret)

# Configurar el host (usa el nombre de tu app)
gigalixir config:set PHX_HOST=tu-app-name.gigalixirapp.com

# Pool size para free tier (máximo 2 conexiones)
gigalixir config:set POOL_SIZE=2

# Configurar email (Brevo)
gigalixir config:set BREVO_API_KEY=tu-api-key
gigalixir config:set MAILER_FROM_EMAIL=noreply@tudominio.com
gigalixir config:set MAILER_FROM_NAME=PuenteApp
```

### 5. Deploy

```bash
git push gigalixir main
```

### 6. Ejecutar migraciones

```bash
gigalixir run mix ecto.migrate
```

## Comandos útiles

```bash
# Ver apps
gigalixir apps

# Ver configuración
gigalixir config

# Ver logs
gigalixir logs

# Abrir consola remota
gigalixir ps:remote_console

# Ver estado de la app
gigalixir ps
```

## Variables de entorno requeridas

| Variable | Descripción | Configuración |
|----------|-------------|---------------|
| `DATABASE_URL` | URL de PostgreSQL | Automático con `pg:create` |
| `SECRET_KEY_BASE` | Clave secreta | `mix phx.gen.secret` |
| `PHX_HOST` | Dominio de la app | `tu-app.gigalixirapp.com` |
| `POOL_SIZE` | Conexiones a DB | `2` (free tier) |
| `BREVO_API_KEY` | API key de Brevo | Tu API key |
| `MAILER_FROM_EMAIL` | Email remitente | Tu email verificado |
| `MAILER_FROM_NAME` | Nombre remitente | `PuenteApp` |

## Limitaciones del free tier

- 1 instancia con 0.2GB de memoria
- Base de datos: 2 conexiones, 10,000 filas, sin backups
- Si no deployeas en 30 días, pueden escalar a 0 réplicas
- Filesystem efímero (uploads se pierden en cada deploy)

## Archivos de configuración

El proyecto incluye `elixir_buildpack.config` con:
```
elixir_version=1.18.1
erlang_version=27.0
```

## Referencias

- [Gigalixir - Getting Started](https://www.gigalixir.com/docs/getting-started-guide/)
- [Gigalixir - Tiers & Pricing](https://www.gigalixir.com/docs/tiers-pricing)
- [Phoenix Docs - Deploying on Gigalixir](https://hexdocs.pm/phoenix/gigalixir.html)
