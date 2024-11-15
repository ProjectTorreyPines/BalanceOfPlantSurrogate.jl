module BalanceOfPlantSurrogate

using DataFrames
using CSV
using Interpolations

mutable struct BOPsurrogate
    data::DataFrames.DataFrame
    thermal_efficiency
end

"""
    (BOP::BOPsurrogate)(breeder_heat_load::Float64, divertor_heat_load::Float64, wall_heat_load::Float64)

Returns thermal efficiency of a BOP cycle given powers in W
"""
function (BOP::BOPsurrogate)(breeder_heat_load::Float64, divertor_heat_load::Float64, wall_heat_load::Float64)
    return thermal_efficiency(BOP, breeder_heat_load, divertor_heat_load, wall_heat_load)
end

"""
    BOPsurrogate(cycle_type::Symbol; data::String="BalanceOfPlantHypercubeN=10000.csv")

Loads BOP surrogate model for a specific cycle type [:rankine, :brayton]
"""
function BOPsurrogate(cycle_type::Symbol; data::AbstractString="BalanceOfPlantHypercubeN=10000.csv")
    @assert cycle_type in (:rankine, :brayton)
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

    return BOPsurrogate(df, itp)
end

export BOPsurrogate

"""
    thermal_efficiency_fractions(BOP::BOPsurrogate, total_heat_load::Float64, breeder_fraction::Float64, divertor_fraction::Float64)

Predict thermal efficiency given a BOP cycle total power and fractions defined as

          total
          |   | (1 - breeder_fraction)
    breeder   div+wall
              |      |   (1 - div_fraciton)
            div      wall
"""
function thermal_efficiency_fractions(BOP::BOPsurrogate, total_heat_load::Float64, breeder_fraction::Float64, divertor_fraction::Float64)
    @assert 0 <= breeder_fraction <= 1
    @assert 0 <= divertor_fraction <= 1
    return BOP.thermal_efficiency(log10(total_heat_load), breeder_fraction, divertor_fraction)
end

export thermal_efficiency_fractions

"""
    thermal_efficiency(BOP::BOPsurrogate, breeder_heat_load::Float64, divertor_heat_load::Float64, wall_heat_load::Float64)

Predict thermal efficiency given a BOP cycle and powers in W
"""
function thermal_efficiency(BOP::BOPsurrogate, breeder_heat_load::Float64, divertor_heat_load::Float64, wall_heat_load::Float64)
    total_heat_load = breeder_heat_load + divertor_heat_load + wall_heat_load
    breeder_fraction = breeder_heat_load / total_heat_load
    divertor_fraction = divertor_heat_load / (total_heat_load - breeder_heat_load)
    return thermal_efficiency_fractions(BOP, total_heat_load, breeder_fraction, divertor_fraction)
end

export thermal_efficiency

const document = Dict()
document[Symbol(@__MODULE__)] = [name for name in Base.names(@__MODULE__, all=false, imported=false) if name != Symbol(@__MODULE__)]

end
