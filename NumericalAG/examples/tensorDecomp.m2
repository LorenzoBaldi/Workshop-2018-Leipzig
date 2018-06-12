needsPackage "MonodromySolver"

-- IN: s, a sequence giving the tensor format
-- OUT: indices for the tensor's entries
makeParameterIndices = s -> (
    d:=#s;
    if d==1 then return toList apply(0..(first s-1),i->sequence(i))
    else (
	r:=makeParameterIndices(drop(s,-1));
	flatten apply(last s,i->toList apply(r,t->append(t,i)))
	)
    )

isBalanced = s -> (
    s':=sort toList s;
    (last s' < #s'+ product drop(s',-1) - sum drop(s',-1))
    )

-- IN: s, a sequence giving the tensor format,
--     j, indexing a rank-1 tensor appearing in a rank decomposition
-- OUT: variable indices in the format (summand, slice, entry)
-- in each summand, we normalize the first coordinate of all but the last factor
-- to remove trivial degrees of freedom
makeVariableIndices = (s,j) -> (
    d:=#s;
    flatten apply(d,n-> (
	    if n==d-1 then start:=0 else start=1;
	    apply(toList(start..(s#n-1)),i->(j,n,i)
	    )))
	)

-- IN: s, a sequence of integers giving the tensor format
--     r, a putative tensor rank
-- todo: 1) give options for specifying parameter symbol
tensorDecompFamily = method(Options=>{})
tensorDecompFamily (Sequence, ZZ) := o ->  (s,r) -> (
    --paramter ring generated by the coordinate of a generic tensor of given format
    w:=symbol w;
    S:=CC[apply(makeParameterIndices dimSlices,ind->w_ind)];
    --variable ring generated by coordinates of a factorization
    x:=symbol x;
    R:=S[apply(flatten apply(r,j->makeVariableIndices(dimSlices,j)),ind->x_ind)];
    polySystem apply(makeParameterIndices s,ind -> w_ind_R - sum apply(r,i-> (
		product apply(d,k-> (
			if ind#k == 0 and k<d-1 then return 1
			else return x_(i,k,ind#k)_R)))))
    )


bezoutNumber = method(Options=>{})
bezoutNumber List := o -> L -> product apply(L,e->first degree e)
bezoutNumber PolySystem := o -> P -> bezoutNumber equations P

end

restart
needs "tensorDecomp.m2"

dimSlices=(2,3,3)-- example tensor format
isBalanced dimSlices
d=#dimSlices
L=toList dimSlices
dimRatio=(product L)/(1-d+sum L) -- is integer?
r=ceiling dimRatio

P=tensorDecompFamily(dimSlices, r)
bezoutNumber P
setRandomSeed 0
(V,npaths)=monodromySolve P;
sols=points V.PartialSols;
#sols
