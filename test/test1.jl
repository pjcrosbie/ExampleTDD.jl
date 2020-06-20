# file test/test1.jl
srcroot = "$(dirname(@__FILE__))/../src"
include("$srcroot/solve_linear.jl")

A = rand(5,5)
b = rand(5)

println(
  """

    norm(linear_system(A, b) - A\b)):
      ==> $(norm(linear_system(A, b) - A\b))
  """
  )
