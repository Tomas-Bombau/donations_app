# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     AppDonation.Repo.insert!(%AppDonation.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias AppDonation.Repo
alias AppDonation.Accounts.User
alias AppDonation.Organizations.Organization
alias AppDonation.Catalog.Category
alias AppDonation.Requests.Request

# Create categories
IO.puts("Creating categories...")

categories = [
  %{name: "Educacion", description: "Material educativo, utiles escolares, equipamiento para aulas"},
  %{name: "Maquinaria", description: "Equipos, herramientas y maquinaria para trabajo"},
  %{name: "Utensilios", description: "Utensilios de cocina, limpieza y uso domestico"},
  %{name: "Comida", description: "Alimentos, insumos para comedores y merenderos"}
]

Enum.each(categories, fn cat ->
  Repo.insert!(%Category{name: cat.name, description: cat.description, active: true})
  IO.puts("Created category: #{cat.name}")
end)

# Helper to create a user with hashed password
defmodule Seeds do
  def create_user!(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Ecto.Changeset.put_change(:confirmed_at, DateTime.utc_now(:second))
    |> Repo.insert!()
  end
end

IO.puts("Creating seed users...")

# Super Admin
super_admin = Seeds.create_user!(%{
  email: "admin@example.com",
  password: "password1234",
  first_name: "Admin",
  last_name: "Sistema",
  role: :super_admin
})
IO.puts("Created super_admin: #{super_admin.email}")

# Donor users
donor1 = Seeds.create_user!(%{
  email: "donor1@example.com",
  password: "password1234",
  first_name: "Juan",
  last_name: "Perez",
  phone: "+54 11 1234-5678",
  role: :donor
})
IO.puts("Created donor: #{donor1.email}")

donor2 = Seeds.create_user!(%{
  email: "donor2@example.com",
  password: "password1234",
  first_name: "Maria",
  last_name: "Garcia",
  phone: "+54 11 8765-4321",
  role: :donor
})
IO.puts("Created donor: #{donor2.email}")

# Requester users (approved)
requester1 = %User{}
|> User.registration_changeset(%{
  email: "requester1@example.com",
  password: "password1234",
  first_name: "Carlos",
  last_name: "Rodriguez",
  phone: "+54 11 5555-1234",
  role: :organization
})
|> Ecto.Changeset.put_change(:confirmed_at, DateTime.utc_now(:second))
|> Ecto.Changeset.put_change(:admin_approved_at, DateTime.utc_now(:second))
|> Repo.insert!()

Repo.insert!(%Organization{
  user_id: requester1.id,
  organization_role: "presidente",
  organization_name: "Fundacion Ayuda Social",
  address: "Av. Corrientes 1234, CABA",
  province: "CABA",
  lat: -34.6037,
  lng: -58.3816,
  has_legal_entity: true
})
IO.puts("Created requester: #{requester1.email}")

requester2 = %User{}
|> User.registration_changeset(%{
  email: "requester2@example.com",
  password: "password1234",
  first_name: "Ana",
  last_name: "Martinez",
  phone: "+54 11 5555-5678",
  role: :organization
})
|> Ecto.Changeset.put_change(:confirmed_at, DateTime.utc_now(:second))
|> Ecto.Changeset.put_change(:admin_approved_at, DateTime.utc_now(:second))
|> Repo.insert!()

Repo.insert!(%Organization{
  user_id: requester2.id,
  organization_role: "colaborador",
  organization_name: "Comedor Comunitario Los Amigos",
  address: "Calle 50 N 1234, La Plata",
  province: "Buenos Aires",
  municipality: "La Plata",
  lat: -34.6158,
  lng: -58.4333,
  has_legal_entity: false
})
IO.puts("Created requester: #{requester2.email}")

requester3 = %User{}
|> User.registration_changeset(%{
  email: "requester3@example.com",
  password: "password1234",
  first_name: "Luis",
  last_name: "Gonzalez",
  phone: "+54 11 5555-9012",
  role: :organization
})
|> Ecto.Changeset.put_change(:confirmed_at, DateTime.utc_now(:second))
|> Ecto.Changeset.put_change(:admin_approved_at, DateTime.utc_now(:second))
|> Repo.insert!()

org3 = Repo.insert!(%Organization{
  user_id: requester3.id,
  organization_role: "tesorero",
  organization_name: "ONG Solidaridad Argentina",
  address: "Av. Callao 1500, CABA",
  province: "CABA",
  lat: -34.5987,
  lng: -58.3925,
  has_legal_entity: true,
  cbu: "0110012330001234567890",
  payment_alias: "solidaridad.arg"
})
IO.puts("Created requester with payment info: #{requester3.email}")

# Get categories for requests
[cat_educacion, cat_maquinaria, cat_utensilios, cat_comida] = Repo.all(Category)

IO.puts("\nCreating requests for requester3...")

# Create 11 completed requests with dates separated by 2 weeks
completed_requests = [
  %{title: "Libros para biblioteca", category: cat_educacion, amount: 15000, goal_reached: true},
  %{title: "Computadoras para aula", category: cat_educacion, amount: 50000, goal_reached: false},
  %{title: "Heladera industrial", category: cat_maquinaria, amount: 80000, goal_reached: true},
  %{title: "Cocina industrial", category: cat_maquinaria, amount: 45000, goal_reached: false},
  %{title: "Ollas y sartenes", category: cat_utensilios, amount: 12000, goal_reached: true},
  %{title: "Vajilla completa", category: cat_utensilios, amount: 8000, goal_reached: false},
  %{title: "Alimentos no perecederos", category: cat_comida, amount: 25000, goal_reached: true},
  %{title: "Leche y cereales", category: cat_comida, amount: 18000, goal_reached: false},
  %{title: "Utiles escolares 2025", category: cat_educacion, amount: 20000, goal_reached: true},
  %{title: "Horno pizzero", category: cat_maquinaria, amount: 35000, goal_reached: false},
  %{title: "Freezer vertical", category: cat_maquinaria, amount: 60000, goal_reached: true}
]

now = DateTime.utc_now(:second)

Enum.with_index(completed_requests, fn request_data, index ->
  # Each request is 2 weeks apart, going back in time
  weeks_ago = (index + 1) * 2
  inserted_at = DateTime.add(now, -weeks_ago * 7, :day)
  deadline = Date.add(Date.utc_today(), -((index + 1) * 7))

  amount = Decimal.new(request_data.amount)
  amount_raised = if request_data.goal_reached, do: amount, else: Decimal.mult(amount, Decimal.from_float(0.6))

  Repo.insert!(%Request{
    organization_id: org3.id,
    category_id: request_data.category.id,
    title: request_data.title,
    description: "Descripcion del pedido: #{request_data.title}. Este es un pedido de ejemplo para pruebas.",
    amount: amount,
    amount_raised: amount_raised,
    deadline: deadline,
    status: :completed,
    inserted_at: inserted_at,
    updated_at: inserted_at
  })

  IO.puts("Created completed request: #{request_data.title} (#{if request_data.goal_reached, do: "goal reached", else: "partial"})")
end)

# Create 1 active request (most recent, 1 day ago)
active_inserted_at = DateTime.add(now, -1, :day)
Repo.insert!(%Request{
  organization_id: org3.id,
  category_id: cat_comida.id,
  title: "Donacion de alimentos frescos",
  description: "Necesitamos alimentos frescos para el comedor. Frutas, verduras y carnes para preparar comidas nutritivas para los niños del barrio.",
  amount: Decimal.new(30000),
  amount_raised: Decimal.new(12500),
  deadline: Date.add(Date.utc_today(), 30),
  status: :active,
  inserted_at: active_inserted_at,
  updated_at: active_inserted_at
})
IO.puts("Created active request: Donacion de alimentos frescos")

# 10 Organizaciones pendientes de aprobacion (sin admin_approved_at)
IO.puts("\nCreating 10 pending organizations...")

pending_orgs = [
  %{name: "Fundacion Esperanza", contact: "Roberto", last: "Sanchez", role: "presidente", address: "Av. Santa Fe 2000", province: "CABA", municipality: nil},
  %{name: "Asociacion Civil Manos Unidas", contact: "Laura", last: "Fernandez", role: "tesorero", address: "Calle 50 N 1234", province: "Buenos Aires", municipality: "La Plata"},
  %{name: "Comedor Los Pibes", contact: "Diego", last: "Gomez", role: "colaborador", address: "Av. Rivadavia 5000", province: "CABA", municipality: nil},
  %{name: "Hogar de Ancianos San Jose", contact: "Marta", last: "Lopez", role: "secretario", address: "San Martin 890", province: "Buenos Aires", municipality: "Quilmes"},
  %{name: "Centro Comunitario El Sol", contact: "Pablo", last: "Diaz", role: "vocal", address: "Mitre 456", province: "Buenos Aires", municipality: "Avellaneda"},
  %{name: "Fundacion Corazon Solidario", contact: "Lucia", last: "Torres", role: "presidente", address: "Belgrano 321", province: "CABA", municipality: nil},
  %{name: "Asociacion Protectora de Animales", contact: "Fernando", last: "Ruiz", role: "otro", address: "Sarmiento 777", province: "Buenos Aires", municipality: "Lomas de Zamora"},
  %{name: "Merendero Los Angelitos", contact: "Silvia", last: "Castro", role: "colaborador", address: "Av. 9 de Julio 1500", province: "CABA", municipality: nil},
  %{name: "Centro de Apoyo Escolar", contact: "Andres", last: "Moreno", role: "secretario", address: "Lavalle 2222", province: "Buenos Aires", municipality: "General Pueyrredon"},
  %{name: "Comedor Infantil Sonrisas", contact: "Veronica", last: "Herrera", role: "tesorero", address: "Urquiza 100", province: "Buenos Aires", municipality: "Tigre"}
]

Enum.each(pending_orgs, fn org ->
  email = "#{String.downcase(org.contact)}@#{String.downcase(String.replace(org.name, ~r/\s+/, ""))}.org"

  user = %User{}
  |> User.registration_changeset(%{
    email: email,
    password: "password1234",
    first_name: org.contact,
    last_name: org.last,
    role: :organization
  })
  |> Ecto.Changeset.put_change(:confirmed_at, DateTime.utc_now(:second))
  # No ponemos admin_approved_at para que quede pendiente
  |> Repo.insert!()

  Repo.insert!(%Organization{
    user_id: user.id,
    organization_role: org.role,
    organization_name: org.name,
    address: org.address,
    province: org.province,
    municipality: org.municipality,
    has_legal_entity: Enum.random([true, false])
  })

  IO.puts("Created pending org: #{org.name}")
end)

IO.puts("\nSeed completed!")
IO.puts("You can log in with any of these users using password: password1234")
IO.puts("Admin: admin@example.com")
