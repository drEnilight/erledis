defmodule Erledis do
  defmacro createGenServer(name) do
    quote do
      defmodule unquote(name) do
        use GenServer

        # API

        def start_link do
          GenServer.start_link(__MODULE__, [], name: __MODULE__)
        end

        @spec get(String.t()) :: list
        def get(key) do
          case is_binary(key) do
            true  -> GenServer.call(__MODULE__, {:get, key})
            false -> error_message()
          end
        end

        @spec push(String.t(), any) :: any
        def push(key, value) do
          case is_binary(key) do
            true  -> GenServer.call(__MODULE__, {:push, {key, value}})
            false -> error_message()
          end
        end

        @spec pop(String.t()) :: any
        def pop(key) do
          case is_binary(key) do
            true  -> GenServer.call(__MODULE__, {:pop, key})
            false -> error_message()
          end
        end

        @spec del(String.t()) :: boolean
        def del(key) do
          case is_binary(key) do
            true  -> GenServer.call(__MODULE__, {:del, key})
            false -> error_message()
          end
        end

        @spec exists?(String.t()) :: boolean
        def exists?(key) do
          case is_binary(key) do
            true  -> GenServer.call(__MODULE__, {:exists, key})
            false -> error_message()
          end
        end

        @spec flushall :: boolean
        def flushall do
          GenServer.call(__MODULE__, :flushall)
        end

        defp error_message do
          "key argument must be a string"
        end

        # CALLBACKS

        def init(_) do
          map = %{}
          {:ok, map}
        end

        def handle_call({:get, key}, _from, map) do
          case Map.get(map, key <> "_read") || Map.get(map, key <> "_write") do
             nil -> {:reply, [], map}
            list -> list = join_two_queues(map, key)
                    {:reply, list, map}
          end
        end

        def handle_call({:push, {key, value}}, _from,  map) do
          case Map.get(map, key <> "_read") || Map.get(map, key <> "_write") do
            empty when empty in [[], nil] -> push_to_empty_queue(map, key, value)
                                     list -> case Map.get(map, key <> "_write") do
                                                nil -> map = Map.put(map, key <> "_write", [value])
                                                       {:reply, value, map}
                                               list -> map = Map.put(map, key <> "_write", [value | list])
                                                       {:reply, value, map}
                                              end
                                      end
        end

        def handle_call({:pop, key}, _from,  map) do
          case Map.get(map, key <> "_read") do
            empty when empty in [[], nil] ->  case Map.get(map, key <> "_write") do
                                                 nil -> {:reply, nil, map}
                                                list -> {map, list} = reverse_writing_queue(map, list, key)
                                                        {map, value} = pop_reading_queue(map, list, key)
                                                        {:reply, value, map}
                                              end
                                     list -> {map, value} = pop_reading_queue(map, list, key)
                                             {:reply, value, map}
          end
        end

        def handle_call({:del, key}, _from, map) do
          case Map.get(map, key <> "_read") || Map.get(map, key <> "_write") do
             nil -> {:reply, false, map}
            list -> map = map
                          |> Map.delete(key <> "_read")
                          |> Map.delete(key <> "_write")
                    {:reply, true, map}
          end
        end

        def handle_call({:exists, key}, _from, map) do
          case Map.get(map, key <> "_read") || Map.get(map, key <> "_write") do
             nil -> {:reply, false, map}
            list -> {:reply, true, map}
          end
        end

        def handle_call(:flushall, _from, map) do
          map = %{}
          {:reply, true, map}
        end

        defp get_queue_values(map, key) do
          case Map.get(map, key) do
            empty when empty in [[], nil] -> []
                                     list -> list
          end
        end

        defp join_two_queues(map, key) do
          read_queue = get_queue_values(map, key <>  "_read")
          write_queue = get_queue_values(map, key <>  "_write") |> Enum.reverse
          read_queue ++ write_queue
        end

        defp push_to_empty_queue(map, key, value) do
          map = Map.put(map, key <> "_read", list = [value])
          {:reply, list, map}
        end

        defp pop_reading_queue(map, list, key) do
          [value | tail] = list
          map = Map.put(map, key <> "_read", tail)
          {map, value}
        end

        defp reverse_writing_queue(map, list, key) do
          reverse_list = list |> Enum.reverse
          map = Map.delete(map, key <> "_write")
          Map.put(map, key <> "_read", reverse_list)
          {map, reverse_list}
        end
      end
    end
  end

  def generate_gen_server do
    s_name = String.to_atom("server-" <> "#{:rand.uniform}")
    {:module, name, _, _} = createGenServer(s_name)
    name
  end
end
