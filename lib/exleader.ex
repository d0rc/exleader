defmodule Exleader do
	def call(name, request), do: :gen_leader.leader_call(name, request)
	def call(name, request, timeout), do: :gen_leader.leader_call(name, request, timeout)
	def cast(name, request), do: :gen_leader.leader_cast(name, request)
end

defmodule Exleader.Behaviour do
	defmacro __using__(_) do
		quote location: :keep do
			@behaviour :gen_leader

			def start_link do 
				start_link([:erlang.node|:erlang.nodes])
			end
			def start_link(nodes) do
				start_link(nodes, [])
			end
			def start_link(nodes, seed) when is_list(nodes) and is_atom(seed) do
				start_link(nodes, {:seed_node, seed})
			end
			def start_link(nodes, opts) do
				:gen_leader.start_link(Messager, nodes, opts, Messager, [], [])
			end

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