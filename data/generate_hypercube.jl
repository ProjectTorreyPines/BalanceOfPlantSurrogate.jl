using DataFrames
using FUSE
using CSV
using ProgressMeter

FUSE.logging(Logging.Info; actors=Logging.Error);

mutable struct BalanceOfPlantHyperCubee
    cases :: AbstractArray
    df :: DataFrames.DataFrame
end

"""
    generate_hypercube(;var_steps::Int=2,cycle_types::Vector{Symbol}=[:rankine, :brayton],
        power_range=(lower=1e6,upper=1e9),breeder_heat_load_fraction_range=(lower=0.5,upper=0.99),
        divertor_heat_load_fraction_range=(lower=0.1,upper=0.9))

Initialize the balance of plant hypercube

    The power to each system is done like:
        total_power 
       |          | (1 - breeder_fraction)
    breeder     div+wall
                 |     |   (1 - div_fraciton)
                div   wall
"""
function generate_hypercube(;var_steps::Int=2,cycle_types::Vector{Symbol}=[:rankine, :brayton],
        power_range=(lower=1e6,upper=1e9),breeder_heat_load_fraction_range=(lower=0.5,upper=0.99),
        divertor_heat_load_fraction_range=(lower=0.1,upper=0.9))
    
    
    df_bop_results = FUSE.DataFrame(cycle_type = Symbol[], total_power=Float64[], breeder_heat_load=Float64[], diverter_heatload=Float64[], wall_heat_load=Float64[], thermal_efficiency_cycle=Float64[])

    power_scan = log10range(power_range.lower,power_range.upper,var_steps)
    breeder_scan = LinRange(breeder_heat_load_fraction_range.lower , breeder_heat_load_fraction_range.upper, var_steps)
    diverter_scan = LinRange(divertor_heat_load_fraction_range.lower , divertor_heat_load_fraction_range.upper, var_steps)
    
    cases = collect(Iterators.product(cycle_types, power_scan, breeder_scan, diverter_scan))
    return BalanceOfPlantHyperCubee(cases, df_bop_results)
end


function log10range(start_value, stop_value, num_points)
    return 10 .^ LinRange(log10(start_value), log10(stop_value), num_points)
end


function workflow(df_res::DataFrames.DataFrame,cycle_type::Symbol,total_power::Float64, bf::Float64, df::Float64)

    dd = IMAS.dd()
    act= FUSE.ParametersActors()
    
    dd.balance_of_plant.power_plant.power_cycle_type = string(cycle_type)
 
    non_bf = 1. - bf
    
    act.ActorThermalPlant.model = :network
    act.ActorThermalPlant.external_heat_loads = [bf * total_power, non_bf * total_power * df, non_bf * total_power * (1. - df)]
    actor_balance_of_plant = FUSE.ActorBalanceOfPlant(dd,act.ActorBalanceOfPlant,act)

    actor_balance_of_plant.thermal_plant_actor.power_cycle_type = cycle_type
   
    thermal_eff = 0.0
    try

        FUSE.finalize(FUSE.step(actor_balance_of_plant))
        thermal_eff = @ddtime (dd.balance_of_plant.thermal_efficiency_cycle)
    catch e
        if isa(e, InterruptException)
            rethrow(e)
        end
        show(e)
    finally
        push!(df_res, (cycle_type, total_power, bf, df, 1-df, thermal_eff))
    end
    return nothing
end

"""
    run_hypercube!(hyper_cube::BalanceOfPlantHyperCubee, save_folder::String)

Runs the hypercube with pmap or map depending if you loaded Distributed
"""
function run_hypercube!(hyper_cube::BalanceOfPlantHyperCubee, save_folder::String)
    println()
    if @isdefined Distributed
        println("running $(length(hyper_cube.cases)) cases on $(nworkers()) workers")
        @showprogress  pmap(case -> workflow(hyper_cube.df,case...), hyper_cube.cases)
    else
        println("running $(length(hyper_cube.cases)) cases serially")
        @showprogress  map(case -> workflow(hyper_cube.df,case...), hyper_cube.cases)
    end

    CSV.write(joinpath(save_folder,"BalanceOfPlantHypercubeN=$(length(hyper_cube.df.thermal_efficiency_cycle)).csv"), hyper_cube.df)

    return hyper_cube
end
