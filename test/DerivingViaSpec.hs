{-# LANGUAGE DerivingVia, DeriveGeneric #-}
{-|
Module      : DerivingViaSpec
Description : Show that TOML classes can be derived with DerivingVia
Copyright   : (c) Eric Mertens, 2024
License     : ISC
Maintainer  : emertens@gmail.com

This module ensures that the classes are actually derivable with
generalized newtype deriving. In particular 'fromValue' uses the
'Matcher' type and that type can't use monad transformers without
preventing this from working. The test ensures we don't have a
regression later.

-}
module DerivingViaSpec (spec) where

import GHC.Generics (Generic)
import Test.Hspec (it, shouldBe, Spec)
import Toml (Value(..))
import Toml.FromValue ( FromValue(fromValue) )
import Toml.FromValue.Matcher (runMatcher, Result(Success))
import Toml.Generic (GenericTomlTable(..), GenericTomlArray(..))
import Toml.ToValue (ToTable(toTable), (.=), table, ToValue(toValue))

data Physical = Physical {
    color :: String,
    shape :: String
    }
    deriving (Eq, Show, Generic)
    deriving (ToTable, FromValue, ToValue) via GenericTomlTable Physical

data TwoThings = TwoThings Int String
    deriving (Eq, Show, Generic)
    deriving (FromValue, ToValue) via GenericTomlArray TwoThings

spec :: Spec
spec =
 do let sem = Physical "red" "round"
        tab = table ["color" .= "red", "shape" .= "round"]

    it "supports toValue" $
        toValue sem
        `shouldBe`
        Table tab

    it "supports toTable" $
        toTable sem
        `shouldBe`
        tab

    it "supports fromValue" $
        runMatcher (fromValue (Table tab))
        `shouldBe`
        Success [] sem

    it "converts from arrays positionally" $
        runMatcher (fromValue (Array [Integer 42, String "forty-two"]))
        `shouldBe`
        Success [] (TwoThings 42 "forty-two")

    it "converts to arrays positionally" $
        toValue (TwoThings 42 "forty-two")
        `shouldBe`
        Array [Integer 42, String "forty-two"]
