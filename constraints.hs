{-

Types can be thought of as tight parity 1 constraints on type variables:

   Foo ≅ (Foo a) -> a

Higher order types constraints could be very powerfull.

Consider a function pointwise, as in pointwise addition of addition.

We might think of it as:

class PointwiseApplicable func vecA vecB vecResult where
	pointwise :: func -> vecA -> vecB -> vecResult

instance PointwiseApplicable (a -> b -> c) a b c where
	pointwise f = f

instance PointwiseApplicable (a -> b -> c) (a,a) (b,b) (c,c) where
	pointwise f (a1, a2) (b1, b2) = (f a1 b1, f a2 b2)

...

There's several problems with this. The most immediate is that it is highly
 tedious, and no finite amount of work can cover vectors of an arbitrary rate,
normally, but one could use templating to solve this.

Alternativly, one could imagine a compiler being able to support something like 

instance PointwiseApplicable (a -> b -> c) (a^n) (b^n) (c^n) where
   ....

Or even us being able to directly define

pointwise :: (a -> b -> c) -> a^n -> b^n -> c^n

But this still isn't right. Consider (Pointwise (+)): it really ought to be able to add
two (Int, Real) vectors, but under this scheme wouldn't be able to.

Instead, imagine if one could 'catch' constrainst of arguments and not deal with them as specific types but as constrained type variables, for example

pointwise :: (cons a b c => a -> b -> c) -> ...

(nb. Any constraints on subsets of a b c can be absorbed into the larger constraint.)

Then imagine that we could have "higher-order" constraints, which take constraints as an argument. In particular, let us consider a hypothetical constraint which I'll call VectorPromote3. It would take a constraint on 3 types and produce a new constraint on 3 types that would accept any vectors as long as the corresponding components were appropriate for the given constraint.

For example, suppose we have

class Aditive a b c | a b -> c where
  (+) :: a -> b -> c

instance Real Real Real where
  ...

isntance Int Int Int where
  ...

Then once could have things like VectorPromote3 Additive (Real, Int) (Real, Int) (Real, Int) -- which makes sense, since you should really be able to add two (Real, Int) s. 

We could now give a proper type signature for our pointwise function:

pointwise :: (VectorPromote3 cons veca vecb vecc) => (cons => a -> b -> c) -> veca -> vecb -> vecc

Yay!

This is just one example of how awesome higher order type constraints would be.

... So, can such a thing be implemented and type checked?

We're going to find out ;-)

-}


-- There isn't actually such a thning as a type. There's a type constraint and the type variable we care about.

-- Let's start by representing the usual constraint system

type TypeVariable = Int

data Constraint = Constraint String [TypeVariable] deriving (Eq)

data TypeExpression = TypeExpression TypeVariable [Constraint]

instance Show Constraint where
	show (Constraint name vars) = name ++ " " ++ (foldl1 (\a b -> a ++ " " ++ b) (map show vars))

expandVar ::
	TypeVariable
	-> [Constraint]
	-> (String,
	    [Constraint])
expandVar var constraints =
	let
		isSpecial (Constraint ('T':':':xs) [relvar]) = var == relvar
		isSpecial (Constraint "List"  (_:relvar:[]))    = var == relvar
		isSpecial (Constraint "Func"  (_:_:relvar:[]))  = var == relvar
		isSpecial (Constraint "Tuple" vars)  = last vars == var
		isSpecial _ = False
		specials = filter isSpecial constraints
		(expansion, used) = if null specials then (show var, []) else case specials !! 0 of 
			Constraint ('T':':':typename) _ -> 
				(typename, [specials !! 0])
			Constraint "List" (a:_) -> 
				("[" ++ fst (expandVar a constraints) ++ "]",
				 [specials !! 0] ++ snd (expandVar a constraints) )
			Constraint "Func" (a:b:_)   -> 
				(fst (expandVar a constraints) ++ "->" ++ fst (expandVar b constraints),
				 [specials !! 0] ++ snd (expandVar a constraints) ++ snd (expandVar b constraints) )
			Constraint "Tuple" vars -> 
				("(" ++ foldl1 (\a b -> a ++ ", " ++ b) (map (\v -> fst $ expandVar v constraints) (init vars)) ++ ")",
				 [specials !! 0] ++ (concat $ map ( \v -> snd $ expandVar v constraints) (init vars) ) )
	in (expansion, used)

instance Show TypeExpression where
	show (TypeExpression var constraints) = 
		let
			(body, used) = expandVar var constraints
			unused = filter (\x -> not $ elem x used) constraints
		in
			if null unused
			then body
			else "(" ++ foldl1 (\a b -> a ++ ", " ++ b) (map show unused) ++ ") => " ++ body

--instance Show Constraint where
--	show Constraint
