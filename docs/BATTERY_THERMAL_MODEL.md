# Battery thermal model

The archived design study resolves heat flow from the cell casing through two
lateral epoxy paths and one base path into the coolant channel.

## Single-cell network

<img src="images/battery_single_cell_network.png" width="620" alt="Single-cell construction and thermal-resistance network">

<img src="images/battery_single_cell_equivalent.png" width="620" alt="Single-cell equivalent thermal circuit">

The reconstructed equivalent resistances are `16.67 K/W` for each lateral path
and `3.10 K/W` from the cell base to the coolant channel.

## Cell-row network

<img src="images/battery_three_cell_network.png" width="620" alt="Three-cell construction and thermal-resistance network">

<img src="images/battery_three_cell_equivalent.png" width="620" alt="Three-cell equivalent thermal circuit">

## Module-row network

<img src="images/battery_module_network.png" width="680" alt="Nine-cell module-row thermal network">

The transient MATLAB model uses the base resistance for a lumped cell-to-plate
energy balance. Lateral resistance is retained in the sensitivity calculation,
but the current uniform-cell model does not predict spatial cell gradients.
