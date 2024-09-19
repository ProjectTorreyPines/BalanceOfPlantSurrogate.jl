using DataFrames
using CSV
using Interpolations

mutable struct BOPSurogate
    data :: DataFrames.DataFrame
    thermal_efficiency
end

function BOPSurogate(cycle_type::Symbol)
    df = DataFrames.DataFrame(CSV.File(joinpath(BalanceOfPlantSurogate.__BalanceOfPlantSurogate__,"data","BalanceOfPlantHypercubeN=16.csv")))
    df = filter(row -> row.cycle_type == string(cycle_type), df)

    sort!(df, [:total_power, :breeder_heat_load, :diverter_heatload,:wall_heat_load])
    total_power = sort(unique(df.total_power))
    breeder_heat_load = sort(unique(df.breeder_heat_load))
    diverter_heatload = sort(unique(df.diverter_heatload))

    thermal_efficiency_cycle = Array{Float64}(undef, size(total_power)..., size(breeder_heat_load)..., size(diverter_heatload)...)
    for (k, row) in enumerate(eachrow(df))
        thermal_efficiency_cycle[k] = row.thermal_efficiency_cycle
    end

    itp = interpolate((log10.(total_power), breeder_heat_load, diverter_heatload), thermal_efficiency_cycle, Gridded(Linear()))#, Flat()

    return BOPSurogate(df, itp)
end

function predict_thermal_efficiency(BOP_sur::BOPSurogate,total_power::Float64,breeder_heat_load::Float64,diverter_heatload::Float64)
    return BOP_sur.thermal_efficiency(log10(total_power), breeder_heat_load,diverter_heatload)
end