# Simulink and Simscape Extension

The MATLAB framework provides boundary conditions, component data contracts, and regression values for a later physical-system model.

## Recommended plant partitions

1. Battery cells, modules, thermal interfaces, and cooling plate.
2. Integrated drive-unit thermal mass and coolant jacket.
3. Propulsion coolant network with pump, restrictions, radiator, fan, and reservoir.
4. Refrigerant loop with compressor, condenser, expansion devices, cabin evaporator, and battery heat exchanger.
5. Cabin moist-air volume and heat loads.

## Recommended control partitions

1. Battery cooling request and temperature hysteresis.
2. Pump and fan speed control.
3. Compressor speed command.
4. Refrigerant branch allocation between battery and cabin.
5. Thermal derating of propulsion or charging power.

Keep plant parameters separate from controller settings. Use the MATLAB CSV results as regression checks when each Simulink subsystem is introduced.

The architecture follows the component, circuit, control, and drive-cycle separation described in the MathWorks EV thermal-management overview. It does not reproduce or redistribute a MathWorks example model.
