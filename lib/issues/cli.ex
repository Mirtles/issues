defmodule Issues.CLI do
  @default_count 4
  import Issues.TableFormatter, only: [ print_table_for_columns: 2 ]

  @moduledoc """
  Handle the command line parsing and the dispatch to
  the various functions that end up generating a
  table of the last _n_ issues in a github project
  """
  def run(argv) do
    argv
    |> parse_args
    |> process
  end

  @doc """
  `argv` can be -h or --help, which returns :help.
  Otherwise it is a github user name, project name, and (optionally)
  the number of entries to format.
  Return a tuple of `{ user, project, count }`, or `:help` if help was given.
  """
  def parse_args(argv) do
    OptionParser.parse(argv, switches: [ help: :boolean],
      aliases: [ h: :help])
    |>elem(1)
    |>args_to_internal_representation()
  end

  #  if count is given
  def args_to_internal_representation([user, project, count]) do
    { user, project, String.to_integer(count) }
  end

  # if no count is given
  def args_to_internal_representation([user, project]) do
    { user, project, @default_count }
  end

  # if 'help' (or error)
  def args_to_internal_representation(_) do
    :help
  end


  def process(:help) do
    IO.puts """
    usage: issues <user> <project> [ count | #{@default_count} ]
    """
    # stops runtime system, returns '0' code to OS
    System.halt(0)
  end

  def process({user, project, count}) do
    Issues.GithubIssues.fetch(user, project)
    |> decode_response()
    |> sort_into_ascending_order()
    |> last(count)
    |> print_table_for_columns(["number", "created_at", "title"])
  end

  def decode_response({:ok, body}), do: body

  def decode_response({:error, error}) do
    {_, message} = List.keyfind(error, "message", 0)
    IO.puts "Error fetching from GitHub: #{message}"
    System.halt(2)
  end

  def sort_into_ascending_order(list_of_issues) do
    list_of_issues
    |> Enum.sort(fn issue, issue2 ->
      issue["created_at"] <= issue2["created_at"]
    end)
  end

  def last(list_of_issues, count) do
    list_of_issues
    |> Enum.reverse
    |> Enum.count(count)
    |> Enum.reverse
  end

end
