# Inmobiliaria Virtual en Elixir

Sistema multiusuario que simula una inmobiliaria virtual con concurrencia, persistencia y mensajería en tiempo real.

## Arquitectura

```
proyecto_inmobiliaria/
├── lib/
│   └── inmobiliaria/
│       ├── application.ex       # Punto de entrada, árbol de supervisión
│       ├── server.ex            # Servidor CLI principal, despachador de comandos
│       ├── property.ex          # GenServer individual por propiedad
│       ├── supervisor.ex        # Documentación del árbol de supervisión
│       ├── user_manager.ex      # Gestión de usuarios (GenServer)
│       ├── property_manager.ex  # Catálogo y operaciones de propiedades (GenServer)
│       ├── message_manager.ex   # Mensajería entre usuarios (GenServer)
│       └── location.ex          # Validación de ubicaciones
├── data/
│   ├── users.dat                # Usuarios: username|rol|contraseña|puntaje
│   ├── properties.dat           # Propiedades: todos los campos separados por |
│   ├── results.log              # Historial de operaciones
│   ├── messages.log             # Mensajes entre usuarios
│   └── locations.dat            # Ubicaciones válidas
├── test/
│   └── inmobiliaria_test.exs    # Suite de tests
└── mix.exs
```

## Árbol de Supervisión

```
Inmobiliaria.Supervisor (one_for_one)
├── Inmobiliaria.PropertySupervisor (DynamicSupervisor)
│   └── Inmobiliaria.Property    ← uno por cada propiedad publicada
├── Inmobiliaria.UserManager     ← GenServer, maneja estado de usuarios
├── Inmobiliaria.PropertyManager ← GenServer, catálogo central
├── Inmobiliaria.MessageManager  ← GenServer, mensajería persistida
└── Inmobiliaria.Server          ← CLI interactivo (lee stdin)
```

### Por qué cada propiedad es un proceso independiente

Cada `Inmobiliaria.Property` es un **GenServer** registrado con un ID único vía `Registry`. Esto garantiza que:

- Las solicitudes de compra/arriendo sobre **la misma propiedad** se serializan automáticamente (solo una puede completarse).
- Un fallo en una propiedad no afecta al resto del sistema.
- Se pueden procesar **miles de propiedades en paralelo**.

## Instalación y ejecución

### Requisitos
- Elixir 1.14+
- Erlang/OTP 25+

### Iniciar el sistema

```bash
cd proyecto_inmobiliaria
mix deps.get
mix run --no-halt
```

### Ejecutar tests

```bash
mix test
```

## Comandos disponibles

### Conexión y sesión

| Comando | Descripción |
|---------|-------------|
| `connect <usuario> <contraseña> [rol]` | Conectarse (o registrarse automáticamente) |
| `disconnect` | Cerrar sesión |
| `quit` | Salir del sistema |
| `help` | Mostrar ayuda |

**Roles disponibles:** `cliente`, `vendedor`, `arrendador`

### Propiedades (vendedor / arrendador)

```bash
publish_property tipo=casa modalidad=venta ubicacion=Armenia precio=300000000 habitaciones=4 area=180
```

**Tipos válidos:** `casa`, `apartamento`, `oficina`, `lote`  
**Modalidades:** `venta`, `arriendo`

### Consultas (todos los roles)

```bash
# Listar todas las propiedades
list_properties

# Con filtros
list_properties tipo=casa modalidad=venta
list_properties ubicacion=Armenia precio_min=100000000 precio_max=400000000
list_properties status=disponible

# Detalle de una propiedad
get_property prop001

# Ver ubicaciones válidas
locations
```

### Operaciones (cliente)

```bash
buy_property prop001     # Comprar una propiedad en venta
rent_property prop001    # Arrendar una propiedad en arriendo
```

### Mensajería

```bash
send_message prop001 Hola, ¿sigue disponible?   # Enviar mensaje al publicador
inbox prop001                                     # Ver mensajes de una propiedad
my_messages                                       # Ver mensajes recibidos (propietario)
```

### Ranking y puntaje

