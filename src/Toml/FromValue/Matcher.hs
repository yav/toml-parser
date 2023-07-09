{-|
Module      : Toml.FromValue.Matcher
Description : A type for building results while tracking scopes
Copyright   : (c) Eric Mertens, 2023
License     : ISC
Maintainer  : emertens@gmail.com

This type helps to build up computations that can validate a TOML
value and compute some application-specific representation.

It supports warning messages which can be used to deprecate old
configuration options and to detect unused table keys.

It supports tracking multiple error messages when you have more
than one decoding option and all of them have failed.

-}
module Toml.FromValue.Matcher ( 
    Matcher,
    Result(..),
    runMatcher,
    withScope,
    getScope,
    warning,

    -- * Scope helpers
    inKey,
    inIndex,
    ) where

import Control.Monad.Trans.Class (lift)
import Control.Monad.Trans.Reader (asks, local, ReaderT(..))
import Control.Monad.Trans.Except (Except, runExcept, throwE)
import Control.Monad.Trans.Writer.CPS (runWriterT, tell, WriterT)
import Data.Monoid (Endo(..))
import Control.Applicative (Alternative(..))
import Control.Monad (MonadPlus)
import Toml.Pretty (prettySimpleKey)

-- | Computations that result in a 'Result' and which track a list
-- of nested contexts to assist in generating warnings and error
-- messages.
--
-- Use 'withScope' to run a 'Matcher' in a new, nested scope.
newtype Matcher a = Matcher (ReaderT [String] (WriterT Strings (Except Strings)) a)
    deriving (Functor, Applicative, Monad, Alternative, MonadPlus)

-- | List of strings that supports efficient left- and right-biased append
newtype Strings = Strings (Endo [String])
    deriving (Semigroup, Monoid)

-- | Create a singleton list of strings
string :: String -> Strings
string x = Strings (Endo (x:))

-- | Extract the list of strings
runStrings :: Strings -> [String]
runStrings (Strings s) = s `appEndo` []

-- | Computation outcome with error and warning messages. Multiple error
-- messages can occur when multiple alternatives all fail. Resolving any
-- one of the error messages could allow the computation to succeed.
data Result a
    = Failure [String]   -- error messages
    | Success [String] a -- warnings and result
    deriving (Read, Show, Eq, Ord)

-- | Run a 'Matcher' with an empty scope.
runMatcher :: Matcher a -> Result a
runMatcher (Matcher m) =
    case runExcept (runWriterT (runReaderT m [])) of
        Left e      -> Failure (runStrings e)
        Right (x,w) -> Success (runStrings w) x

-- | Run a 'Matcher' with a locally extended scope.
withScope :: String -> Matcher a -> Matcher a
withScope ctx (Matcher m) = Matcher (local (ctx:) m)

-- | Get the current list of scopes.
getScope :: Matcher [String]
getScope = Matcher (asks reverse)

-- | Emit a warning mentioning the current scope.
warning :: String -> Matcher ()
warning w =
 do loc <- getScope
    Matcher (lift (tell (string (w ++ " in top" ++ concat loc))))

-- | Fail with an error message annotated to the current location.
instance MonadFail Matcher where
    fail e =
     do loc <- getScope
        Matcher (lift (lift (throwE (string (e ++ " in top" ++ concat loc)))))

-- | Update the scope with the message corresponding to a table key
--
-- @since 1.1.2.0
inKey :: String -> Matcher a -> Matcher a
inKey key = withScope ('.' : show (prettySimpleKey key))

-- | Update the scope with the message corresponding to an array index
--
-- @since 1.1.2.0
inIndex :: Int -> Matcher a -> Matcher a
inIndex i = withScope ("[" ++ show i ++ "]")
