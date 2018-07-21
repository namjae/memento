defmodule Memento.Mnesia do
  alias Memento.MnesiaException

  @moduledoc """
  Helper wrapper module to delegate calls to Erlang's `:mnesia`
  """



  # Type Definitions
  # ----------------

  @typedoc "Normalized response of an Mnesia call"
  @type result :: :ok | {:error, any}




  # Public API
  # ----------


  @doc "Call an Mnesia function"
  defmacro call(method, arguments \\ []) do
    quote(bind_quoted: [fun: method, args: arguments]) do
      require MnesiaException

      try do
        apply(:mnesia, fun, args)
      catch
        :exit, error -> MnesiaException.raise(error)
      end

    end
  end




  @doc "Normalize the result of an :mnesia call"
  @spec handle_result(any) :: result
  def handle_result(result) do
    case result do
      :ok ->
        :ok

      {:atomic, :ok} ->
        :ok

      {:atomic, term} ->
        {:ok, term}

      {:error, reason} ->
        {:error, reason}

      {:aborted, reason = {exception, stacktrace}} ->
        if erlang_error?(exception, stacktrace) do
          reraise Exception.normalize(:error, exception, stacktrace), stacktrace
        else
          {:error, reason}
        end

      {:aborted, reason} ->
        {:error, reason}
    end
  end




  # Private Helpers
  # ---------------

  # Check if the error is actually an erlang error
  defp erlang_error?(exception, stacktrace) do
    %ErlangError{original: exception} !=
      ErlangError.normalize(exception, stacktrace)
  end


end
