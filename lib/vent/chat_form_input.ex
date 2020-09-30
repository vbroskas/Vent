defmodule Vent.ChatFormInput do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :name, :string
  end

  @allowed_fields ~w(name)a
  @required_fields @allowed_fields

  def new_changeset(chat_form_input, params \\ %{}) do
    chat_form_input
    |> cast(params, @allowed_fields)
  end

  def validate_changeset(chat_form_input, params) do
    new_changeset(chat_form_input, params)
    |> validate_required(@required_fields)
    |> validate_length(:name, min: 2)
  end
end
