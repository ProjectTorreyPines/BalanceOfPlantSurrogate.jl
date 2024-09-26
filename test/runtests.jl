using Test
using BalanceOfPlantSurrogate

@testset "BalanceOfPlantSurrogate" begin
    for cycle in [:rankine, :brayton]
        BOP = BalanceOfPlantSurrogate.BOPSurogate(cycle)

        breeder_heat_load = 1E7
        divertor_heat_load = 1E6
        wall_heat_load = 1E6

        res1 = BalanceOfPlantSurrogate.thermal_efficiency(BOP, breeder_heat_load, divertor_heat_load, wall_heat_load)
        @test !isnan(res1)

        res2 = BOP(breeder_heat_load, divertor_heat_load, wall_heat_load)
        @test res1 == res2
    end
end
