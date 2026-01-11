defmodule PuenteApp.Organizations.Organization do
  use PuenteApp, :schema
  import Ecto.Changeset

  alias PuenteApp.Accounts.User

  @organization_roles ["presidente", "tesorero", "secretario", "vocal", "colaborador", "otro"]
  @provinces ["CABA", "Buenos Aires"]

  @buenos_aires_municipalities [
    "Adolfo Alsina", "Adolfo Gonzales Chaves", "Alberti", "Almirante Brown", "Arrecifes",
    "Avellaneda", "Ayacucho", "Azul", "Bahia Blanca", "Balcarce", "Baradero", "Berazategui",
    "Berisso", "Bolivar", "Bragado", "Brandsen", "Campana", "Canuelas", "Capitan Sarmiento",
    "Carlos Casares", "Carlos Tejedor", "Carmen de Areco", "Castelli", "Chacabuco", "Chascomus",
    "Chivilcoy", "Colon", "Coronel de Marina Leonardo Rosales", "Coronel Dorrego", "Coronel Pringles",
    "Coronel Suarez", "Daireaux", "Dolores", "Ensenada", "Escobar", "Esteban Echeverria",
    "Exaltacion de la Cruz", "Ezeiza", "Florencio Varela", "Florentino Ameghino", "General Alvarado",
    "General Alvear", "General Arenales", "General Belgrano", "General Guido", "General Juan Madariaga",
    "General La Madrid", "General Las Heras", "General Lavalle", "General Paz", "General Pinto",
    "General Pueyrredon", "General Rodriguez", "General San Martin", "General Viamonte", "General Villegas",
    "Guamini", "Hipolito Yrigoyen", "Hurlingham", "Ituzaingo", "Jose C. Paz", "Junin", "La Costa",
    "La Matanza", "La Plata", "Lanus", "Laprida", "Las Flores", "Leandro N. Alem", "Lezama",
    "Lincoln", "Loberia", "Lobos", "Lomas de Zamora", "Lujan", "Magdalena", "Maipu", "Malvinas Argentinas",
    "Mar Chiquita", "Marcos Paz", "Mercedes", "Merlo", "Monte", "Monte Hermoso", "Moron", "Navarro",
    "Necochea", "Nueve de Julio", "Olavarria", "Patagones", "Pehuajo", "Pellegrini", "Pergamino",
    "Pila", "Pilar", "Pinamar", "Presidente Peron", "Puan", "Punta Indio", "Quilmes", "Ramallo",
    "Rauch", "Rivadavia", "Rojas", "Roque Perez", "Saavedra", "Saladillo", "Salliquelo", "Salto",
    "San Andres de Giles", "San Antonio de Areco", "San Cayetano", "San Fernando", "San Isidro",
    "San Miguel", "San Nicolas", "San Pedro", "San Vicente", "Suipacha", "Tandil", "Tapalque",
    "Tigre", "Tordillo", "Tornquist", "Trenque Lauquen", "Tres Arroyos", "Tres de Febrero",
    "Tres Lomas", "Veinticinco de Mayo", "Vicente Lopez", "Villa Gesell", "Villarino", "Zarate"
  ]

  schema "organizations" do
    field :organization_role, :string
    field :organization_name, :string
    field :address, :string
    field :lat, :float
    field :lng, :float
    field :has_legal_entity, :boolean, default: false
    field :province, :string
    field :municipality, :string
    field :cbu, :string
    field :payment_alias, :string
    field :image_path, :string
    field :facebook, :string
    field :instagram, :string
    field :activities, :string
    field :audience, :string
    field :reach, :string

    has_many :requests, PuenteApp.Requests.Request

    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  def organization_roles, do: @organization_roles
  def provinces, do: @provinces
  def buenos_aires_municipalities, do: @buenos_aires_municipalities

  def organization_role_options do
    [
      {"Presidente", "presidente"},
      {"Tesorero", "tesorero"},
      {"Secretario", "secretario"},
      {"Vocal", "vocal"},
      {"Colaborador", "colaborador"},
      {"Otro", "otro"}
    ]
  end

  def province_options do
    [
      {"CABA", "CABA"},
      {"Buenos Aires", "Buenos Aires"}
    ]
  end

  def municipality_options do
    Enum.map(@buenos_aires_municipalities, fn m -> {m, m} end)
  end

  @doc """
  Checks if the organization has payment info configured (CBU or alias).
  """
  def has_payment_configured?(%__MODULE__{cbu: nil, payment_alias: nil}), do: false
  def has_payment_configured?(%__MODULE__{cbu: "", payment_alias: nil}), do: false
  def has_payment_configured?(%__MODULE__{cbu: nil, payment_alias: ""}), do: false
  def has_payment_configured?(%__MODULE__{cbu: "", payment_alias: ""}), do: false
  def has_payment_configured?(%__MODULE__{}), do: true

  @doc false
  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:organization_role, :organization_name, :address, :lat, :lng, :has_legal_entity, :province, :municipality, :user_id])
    |> validate_required([:organization_role, :organization_name, :address, :province, :user_id])
    |> validate_inclusion(:organization_role, @organization_roles, message: "debe seleccionar un rol valido")
    |> validate_inclusion(:province, @provinces, message: "debe seleccionar una provincia valida")
    |> validate_municipality()
    |> validate_length(:organization_name, max: 200)
    |> validate_length(:address, max: 500)
    |> validate_number(:lat, greater_than_or_equal_to: -90, less_than_or_equal_to: 90)
    |> validate_number(:lng, greater_than_or_equal_to: -180, less_than_or_equal_to: 180)
    |> unique_constraint(:user_id)
    |> foreign_key_constraint(:user_id)
  end

  @doc """
  Changeset for organization registration (without address and has_legal_entity).
  These fields will be completed by admin later.
  """
  def registration_changeset(organization, attrs) do
    organization
    |> cast(attrs, [:organization_role, :organization_name, :province, :municipality, :user_id])
    |> validate_required([:organization_role, :organization_name, :province, :user_id])
    |> validate_inclusion(:organization_role, @organization_roles, message: "debe seleccionar un rol valido")
    |> validate_inclusion(:province, @provinces, message: "debe seleccionar una provincia valida")
    |> validate_municipality()
    |> validate_length(:organization_name, max: 200)
    |> unique_constraint(:user_id)
    |> foreign_key_constraint(:user_id)
  end

  @doc """
  Changeset for updating profile (including payment info).
  """
  def profile_changeset(organization, attrs) do
    organization
    |> cast(attrs, [:organization_name, :address, :province, :municipality, :has_legal_entity, :cbu, :payment_alias, :facebook, :instagram])
    |> validate_required([:organization_name, :address, :province])
    |> validate_inclusion(:province, @provinces, message: "debe seleccionar una provincia valida")
    |> validate_municipality()
    |> validate_length(:organization_name, max: 200)
    |> validate_length(:address, max: 500)
    |> validate_cbu()
  end

  @doc """
  Changeset for organization to update only social media fields.
  """
  def social_changeset(organization, attrs) do
    organization
    |> cast(attrs, [:facebook, :instagram])
  end

  @doc """
  Changeset for admin to update all organization fields including payment.
  """
  def admin_changeset(organization, attrs) do
    organization
    |> cast(attrs, [:organization_role, :organization_name, :address, :province, :municipality, :has_legal_entity, :cbu, :payment_alias, :image_path, :facebook, :instagram, :activities, :audience, :reach])
    |> validate_required([:organization_role, :organization_name, :address, :province])
    |> validate_inclusion(:organization_role, @organization_roles, message: "debe seleccionar un rol valido")
    |> validate_inclusion(:province, @provinces, message: "debe seleccionar una provincia valida")
    |> validate_municipality()
    |> validate_length(:organization_name, max: 200)
    |> validate_length(:address, max: 500)
    |> validate_cbu()
  end

  defp validate_cbu(changeset) do
    case get_change(changeset, :cbu) do
      nil -> changeset
      "" -> changeset
      cbu ->
        if Regex.match?(~r/^\d{22}$/, cbu) do
          changeset
        else
          add_error(changeset, :cbu, "debe tener 22 digitos numericos")
        end
    end
  end

  defp validate_municipality(changeset) do
    province = get_field(changeset, :province)
    municipality = get_field(changeset, :municipality)

    cond do
      province == "Buenos Aires" && (is_nil(municipality) || municipality == "") ->
        add_error(changeset, :municipality, "debe seleccionar un municipio")

      province == "Buenos Aires" && municipality not in @buenos_aires_municipalities ->
        add_error(changeset, :municipality, "municipio invalido")

      province == "CABA" ->
        put_change(changeset, :municipality, nil)

      true ->
        changeset
    end
  end
end
