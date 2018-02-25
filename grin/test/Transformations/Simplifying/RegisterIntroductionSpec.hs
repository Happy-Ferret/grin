{-# LANGUAGE TypeApplications, OverloadedStrings #-}
module Transformations.Simplifying.RegisterIntroductionSpec where

import Control.Monad
import Test.Hspec
import Transformations.Simplifying.RegisterIntroduction
import Test.QuickCheck.Property

import Free
import Grin
import Assertions
import Test hiding (asVal)


spec :: Spec
spec = do
  describe "internals" tests

  it "Example from Figure 4.17" $ do
    before <- buildExpM $
      "l1" <=: store @Int 0                       $
      "p"  <=: store @Val ("Cons" @: ["a", "b"])  $
      "u'" <=: app "foo" (asVal @Int <$> [1, 3])  $
      "q"  <=: store @Val ("Int" @: ["u'"])       $
      "x"  <=: unit @Val ("Cons" @: ["q", "p"])   $
      "l2" <=: store @Int 1                       $
      unit @Int 2

    after <- buildExpM $
      "l1" <=: store @Int 0                  $
      "t1" <=: unit @Val (tag "Cons" 2)      $
      "p"  <=: store @Val ("t1" @: ["a", "b"])    $
      "x'" <=: store @Int 1 $
      "y'" <=: store @Int 3 $
      "u'" <=: app "foo" ["x'", "y'"] $
      "t2" <=: unit @Val (tag "Int" 1) $
      "q"  <=: store @Val ("t2" @: ["u'"]) $
      "t3" <=: unit @Val (tag "Cons" 2) $
      "x"  <=: unit @Val ("t3" @: ["q", "p"]) $
      "l2" <=: store @Int 1                  $
      unit @Int 2

    registerIntroduction 0 before `sameAs` after

  forM_ programGenerators $ \(name, gen) -> do
    describe name $ do
      it "transformation has effect" $ property $
        forAll gen $ \before ->
          let after = registerIntroduction 0 before
          in changed before after True


runTests :: IO ()
runTests = hspec spec
