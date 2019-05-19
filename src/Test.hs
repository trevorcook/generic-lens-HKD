{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE DeriveGeneric  #-}
{-# LANGUAGE DataKinds  #-}
{-# LANGUAGE KindSignatures  #-}
{-# LANGUAGE TypeFamilies  #-}
{-# LANGUAGE UndecidableInstances  #-}
{-# LANGUAGE PolyKinds #-}

module Test where

import Generics.OneLiner --package one-liner
import Control.Lens      --package lens
import HKD.Traversal
import GHC.TypeLits
import GHC.Generics(Generic)

-- Higher Kind 0, used for "Un" higher kinding.
data HK0 a
type family HK (f :: ( * -> * ) ) a where
  HK HK0 a = a
  HK f   a = f a

type AB = AB' HK0
data AB' f a b = A { a_A :: HK f a, num_A :: HK f Int }
               | B { bs_B :: HK f [b] }
              deriving Generic
deriving instance (Constraints (AB' f a b) Show) => Show (AB' f a b)

thisABs :: [AB String Int]
thisABs = [ A "1" 1
          , B [0,1,2] ]
thisABs' :: [ (AB Int Int, AB String Int, AB String String) ]
thisABs' = foo thisABs
--   = [ (A 1 1, A "1" 10, A "1" 1)
--     , (B [0,1,2], B [0,1,2], B ["0","1","2"]) ]

foo :: [AB String Int] -> [ (AB Int Int, AB String Int, AB String String) ]
foo = map $ \ab -> ( ab & getTraverseForN (a_A tA) %~ read
                   , ab & getTraverseForN (num_A tA) %~ (*10)
                   , ab & getTraverseForN (bs_B tB) %~ map show )

tA, tB :: MakeTraverseFor (AB a b) (AB c d) 1
tA = makeTraversal @"A"
tB = makeTraversal @"B"

type C = C' HK0
data C' f a = C1 { c1_a :: HK f a } deriving Generic
deriving instance (Constraints (C' f a ) Show) => Show (C' f a)

tC :: MakeTraverseFor (C a) (C b) 1
tC = makeTraversal @""

-- Define some data to traverse
c1 :: C Int
c1 = C1 1

-- An application of the traversal
c2 :: C String
c2 = c1 & getTraverseForN (c1_a tC) .~ "a" -- Yields C1 "a"

tC' :: C' (TraverseForN (C a) (C b)) (NProxyK 2 a)
tC' = makeTraversal @""

type D = D' HK0
data D' f g a b c = D1 { d1_a      :: HK f ((Int, a))
                       , d1_String :: HK f (g String) }
                  | D2 { d2_b :: HK f b
                       , d2_c :: HK f c }
                  | D3 { d3_c :: HK f c }
                  deriving (Generic)

deriving instance (Constraints (D' f g a b c) Show) =>
  Show (D' f g a b c)

-- Example Data
d1, d2, d3 :: D [] Int Int Int
d1 = D1 (1,1) ["1"]
d2 = D2 2 2
d3 = D3 3

-- tD1 targets the "D1" constructor.
tD1 :: D' (TraverseForN (D g a b c) (D g' a' b' c))
              (NProxyK 2 g) (NProxyK 3 a) (NProxyK 4 b) (NProxyK 5 c)
tD1 = makeTraversal @"D1"

tD2 , tD3 :: MakeTraverseFor (D g a b c) (D g' a' b' c) 1
tD2 = makeTraversal @"D2"
tD3 = makeTraversal @"D3"

d2' :: D [] Int String Int
d2' = d2 & getTraverseForN (d2_b tD2) .~ "B"

tD1_ProbablyShouldn't :: MakeTraverseFor (D g a b c) (D g a' b' c') 1
tD1_ProbablyShouldn't = makeTraversal @"D1"
