# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     PuenteApp.Repo.insert!(%PuenteApp.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias PuenteApp.Repo
alias PuenteApp.Accounts.User
alias PuenteApp.Organizations.Organization
alias PuenteApp.Catalog.Category
alias PuenteApp.Requests.Request

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
  has_legal_entity: true,
  cbu: "0140012301234567890123",
  payment_alias: "fundacion.ayuda",
  facebook: "facebook.com/fundacionayudasocial",
  instagram: "@fundacionayudasocial",
  activities: "Brindamos apoyo educativo a niños y adolescentes en situacion de vulnerabilidad. Realizamos talleres de alfabetizacion digital para adultos mayores.",
  audience: "Niños, adolescentes y adultos mayores",
  reach: "200 personas por mes"
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
  has_legal_entity: false,
  cbu: "0170012301234567890456",
  payment_alias: "comedor.losamigos",
  facebook: "facebook.com/comedorlosamigos",
  instagram: "@comedorlosamigos",
  activities: "Comedor comunitario que brinda almuerzo y merienda a niños del barrio. Tambien realizamos actividades recreativas los fines de semana.",
  audience: "Niños y familias del barrio",
  reach: "80 personas diarias"
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
  payment_alias: "solidaridad.arg",
  facebook: "facebook.com/solidaridadargentina",
  instagram: "@solidaridadarg",
  activities: "Asistencia social integral a familias en situacion de vulnerabilidad. Entrega de alimentos, ropa y utiles escolares. Acompañamiento a adultos mayores.",
  audience: "Familias, niños y adultos mayores",
  reach: "500 familias por mes"
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

# Create ONE active request for org3 (only 1 active per organization)
active_req_org3 = %{title: "Donacion de alimentos frescos", category: cat_comida, amount: 30000, raised: 12500, days_deadline: 30, description: "Necesitamos alimentos frescos para el comedor. Frutas, verduras y carnes para preparar comidas nutritivas para los niños del barrio."}

inserted_at = DateTime.add(now, -1, :day)
Repo.insert!(%Request{
  organization_id: org3.id,
  category_id: active_req_org3.category.id,
  title: active_req_org3.title,
  description: active_req_org3.description,
  amount: Decimal.new(active_req_org3.amount),
  amount_raised: Decimal.new(active_req_org3.raised),
  deadline: Date.add(Date.utc_today(), active_req_org3.days_deadline),
  status: :active,
  inserted_at: inserted_at,
  updated_at: inserted_at
})
IO.puts("Created active request for org3: #{active_req_org3.title}")

# Get org1 and org2 for active requests
org1 = Repo.get_by!(Organization, organization_name: "Fundacion Ayuda Social")
org2 = Repo.get_by!(Organization, organization_name: "Comedor Comunitario Los Amigos")

IO.puts("\nCreating active requests for other organizations...")

# ONE active request for org1 (Fundacion Ayuda Social)
active_req_org1 = %{title: "Tablets para alfabetizacion digital", category: cat_educacion, amount: 120000, raised: 45000, days_deadline: 60, description: "Buscamos tablets para nuestro programa de alfabetizacion digital para adultos mayores. Queremos enseñarles a usar tecnologia para comunicarse con sus familias."}

inserted_at = DateTime.add(now, -2, :day)
Repo.insert!(%Request{
  organization_id: org1.id,
  category_id: active_req_org1.category.id,
  title: active_req_org1.title,
  description: active_req_org1.description,
  amount: Decimal.new(active_req_org1.amount),
  amount_raised: Decimal.new(active_req_org1.raised),
  deadline: Date.add(Date.utc_today(), active_req_org1.days_deadline),
  status: :active,
  inserted_at: inserted_at,
  updated_at: inserted_at
})
IO.puts("Created active request for org1: #{active_req_org1.title}")

# ONE active request for org2 (Comedor Comunitario Los Amigos)
active_req_org2 = %{title: "Insumos para merendero", category: cat_comida, amount: 18000, raised: 7500, days_deadline: 14, description: "Necesitamos leche, galletitas, mate cocido y facturas para las meriendas de los 50 niños que asisten diariamente a nuestro merendero."}

inserted_at = DateTime.add(now, -1, :day)
Repo.insert!(%Request{
  organization_id: org2.id,
  category_id: active_req_org2.category.id,
  title: active_req_org2.title,
  description: active_req_org2.description,
  amount: Decimal.new(active_req_org2.amount),
  amount_raised: Decimal.new(active_req_org2.raised),
  deadline: Date.add(Date.utc_today(), active_req_org2.days_deadline),
  status: :active,
  inserted_at: inserted_at,
  updated_at: inserted_at
})
IO.puts("Created active request for org2: #{active_req_org2.title}")

# 10 Organizaciones pendientes de aprobacion (sin admin_approved_at)
IO.puts("\nCreating 10 pending organizations...")

