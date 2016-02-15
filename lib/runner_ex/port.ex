defmodule RunnerEx.Port do

  require Logger

  @unix_signal_map %{
    kill: "kill",
    force_kill: "kill -9",
    interrupt: "kill -2",
  }
  @unix_signals Map.keys @unix_signal_map

  def signal(port, command) when command in @unix_signals do
    signal(port, Map.get(@unix_signal_map, command))
  end 

  def signal(port, command) when command |> is_binary do
    case :erlang.port_info(port, :os_pid) do
      {:os_pid, os_pid} -> do_signal(command, os_pid)
      x                 -> {:error, {:os_pid, x}}
    end
  end

  defp do_signal(command, os_pid) do
    command
    |> String.split(" ")
    |> Kernel.++([os_pid])
    |> Enum.join(" ")
    |> String.to_char_list
    |> :os.cmd
    |> handle_signal_response
  end

  defp handle_signal_response(resp) do
    case resp do
      [] -> {:ok, :exited}
      x  -> {:error, x}
    end
  end

  def start(name, flags) when flags |> is_list do
    executable = RunnerEx.OS.find_program(name)
    command = (RunnerEx.shell
      ++ [executable]
      ++ flags)
      |> Enum.join(" ")
    Logger.info "Starting port with command: #{inspect command}"
    Port.open({:spawn, command}, [])
  end

  def stop(port) do
    port
    |> Port.close
  end
end