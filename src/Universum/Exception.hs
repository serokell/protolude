{-# LANGUAGE CPP                   #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE PatternSynonyms       #-}
{-# LANGUAGE Safe                  #-}
{-# LANGUAGE ViewPatterns          #-}

-- | Re-exports most useful functionality from 'safe-exceptions'. Also
-- provides some functions to work with exceptions over 'MonadError'.

module Universum.Exception
       ( module Control.Exception.Safe
#if ( __GLASGOW_HASKELL__ >= 800 )
       , Bug (..)
       , bug
       , pattern Exc
#endif
       , note
       , mask_
       ) where

-- exceptions from safe-exceptions
import Control.Exception.Safe (Exception (..), MonadCatch, MonadMask (..), MonadThrow,
                               SomeException (..), bracket, bracketOnError, bracket_, catch,
                               catchAny, displayException, finally, handleAny, onException,
                               throwM, try, tryAny)
import qualified Control.Exception.Safe as Safe (mask_)
import Control.Monad.Except (MonadError, throwError)
import Universum.Applicative (Applicative (pure))
import Universum.Monad (Maybe (..), maybe)

#if ( __GLASGOW_HASKELL__ >= 800 )
import Data.List ((++))
import GHC.Show (Show)
import GHC.Stack (CallStack, HasCallStack, callStack, prettyCallStack)

import qualified Control.Exception.Safe as Safe (displayException, impureThrow, toException)

-- | Type that represents exceptions used in cases when a particular codepath
-- is not meant to be ever executed, but happens to be executed anyway.
data Bug = Bug SomeException CallStack
    deriving (Show)

instance Exception Bug where
    displayException (Bug e cStack) = Safe.displayException e ++ "\n"
                                   ++ prettyCallStack cStack

-- | Generate a pure value which, when forced, will synchronously
-- throw the exception wrapped into 'Bug' data type.
bug :: (HasCallStack, Exception e) => e -> a
bug e = Safe.impureThrow (Bug (Safe.toException e) callStack)
#endif

mask_ :: MonadMask m => m a -> m a
mask_ = Safe.mask_
{-# DEPRECATED mask_ "This function will be removed in a future version of this package, use `Control.Exception.Safe.mask_` from `safe-exceptions` instead." #-}

-- To suppress redundant applicative constraint warning on GHC 8.0
-- | Throws error for 'Maybe' if 'Data.Maybe.Nothing' is given.
-- Operates over 'MonadError'.
#if ( __GLASGOW_HASKELL__ >= 800 )
note :: (MonadError e m) => e -> Maybe a -> m a
note err = maybe (throwError err) pure
#else
note :: (MonadError e m, Applicative m) => e -> Maybe a -> m a
note err = maybe (throwError err) pure
#endif


#if ( __GLASGOW_HASKELL__ >= 800 )
{- | Pattern synonym to easy pattern matching on exceptions. So intead of
writing something like this:

@
isNonCriticalExc e
    | Just (_ :: NodeAttackedError) <- fromException e = True
    | Just DialogUnexpected{} <- fromException e = True
    | otherwise = False
@

you can use 'Exc' pattern synonym:

@
isNonCriticalExc = \case
    Exc (_ :: NodeAttackedError) -> True  -- matching all exceptions of type 'NodeAttackedError'
    Exc DialogUnexpected{} -> True
    _ -> False
@

This pattern is bidirectional. You can use @Exc e@ instead of @toException e@.
-}
pattern Exc :: Exception e => e -> SomeException
pattern Exc e <- (fromException -> Just e)
  where
    Exc e = toException e
#endif
