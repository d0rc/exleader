# Exleader

Usage is quite simple:


```elixir
defmodule Messager do
	use Exleader.Behaviour

	def elected(state, _election, :undefined) do
		IO.puts "Elected as leader, starting priting..."
		Exleader.cast Messager, :print_time
		{:ok, [], state}
	end
	def elected(state, _election, _node), do: {:ok, [], state}

	def handle_leader_cast(:print_time, state, _election) do
		IO.puts "Priting time\r"
		:erlang.spawn_link fn() ->
			receive do after 1000 -> :ok end
			Exleader.cast Messager, :print_time
		end
		{:noreply, state}
	end
	def handle_leader_cast(_request, state, _election) do
		{:noreply, state}
	end
end
```
