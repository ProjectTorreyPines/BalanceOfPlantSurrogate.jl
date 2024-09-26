module BalanceOfPlantSurrogate

using DataFrames
using CSV
using Interpolations

mutable struct BOPSurogate
    data::DataFrames.DataFrame
    thermal_efficiency
end

function (bop::BOPSurogate)(breeder_heat_load::Float64, divertor_heat_load::Float64, wall_heat_load::Float64)
    return predict_thermal_efficiency(bop, breeder_heat_load, divertor_heat_load, wall_heat_load)
end

"""
    BOPSurogate(cycle_type::Symbol; data::String="BalanceOfPlantHypercubeN=10000.csv")

Loads hypercube interpolator

NOTE: in the CSV file :breeder_heat_load and :divertor_heat_load are really :breeder_fraction and :divertor_fraction
"""
function BOPSurogate(cycle_type::Symbol; data::String="BalanceOfPlantHypercubeN=10000.csv")
    df = DataFrames.DataFrame(CSV.File(joinpath(@__DIR__, "..", "data", data)))
    df = filter(row -> row.cycle_type == string(cycle_type), df)

    sort!(df, [:divertor_heat_load, :breeder_heat_load, :total_heat_load])
    total_heat_load = unique(df.total_heat_load)
    breeder_heat_load = unique(df.breeder_heat_load)
    divertor_heat_load = unique(df.divertor_heat_load)

    thermal_efficiency_plant = Array{Float64}(undef, size(total_heat_load)..., size(breeder_heat_load)..., size(divertor_heat_load)...)
    for (k, row) in enumerate(eachrow(df))
        thermal_efficiency_plant[k] = row.thermal_efficiency_plant
    end

    itp = extrapolate(interpolate((log10.(total_heat_load), breeder_heat_load, divertor_heat_load), thermal_efficiency_plant, Gridded(Linear())), Flat())

    return BOPSurogate(df, itp)
end

"""
    predict_thermal_efficiency_fractions(BOP_sur::BOPSurogate, total_heat_load::Float64, breeder_fraction::Float64, divertor_fraction::Float64)

Predict thermal efficiency given a BOP cycle total power and fractions defined as

          total
          |   | (1 - breeder_fraction)
    breeder   div+wall
              |      |   (1 - div_fraciton)
            div      wall
"""
function predict_thermal_efficiency_fractions(BOP_sur::BOPSurogate, total_heat_load::Float64, breeder_fraction::Float64, divertor_fraction::Float64)
    @assert 0 <= breeder_fraction <= 1
    @assert 0 <= divertor_fraction <= 1
    return BOP_sur.thermal_efficiency(log10(total_heat_load), breeder_fraction, divertor_fraction)
end

"""
    predict_thermal_efficiency(BOP_sur::BOPSurogate, breeder_heat_load::Float64, divertor_heat_load::Float64, wall_heat_load::Float64)

Predict thermal efficiency given a BOP cycle and powers in W
"""
function predict_thermal_efficiency(BOP_sur::BOPSurogate, breeder_heat_load::Float64, divertor_heat_load::Float64, wall_heat_load::Float64)
    total_heat_load = breeder_heat_load + divertor_heat_load + wall_heat_load
    breeder_fraction = breeder_heat_load / total_heat_load
    divertor_fraction = divertor_heat_load / (total_heat_load - breeder_heat_load)
    return predict_thermal_efficiency_fractions(BOP_sur, total_heat_load, breeder_fraction, divertor_fraction)
end


end # module BalanceOfPlantSurrogate
