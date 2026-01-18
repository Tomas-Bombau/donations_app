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
alias PuenteApp.Catalog.Category

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

# Create admin user
IO.puts("Creating admin user...")

admin = %User{}
|> User.registration_changeset(%{
  email: "admin@example.com",
  password: "password1234",
  first_name: "Admin",
  last_name: "Sistema",
  role: :super_admin
})
|> Ecto.Changeset.put_change(:confirmed_at, DateTime.utc_now(:second))
|> Repo.insert!()

IO.puts("Created super_admin: #{admin.email}")

IO.puts("\nSeed completed!")
IO.puts("Admin: admin@example.com / password1234")
