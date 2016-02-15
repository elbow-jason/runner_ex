defmodule RunnerEx.Process do

  defp collect_output(port, output, error, result_opt, callback_module) do
    receive do
      { ^port, {:data, data} } ->
        {output, error} = callback_module.process_data(data, output, error)
        collect_output(port, output, error, result_opt, callback_module)

      { ^port, {:exit_status, status} } ->
        result = finalize_result(status, output, error)
        send_result(output, error, result_opt, result)
        || case result_opt do
          nil      -> result
          :discard -> nil
          :keep    -> wait_for_command(result)
        end

      {:input, data} ->
        callback_module.feed_input(port, data)
        collect_output(port, output, error, result_opt, callback_module)

      {:signal, sig} ->
        send_signal(port, sig)
        collect_output(port, output, error, result_opt, callback_module)

      {:stop, from, ref} ->
        status = callback_module.stop_process(port)
        result = finalize_result(status, output, error)
        send_result(output, error, result_opt, result)
        send(from, {ref, :stopped})
    end
  end


end