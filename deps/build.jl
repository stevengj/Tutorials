using Literate

repo_src = joinpath(@__DIR__,"..","src")
notebooks_dir = joinpath(@__DIR__,"..","notebooks")

files = []

files = [
  "t001_poisson",
  "t002_validation",
  "t003_elasticity", 
  "t0041_p_laplacian", 
  "t004_hyperelasticity",
  "t005_dg_discretization",
  "t007_darcy"]

Sys.rm(notebooks_dir;recursive=true,force=true)
for file in files
  file_jl = file*".jl"
  Literate.notebook(joinpath(repo_src,file_jl), notebooks_dir; documenter=false, execute=false)
end
