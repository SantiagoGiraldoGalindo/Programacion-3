defmodule Snake.Game do
  @moduledoc "Lógica principal del juego Snake"
  @width 40
  @height 15
  @initial_delay 150

  defstruct snake: [{10, 7}, {9, 7}, {8, 7}],
            direction: :right,
            next_direction: :right,
            food: {20, 7},
            score: 0,
            over: false

  def start(player_name) do
    IO.write("\e[H\e[2J")
    IO.puts("🐍 ¡A jugar! #{player_name}")
    IO.puts("Controles: W=Arriba | S=Abajo | A=Izquierda | D=Derecha | Q=Salir")
    Process.sleep(1000)

    state = %__MODULE__{}
    game_loop(state, player_name, @initial_delay)
  end

  defp game_loop(state, player_name, delay) do
    IO.write("\e[H\e[2J")
    render(state)

    if state.over do
      IO.puts("\n❌ ¡GAME OVER!")
      IO.puts("Puntuación final: #{state.score}")
      Snake.Player.update_score(player_name, state.score)
      :game_over
    else
      direction = get_input_non_blocking()

      case direction do
        :quit ->
          IO.puts("\n👋 ¡Juego terminado!")
          :quit
        _ ->
          new_state = state
            |> validate_direction(direction)
            |> step()

          new_delay = if state.score > 0 and rem(state.score, 50) == 0 do
            max(50, delay - 10)
          else
            delay
          end

          Process.sleep(new_delay)
          game_loop(new_state, player_name, new_delay)
      end
    end
  end

  defp get_input_non_blocking do
    case IO.getn("", 1) do
      "w" -> :up
      "W" -> :up
      "s" -> :down
      "S" -> :down
      "a" -> :left
      "A" -> :left
      "d" -> :right
      "D" -> :right
      "q" -> :quit
      "Q" -> :quit
      _ -> nil
    end
  rescue
    _ -> nil
  end

  defp validate_direction(state, direction) when direction != nil do
    case {state.direction, direction} do
      {:up, :down} -> state
      {:down, :up} -> state
      {:left, :right} -> state
      {:right, :left} -> state
      _ -> %{state | next_direction: direction}
    end
  end

  defp validate_direction(state, _), do: state

  defp step(state) do
    direction = state.next_direction
    [head | tail] = state.snake
    new_head = move(head, direction)

    cond do
      out_of_bounds?(new_head) ->
        %{state | over: true}

      new_head in state.snake ->
        %{state | over: true}

      new_head == state.food ->
        new_food = random_food(state.snake)
        %{
          state
          | snake: [new_head | state.snake],
            food: new_food,
            score: state.score + 10,
            direction: direction
        }

      true ->
        %{
          state
          | snake: [new_head | Enum.drop(tail, -1)],
            direction: direction
        }
    end
  end

  defp move({x, y}, :up), do: {x, y - 1}
  defp move({x, y}, :down), do: {x, y + 1}
  defp move({x, y}, :left), do: {x - 1, y}
  defp move({x, y}, :right), do: {x + 1, y}

  defp out_of_bounds?({x, y}) do
    x < 0 or x >= @width or y < 0 or y >= @height
  end

  defp random_food(snake) do
    pos = {Enum.random(0..(@width - 1)), Enum.random(0..(@height - 1))}
    if pos in snake, do: random_food(snake), else: pos
  end

  def render(state) do
    board = Enum.map_join(0..(@height - 1), "\n", fn y ->
      Enum.map_join(0..(@width - 1), "", fn x ->
        pos = {x, y}

        cond do
          pos == hd(state.snake) -> "◉"
          pos in tl(state.snake) -> "●"
          pos == state.food -> "🍎"
          true -> " "
        end
      end)
    end)

    border = "┌" <> String.duplicate("─", @width) <> "┐"
    bottom = "└" <> String.duplicate("─", @width) <> "┘"

    IO.puts(border)
    board |> String.split("\n") |> Enum.each(&IO.puts("│" <> &1 <> "│"))
    IO.puts(bottom)
    IO.puts("📊 Puntuación: #{state.score} | 🐍 Longitud: #{length(state.snake)}")
  end
end