```bash
my_score                  # Ver puntaje propio
ranking                   # Ranking global
ranking cliente           # Solo clientes
ranking vendedor          # Solo vendedores
ranking arrendador        # Solo arrendadores
```

## Flujo de ejemplo completo

```
# Terminal 1 - Carlos (vendedor)
[sin sesión]> connect carlos 1234 vendedor
✓ Registrado y conectado como carlos (rol: vendedor)

[carlos(vendedor)]> publish_property tipo=casa modalidad=venta ubicacion=Armenia precio=300000000 habitaciones=4 area=180
✓ Propiedad publicada exitosamente:
  ID:          prop001
  Tipo:        casa
  Modalidad:   venta
  ...

# Terminal 2 - Ana (cliente, conexión simultánea)
[sin sesión]> connect ana 4321 cliente
✓ Registrado y conectado como ana (rol: cliente)

[ana(cliente)]> list_properties
  ID      | Tipo         | Modalidad | Ubicación       | Precio          | Estado
-----...
  prop001 | casa         | venta     | Armenia         | $300.000.000    | disponible

[ana(cliente)]> send_message prop001 Hola, ¿sigue disponible la casa?
✓ Mensaje enviado a la propiedad prop001.

[ana(cliente)]> buy_property prop001
✓ ¡Compra exitosa!
  Propiedad:  prop001 (casa en Armenia)
  Precio:     $300.000.000
  Estado:     vendida
  Puntos obtenidos: +10 (total: 10)

# Carlos revisa sus mensajes y puntaje
[carlos(vendedor)]> my_messages
  [prop001] ana: Hola, ¿sigue disponible la casa?

[carlos(vendedor)]> my_score
Tu puntaje actual: 15 puntos

# Ranking global
[carlos(vendedor)]> ranking
  Pos | Usuario            | Rol          | Puntaje
-------------------------------------------------------
    1 | carlos             | vendedor     | 15
    2 | ana                | cliente      | 10
```

## Puntos por operación

| Operación | Cliente | Propietario |
|-----------|---------|-------------|
| Compra    | +10     | +15         |
| Arriendo  | +8      | +12         |

## Formato de archivos de persistencia

### users.dat
```
username|rol|contraseña|puntaje
carlos|vendedor|1234|15
ana|cliente|4321|10
```

### properties.dat
```
id|tipo|modalidad|ubicacion|precio|habitaciones|area|status|owner|client
prop001|casa|venta|Armenia|300000000|4|180|vendida|carlos|ana
```

### results.log
```
2026-05-01; cliente=ana; responsable=carlos; propiedad=prop001; operacion=compra; ubicacion=Armenia; precio=300000000; status=Completada
```

### messages.log
```
2026-05-01 10:30:00Z|prop001|ana|Hola, ¿sigue disponible la casa?
```

## Manejo de concurrencia

El sistema garantiza consistencia bajo carga concurrente mediante:

1. **GenServer por propiedad**: Todas las operaciones sobre `propXXX` pasan por la cola de mensajes del proceso `Inmobiliaria.Property`. Elixir garantiza que los mensajes se procesan de uno en uno → no hay condiciones de carrera.

2. **DynamicSupervisor**: Inicia y supervisa procesos Property en tiempo de ejecución. Si un proceso falla, se reinicia automáticamente.

3. **Registry**: Permite localizar procesos Property por ID de forma concurrente y eficiente.

```elixir
# Ejemplo: dos clientes intentan comprar al mismo tiempo
Task.async(fn -> PropertyManager.operate("prop001", "ana", "compra") end)
Task.async(fn -> PropertyManager.operate("prop001", "pedro", "compra") end)

# Resultado garantizado:
# → {:ok, prop}      (uno gana)
# → {:error, "..."}  (el otro pierde)
```

## Tests

```bash
mix test --trace
```

Los tests cubren:
- Registro y autenticación de usuarios
- Publicación y consulta de propiedades
- Filtros de búsqueda
- Operaciones de compra y arriendo
- **Test de concurrencia**: 5 clientes simultáneos → solo 1 compra exitosa
- Mensajería entre usuarios
- Validación de ubicaciones
- Ranking y puntajes
