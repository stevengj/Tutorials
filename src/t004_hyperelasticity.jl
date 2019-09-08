# # Tutorial 4: Hyperelasticity
#
#md # [![](https://mybinder.org/badge_logo.svg)](@__BINDER_ROOT_URL__/notebooks/t004_hyperelasticity.ipynb)
#md # [![](https://img.shields.io/badge/show-nbviewer-579ACA.svg)](@__NBVIEWER_ROOT_URL__/notebooks/t004_hyperelasticity.ipynb)
# 
# ## Problem statement

using Gridap
using LinearAlgebra

# Model
#model = CartesianDiscreteModel(domain=(0.0,0.5,0.0,10.0), partition=(4,80))
model = CartesianDiscreteModel(domain=(0.0,1.0,0.0,1.0), partition=(20,20))

# Construct the FEspace
order = 1
diritags = [1,2,5]
T = VectorValue{2,Float64}
fespace = CLagrangianFESpace(T,model,order,diritags)

g(x) = zero(T)
V = TestFESpace(fespace)
U = TrialFESpace(fespace,g)

# Setup integration
trian = Triangulation(model)
quad = CellQuadrature(trian,order=2)

neumtag = 6
btrian = BoundaryTriangulation(model,neumtag)
bquad = CellQuadrature(btrian,order=2)

# Material parameters
const λ = 30.0
const μ = 40.0

# Identity tensor
const I = one(TensorValue{2,Float64,4})

# Deformation Gradient
F(∇u) = I + ∇u'

J(F) = det(F)

#Green strain

E(F) = 0.5*( F'*F - I )

@law dE(x,∇du,∇u) = 0.5*( ∇du*F(∇u) + (∇du*F(∇u))' )

# Right Cauchy-green deformation tensor

C(F) = (F')*F

# Constitutive law (Neo hookean)

@law function S(x,∇u)
  Cinv = inv(C(F(∇u)))
  μ*(I-Cinv) + λ*log(J(F(∇u)))*Cinv
end

@law function dS(x,∇du,∇u)
  Cinv = inv(C(F(∇u)))
  _dE = dE(x,∇du,∇u)
  λ*inner(Cinv,_dE)*Cinv + 2*(μ-λ*log(J(F(∇u))))*Cinv*_dE*(Cinv')
end

# Cauchy stress tensor

@law σ(x,∇u) = (1.0/J(F(∇u)))*F(∇u)*S(x,∇u)*(F(∇u))'

# Weak form

res(u,v) = inner( dE(∇(v),∇(u)) , S(∇(u)) )

jac_mat(u,v,du) = inner( dE(∇(v),∇(u)), dS(∇(du),∇(u)) )

jac_geo(u,v,du) = inner( ∇(v), S(∇(u))*∇(du) )

jac(u,v,du) = jac_mat(u,v,du) + jac_geo(u,v,du)

t_Ω = NonLinearFETerm(res,jac,trian,quad)

t(x) = VectorValue(0.00,50.0)

source(v) = inner(v, t)

t_Γ = FESource(source,btrian,bquad)

# FE problem
op = NonLinearFEOperator(V,U,t_Ω,t_Γ)

# Define the FESolver
ls = LUSolver()
tol = 1.e-10
maxiters = 20
nls = NewtonRaphsonSolver(ls,tol,maxiters)
solver = NonLinearFESolver(nls)

# Solve!
free_vals = 0.00001*rand(Float64,num_free_dofs(U))
uh = FEFunction(U,free_vals)
solve!(uh,solver,op)

writevtk(trian,"results",nref=2,cellfields=["uh"=>uh,"sigma"=>σ(∇(uh))])

