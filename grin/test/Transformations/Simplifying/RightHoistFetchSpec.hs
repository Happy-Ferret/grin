{-# LANGUAGE TypeApplications, OverloadedStrings, LambdaCase #-}

module Transformations.Simplifying.RightHoistFetchSpec where

import Control.Monad
import Test.Hspec
import Test hiding (asVal)
import Test.QuickCheck.Property

import Free
import Grin
import Assertions
import Transformations.Simplifying.RightHoistFetch2

spec :: Spec
spec = do
  it "Example from Figure 4.16" $ do
    before <- buildExpM $
      "l0" <=: store @Int 0        $
      "p"  <=: store (constTagNode "Cons" (asVal @Int <$> [1, 2])) $
      "t"  <=: fetch "p" (Just 0)  $
      "a1" <=: fetch "p" (Just 1)  $
      "a2" <=: fetch "p" (Just 2)  $
      "l1" <=: store @Int 1        $
      switch "t"
        [ (tag "Nil" 0,  "l3" <=: store @Int 2 $
                         unit @Int 2)
        , (tag "Cons" 2, "l4" <=: store @Int 3     $
                         "l5" <=: store @Var "a1"  $
                         "l6" <=: store @Var "a2"  $
                         unit @Int 3)
        ]
    after <- buildExpM $
      "l0" <=: store @Int 0        $
      "p"  <=: store (constTagNode "Cons" (asVal @Int <$> [1, 2])) $
      "t"  <=: fetch "p" (Just 0)  $
      "l1" <=: store @Int 1        $
      switch "t"
        [ (tag "Nil" 0,  "l3" <=: store @Int 2 $
                         unit @Int 2)
        , (tag "Cons" 2, "a1.a1" <=: fetch "p" (Just 1)  $
                         "a2.a1" <=: fetch "p" (Just 2)  $
                         "l4" <=: store @Int 3           $
                         "l5" <=: store @Var "a1.a1"     $
                         "l6" <=: store @Var "a2.a1"     $
                         unit @Int 3)
        ]
    rightHoistFetch before `sameAs` after

  forM_ programGenerators $ \(name, gen) -> do
    describe name $ do
      it "transformation has effect" $ property $
        forAll gen $ \before ->
          let after = rightHoistFetch before
          in changed before after True

runTests :: IO ()
runTests = hspec spec
