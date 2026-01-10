# AppDonation

A donation crowdfunding platform built with Phoenix LiveView, designed for organizations in Argentina (Buenos Aires and CABA) to create fundraising campaigns and connect with donors.

## Features

**For Organizations:**
- Create and manage donation requests with funding goals and deadlines
- Track donation progress in real-time
- Configure payment information (CBU or payment alias)
- Automatic request completion when funding goals are reached

**For Donors:**
- Browse active donation requests by category and location
- Make contributions to campaigns
- Track personal donation history

**For Administrators:**
- Approve new organization registrations
- Manage categories, organizations, and donors
- View platform metrics

## Tech Stack

- **Elixir** ~> 1.15
- **Phoenix** ~> 1.8.3
- **Phoenix LiveView** ~> 1.1.0
- **PostgreSQL** with UUID primary keys
- **Tailwind CSS** for styling

## Getting Started

### Prerequisites

- Elixir 1.15+
- PostgreSQL
- Node.js (for assets)

### Installation

1. Install dependencies:
   ```bash
   mix setup
   ```

2. Start the Phoenix server:
   ```bash
   mix phx.server
   ```

3. Visit [`localhost:4000`](http://localhost:4000) in your browser.

### Running Tests

```bash
mix test
```

## Project Structure

```
lib/
├── app_donation/           # Business logic contexts
│   ├── accounts/           # User authentication & management
│   ├── organizations/      # Organization profiles
│   ├── requests/           # Donation requests
│   ├── donations/          # Donation tracking
│   └── catalog/            # Categories
└── app_donation_web/       # Web layer
    ├── controllers/        # Traditional controllers
    ├── live/               # LiveView components
    │   ├── admin/          # Admin dashboard
    │   ├── donor/          # Donor interface
    │   └── organization/   # Organization interface
    └── components/         # Shared UI components
```

## User Roles

| Role | Description |
|------|-------------|
| `donor` | Can browse requests and make donations |
| `organization` | Can create donation requests (requires admin approval) |
| `super_admin` | Full platform management access |

## Deployment

See the [Phoenix deployment guides](https://hexdocs.pm/phoenix/deployment.html) for production setup.
