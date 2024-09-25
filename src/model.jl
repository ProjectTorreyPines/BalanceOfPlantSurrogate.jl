using DataFrames
using CSV
using Interpolations

mutable struct BOPSurogate
    data :: DataFrames.DataFrame
    thermal_efficiency
end

function BOPSurogate(cycle_type::Symbol;data::String="BalanceOfPlantHypercubeN=3600.csv")
    df = DataFrames.DataFrame(CSV.File(joinpath(BalanceOfPlantSurogate.__BalanceOfPlantSurogate__,"data",data)))
    df = filter(row -> row.cycle_type == string(cycle_type), df)

    sort!(df, [:diverter_heatload, :breeder_heat_load, :total_power])
    total_power = unique(df.total_power)
    breeder_heat_load = unique(df.breeder_heat_load)
    diverter_heatload = unique(df.diverter_heatload)

    thermal_efficiency_plant = Array{Float64}(undef, size(total_power)..., size(breeder_heat_load)..., size(diverter_heatload)...)
    for (k, row) in enumerate(eachrow(df))
        thermal_efficiency_plant[k] = row.thermal_efficiency_plant
    end

    itp = extrapolate(interpolate((log10.(total_power), breeder_heat_load, diverter_heatload), thermal_efficiency_plant, Gridded(Linear())), Flat())

    return BOPSurogate(df, itp)
end

function predict_thermal_efficiency(BOP_sur::BOPSurogate,total_power::Float64,breeder_heat_load::Float64,diverter_heatload::Float64)
    @assert 0 <= breeder_heat_load <=1
    @assert 0 <= diverter_heatload <=1
    return BOP_sur.thermal_efficiency(log10(total_power), breeder_heat_load,diverter_heatload)
end