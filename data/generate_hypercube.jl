using DataFrames
using FUSE
using CSV
using ProgressMeter

FUSE.logging(Logging.Info; actors=Logging.Error);

mutable struct BalanceOfPlantHyperCube
    cases::AbstractArray
    df::Union{DataFrames.DataFrame,Nothing}
end

"""
    generate_hypercube(;var_steps::Int=2,cycle_types::Vector{Symbol}=[:rankine, :brayton],
        power_range=(lower=1e6,upper=1e9),breeder_heat_load_fraction_range=(lower=0.5,upper=0.99),
        divertor_heat_load_fraction_range=(lower=0.1,upper=0.9))

Initialize the balance of plant hypercube

    The power to each system is done like:
          total
          |   | (1 - breeder_fraction)
    breeder   div+wall
              |      |   (1 - div_fraciton)
            div      wall
"""
function generate_hypercube(; var_steps::Int=2, cycle_types::Vector{Symbol}=[:rankine, :brayton],
    power_range=(lower=1e6, upper=1e9), breeder_heat_load_fraction_range=(lower=0.5, upper=0.99),
    divertor_heat_load_fraction_range=(lower=0.1, upper=0.9))

    power_scan = log10range(power_range.lower, power_range.upper, var_steps)
    breeder_scan = LinRange(breeder_heat_load_fraction_range.lower, breeder_heat_load_fraction_range.upper, var_steps)
    divertor_scan = LinRange(divertor_heat_load_fraction_range.lower, divertor_heat_load_fraction_range.upper, var_steps)

    cases = collect(Iterators.product(cycle_types, power_scan, breeder_scan, divertor_scan))
    return BalanceOfPlantHyperCube(cases, nothing)
end


function log10range(start_value, stop_value, num_points)
    return 10 .^ LinRange(log10(start_value), log10(stop_value), num_points)
end


function workflow_case(cycle_type::Symbol, total_heat_load::Float64, bf::Float64, df::Float64)

    dd = IMAS.dd()
    act = FUSE.ParametersActors()

    bop = dd.balance_of_plant

    bop.time = [0.0]
    dd.global_time = 0.0

    non_bf = 1.0 - bf
    @ddtime(bop.power_plant.heat_load.breeder = bf * total_heat_load)
    @ddtime(bop.power_plant.heat_load.divertor = non_bf * total_heat_load * df)
    @ddtime(bop.power_plant.heat_load.wall = non_bf * total_heat_load * (1.0 - df))

    act.ActorThermalPlant.model = :network
    bop.power_plant.power_cycle_type = string(cycle_type)
    FUSE.ActorThermalPlant(dd, act)

    thermal_eff_cycle = @ddtime (bop.thermal_efficiency_cycle)
    thermal_eff_plant = @ddtime (bop.thermal_efficiency_plant)

    return (cycle_type, total_heat_load, bf, df, 1 - df, thermal_eff_cycle, thermal_eff_plant)
end

"""
    run_hypercube!(hyper_cube::BalanceOfPlantHyperCube, save_folder::String)

Runs the hypercube with pmap or map depending if you loaded Distributed
"""
function run_hypercube!(hyper_cube::BalanceOfPlantHyperCube, save_folder::String)
    println()
    if @isdefined Distributed
        println("running $(length(hyper_cube.cases)) cases on $(nworkers()) workers")
        results = @showprogress pmap(case -> workflow_case(case...), hyper_cube.cases)
    else
        println("running $(length(hyper_cube.cases)) cases serially")
        results = @showprogress map(case -> workflow_case(case...), hyper_cube.cases)
    end

    hyper_cube.df = DataFrame(results, [:cycle_type, :total_heat_load, :breeder_heat_load, :divertor_heat_load, :wall_heat_load, :thermal_efficiency_cycle, :thermal_efficiency_plant])

    CSV.write(joinpath(save_folder, "BalanceOfPlantHypercubeN=$(length(hyper_cube.df.thermal_efficiency_plant)).csv"), hyper_cube.df)

    return hyper_cube
end
