# file test/solve_linear_test.jl
srcroot = "$(dirname(@__FILE__))/../src"
include("$srcroot/solve_linear.jl")

using Test: @test



ϵ = 1e-12

for n = 10:10:100
  for T = 1:10
    A = rand(n,n); e = ones(n); b = A*e;
    x = linear_system(A, b)
    κ = cond(A)
    @test norm(x - e) < ϵ*κ
    @test norm(A*x - b) < ϵ*κ
  end
end
