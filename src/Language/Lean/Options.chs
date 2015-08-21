{-# LANGUAGE DoAndIfThenElse #-}
{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE StandaloneDeriving #-}
module Language.Lean.Options
  ( Options
  , emptyOptions
  , optionsContains
  , boolOption
  , doubleOption
  , intOption
  , uintOption
  , stringOption
  ) where

import Control.Exception (assert)
import Control.Lens
import Foreign
import Foreign.C
import System.IO.Unsafe

{#import Language.Lean.Internal.Exception #}
{#import Language.Lean.Internal.Name #}
{#import Language.Lean.Internal.Options #}
{#import Language.Lean.Internal.String #}
import Language.Lean.Internal.Utils

#include "lean_macros.h"
#include "lean_bool.h"
#include "lean_exception.h"
#include "lean_name.h"
#include "lean_options.h"

{#fun unsafe lean_options_mk_empty
  { id `Ptr OptionsPtr'
  , id `Ptr ExceptionPtr'
  } -> `Bool' #}

{#fun unsafe lean_options_set_bool
  { withOptionsPtr* `Options'
  , withNamePtr* `Name'
  , `Bool'
  , id `Ptr OptionsPtr'
  , id `Ptr ExceptionPtr'
  } -> `Bool' #}

{#fun unsafe lean_options_set_int
  { withOptionsPtr* `Options'
  , withNamePtr* `Name'
  , `Int32'
  , id `Ptr OptionsPtr'
  , id `Ptr ExceptionPtr'
  } -> `Bool' #}

{#fun unsafe lean_options_set_unsigned
  { withOptionsPtr* `Options'
  , withNamePtr* `Name'
  , `Word32'
  , id `Ptr OptionsPtr'
  , id `Ptr ExceptionPtr'
  } -> `Bool' #}

{#fun unsafe lean_options_set_double
  { withOptionsPtr* `Options'
  , withNamePtr* `Name'
  , `Double'
  , id `Ptr OptionsPtr'
  , id `Ptr ExceptionPtr'
  } -> `Bool' #}

{#fun unsafe lean_options_set_string
  { withOptionsPtr* `Options'
  , withNamePtr* `Name'
  , withLeanStringPtr* `String'
  , id `Ptr OptionsPtr'
  , id `Ptr ExceptionPtr'
  } -> `Bool' #}

{#fun unsafe lean_options_join
  { withOptionsPtr* `Options'
  , withOptionsPtr* `Options'
  , id `Ptr OptionsPtr'
  , id `Ptr ExceptionPtr'
  } -> `Bool' #}

{#fun pure unsafe lean_options_empty
  { withOptionsPtr* `Options'
  } -> `Bool' #}

-- | Indicate whether name is set in the lean options.
{#fun pure unsafe lean_options_contains as optionsContains
  { withOptionsPtr* `Options'
  , withNamePtr* `Name'
  } -> `Bool' #}

{#fun unsafe lean_options_get_bool
  { withOptionsPtr* `Options'
  , withNamePtr* `Name'
  , id `Ptr CInt'
  , id `Ptr ExceptionPtr'
  } -> `Bool' #}

{#fun unsafe lean_options_get_int
  { withOptionsPtr* `Options'
  , withNamePtr* `Name'
  , id `Ptr CInt'
  , id `Ptr ExceptionPtr'
  } -> `Bool' #}

{#fun unsafe lean_options_get_unsigned
  { withOptionsPtr* `Options'
  , withNamePtr* `Name'
  , id `Ptr CUInt'
  , id `Ptr ExceptionPtr'
  } -> `Bool' #}

{#fun unsafe lean_options_get_double
  { withOptionsPtr* `Options'
  , withNamePtr* `Name'
  , id `Ptr CDouble'
  , id `Ptr ExceptionPtr'
  } -> `Bool' #}

{#fun unsafe lean_options_get_string
  { withOptionsPtr* `Options'
  , withNamePtr* `Name'
  , id `Ptr CString'
  , id `Ptr ExceptionPtr'
  } -> `Bool' #}

emptyOptions :: Options
emptyOptions = unsafePerformIO $
  tryAllocOptions lean_options_mk_empty

-- | Retrieves a value for a Lean option
optionsGet :: (LeanPartialFn a -> IO b)
           -> (Options -> Name -> LeanPartialFn a)
           -> Options
           -> Name
           -> b
optionsGet tryGetVal leanGetter o nm = unsafePerformIO $ do
  tryGetVal $ leanGetter o nm

-- | Sets a Lean option with a new value
optionsSet :: (Options -> Name -> a -> LeanPartialFn OptionsPtr)
           -> Options
           -> Name
           -> a
           -> Options
optionsSet leanSetter o nm v = unsafePerformIO $ do
  tryAllocOptions $ leanSetter o nm v

-- | Lens for getting and setting boolean options without
--   rewriting equivalent values
simpleLensEq :: (Eq a) => (s -> a) -> (s -> a -> s) -> Simple Lens s a
simpleLensEq getter setter f o = fmap setFun (f oldVal)
  where
    oldVal = getter o
    setFun newVal
     | oldVal == newVal = o
     | otherwise        = setter o newVal

boolOption :: Name -> Simple Lens Options Bool
boolOption nm = simpleLensEq (`optGet` nm) (`optSet` nm)
  where
    optGet = optionsGet tryGetBool lean_options_get_bool
    optSet = optionsSet lean_options_set_bool

intOption :: Name -> Simple Lens Options Int32
intOption nm = simpleLensEq (`optGet` nm) (`optSet` nm)
  where
    optGet = optionsGet tryGetInt lean_options_get_int
    optSet = optionsSet lean_options_set_int

uintOption :: Name -> Simple Lens Options Word32
uintOption nm = simpleLensEq (`optGet` nm) (`optSet` nm)
  where
    optGet = optionsGet tryGetUInt lean_options_get_unsigned
    optSet = optionsSet lean_options_set_unsigned

doubleOption :: Name -> Simple Lens Options Double
doubleOption nm = simpleLensEq (`optGet` nm) (`optSet` nm)
  where
    optGet = optionsGet tryGetDouble lean_options_get_double
    optSet = optionsSet lean_options_set_double

stringOption :: Name -> Simple Lens Options String
stringOption nm = simpleLensEq (`optGet` nm) (`optSet` nm)
  where
    optGet = optionsGet tryAllocString lean_options_get_string
    optSet = optionsSet lean_options_set_string