pending_orgs = [
  %{name: "Fundacion Esperanza", contact: "Roberto", last: "Sanchez", role: "presidente", address: "Av. Santa Fe 2000", province: "CABA", municipality: nil, activities: "Apoyo a familias en situacion de calle", audience: "Personas en situacion de calle", reach: "50 personas por semana", facebook: "facebook.com/fundacionesperanza", instagram: "@fundacionesperanza"},
  %{name: "Asociacion Civil Manos Unidas", contact: "Laura", last: "Fernandez", role: "tesorero", address: "Calle 50 N 1234", province: "Buenos Aires", municipality: "La Plata", activities: "Talleres de oficios y capacitacion laboral", audience: "Jovenes desempleados", reach: "100 jovenes por mes", facebook: "facebook.com/manosunidas", instagram: "@manosunidas"},
  %{name: "Comedor Los Pibes", contact: "Diego", last: "Gomez", role: "colaborador", address: "Av. Rivadavia 5000", province: "CABA", municipality: nil, activities: "Comedor comunitario y apoyo escolar", audience: "Niños y adolescentes", reach: "60 niños diarios", facebook: nil, instagram: "@comedorlospibes"},
  %{name: "Hogar de Ancianos San Jose", contact: "Marta", last: "Lopez", role: "secretario", address: "San Martin 890", province: "Buenos Aires", municipality: "Quilmes", activities: "Residencia y cuidado de adultos mayores", audience: "Adultos mayores", reach: "30 residentes permanentes", facebook: "facebook.com/hogarsanjose", instagram: nil},
  %{name: "Centro Comunitario El Sol", contact: "Pablo", last: "Diaz", role: "vocal", address: "Mitre 456", province: "Buenos Aires", municipality: "Avellaneda", activities: "Actividades recreativas y deportivas para el barrio", audience: "Toda la comunidad", reach: "200 personas por semana", facebook: "facebook.com/centroelsol", instagram: "@centroelsol"},
  %{name: "Fundacion Corazon Solidario", contact: "Lucia", last: "Torres", role: "presidente", address: "Belgrano 321", province: "CABA", municipality: nil, activities: "Asistencia medica y medicamentos para personas sin cobertura", audience: "Personas sin cobertura medica", reach: "150 pacientes por mes", facebook: "facebook.com/corazonsolidario", instagram: "@corazonsolidario"},
  %{name: "Asociacion Protectora de Animales", contact: "Fernando", last: "Ruiz", role: "otro", address: "Sarmiento 777", province: "Buenos Aires", municipality: "Lomas de Zamora", activities: "Rescate y adopcion de animales abandonados", audience: "Animales abandonados", reach: "50 animales rescatados por mes", facebook: "facebook.com/protectoraanimales", instagram: "@protectoralz"},
  %{name: "Merendero Los Angelitos", contact: "Silvia", last: "Castro", role: "colaborador", address: "Av. 9 de Julio 1500", province: "CABA", municipality: nil, activities: "Meriendas y copa de leche para niños", audience: "Niños del barrio", reach: "40 niños diarios", facebook: nil, instagram: "@merenderolosangelitos"},
  %{name: "Centro de Apoyo Escolar", contact: "Andres", last: "Moreno", role: "secretario", address: "Lavalle 2222", province: "Buenos Aires", municipality: "General Pueyrredon", activities: "Clases de apoyo y tutoria escolar", audience: "Estudiantes primarios y secundarios", reach: "80 estudiantes por semana", facebook: "facebook.com/apoyoescolar", instagram: "@apoyoescolarmdp"},
  %{name: "Comedor Infantil Sonrisas", contact: "Veronica", last: "Herrera", role: "tesorero", address: "Urquiza 100", province: "Buenos Aires", municipality: "Tigre", activities: "Almuerzo y merienda para niños", audience: "Niños de 0 a 12 años", reach: "70 niños diarios", facebook: "facebook.com/comedorsonrisas", instagram: "@comedorsonrisas"}
]

Enum.each(pending_orgs, fn org ->
  email = "#{String.downcase(org.contact)}@#{String.downcase(String.replace(org.name, ~r/\s+/, ""))}.org"

  user = %User{}
  |> User.registration_changeset(%{
    email: email,
    password: "password1234",
    first_name: org.contact,
    last_name: org.last,
    phone: "+54 11 #{:rand.uniform(9999)}-#{:rand.uniform(9999)}",
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
    has_legal_entity: Enum.random([true, false]),
    activities: org.activities,
    audience: org.audience,
    reach: org.reach,
    facebook: org.facebook,
    instagram: org.instagram
  })

  IO.puts("Created pending org: #{org.name}")
end)

IO.puts("\nSeed completed!")
IO.puts("You can log in with any of these users using password: password1234")
IO.puts("Admin: admin@example.com")
