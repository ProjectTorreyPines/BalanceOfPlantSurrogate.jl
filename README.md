# BalanceOfPlantSurogate

The BalanceOfPlantSurogate is a surogate model to the FUSE.ActorBalanceOfPlant actor in FUSE, this is done by simple interpolate/extrapolate of a hypercube

Some example of setting up the data generation:

'''julia
    using BalanceOfPlantSurogate
    hyper_cube = BalanceOfPlantSurogate.generate_hypercube()
    BalanceOfPlantSurogate.run_hypercube!(hyper_cube, "/Users/slendebroek/.julia/dev/BalanceOfPlantSurogate/data")
'''
