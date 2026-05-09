# reluctant-handling

In-game vehicle handling editor with live parameter editing and XML code view.

Open the editor with **F7** or the command `/handling`.

---

## Permission Setup

By default permissions are **disabled** — anyone can open the editor. To restrict access, enable the ACE check in `config.lua`:

```lua
Config.checkAce = true
Config.ace      = 'reluctant.handling'  -- change this if you want a different ace node
```

Then grant the ace to whoever should have access in your **server.cfg**.

### Allow a specific Steam identifier

```
add_ace identifier.steam:110000112345678 reluctant.handling allow
```

### Allow a group (e.g. admins)

```
add_ace group.admin reluctant.handling allow
```

Make sure the player is already in that group:

```
add_principal identifier.steam:110000112345678 group.admin
```

### Allow everyone (same as leaving checkAce false)

```
add_ace builtin.everyone reluctant.handling allow
```

---

## Config Reference

| Option | Default | Description |
|---|---|---|
| `Config.cmdName` | `'handling'` | Chat command to open the editor |
| `Config.keybind` | `'F7'` | Default keybind |
| `Config.checkAce` | `false` | Enable ACE permission check |
| `Config.ace` | `'reluctant.handling'` | ACE permission node to check |
