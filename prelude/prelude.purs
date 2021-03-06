module Prelude
  ( otherwise
  , flip
  , const
  , asTypeOf
  , Semigroupoid, (<<<), (>>>)
  , Category, id
  , ($), (#)
  , (:), cons
  , Show, show
  , Functor, (<$>), (<#>), void
  , Apply, (<*>)
  , Applicative, pure, liftA1
  , Bind, (>>=)
  , Monad, return, liftM1, ap
  , Semiring, (+), zero, (*), one
  , ModuloSemiring, (/), mod
  , Ring, (-)
  , (%)
  , negate
  , DivisionRing
  , Num
  , Eq, (==), (/=), refEq, refIneq
  , Ord, Ordering(..), compare, (<), (>), (<=), (>=)
  , Bits, (.&.), (.|.), (.^.), shl, shr, zshr, complement
  , BoolLike, (&&), (||)
  , not
  , Semigroup, (<>), (++)
  , Unit(..), unit
  ) where

  -- | An alias for `true`, which can be useful in guard clauses:
  -- |
  -- | E.g.
  -- |
  -- |     max x y | x >= y = x
  -- |             | otherwise = y
  otherwise :: Boolean
  otherwise = true

  -- | Flips the order of the arguments to a function of two arguments.
  -- |
  -- | E.g.
  -- |
  -- |     flip const 1 2 = const 2 1 = 2
  -- |
  flip :: forall a b c. (a -> b -> c) -> b -> a -> c
  flip f b a = f a b

  -- | Returns its first argument and ignores its second.
  -- |
  -- | E.g.
  -- |
  -- |     const 1 2 = 1
  -- |
  const :: forall a b. a -> b -> a
  const a _ = a

  -- | This function returns its first argument, and can be used to assert type equalities.
  -- | This can be useful when types are otherwise ambiguous.
  -- |
  -- | E.g.
  -- |
  -- |     main = print $ [] `asTypeOf` [0]
  -- |
  -- | If instead, we had written `main = print []`, the type of the argument `[]` would have
  -- | been ambiguous, resulting in a compile-time error.
  asTypeOf :: forall a. a -> a -> a
  asTypeOf x _ = x

  infixr 9 >>>
  infixr 9 <<<

  -- | A `Semigroupoid` is similar to a [`Category`](#category) but does not require an identity
  -- | element `id`, just composable morphisms.
  -- |
  -- | `Semigroupoid`s should obey the following rule:
  -- |
  -- | Association:
  -- |     `forall p q r. p <<< (q <<< r) = (p <<< q) <<< r`
  -- |
  class Semigroupoid a where
    (<<<) :: forall b c d. a c d -> a b c -> a b d

  instance semigroupoidArr :: Semigroupoid (->) where
    (<<<) f g x = f (g x)

  (>>>) :: forall a b c d. (Semigroupoid a) => a b c -> a c d -> a b d
  (>>>) f g = g <<< f

  -- | `Category`s consist of objects and composable morphisms between them, and as such are
  -- | [`Semigroupoids`](#semigroupoid), but unlike `semigroupoids` must have an identity element.
  -- |
  -- | `Category`s should obey the following rules.
  -- |
  -- | Left Identity:
  -- |     `forall p. id <<< p = p`
  -- |
  -- | Right Identity:
  -- |     `forall p. p <<< id = p`
  -- |
  class (Semigroupoid a) <= Category a where
    id :: forall t. a t t

  instance categoryArr :: Category (->) where
    id x = x

  infixr 0 $
  infixl 0 #

  -- | Applies a function to its argument
  -- |
  -- | E.g.
  -- |
  -- |     const $ 1 2 = const 1 2 = 1
  -- |
  -- | `($)` is different from [`(#)`](#-2) because it is right-infix instance instead of left.
  -- | Right-infix operators parse like (a $ (b $ (c $ (d ...)))) whereas left-infix operators parse
  -- | like (((a # b) # c) # d ...).
  -- |
  ($) :: forall a b. (a -> b) -> a -> b
  ($) f x = f x

  -- | Applies a function to its argument
  -- |
  -- | E.g.
  -- |
  -- |     3 # ((+) 1) = 3 + 1 = 4
  -- |
  -- | `(#)` is different from [`($)`](#-1) because it is left-infix instance instead of right.
  -- | Right-infix operators parse like (a $ (b $ (c $ (d ...)))) whereas left-infix operators parse
  -- | like (((a # b) # c) # d ...).
  -- |
  (#) :: forall a b. a -> (a -> b) -> b
  (#) x f = f x

  infixr 6 :

  -- | Attaches an element to the front of a list.
  -- |
  -- | E.g.
  -- |
  -- |     1 : [2, 3, 4] = [1, 2, 3, 4]
  -- |
  (:) :: forall a. a -> [a] -> [a]
  (:) = cons

  foreign import cons
    """
    function cons(e) {
      return function(l) {
        return [e].concat(l);
      };
    }
    """ :: forall a. a -> [a] -> [a]

  class Show a where
    show :: a -> String

  foreign import showStringImpl
    """
    function showStringImpl(s) {
      return JSON.stringify(s);
    }
    """ :: String -> String

  instance showUnit :: Show Unit where
    show (Unit {}) = "Unit {}"

  instance showString :: Show String where
    show = showStringImpl

  instance showBoolean :: Show Boolean where
    show true = "true"
    show false = "false"

  foreign import showNumberImpl
    """
    function showNumberImpl(n) {
      return n.toString();
    }
    """ :: Number -> String

  instance showNumber :: Show Number where
    show = showNumberImpl

  foreign import showArrayImpl
    """
    function showArrayImpl(f) {
      return function(xs) {
        var ss = [];
        for (var i = 0, l = xs.length; i < l; i++) {
          ss[i] = f(xs[i]);
        }
        return '[' + ss.join(',') + ']';
      };
    }
    """ :: forall a. (a -> String) -> [a] -> String

  instance showArray :: (Show a) => Show [a] where
    show = showArrayImpl show

  infixl 4 <$>
  infixl 1 <#>

  -- | A `Functor` is intuitively a type which can be mapped over, and more formally a mapping
  -- | between [`Category`](#category)s that preserves structure.
  -- |
  -- | `Functor`s should obey the following rules.
  -- |
  -- | Identity:
  -- |     `(<$>) id = id`
  -- |
  -- | Composition:
  -- |     `forall f g. (<$>) (f . g) = ((<$>) f) . ((<$>) g)`
  -- |
  class Functor f where
    (<$>) :: forall a b. (a -> b) -> f a -> f b

  (<#>) :: forall f a b. (Functor f) => f a -> (a -> b) -> f b
  (<#>) fa f = f <$> fa

  void :: forall f a. (Functor f) => f a -> f Unit
  void fa = const unit <$> fa

  infixl 4 <*>

  -- | `Apply`s are intuitively [`Applicative`](#applicative)s less `pure`, and more formally a
  -- | strong lax semi-monoidal endofunctor.
  -- |
  -- | `Apply`s should obey the following rules.
  -- |
  -- | Associative Composition:
  -- |     `forall f g h. (.) <$> f <*> g <*> h = f <*> (g <*> h)`
  -- |
  class (Functor f) <= Apply f where
    (<*>) :: forall a b. f (a -> b) -> f a -> f b

  -- | `Applicative`s are [`Functor`](#functor)s which can be "applied" by sequencing composition
  -- | (`<*>`) or embedding pure expressions (`pure`).
  -- |
  -- | `Applicative`s should obey the following rules.
  -- |
  -- | Identity:
  -- |     `forall v. (pure id) <*> v = v`
  -- |
  -- | Composition:
  -- |     `forall f g h. (pure (.)) <*> f <*> g <*> h = f <*> (g <*> h)`
  -- |
  -- | Homomorphism:
  -- |     `forall f x. (pure f) <*> (pure x) = pure (f x)`
  -- |
  -- | Interchange:
  -- |     `forall u y. u <*> (pure y) = (pure (($) y)) <*> u`
  -- |
  class (Apply f) <= Applicative f where
    pure :: forall a. a -> f a

  liftA1 :: forall f a b. (Applicative f) => (a -> b) -> f a -> f b
  liftA1 f a = pure f <*> a

  infixl 1 >>=

  -- | A `Bind` is an [`Apply`](#apply) with a bind operation which sequentially composes actions.
  -- |
  -- | `Bind`s should obey the following rule.
  -- |
  -- | Associativity:
  -- |     `forall f g x. (x >>= f) >>= g = x >>= (\k => f k >>= g)`
  -- |
  class (Apply m) <= Bind m where
    (>>=) :: forall a b. m a -> (a -> m b) -> m b

  -- | `Monad` is a class which can be intuitively thought of as an abstract datatype of actions or
  -- | more formally though of as a monoid in the category of endofunctors.
  -- |
  -- | `Monad`s should obey the following rules.
  -- |
  -- | Left Identity:
  -- |     `forall f x. pure x >>= f = f x`
  -- |
  -- | Right Identity:
  -- |     `forall x. x >>= pure = x`
  -- |
  class (Applicative m, Bind m) <= Monad m

  return :: forall m a. (Monad m) => a -> m a
  return = pure

  liftM1 :: forall m a b. (Monad m) => (a -> b) -> m a -> m b
  liftM1 f a = do
    a' <- a
    return (f a')

  ap :: forall m a b. (Monad m) => m (a -> b) -> m a -> m b
  ap f a = do
    f' <- f
    a' <- a
    return (f' a')

  instance functorArr :: Functor ((->) r) where
    (<$>) = (<<<)

  instance applyArr :: Apply ((->) r) where
    (<*>) f g x = f x (g x)

  instance applicativeArr :: Applicative ((->) r) where
    pure = const

  instance bindArr :: Bind ((->) r) where
    (>>=) m f x = f (m x) x

  instance monadArr :: Monad ((->) r)

  infixl 7 *
  infixl 7 /
  infixl 7 %

  infixl 6 -
  infixl 6 +

  -- | Addition and multiplication
  class Semiring a where
    (+)  :: a -> a -> a
    zero :: a
    (*)  :: a -> a -> a
    one  :: a

  -- | Semiring with modulo operation and division where
  -- | ```a / b * b + (a `mod` b) = a```
  class (Semiring a) <= ModuloSemiring a where
    (/) :: a -> a -> a
    mod :: a -> a -> a

  -- | Addition, multiplication, and subtraction
  class (Semiring a) <= Ring a where
    (-) :: a -> a -> a

  negate :: forall a. (Ring a) => a -> a
  negate a = zero - a

  -- | Ring where every nonzero element has a multiplicative inverse (possibly
  -- | a non-commutative field) so that ```a `mod` b = zero```
  class (Ring a, ModuloSemiring a) <= DivisionRing a

  -- | A commutative field
  class (DivisionRing a) <= Num a

  foreign import numAdd
    """
    function numAdd(n1) {
      return function(n2) {
        return n1 + n2;
      };
    }
    """ :: Number -> Number -> Number

  foreign import numSub
    """
    function numSub(n1) {
      return function(n2) {
        return n1 - n2;
      };
    }
    """ :: Number -> Number -> Number

  foreign import numMul
    """
    function numMul(n1) {
      return function(n2) {
        return n1 * n2;
      };
    }
    """ :: Number -> Number -> Number

  foreign import numDiv
    """
    function numDiv(n1) {
      return function(n2) {
        return n1 / n2;
      };
    }
    """ :: Number -> Number -> Number

  foreign import numMod
    """
    function numMod(n1) {
      return function(n2) {
        return n1 % n2;
      };
    }
    """ :: Number -> Number -> Number

  (%) = numMod

  instance semiringNumber :: Semiring Number where
    (+) = numAdd
    zero = 0
    (*) = numMul
    one = 1

  instance ringNumber :: Ring Number where
    (-) = numSub

  instance moduloSemiringNumber :: ModuloSemiring Number where
    (/) = numDiv
    mod _ _ = 0

  instance divisionRingNumber :: DivisionRing Number

  instance numNumber :: Num Number

  newtype Unit = Unit {}

  unit :: Unit
  unit = Unit {}

  infix 4 ==
  infix 4 /=

  class Eq a where
    (==) :: a -> a -> Boolean
    (/=) :: a -> a -> Boolean

  foreign import refEq
    """
    function refEq(r1) {
      return function(r2) {
        return r1 === r2;
      };
    }
    """ :: forall a. a -> a -> Boolean

  foreign import refIneq
    """
    function refIneq(r1) {
      return function(r2) {
        return r1 !== r2;
      };
    }
    """ :: forall a. a -> a -> Boolean

  instance eqUnit :: Eq Unit where
    (==) (Unit {}) (Unit {}) = true
    (/=) (Unit {}) (Unit {}) = false

  instance eqString :: Eq String where
    (==) = refEq
    (/=) = refIneq

  instance eqNumber :: Eq Number where
    (==) = refEq
    (/=) = refIneq

  instance eqBoolean :: Eq Boolean where
    (==) = refEq
    (/=) = refIneq

  foreign import eqArrayImpl
    """
    function eqArrayImpl(f) {
      return function(xs) {
        return function(ys) {
          if (xs.length !== ys.length) return false;
          for (var i = 0; i < xs.length; i++) {
            if (!f(xs[i])(ys[i])) return false;
          }
          return true;
        };
      };
    }
    """ :: forall a. (a -> a -> Boolean) -> [a] -> [a] -> Boolean

  instance eqArray :: (Eq a) => Eq [a] where
    (==) xs ys = eqArrayImpl (==) xs ys
    (/=) xs ys = not (xs == ys)

  data Ordering = LT | GT | EQ

  instance eqOrdering :: Eq Ordering where
    (==) LT LT = true
    (==) GT GT = true
    (==) EQ EQ = true
    (==) _  _  = false
    (/=) x y = not (x == y)

  instance showOrdering :: Show Ordering where
    show LT = "LT"
    show GT = "GT"
    show EQ = "EQ"

  instance semigroupOrdening :: Semigroup Ordering where
    (<>) LT _ = LT
    (<>) GT _ = GT
    (<>) EQ y = y


  class (Eq a) <= Ord a where
    compare :: a -> a -> Ordering

  infixl 4 <

  (<) :: forall a. (Ord a) => a -> a -> Boolean
  (<) a1 a2 = case a1 `compare` a2 of
    LT -> true
    _ -> false

  infixl 4 >

  (>) :: forall a. (Ord a) => a -> a -> Boolean
  (>) a1 a2 = case a1 `compare` a2 of
    GT -> true
    _ -> false

  infixl 4 <=

  (<=) :: forall a. (Ord a) => a -> a -> Boolean
  (<=) a1 a2 = case a1 `compare` a2 of
    GT -> false
    _ -> true

  infixl 4 >=

  (>=) :: forall a. (Ord a) => a -> a -> Boolean
  (>=) a1 a2 = case a1 `compare` a2 of
    LT -> false
    _ -> true

  foreign import unsafeCompareImpl
    """
    function unsafeCompareImpl(lt) {
      return function(eq) {
        return function(gt) {
          return function(x) {
            return function(y) {
              return x < y ? lt : x > y ? gt : eq;
            };
          };
        };
      };
    }
    """ :: forall a. Ordering -> Ordering -> Ordering -> a -> a -> Ordering

  unsafeCompare :: forall a. a -> a -> Ordering
  unsafeCompare = unsafeCompareImpl LT EQ GT

  instance ordUnit :: Ord Unit where
    compare (Unit {}) (Unit {}) = EQ

  instance ordBoolean :: Ord Boolean where
    compare false false = EQ
    compare false true  = LT
    compare true  true  = EQ
    compare true  false = GT

  instance ordNumber :: Ord Number where
    compare = unsafeCompare

  instance ordString :: Ord String where
    compare = unsafeCompare

  instance ordArray :: (Ord a) => Ord [a] where
    compare [] [] = EQ
    compare [] _ = LT
    compare _ [] = GT
    compare (x:xs) (y:ys) = case compare x y of
      EQ -> compare xs ys
      other -> other

  infixl 10 .&.
  infixl 10 .|.
  infixl 10 .^.

  class Bits b where
    (.&.) :: b -> b -> b
    (.|.) :: b -> b -> b
    (.^.) :: b -> b -> b
    shl :: b -> Number -> b
    shr :: b -> Number -> b
    zshr :: b -> Number -> b
    complement :: b -> b

  foreign import numShl
    """
    function numShl(n1) {
      return function(n2) {
        return n1 << n2;
      };
    }
    """ :: Number -> Number -> Number

  foreign import numShr
    """
    function numShr(n1) {
      return function(n2) {
        return n1 >> n2;
      };
    }
    """ :: Number -> Number -> Number

  foreign import numZshr
    """
    function numZshr(n1) {
      return function(n2) {
        return n1 >>> n2;
      };
    }
    """ :: Number -> Number -> Number

  foreign import numAnd
    """
    function numAnd(n1) {
      return function(n2) {
        return n1 & n2;
      };
    }
    """ :: Number -> Number -> Number

  foreign import numOr
    """
    function numOr(n1) {
      return function(n2) {
        return n1 | n2;
      };
    }
    """ :: Number -> Number -> Number

  foreign import numXor
    """
    function numXor(n1) {
      return function(n2) {
        return n1 ^ n2;
      };
    }
    """ :: Number -> Number -> Number

  foreign import numComplement
    """
    function numComplement(n) {
      return ~n;
    }
    """ :: Number -> Number

  instance bitsNumber :: Bits Number where
    (.&.) = numAnd
    (.|.) = numOr
    (.^.) = numXor
    shl = numShl
    shr = numShr
    zshr = numZshr
    complement = numComplement

  infixr 2 ||
  infixr 3 &&

  class BoolLike b where
    (&&) :: b -> b -> b
    (||) :: b -> b -> b
    not :: b -> b

  foreign import boolAnd
    """
    function boolAnd(b1) {
      return function(b2) {
        return b1 && b2;
      };
    }
    """  :: Boolean -> Boolean -> Boolean

  foreign import boolOr
    """
    function boolOr(b1) {
      return function(b2) {
        return b1 || b2;
      };
    }
    """ :: Boolean -> Boolean -> Boolean

  foreign import boolNot
    """
    function boolNot(b) {
      return !b;
    }
    """ :: Boolean -> Boolean

  instance boolLikeBoolean :: BoolLike Boolean where
    (&&) = boolAnd
    (||) = boolOr
    not = boolNot

  infixr 5 <>

  class Semigroup a where
    (<>) :: a -> a -> a

  foreign import concatString
    """
    function concatString(s1) {
      return function(s2) {
        return s1 + s2;
      };
    }
    """ :: String -> String -> String

  instance semigroupUnit :: Semigroup Unit where
    (<>) (Unit {}) (Unit {}) = Unit {}

  instance semigroupString :: Semigroup String where
    (<>) = concatString

  instance semigroupArr :: (Semigroup s') => Semigroup (s -> s') where
    (<>) f g = \x -> f x <> g x

  infixr 5 ++

  (++) :: forall s. (Semigroup s) => s -> s -> s
  (++) = (<>)

module Data.Function where

  on :: forall a b c. (b -> b -> c) -> (a -> b) -> a -> a -> c
  on f g x y = g x `f` g y

  foreign import data Fn0 :: * -> *
  foreign import data Fn1 :: * -> * -> *
  foreign import data Fn2 :: * -> * -> * -> *
  foreign import data Fn3 :: * -> * -> * -> * -> *
  foreign import data Fn4 :: * -> * -> * -> * -> * -> *
  foreign import data Fn5 :: * -> * -> * -> * -> * -> * -> *
  foreign import data Fn6 :: * -> * -> * -> * -> * -> * -> * -> *
  foreign import data Fn7 :: * -> * -> * -> * -> * -> * -> * -> * -> *
  foreign import data Fn8 :: * -> * -> * -> * -> * -> * -> * -> * -> * -> *
  foreign import data Fn9 :: * -> * -> * -> * -> * -> * -> * -> * -> * -> * -> *
  foreign import data Fn10 :: * -> * -> * -> * -> * -> * -> * -> * -> * -> * -> * -> *

  foreign import mkFn0
    """
    function mkFn0(fn) {
      return function() {
        return fn({});
      };
    }
    """ :: forall a. (Unit -> a) -> Fn0 a

  foreign import mkFn1
    """
    function mkFn1(fn) {
      return function(a) {
        return fn(a);
      };
    }
    """ :: forall a b. (a -> b) -> Fn1 a b

  foreign import mkFn2
    """
    function mkFn2(fn) {
      return function(a, b) {
        return fn(a)(b);
      };
    }
    """ :: forall a b c. (a -> b -> c) -> Fn2 a b c

  foreign import mkFn3
    """
    function mkFn3(fn) {
      return function(a, b, c) {
        return fn(a)(b)(c);
      };
    }
    """ :: forall a b c d. (a -> b -> c -> d) -> Fn3 a b c d

  foreign import mkFn4
    """
    function mkFn4(fn) {
      return function(a, b, c, d) {
        return fn(a)(b)(c)(d);
      };
    }
    """ :: forall a b c d e. (a -> b -> c -> d -> e) -> Fn4 a b c d e

  foreign import mkFn5
    """
    function mkFn5(fn) {
      return function(a, b, c, d, e) {
        return fn(a)(b)(c)(d)(e);
      };
    }
    """ :: forall a b c d e f. (a -> b -> c -> d -> e -> f) -> Fn5 a b c d e f

  foreign import mkFn6
    """
    function mkFn6(fn) {
      return function(a, b, c, d, e, f) {
        return fn(a)(b)(c)(d)(e)(f);
      };
    }
    """ :: forall a b c d e f g. (a -> b -> c -> d -> e -> f -> g) -> Fn6 a b c d e f g

  foreign import mkFn7
    """
    function mkFn7(fn) {
      return function(a, b, c, d, e, f, g) {
        return fn(a)(b)(c)(d)(e)(f)(g);
      };
    }
    """ :: forall a b c d e f g h. (a -> b -> c -> d -> e -> f -> g -> h) -> Fn7 a b c d e f g h

  foreign import mkFn8
    """
    function mkFn8(fn) {
      return function(a, b, c, d, e, f, g, h) {
        return fn(a)(b)(c)(d)(e)(f)(g)(h);
      };
    }
    """ :: forall a b c d e f g h i. (a -> b -> c -> d -> e -> f -> g -> h -> i) -> Fn8 a b c d e f g h i

  foreign import mkFn9
    """
    function mkFn9(fn) {
      return function(a, b, c, d, e, f, g, h, i) {
        return fn(a)(b)(c)(d)(e)(f)(g)(h)(i);
      };
    }
    """ :: forall a b c d e f g h i j. (a -> b -> c -> d -> e -> f -> g -> h -> i -> j) -> Fn9 a b c d e f g h i j

  foreign import mkFn10
    """
    function mkFn10(fn) {
      return function(a, b, c, d, e, f, g, h, i, j) {
        return fn(a)(b)(c)(d)(e)(f)(g)(h)(i)(j);
      };
    }
    """ :: forall a b c d e f g h i j k. (a -> b -> c -> d -> e -> f -> g -> h -> i -> j -> k) -> Fn10 a b c d e f g h i j k

  foreign import runFn0
    """
    function runFn0(fn) {
      return fn();
    }
    """ :: forall a. Fn0 a -> a

  foreign import runFn1
    """
    function runFn1(fn) {
      return function(a) {
        return fn(a);
      };
    }
    """ :: forall a b. Fn1 a b -> a -> b

  foreign import runFn2
    """
    function runFn2(fn) {
      return function(a) {
        return function(b) {
          return fn(a, b);
        };
      };
    }
    """ :: forall a b c. Fn2 a b c -> a -> b -> c

  foreign import runFn3
    """
    function runFn3(fn) {
      return function(a) {
        return function(b) {
          return function(c) {
            return fn(a, b, c);
          };
        };
      };
    }
    """ :: forall a b c d. Fn3 a b c d -> a -> b -> c -> d

  foreign import runFn4
    """
    function runFn4(fn) {
      return function(a) {
        return function(b) {
          return function(c) {
            return function(d) {
              return fn(a, b, c, d);
            };
          };
        };
      };
    }
    """ :: forall a b c d e. Fn4 a b c d e -> a -> b -> c -> d -> e

  foreign import runFn5
    """
    function runFn5(fn) {
      return function(a) {
        return function(b) {
          return function(c) {
            return function(d) {
              return function(e) {
                return fn(a, b, c, d, e);
              };
            };
          };
        };
      };
    }
    """ :: forall a b c d e f. Fn5 a b c d e f -> a -> b -> c -> d -> e -> f

  foreign import runFn6
    """
    function runFn6(fn) {
      return function(a) {
        return function(b) {
          return function(c) {
            return function(d) {
              return function(e) {
                return function(f) {
                  return fn(a, b, c, d, e, f);
                };
              };
            };
          };
        };
      };
    }
    """ :: forall a b c d e f g. Fn6 a b c d e f g -> a -> b -> c -> d -> e -> f -> g

  foreign import runFn7
    """
    function runFn7(fn) {
      return function(a) {
        return function(b) {
          return function(c) {
            return function(d) {
              return function(e) {
                return function(f) {
                  return function(g) {
                    return fn(a, b, c, d, e, f, g);
                  };
                };
              };
            };
          };
        };
      };
    }
    """ :: forall a b c d e f g h. Fn7 a b c d e f g h -> a -> b -> c -> d -> e -> f -> g -> h

  foreign import runFn8
    """
    function runFn8(fn) {
      return function(a) {
        return function(b) {
          return function(c) {
            return function(d) {
              return function(e) {
                return function(f) {
                  return function(g) {
                    return function(h) {
                      return fn(a, b, c, d, e, f, g, h);
                    };
                  };
                };
              };
            };
          };
        };
      };
    }
    """ :: forall a b c d e f g h i. Fn8 a b c d e f g h i -> a -> b -> c -> d -> e -> f -> g -> h -> i

  foreign import runFn9
    """
    function runFn9(fn) {
      return function(a) {
        return function(b) {
          return function(c) {
            return function(d) {
              return function(e) {
                return function(f) {
                  return function(g) {
                    return function(h) {
                      return function(i) {
                        return fn(a, b, c, d, e, f, g, h, i);
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
    }
    """ :: forall a b c d e f g h i j. Fn9 a b c d e f g h i j -> a -> b -> c -> d -> e -> f -> g -> h -> i -> j

  foreign import runFn10
    """
    function runFn10(fn) {
      return function(a) {
        return function(b) {
          return function(c) {
            return function(d) {
              return function(e) {
                return function(f) {
                  return function(g) {
                    return function(h) {
                      return function(i) {
                        return function(j) {
                          return fn(a, b, c, d, e, f, g, h, i, j);
                        };
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
    }
    """ :: forall a b c d e f g h i j k. Fn10 a b c d e f g h i j k -> a -> b -> c -> d -> e -> f -> g -> h -> i -> j -> k

module Prelude.Unsafe where

  foreign import unsafeIndex
    """
    function unsafeIndex(xs) {
      return function(n) {
        return xs[n];
      };
    }
    """ :: forall a. [a] -> Number -> a

module Control.Monad.Eff where

  foreign import data Eff :: # ! -> * -> *

  foreign import returnE
    """
    function returnE(a) {
      return function() {
        return a;
      };
    }
    """ :: forall e a. a -> Eff e a

  foreign import bindE
    """
    function bindE(a) {
      return function(f) {
        return function() {
          return f(a())();
        };
      };
    }
    """ :: forall e a b. Eff e a -> (a -> Eff e b) -> Eff e b

  type Pure a = forall e. Eff e a

  foreign import runPure
    """
    function runPure(f) {
      return f();
    }
    """ :: forall a. Pure a -> a

  instance functorEff :: Functor (Eff e) where
    (<$>) = liftA1

  instance applyEff :: Apply (Eff e) where
    (<*>) = ap

  instance applicativeEff :: Applicative (Eff e) where
    pure = returnE

  instance bindEff :: Bind (Eff e) where
    (>>=) = bindE

  instance monadEff :: Monad (Eff e)

  foreign import untilE
    """
    function untilE(f) {
      return function() {
        while (!f());
        return {};
      };
    }
    """ :: forall e. Eff e Boolean -> Eff e Unit

  foreign import whileE
    """
    function whileE(f) {
      return function(a) {
        return function() {
          while (f()) {
            a();
          }
          return {};
        };
      };
    }
    """ :: forall e a. Eff e Boolean -> Eff e a -> Eff e Unit

  foreign import forE
    """
    function forE(lo) {
      return function(hi) {
        return function(f) {
          return function() {
            for (var i = lo; i < hi; i++) {
              f(i)();
            }
          };
        };
      };
    }
    """ :: forall e. Number -> Number -> (Number -> Eff e Unit) -> Eff e Unit


  foreign import foreachE
    """
    function foreachE(as) {
      return function(f) {
        return function() {
          for (var i = 0; i < as.length; i++) {
            f(as[i])();
          }
        };
      };
    }
    """ :: forall e a. [a] -> (a -> Eff e Unit) -> Eff e Unit

module Control.Monad.Eff.Unsafe where

  import Control.Monad.Eff

  foreign import unsafeInterleaveEff
    """
    function unsafeInterleaveEff(f) {
      return f;
    }
    """ :: forall eff1 eff2 a. Eff eff1 a -> Eff eff2 a

module Debug.Trace where

  import Control.Monad.Eff

  foreign import data Trace :: !

  foreign import trace
    """
    function trace(s) {
      return function() {
        console.log(s);
        return {};
      };
    }
    """ :: forall r. String -> Eff (trace :: Trace | r) Unit

  print :: forall a r. (Show a) => a -> Eff (trace :: Trace | r) Unit
  print o = trace (show o)

module Control.Monad.ST where

  import Control.Monad.Eff

  foreign import data ST :: * -> !

  foreign import data STRef :: * -> * -> *

  foreign import newSTRef
    """
    function newSTRef(val) {
      return function() {
        return { value: val };
      };
    }
    """ :: forall a h r. a -> Eff (st :: ST h | r) (STRef h a)

  foreign import readSTRef
    """
    function readSTRef(ref) {
      return function() {
        return ref.value;
      };
    }
    """ :: forall a h r. STRef h a -> Eff (st :: ST h | r) a

  foreign import modifySTRef
    """
    function modifySTRef(ref) {
      return function(f) {
        return function() {
          return ref.value = f(ref.value);
        };
      };
    }
    """ :: forall a h r. STRef h a -> (a -> a) -> Eff (st :: ST h | r) a

  foreign import writeSTRef
    """
    function writeSTRef(ref) {
      return function(a) {
        return function() {
          return ref.value = a;
        };
      };
    }
    """ :: forall a h r. STRef h a -> a -> Eff (st :: ST h | r) a

  foreign import runST
    """
    function runST(f) {
      return f;
    }
    """ :: forall a r. (forall h. Eff (st :: ST h | r) a) -> Eff r a

  pureST :: forall a. (forall h r. Eff (st :: ST h | r) a) -> a
  pureST st = runPure (runST st)
