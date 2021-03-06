{-# LANGUAGE GADTs #-}
module Storm.Insert where


import           Control.Exception              ( SomeException(..) )
import           Control.Monad.Catch            ( catch )
import           Control.Monad.Reader           ( MonadReader(..)
                                                , runReaderT
                                                )
import qualified Database.Persist              as Persist

import           Storm.Core
import           Storm.Infrastructure

{-@ ignore insert @-}
{-@
assume insert :: forall < p :: Entity record -> Bool
                        , insertpolicy :: Entity record -> user -> Bool
                        , querypolicy  :: Entity record -> user -> Bool
                        , audience :: user -> Bool
                        >.
  { rec :: (Entity<p> record)
      |- {v: (user) | v == currentUser 0} <: {v: (user<insertpolicy rec>) | True}
  }

  { rec :: (Entity<p> record)
      |- {v: (user<querypolicy rec>) | True} <: {v: (user<audience>) | True}
  }

  StormRecord<p, insertpolicy, querypolicy> user record
  -> TaggedT<{\_ -> True}, audience> user m (Key record)
@-}
insert
  :: ( MonadTIO m
     , Persist.PersistStoreWrite backend
     , Persist.PersistRecordBackend record backend
     , MonadReader backend m
     )
  => StormRecord user record
  -> TaggedT user m (Key record)
insert (StormRecord record) = do
  backend <- ask
  liftTIO . TIO $ runReaderT (Persist.insert record) backend

{-@ ignore insertMany @-}
{-@
assume insertMany :: forall < p :: Entity record -> Bool
                            , insertpolicy :: Entity record -> user -> Bool
                            , querypolicy  :: Entity record -> user -> Bool
                            , audience :: user -> Bool
                            >.
  { rec :: (Entity<p> record)
      |- {v: (user) | v == currentUser 0} <: {v: (user<insertpolicy rec>) | True}
  }

  { rec :: (Entity<p> record)
      |- {v: (user<querypolicy rec>) | True} <: {v: (user<audience>) | True}
  }

  [StormRecord<p, insertpolicy, querypolicy> user record]
  -> TaggedT<{\_ -> True}, audience> user m [Key record]
@-}
insertMany
  :: ( MonadTIO m
     , Persist.PersistStoreWrite backend
     , Persist.PersistRecordBackend record backend
     , MonadReader backend m
     )
  => [StormRecord user record]
  -> TaggedT user m [Key record]
insertMany records = do
  backend <- ask
  liftTIO . TIO $ runReaderT (Persist.insertMany (map (\(StormRecord r) -> r) records)) backend

{-@ ignore insertMaybe @-}
{-@
assume insertMaybe :: forall < p :: Entity record -> Bool
                             , insertpolicy :: Entity record -> user -> Bool
                             , querypolicy  :: Entity record -> user -> Bool
                             , audience :: user -> Bool
                             >.
  { rec :: (Entity<p> record)
      |- {v: user | v == currentUser 0} <: {v: user<insertpolicy rec> | True}
  }

  { rec :: (Entity<p> record)
      |- {v: user<querypolicy rec> | True} <: {v: user<audience> | True}
  }

  StormRecord<p, insertpolicy, querypolicy> user record
  -> TaggedT<{\_ -> True}, audience> user m (Maybe (Key record))
@-}
insertMaybe
  :: ( MonadTIO m
     , Persist.PersistStoreWrite backend
     , Persist.PersistRecordBackend record backend
     , MonadReader backend m
     )
  => StormRecord user record
  -> TaggedT user m (Maybe (Key record))
insertMaybe (StormRecord record) = do
  backend <- ask
  liftTIO . TIO $ runReaderT act backend
  where
    act = (Just <$> Persist.insert record)
            `catch`
              (\(SomeException e) -> return Nothing)