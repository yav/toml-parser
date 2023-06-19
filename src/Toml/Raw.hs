{-|
Module      : Toml.Raw
Description : Raw expressions from a parsed TOML file
Copyright   : (c) Eric Mertens, 2023
License     : ISC
Maintainer  : emertens@gmail.com

This module provides a raw representation of TOML files as
a list of table definitions and key-value assignments.

These values use the raw dotted keys and have no detection
for overlapping assignments.

Further processing will happen in the "Semantics" module.

-}
module Toml.Raw (
    Key,
    Expr(..),
    Val(..),
    SectionKind(..),
    ) where

import Data.List.NonEmpty (NonEmpty)
import Data.Time (Day, LocalTime, TimeOfDay, ZonedTime)

-- | Non-empty sequence of dotted simple keys
type Key = NonEmpty String

-- | Headers and assignments corresponding to lines of a TOML file
data Expr
    = KeyValExpr     Int Key Val -- ^ line-no key value
    | TableExpr      Int Key     -- ^ line-no table-header
    | ArrayTableExpr Int Key     -- ^ line-no array-table-header
    deriving Show

-- | Unvalidated TOML values. Table are represented as a list of
-- assignments rather than as resolved maps.
data Val
    = ValInteger Integer
    | ValFloat Double
    | ValArray [Val]
    | ValTable [(Key, Val)]
    | ValBool Bool
    | ValString String
    | ValTimeOfDay TimeOfDay
    | ValZonedTime ZonedTime
    | ValLocalTime LocalTime
    | ValDay Day
    deriving Show

-- | Kinds of table headers.
data SectionKind
    = TableKind -- ^ [table]
    | ArrayTableKind -- ^ [[array of tables]]
    deriving Show