Higher order types constraints could be very powerfull.

Consider a function `tmap` which maps a function over a tuple. That is,

```haskell
tmap f (a,b) = (f a, f b)
tmap f (a,b,c) = (f a, f b, f c)
...
```

One might imagine having a class, `TMap`, that would help us with this.

```haskell
class TMap func vecA vecB | func vecA -> vecB where
	tmap :: func -> vecA -> vecB

instance TMap (a -> b) a b where
	tmap f a = f a

instance TMap (a -> b) (a,a) (b,b) where
	tmap f (a1, a2) = (f a1, f a2)

...
```

One might even imagine being able to do something like in a really cool compiler,

```haskell
instance TMap (a -> b) (a^n) (b^n) where
   ....
```


Now let's imagine using it.

```haskell
Prelude> let f name = "Holy " ++ name ++ " Batman!"
Prelude> tmap f "jelly beans"
"Holy jelly beans, Batman!"
Prelude> tmap f ("kitties", "cats")
("Holy kitties, Batman!","Holy cats, Batman!")
Prelude>  tmap f ("cat","dog","mouse")
("Holy cat, Batman!","Holy dog, Batman!","Holy mouse, Batman!")
Prelude> -- So far, so good
Prelude> -- Now, let's do something more interestng
Prelude> tmap show ("cat","dog")

<interactive>:1:1:
    No instance for (TMap (a0 -> String) ([Char], [Char]) vecB0)
      arising from a use of `tmap'
    Possible fix:
      add an instance declaration for
      (TMap (a0 -> String) ([Char], [Char]) vecB0)
    In the expression: tmap show ("cat", "dog")
    In an equation for `it': it = tmap show ("cat", "dog")

Prelude> -- OK, it doesn't like the polymorphism of show.
Prelude> -- That sucks, but we can make do.
Prelude> tmap (show :: String -> String) ("cat","dog")
("\"cat\"","\"dog\"")
Prelude> -- What if we want to do something like this though?
Prelude> tmap show (1,"foo")
<compiler shouts a lot>
```

It simply can't be done. And that *really* sucks.

In order for something like this to be possible, we'd need to cick our type system up a notch. Here's what I'm thinking:

```haskell
class (Constraint cons) => TMap cons veca vecb where
	tmap :: (cons a b => a -> b) -> veca -> vecb

instance (cons a b) => TMap cons a b where
	tmap f a = f a

instance (cons a1 b1, cons a2 b2) => TMap cons (a1, a2) (b1, b2) where
	tmap f (a1, a2) = (f a1, f a2)
```

The basic idea is that constraints, in addition to types, can be variables. `(Constraint cons) =>` tells the compiler that `cons` is going to be a constraint variable instead of a type variable. Then `TMap` acts on the three variables, a constraint variable `cons`, a type variable `veca` and a second type variable `vecb`, providing a function `tmap` which takes a first argument, of a function with its inpute and output described by our constraint -- `(cons a b => a -> b)` -- and yielding a function from `veca` to `vecb`.

After that, we begin declaring instances. The key part is stating how the constraint needs to relate to the type variables, in order for the instance to be valid (for example: `(cons a1 b1, cons a2 b2) => `).

These are trivial examples. Are there more interesting ones? Certainly.


