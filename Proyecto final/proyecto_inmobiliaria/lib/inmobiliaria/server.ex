defmodule Inmobiliaria.Server do
  @moduledoc """
  Servidor principal: lee comandos desde stdin y los despacha.
  Soporta múltiples sesiones concurrentes mediante tareas (Task).

  Comandos disponibles:
    connect <usuario> <contraseña> [rol]
    disconnect
    publish_property tipo=X modalidad=X ubicacion=X precio=X habitaciones=X area=X
    list_properties [tipo=X] [modalidad=X] [ubicacion=X] [precio_min=X] [precio_max=X] [status=X]
    get_property <id>
    buy_property <id>
    rent_property <id>
    send_message <id_propiedad> <mensaje...>
    my_messages
    inbox
    my_score
    ranking [cliente|vendedor|arrendador]
    locations
    help
    quit
  """
  use GenServer

  alias Inmobiliaria.{UserManager, PropertyManager, MessageManager, Location}

  @results_file "data/results.log"

  # Puntos por operación
  @points_client_buy 10
  @points_owner_sell 15
  @points_client_rent 8
  @points_owner_rent 12

  # ── Arranque ─────────────────────────────────────────────────────────────────

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    Location.init()
    File.mkdir_p!("data")
    # Inicia el loop de lectura en un proceso separado
    Task.start(fn -> input_loop() end)
    {:ok, state}
  end

  # ── Loop de entrada ───────────────────────────────────────────────────────────

  defp input_loop do
    print_banner()
    session = %{user: nil}
    repl(session)
  end

  defp repl(session) do
    prompt =
      if session.user do
        "[#{session.user.username}(#{session.user.role})]> "
      else
        "[sin sesión]> "
      end

    IO.write(prompt)

    case IO.gets("") do
      :eof ->
        IO.puts("\nConexión cerrada.")

      {:error, reason} ->
        IO.puts("Error de entrada: #{inspect(reason)}")

      line ->
        line = String.trim(line)

        if line != "" do
          {output, new_session} = handle_command(line, session)
          IO.puts(output)
          repl(new_session)
        else
          repl(session)
        end
    end
  end

  # ── Despachador de comandos ───────────────────────────────────────────────────

  defp handle_command("quit", session) do
    if session.user do
      UserManager.disconnect(session.user.username)
    end

    IO.puts("Hasta luego.")
    System.halt(0)
    {"", session}
  end

  defp handle_command("help", session) do
    help = """

    ╔══════════════════════════════════════════════════════════╗
    ║            INMOBILIARIA VIRTUAL - COMANDOS               ║
    ╠══════════════════════════════════════════════════════════╣
    ║ CONEXIÓN                                                 ║
    ║  connect <usuario> <contraseña> [rol]                    ║
    ║    roles: cliente | vendedor | arrendador                ║
    ║  disconnect                                              ║
    ╠══════════════════════════════════════════════════════════╣
    ║ PROPIEDADES (vendedor/arrendador)                        ║
    ║  publish_property tipo=X modalidad=X ubicacion=X         ║
    ║    precio=X habitaciones=X area=X                        ║
    ╠══════════════════════════════════════════════════════════╣
    ║ CONSULTAS (todos)                                        ║
    ║  list_properties [filtros...]                            ║
    ║    filtros: tipo, modalidad, ubicacion,                  ║
    ║             precio_min, precio_max, status               ║
    ║  get_property <id>                                       ║
    ║  locations                                               ║
    ╠══════════════════════════════════════════════════════════╣
    ║ OPERACIONES (cliente)                                    ║
    ║  buy_property <id>                                       ║
    ║  rent_property <id>                                      ║
    ╠══════════════════════════════════════════════════════════╣
    ║ MENSAJES                                                 ║
    ║  send_message <id_prop> <texto...>                       ║
    ║  my_messages   (mensajes recibidos en mis props)         ║
    ║  inbox <id_prop> (mensajes de una propiedad)             ║
    ╠══════════════════════════════════════════════════════════╣
    ║ RANKING Y PUNTAJE                                        ║
    ║  my_score                                                ║
    ║  ranking [cliente|vendedor|arrendador]                   ║
    ╚══════════════════════════════════════════════════════════╝
    """

    {help, session}
  end

  # -- Conexión --

  defp handle_command("connect " <> rest, session) do
    parts = String.split(rest)

    case parts do
      [username, password | maybe_role] ->
        role = List.first(maybe_role)

        case UserManager.connect(username, password, role) do
          {:ok, user, :registered} ->
            msg = "✓ Registrado y conectado como #{user.username} (rol: #{user.role})"
            {msg, %{session | user: user}}

          {:ok, user, :logged_in} ->
            msg = "✓ Bienvenido de nuevo, #{user.username} (rol: #{user.role})"
            {msg, %{session | user: user}}

          {:error, reason} ->
            {"✗ Error: #{reason}", session}
        end

      _ ->
        {"✗ Uso: connect <usuario> <contraseña> [rol]", session}
    end
  end

  defp handle_command("disconnect", session) do
    case session.user do
      nil ->
        {"✗ No hay sesión activa.", session}

      user ->
        UserManager.disconnect(user.username)
        {"✓ Desconectado. Hasta pronto, #{user.username}.", %{session | user: nil}}
    end
  end

  # -- Publicación --

  defp handle_command("publish_property " <> rest, session) do
    with {:ok, user} <- require_login(session),
         :ok <- require_role(user, ["vendedor", "arrendador"]) do
      attrs = parse_kv(rest)

      required = ["tipo", "modalidad", "ubicacion", "precio", "habitaciones", "area"]
      missing = Enum.reject(required, &Map.has_key?(attrs, &1))

      if missing != [] do
        {"✗ Faltan campos: #{Enum.join(missing, ", ")}", session}
      else
        ubicacion = attrs["ubicacion"]

        location_ok =
          if Location.valid?(ubicacion) do
            true
          else
            IO.puts(
              "⚠ Ubicación '#{ubicacion}' no está en la lista de ubicaciones válidas. " <>
                "Use 'locations' para ver la lista. Se registrará de todas formas."
            )

            true
          end

        if location_ok do
          pub_attrs = %{
            tipo: attrs["tipo"],
            modalidad: attrs["modalidad"],
            ubicacion: ubicacion,
            precio: parse_int(attrs["precio"]),
            habitaciones: parse_int(attrs["habitaciones"]),
            area: parse_int(attrs["area"]),
            owner: user.username
          }

          case PropertyManager.publish(pub_attrs) do
            {:ok, prop} ->
              msg = """
              ✓ Propiedad publicada exitosamente:
                ID:          #{prop.id}
                Tipo:        #{prop.tipo}
                Modalidad:   #{prop.modalidad}
                Ubicación:   #{prop.ubicacion}
                Precio:      $#{format_price(prop.precio)}
                Habitaciones:#{prop.habitaciones}
                Área:        #{prop.area} m²
                Estado:      #{prop.status}
              """

              {String.trim(msg), session}

            {:error, reason} ->
              {"✗ Error publicando propiedad: #{reason}", session}
          end
        else
          {"✗ Operación cancelada.", session}
        end
      end
    else
      {:error, msg} -> {msg, session}
    end
  end

  # -- Listado de propiedades --

  defp handle_command("list_properties" <> rest, session) do
    attrs = parse_kv(String.trim(rest))

    filters =
      %{}
      |> maybe_put(:tipo, attrs["tipo"])
      |> maybe_put(:modalidad, attrs["modalidad"])
      |> maybe_put(:ubicacion, attrs["ubicacion"])
      |> maybe_put(:status, attrs["status"])
      |> maybe_put(:precio_min, attrs["precio_min"] && parse_int(attrs["precio_min"]))
      |> maybe_put(:precio_max, attrs["precio_max"] && parse_int(attrs["precio_max"]))

    properties = PropertyManager.list(filters)

    if properties == [] do
      {"No se encontraron propiedades con los filtros indicados.", session}
    else
      rows =
        Enum.map_join(properties, "\n", fn p ->
          "  #{p.id} | #{String.pad_trailing(p.tipo, 12)} | #{String.pad_trailing(p.modalidad, 8)} | " <>
            "#{String.pad_trailing(p.ubicacion, 15)} | $#{format_price(p.precio)} | #{p.status}"
        end)

      header =
        "\n  ID      | Tipo         | Modalidad | Ubicación       | Precio          | Estado\n" <>
          String.duplicate("-", 85)

      {"#{header}\n#{rows}\n  Total: #{length(properties)} propiedad(es)", session}
    end
  end

  # -- Detalle de propiedad --

  defp handle_command("get_property " <> prop_id, session) do
    prop_id = String.trim(prop_id)

    case PropertyManager.get(prop_id) do
      {:ok, p} ->
        msg = """

        ┌─────────────────────────────────────────┐
        │ Propiedad: #{String.pad_trailing(p.id, 30)}│
        ├─────────────────────────────────────────┤
        │ Tipo:        #{String.pad_trailing(p.tipo, 27)}│
        │ Modalidad:   #{String.pad_trailing(p.modalidad, 27)}│
        │ Ubicación:   #{String.pad_trailing(p.ubicacion, 27)}│
        │ Precio:      $#{String.pad_trailing(format_price(p.precio), 26)}│
        │ Habitaciones:#{String.pad_trailing(to_string(p.habitaciones), 27)}│
        │ Área:        #{String.pad_trailing("#{p.area} m²", 27)}│
        │ Estado:      #{String.pad_trailing(p.status, 27)}│
        │ Propietario: #{String.pad_trailing(p.owner, 27)}│
        └─────────────────────────────────────────┘
        """

        {String.trim(msg), session}

      {:error, reason} ->
        {"✗ #{reason}", session}
    end
  end

  # -- Compra --

  defp handle_command("buy_property " <> prop_id, session) do
    prop_id = String.trim(prop_id)

    with {:ok, user} <- require_login(session),
         :ok <- require_role(user, ["cliente"]) do
      case PropertyManager.operate(prop_id, user.username, "compra") do
        {:ok, prop} ->
          # Asignar puntos
          UserManager.add_points(user.username, @points_client_buy)
          UserManager.add_points(prop.owner, @points_owner_sell)
          # Registrar en results.log
          log_operation(user.username, prop, "compra")

          msg = """
          ✓ ¡Compra exitosa!
            Propiedad:  #{prop.id} (#{prop.tipo} en #{prop.ubicacion})
            Precio:     $#{format_price(prop.precio)}
            Estado:     #{prop.status}
            Puntos obtenidos: +#{@points_client_buy} (total: #{get_score(user.username)})
          """

          {String.trim(msg), session}

        {:error, reason} ->
          {"✗ No se pudo completar la compra: #{reason}", session}
      end
    else
      {:error, msg} -> {msg, session}
    end
  end

  # -- Arriendo --

  defp handle_command("rent_property " <> prop_id, session) do
    prop_id = String.trim(prop_id)

    with {:ok, user} <- require_login(session),
         :ok <- require_role(user, ["cliente"]) do
      case PropertyManager.operate(prop_id, user.username, "arriendo") do
        {:ok, prop} ->
          UserManager.add_points(user.username, @points_client_rent)
          UserManager.add_points(prop.owner, @points_owner_rent)
          log_operation(user.username, prop, "arriendo")

          msg = """
          ✓ ¡Arriendo exitoso!
            Propiedad:  #{prop.id} (#{prop.tipo} en #{prop.ubicacion})
            Precio:     $#{format_price(prop.precio)}
            Estado:     #{prop.status}
            Puntos obtenidos: +#{@points_client_rent} (total: #{get_score(user.username)})
          """

          {String.trim(msg), session}

        {:error, reason} ->
          {"✗ No se pudo completar el arriendo: #{reason}", session}
      end
    else
      {:error, msg} -> {msg, session}
    end
  end

  # -- Mensajería --

  defp handle_command("send_message " <> rest, session) do
    with {:ok, user} <- require_login(session) do
      case String.split(rest, " ", parts: 2) do
        [prop_id, text] ->
          case MessageManager.send_message(prop_id, user.username, text) do
            :ok ->
              {"✓ Mensaje enviado a la propiedad #{prop_id}.", session}

            _ ->
              {"✗ Error al enviar mensaje.", session}
          end

        _ ->
          {"✗ Uso: send_message <id_propiedad> <texto...>", session}
      end
    else
      {:error, msg} -> {msg, session}
    end
  end

  # Mensajes recibidos en mis propiedades (propietario)
  defp handle_command("my_messages", session) do
    with {:ok, user} <- require_login(session),
         :ok <- require_role(user, ["vendedor", "arrendador"]) do
      messages = MessageManager.get_owner_messages(user.username)

      if messages == [] do
        {"No tienes mensajes.", session}
      else
        rows =
          Enum.map_join(messages, "\n", fn m ->
            "  [#{m.property_id}] #{m.from}: #{m.text}  (#{m.timestamp})"
          end)

        {"\nMensajes recibidos:\n#{rows}", session}
      end
    else
      {:error, msg} -> {msg, session}
    end
  end

  # Mensajes de una propiedad específica
  defp handle_command("inbox " <> prop_id, session) do
    with {:ok, _user} <- require_login(session) do
      prop_id = String.trim(prop_id)
      messages = MessageManager.get_messages(prop_id)

      if messages == [] do
        {"No hay mensajes para la propiedad #{prop_id}.", session}
      else
        rows =
          Enum.map_join(messages, "\n", fn m ->
            "  #{m.from}: #{m.text}  (#{m.timestamp})"
          end)

        {"\nMensajes de #{prop_id}:\n#{rows}", session}
      end
    else
      {:error, msg} -> {msg, session}
    end
  end

  # -- Ranking y puntaje --

  defp handle_command("my_score", session) do
    with {:ok, user} <- require_login(session) do
      score = get_score(user.username)
      {"Tu puntaje actual: #{score} puntos", session}
    else
      {:error, msg} -> {msg, session}
    end
  end

  defp handle_command("ranking" <> rest, session) do
    role =
      case String.trim(rest) do
        "" -> nil
        r -> r
      end

    users = UserManager.ranking(role)

    if users == [] do
      {"No hay usuarios para mostrar.", session}
    else
      header =
        "\n  Pos | Usuario            | Rol          | Puntaje\n" <>
          String.duplicate("-", 55)

      rows =
        users
        |> Enum.with_index(1)
        |> Enum.map_join("\n", fn {u, i} ->
          "  #{String.pad_leading(to_string(i), 3)} | #{String.pad_trailing(u.username, 18)} | " <>
            "#{String.pad_trailing(u.role, 12)} | #{u.score}"
        end)

      {header <> "\n" <> rows, session}
    end
  end

  # -- Ubicaciones --

  defp handle_command("locations", session) do
    locs = Location.list()
    list = Enum.map_join(locs, "\n", &"  - #{&1}")
    {"\nUbicaciones válidas:\n#{list}", session}
  end

  # -- Fallback --

  defp handle_command(cmd, session) do
    {"✗ Comando desconocido: '#{cmd}'. Escribe 'help' para ver los comandos disponibles.",
     session}
  end

  # ── Helpers ──────────────────────────────────────────────────────────────────

  defp require_login(%{user: nil}), do: {:error, "✗ Debes conectarte primero. Usa: connect <usuario> <contraseña>"}
  defp require_login(%{user: user}), do: {:ok, user}

  defp require_role(user, allowed_roles) do
    if user.role in allowed_roles do
      :ok
    else
      {:error,
       "✗ Tu rol '#{user.role}' no tiene permiso para esta acción. " <>
         "Roles permitidos: #{Enum.join(allowed_roles, ", ")}"}
    end
  end

  defp parse_kv(str) do
    str
    |> String.split(~r/\s+/, trim: true)
    |> Enum.reduce(%{}, fn token, acc ->
      case String.split(token, "=", parts: 2) do
        [k, v] -> Map.put(acc, k, v)
        _ -> acc
      end
    end)
  end

  defp parse_int(str) do
    case Integer.parse(to_string(str)) do
      {n, _} -> n
      :error -> 0
    end
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp format_price(price) when is_integer(price) do
    price
    |> Integer.to_string()
    |> String.graphemes()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.join(".")
    |> String.reverse()
  end

  defp format_price(price), do: to_string(price)

  defp get_score(username) do
    case UserManager.get_user(username) do
      nil -> 0
      user -> user.score
    end
  end

  defp log_operation(client, prop, operation) do
    File.mkdir_p!("data")
    date = Date.utc_today() |> Date.to_string()

    line =
      "#{date}; cliente=#{client}; responsable=#{prop.owner}; " <>
        "propiedad=#{prop.id}; operacion=#{operation}; " <>
        "ubicacion=#{prop.ubicacion}; precio=#{prop.precio}; status=Completada\n"

    File.write!(@results_file, line, [:append])
  end

  defp print_banner do
    IO.puts("""

    ╔══════════════════════════════════════════════════════╗
    ║       INMOBILIARIA VIRTUAL EN ELIXIR v1.0            ║
    ║  Sistema multiusuario de propiedades en tiempo real  ║
    ╠══════════════════════════════════════════════════════╣
    ║  Escribe 'help' para ver los comandos disponibles.   ║
    ╚══════════════════════════════════════════════════════╝
    """)
  end
end
