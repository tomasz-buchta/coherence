require IEx
defmodule Coherence.Rememberable do
  use Coherence.Web, :model
  use Timex
  alias Coherence.Config
  require Logger
  alias __MODULE__

  schema "rememberables" do
    field :series_hash, :string
    field :token_hash, :string
    field :token_created_at, Timex.Ecto.DateTime
    belongs_to :user, Module.concat(Config.module, Config.user_schema)

    timestamps
  end

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    # params[:token_created_at]
    model
    |> cast(params, ~w(series_hash token_hash token_created_at user_id))
    |> validate_required(~w(series_hash token_hash token_created_at user_id)a)
  end

  def create_login(user) do
    series = gen_series
    token = gen_token
    changeset = changeset(%__MODULE__{}, %{token_created_at: created_at, user_id: user.id,
      series_hash: hash(series), token_hash: hash(token)})
    {changeset, series, token}
  end

  def update_login(rememberable) do
    token = gen_token
    {changeset(rememberable, %{token_hash: hash(token)}), token}
  end

  def get_valid_login(user_id, series, token) do
    from p in Rememberable,
      where: p.user_id == ^user_id and p.series_hash == ^series and p.token_hash == ^token
  end

  def get_invalid_login(user_id, series, token) do
    from p in Rememberable,
      where: p.user_id == ^user_id and p.series_hash == ^series and p.token_hash != ^token,
      select: count(p.id)
  end

  def delete_all(user_id) do
    from p in Rememberable, where: p.user_id == ^user_id
  end

  def delete_expired_tokens do
    expire_datetime = Timex.shift(Timex.now, hours: -Config.rememberable_cookie_expire_hours)
    from p in Rememberable, where: p.token_created_at < ^expire_datetime
  end

  def gen_cookie(user_id, series, token), do: "#{user_id} #{series} #{token}"

  def hash(string) do
    :crypto.hash(:sha, String.to_char_list(string))
    |> Base.url_encode64
  end

  def log_cookie(cookie) do
    [_id, series, token] = String.split cookie, " "
    cookie <> " : #{hash series}  #{hash token}"
  end

  defp created_at, do: Timex.now

  defp gen_token do
    Coherence.ControllerHelpers.random_string 24
  end
  defp gen_series do
    Coherence.ControllerHelpers.random_string 10
  end

  defp parse_token_created_at(changeset, token_created_at) do
    case Timex.parse(token_created_at, "{YYYY}-{0M}-{0D} {h24}:{m}:{s}") do
      {:ok, parsed} -> update_change(changeset, :token_created_at, parsed)
      {:error, error} -> add_error(changeset, :token_created_at, "Cannot parse")
    end
    changeset
  end

end
