# BalanceOfPlantSurrogate.jl

The BalanceOfPlantSurrogate is a surogate model to the FUSE.ActorBalanceOfPlant actor in FUSE, this is done by simple interpolate/extrapolate of a hypercube.

The data generation is done inside the ```BalanceOfPlantSurrogate/src/data``` folder , checkout the notebook in that folder!

To run the surogate model:

```julia
using BalanceOfPlantSurrogate

BOP = BalanceOfPlantSurrogate.BOPSurogate(:rankine) # :rankine or :brayton
breeder_heat_load = 5e8
divertor_heat_load = 4e8
wall_heat_load = 0.5e8
plant_efficiency = BOP(breeder_heat_load, divertor_heat_load, wall_heat_load)
```
