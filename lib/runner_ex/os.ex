defmodule RunnerEx.OS do

  def assign_shell(mod, shell, opt) do
    Module.put_attribute(mod, :shell, shell)
    Module.put_attribute(mod, :shell_options, opt)
  end

  def find_program(name) when name |> is_binary do
    program = if File.exists?(name) do
      name 
      |> Path.absname
    else
      IO.puts "Look up name '#{name}'"
      name
      |> to_char_list
      |> IO.inspect
      |> :os.find_executable
    end

    if program == false do
      err = "Could not find program #{inspect name}"
      raise ArgumentError, message: err
    end
    # protects against charlists
    "#{program}"
  end

  defmacro __using__(_opts) do
    quote do
    
      Module.register_attribute(__MODULE__, :shell, [])
      Module.register_attribute(__MODULE__, :shell_options, accumulate: true)

      case :os.type do
        {:unix, _} ->
          RunnerEx.OS.assign_shell(__MODULE__, "sh", "-c")
        {:win32, osname} ->
          shell = case {System.get_env("COMSPEC"), osname} do
            {nil, :windows} -> 'command.com'
            {nil, _}        -> 'cmd'
            {cmd, _}        -> cmd
        end
        RunnerEx.OS.assign_shell(__MODULE__, shell, "/c")
      end

      def shell do
        [@shell, @shell_options] |> List.flatten
      end

      def shell(command) do
        shell ++ [command] |> List.flatten
      end

    end
  end
end