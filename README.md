Higher order types constraints could be very powerfull.

Consider a function `pointwise`, as in pointwise addition of addition.

We might think of it as:

```haskell
class PointwiseApplicable func vecA vecB vecResult where
	pointwise :: func -> vecA -> vecB -> vecResult

instance PointwiseApplicable (a -> b -> c) a b c where
	pointwise f = f

instance PointwiseApplicable (a -> b -> c) (a,a) (b,b) (c,c) where
	pointwise f (a1, a2) (b1, b2) = (f a1 b1, f a2 b2)

...
```

There's several problems with this. The most immediate is that it is highly
 tedious, and no finite amount of work can cover vectors of an arbitrary rate,
normally, but one could use templating to solve this.

Alternativly, one could imagine a compiler being able to support something like 

```haskell
instance PointwiseApplicable (a -> b -> c) (a^n) (b^n) (c^n) where
   ....
```

Or even us being able to directly define

```haskell
pointwise :: (a -> b -> c) -> a^n -> b^n -> c^n
```

But this still isn't right. Consider `(Pointwise (+))`: it really ought to be able to add
two `(Int, Real)` vectors, but under this scheme wouldn't be able to.

Instead, imagine if one could 'catch' constrainst of arguments and not deal with them as specific types but as constrained type variables, for example

```haskell
pointwise :: (cons a b c => a -> b -> c) -> ...
```

(nb. Any constraints on subsets of a b c can be absorbed into the larger constraint.)

Then imagine that we could have "higher-order" constraints, which take constraints as an argument. In particular, let us consider a hypothetical constraint which I'll call `VectorPromote3`. It would take a constraint on 3 types and produce a new constraint on 3 types that would accept any vectors as long as the corresponding components were appropriate for the given constraint.

For example, suppose we have the following `Additive` class, similar to what is seen in the [Functional Dependency page](http://www.haskell.org/haskellwiki/Functional_dependencies) on Haskell Wiki.

```haskell
class Additive a b c | a b -> c where
  (+) :: a -> b -> c

instance Additive Real Real Real where
  ...

isntance Additive Int Int Int where
  ...
```

Then once could have things like `VectorPromote3 Additive (Real, Int) (Real, Int) (Real, Int)` -- which makes sense, since you should really be able to add two `(Real, Int)` s. 

We could now give a proper type signature for our pointwise function:

```haskell
pointwise :: (VectorPromote3 cons veca vecb vecc) => (cons => a -> b -> c) -> veca -> vecb -> vecc
```

Yay!

This is just one example of how awesome higher order type constraints would be.

... So, can such a thing be implemented and type checked?

We're going to find out ;-)
