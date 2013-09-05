defmodule Exleader do
	def call(name, request), do: :gen_leader.leader_call(name, request)
	def call(name, request, timeout), do: :gen_leader.leader_call(name, request, timeout)
	def cast(name, request), do: :gen_leader.leader_cast(name, request)
end

defmodule Exleader.Behaviour do
	defmacro __using__(_) do
		quote location: :keep do
			@behaviour :gen_leader
			def init([]), do: {:ok, []}
			
			def elected(state, _election, :undefined), do: {:ok, [], state}
			def elected(state, _election, _election), do: {:reply, [], state}
			
			def surrendered(state, _synch, _election), do: {:ok, state}

			def handle_leader_call(_request, _from, state, _election), do: {:reply, :ok, state}
			def handle_leader_cast(_request, state, _election), do: {:noreply, state}

			def from_leader(_synch, state, _election), do: {:ok, state}
			def handle_DOWN(_node, state, _election), do: {:ok, state}
			def handle_call(_request, _from, state, _election), do: {:ok, :ok, state}
			def handle_cast(_msg, state, _election), do: {:noreply, state}
			def handle_info(_inof, state), do: {:noreply, state}

			def terminate(_reason, _state), do: :ok

			def code_change(_oldvsn, state, _election, _extra), do: {:ok, state} 
		
			defoverridable [
				init: 1, 
				elected: 3, 
				surrendered: 3, 
				handle_leader_call: 4, 
				handle_leader_cast: 3,
				from_leader: 3,
				handle_DOWN: 3,
				handle_call: 4,
				handle_cast: 3,
				handle_info: 2,
				terminate: 2,
				code_change: 4
			]
		end
	end
end

defmodule Messager do
	use Exleader.Behaviour

	def start_link, do: start_link([:erlang.node|:erlang.nodes])
	def start_link(nodes), do: start_link(nodes)

	def elected(state, _election, :undefined) do
		IO.puts "Elected as leader, starting priting..."
		Exleader.cast Messager, :print_time
		{:ok, [], state}
	end
	def elected(state, _election, _node), do: {:ok, [], state}

	def handle_leader_cast(:print_time, state, _election) do
		IO.puts "Priting time"
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