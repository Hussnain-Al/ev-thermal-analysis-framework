# Examples

Each example runs one analysis with the shared configuration from
`system_config.m` in the project root.

```matlab
cfg = setup_project;
battery = run_battery_analysis(cfg);
cycles = run_drive_cycle_analysis(cfg);
driveUnit = run_drive_unit_analysis(cfg,cycles.summary);
hydraulics = run_cooling_loop_analysis(cfg);
cabin = run_cabin_load_analysis(cfg);
```

Use `run_all` for the complete workflow. The examples contain orchestration
and plotting only. Reusable equations and data-processing functions are in
`src/calculations`.
