defmodule Ash.Resource.Validation.AttributeEquals do
  @moduledoc false

  @opt_schema [
    attribute: [
      type: :atom,
      required: true,
      doc: "The attribute to check"
    ],
    value: [
      type: :any,
      required: true,
      doc: "The value the attribute must equal"
    ]
  ]

  use Ash.Resource.Validation
  alias Ash.Error.Changes.InvalidAttribute
  require Ash.Expr
  import Ash.Filter.TemplateHelpers

  @impl true
  def atomic(_changeset, opts) do
    {:atomic, [opts[:attribute]], Ash.Expr.expr(^atomic_ref(opts[:attribute]) != ^opts[:value]),
     Ash.Expr.expr(
       error(^InvalidAttribute, %{
         field: ^opts[:attribute],
         value: ^atomic_ref(opts[:attribute]),
         message: "must equal %{value}",
         vars: %{field: ^opts[:attribute], value: ^opts[:value]}
       })
     )}
  end

  @impl true
  def init(opts) do
    case Spark.OptionsHelpers.validate(opts, @opt_schema) do
      {:ok, opts} ->
        {:ok, opts}

      {:error, error} ->
        {:error, Exception.message(error)}
    end
  end

  @impl true
  def validate(changeset, opts) do
    value = Ash.Changeset.get_attribute(changeset, opts[:attribute])

    if value != opts[:value] do
      {:error,
       [field: opts[:attribute], value: value]
       |> with_description(opts)
       |> InvalidAttribute.exception()}
    else
      :ok
    end
  end

  @impl true
  def describe(opts) do
    [
      message: "must equal %{value}",
      vars: [field: opts[:attribute], value: opts[:value]]
    ]
  end
end
