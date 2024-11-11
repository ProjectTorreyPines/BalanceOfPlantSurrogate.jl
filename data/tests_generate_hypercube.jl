using Test
using Pkg
using BalanceOfPlantSurrogate

Pkg.activate(@__DIR__)

@testset "BalanceOfPlantSurrogate Tests" begin
    include(joinpath(@__DIR__,"generate_hypercube.jl"))
    hyper_cube = generate_hypercube()
    @assert !isempty(hyper_cube.cases)
    N = 2
    map(case -> workflow(hyper_cube.df,case...), hyper_cube.cases[1:N]);
    @assert length(hyper_cube.df.thermal_efficiency_cycle)==N
end
