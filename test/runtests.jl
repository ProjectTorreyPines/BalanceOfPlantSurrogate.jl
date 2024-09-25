using Test
using BalanceOfPlantSurrogate

@testset "BalanceOfPlantSurrogate" begin
    for cycle in [:rankine, :brayton]
        BOPSur = BalanceOfPlantSurrogate.BOPSurogate(cycle)
        @assert !isnan(BalanceOfPlantSurrogate.predict_thermal_efficiency(BOPSur,1e7,0.9,0.1))
    end
end
