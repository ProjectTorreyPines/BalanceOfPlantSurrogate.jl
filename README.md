# BalanceOfPlantSurogate

The BalanceOfPlantSurogate is a surogate model to the FUSE.ActorBalanceOfPlant actor in FUSE, this is done by simple interpolate/extrapolate of a hypercube

The data generation is done inside the ```BalanceOfPlantSurogate/src/data``` folder , checkout the notebook in that folder!

To run the surogate model::

```julia
using BalanceOfPlantSurogate

bop_sur = BalanceOfPlantSurogate.BOPSurogate(:rankine)
total_heat_load = 5e8
breeder_heat_load = 4e8
divertor_heat_load = 0.5e8
plant_efficiency = BalanceOfPlantSurogate.predict_thermal_efficiency(bop_sur, total_heat_load, breeder_heat_load/total_heat_load, divertor_heat_load / (total_heat_load - breeder_heat_load))
```
