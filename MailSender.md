# Email Provider - Decisión Técnica

## Comparativa de Providers Gratuitos

| Provider | Emails Gratis | Límite Diario | Notas |
|----------|---------------|---------------|-------|
| **SendPulse** | 12,000/mes | - | El más generoso en cantidad |
| **Brevo** | ~9,000/mes | 300/día | CRM incluido, automations, templates |
| **Mailjet** | 6,000/mes | 200/día | GDPR-friendly, buen deliverability (85%) |
| **Mailtrap** | 3,500/mes | - | Ideal para testing + envío |
| **Resend** | 3,000/mes | 100/día | API moderna, excelente DX |
| **SendGrid** | ~3,000/mes | 100/día | Establecido pero costoso al escalar |

## Decisión: Brevo

Elegimos **Brevo** (anteriormente Sendinblue) por las siguientes razones:

### 1. Balance cantidad/funcionalidades
- 300 emails/día (~9,000/mes) es suficiente para nuestra escala inicial
- Más generoso que SendGrid y Resend en el tier gratuito

### 2. Funcionalidades incluidas en el plan gratuito
- **CRM integrado**: Gestión de contactos sin costo adicional
- **Templates de email**: Editor visual para crear emails
- **Automations**: Flujos automatizados básicos
- **Analytics**: Métricas de apertura, clicks, bounces

### 3. Cumplimiento GDPR
- Empresa francesa con servidores en EU
- Ideal para manejar datos de usuarios argentinos con estándares europeos

### 4. Integración con Phoenix/Swoosh
- Adaptador oficial: `Swoosh.Adapters.Brevo`
- Documentación clara y bien mantenida

### 5. Escalabilidad
- Plan pago accesible cuando crezcamos
- Sin "vendor lock-in" excesivo

## Links Útiles

- [Brevo - Sitio oficial](https://www.brevo.com)
- [Brevo - Documentación API](https://developers.brevo.com/)
- [Swoosh Brevo Adapter](https://hexdocs.pm/swoosh/Swoosh.Adapters.Brevo.html)
- [Brevo - Crear cuenta](https://app.brevo.com/account/register)

## Configuración en Phoenix

La configuración ya está implementada en `config/runtime.exs`:

```elixir
# Brevo mailer
config :puente_app, PuenteApp.Mailer,
  adapter: Swoosh.Adapters.Brevo,
  api_key: System.get_env("BREVO_API_KEY")

# Email sender
config :puente_app,
  mailer_from_name: System.get_env("MAILER_FROM_NAME", "PuenteApp"),
  mailer_from_email: System.get_env("MAILER_FROM_EMAIL")
```

## Variables de Entorno Requeridas

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `BREVO_API_KEY` | API Key de Brevo | `xkeysib-xxx...` |
| `MAILER_FROM_EMAIL` | Email remitente (debe estar verificado en Brevo) | `noreply@tudominio.com` |
| `MAILER_FROM_NAME` | Nombre del remitente (opcional) | `PuenteApp` |

## Pasos para configurar Brevo

1. Crear cuenta en [Brevo](https://app.brevo.com/account/register)
2. Ir a **SMTP & API** > **API Keys**
3. Crear una nueva API Key
4. Verificar el dominio o email remitente en **Senders & IPs**
5. Configurar las variables de entorno en producción

## Alternativas Consideradas

| Provider | Por qué no |
|----------|------------|
| SendPulse | Más emails pero menos features integradas |
| Resend | Excelente DX pero solo 3,000/mes y sin analytics en free tier |
| SendGrid | Límite bajo (3,000/mes) y costoso al escalar |
| Mailjet | Buena opción pero Brevo ofrece más features |
