using Test
using BalanceOfPlantSurogate

@testset "BalanceOfPlantSurogate" begin
    for cycle in [:rankine, :brayton]
        BOPSur = BalanceOfPlantSurogate.BOPSurogate(cycle)
        @assert !isnan(BalanceOfPlantSurogate.predict_thermal_efficiency(BOPSur,1e7,0.9,0.1))
    end
end
