# Newton air track mission

Run the interactive experiment from the repository root with Godot 4.7.2:

```sh
godot --path . res://stations/newton/mission.tscn
```

Choose an impulse from 2–8 N and switch between the 1 kg light sled and 4 kg
loaded sled. The comparison panel shows acceleration and time for both sleds
under the selected force. **Kızağı çalıştır** animates the selected sled along
the 40 m track; **Sıfırla** stops or resets the run. Force and mass stay locked
while it runs so the result remains tied to the displayed setup.

Acceleration, time to cover the track, and animated position/speed come from
`newton_sim.gd`. The mission only presents those values and animates the existing
rail, sled, gate, and thruster assets.

Review captures from the actual Godot scene are in `docs/review/`:

- `newton_mission_ready.png`
- `newton_mission_running.png`

To regenerate them with the desktop renderer:

```sh
godot --path . --rendering-method gl_compatibility --script res://stations/newton/capture_mission.gd
```
