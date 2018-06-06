-- Lists all moments of the univariate Gaussian
listOfMoments = (d,R) -> (
  S := R[t]/t^(d+1);
  use S;
  g := gens R;
  a := g_0*t + 1/2 * g_1^2 * t^2;
  b := exp(a);
  li := for i from 1 to d list i! * coefficient(t^i,b);
  use R;
  li
)

--Gaussian

momentIdeal = (d, R)->(
    -- Append auxilliary vars to construct power series
    (S, phi) :=  flattenRing(R[mn, sd]);
    T := S[t]/t^(d+1);
    use T;
    g := gens R;
    series := exp(phi(mn)*t+(1/2)*phi(sd)^2*t^2);
    I := ideal for i from 1 to d list i!*coefficient(t^i,series)-phi(g#i);
    -- Construct map from S back to the original ring R
    psi := map(R, S, (for i from 0 to #g-1 list phi(g#i) => g#i) | {phi(mn) => 0, phi(sd) => 0});
    psi(eliminate({phi(mn),phi(sd)},I))
    )

--Exponential mixture
--takes highest  degree d of moments and number of mixtures
--NEEDS TO EB HOMOGENISED, NEEDS TO FIX DOUBLE ELIMINATE
momentIdealExponential = (mix,d) ->(
    R:=QQ[lam_1..lam_mix,alp_1..alp_mix,m_0..m_d];
    I:=ideal (for i from 1 to d list -m_i+sum for j from 1 to mix list alp_j*lam_j^i*i!) +
       ideal(-1+sum for i from 1 to mix list alp_i);
    eliminate ((for j from 1 to mix list alp_j)|(for i from 1 to mix list lam_i) ,I)
)

--Gaussian Mixtures
--takes as input the number of mixtures and the highest degree of moments appearing
--computes the homogeneous moment ideal by eliminating the means and standard deviations
momentIdealGaussian = (mix,d)->(
    R:=QQ[mn_1..mn_mix,sd_1..sd_mix,a_1..a_mix,m_0..m_d][t]/t^(d+1);
    series:=sum for i from 1 to mix list a_i*exp(mn_i*t+(1/2)*sd_i^2*t^2);
    I:=ideal for i from 1 to d list i!*coefficient(t^i,series)-m_i+ideal(-1+sum for i from 1 to mix list a_i);
    homogenize(eliminate((for i from 1 to mix list a_i)|(for i from 1 to mix list mn_i)|(for i from 1 to mix list sd_i),I),m_0)
)

--------------------------------------------------------------------------------------

momentMapGaussians =  (n,d) -> (
      
  par:=toList(x_1..x_n);
  for i from 1 to n do (for j from i to n do (par=append(par,s_(i,j))) );
  par=toSequence(par);
  R := QQ[par];
  mu := matrix({toList(x_1..x_n)});
  Sigma := genericSymmetricMatrix(R,s_(1,1),n);
     
  S := R[t_1..t_n]/((ideal(t_1..t_n))^(d+1));
  use S;
  a := vars(S)*transpose(mu) + (1/2) * vars(S)*Sigma*transpose(vars(S));
  MGF := exp(a_(0,0));
  
  
  (M,C):=coefficients(MGF);
  use R;
  C = mutableMatrix(C);
  lM :=  flatten (entries M);
  lexpM := flatten (apply(lM,mon->exponents(mon)));
  c := 1;
  for i from 0 to numColumns(M)-1 do (
      (for e in lexpM_i do c = c*(e!));
      -- (for m in ( (entries vars S)_0 ) do c = c*((degree(m,M_(0,i)))!));
      C_(i,0) = c*C_(i,0);
      c=1;
      );
  C = matrix(C);
  C=lift(C,R);
  
  momvars := toSequence reverse (apply(lexpM,e->m_e));
  
  return (matrix({(reverse((entries(transpose(C)))_0))}),momvars);
     
)   	    	    	

-- This computes the homogeneous ideal of the moment variety.

momentVarietyGaussians = (n,d) -> (
    
  (C,momvars) := momentMapGaussians(n,d);   
  R := ring(C);
  k := coefficientRing(R);
    
  PPM := k[momvars];
  varmoms := gens PPM;
  f := map(R,PPM,C);
  I := kernel f;
  I = homogenize(I,varmoms_0);
  
  return I;  
   
)

-------------------------------------------------------------------------------------

--Poisson Mixtures
--takes as input the number of mixtures and the highest degree of moments appearing
--computes the homogeneous moment ideal 
momentIdealPoisson = (mix,d)->(
    R:=QQ[lambda_1..lambda_mix,a_1..a_mix,m_0..m_d][t]/t^(d+1);
    series:=sum for i from 1 to mix list a_i*exp(lambda_i*(exp(t)-1));
    I:=ideal for i from 1 to d list i!*coefficient(t^i,series)-m_i+ideal(-1+sum for i from 1 to mix list a_i);
    homogenize(eliminate((for i from 1 to mix list a_i)|(for i from 1 to mix list lambda_i),I),m_0)
)

--Gaussian Mixtures Test
--written to eliminate a_mix
momentIdealGaussianTest = (mix,d)->(
    if mix == 1 then(
	R:=QQ[mn_1..mn_mix,sd_1..sd_mix,m_0..m_d][t]/t^(d+1);
    	series:= exp(mn_1*t+(1/2)*sd_1^2*t^2);
    	I:=ideal for i from 1 to d list i!*coefficient(t^i,series)-m_i;
    	return homogenize(eliminate((for i from 1 to mix list mn_i)|(for i from 1 to mix list sd_i),I),m_0);)
    else( 
	R:=QQ[mn_1..mn_mix,sd_1..sd_mix,a_1..a_(mix-1),m_0..m_d][t]/t^(d+1);
    	amix := 1 - sum for i from 1 to mix-1 list a_i;
    	series:=sum for i from 1 to mix-1 list a_i*exp(mn_i*t+(1/2)*sd_i^2*t^2) + amix*exp(mn_mix*t+(1/2)*sd_mix^2*t^2);
    	I:=ideal for i from 1 to d list i!*coefficient(t^i,series)-m_i;
    	return homogenize(eliminate((for i from 1 to mix-1 list a_i)|(for i from 1 to mix list mn_i)|(for i from 1 to mix list sd_i),I),m_0))
)


--computing the moment ideal for the multinomial distribution
--k = #possible outcomes
--n = #trials
--p_1,..,p_k are the probabilities of each outcome so that their sum is 1
--t_1..t_k are the variables of the moment generating function
--d is the truncation order
momentIdealMultinomial = (k,n,d) -> (
    S := QQ[t_1..t_k];
    exps := flatten apply(toList(0..d), i->flatten entries basis(i,S) / exponents / flatten);
    quotientExps := flatten entries basis(d+1,S) / exponents / flatten;
    Mons := ideal(apply(quotientExps, e->S_e));
    R := QQ[p_1..p_k,apply(exps,i->m_i)][t_1..t_k];
    Mons = sub(Mons,R);
    R = R / Mons;
    use R;
    series := (sum apply(toList(1..k), j-> p_j*exp(t_j)))^n; --moment gen fxn of the multinomial distribution
    I := ideal( apply(exps, e-> (sum e)!*coefficient(sub(S_e,R),series)-m_e) ) + ideal( 1 - sum apply(toList(1..k), i -> p_i));
    T := QQ[apply(exps,i->m_i)];
    homogenize(sub((eliminate(toList(p_1..p_k),I),T)),m_(exps#0))
)