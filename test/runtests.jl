using Test
using BalanceOfPlantSurogate  # Replace X with your package name

@testset "BalanceOfPlantSurogate Tests" begin
    hyper_cube = generate_hypercube()
    @assert !isempty(hyper_cube.cases)

    map(case -> BalanceOfPlantSurogate.workflow(hyper_cube.df,case...), hyper_cube.cases[1:2]);

    @assert length(hyper_cube.df.thermal_efficiency_cycle)
end