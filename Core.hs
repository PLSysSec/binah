-- | Functionality that needs to be loaded before checking the Models file.

module Binah.Core ( Entity, Key, EntityFieldWrapper(..), BinahRecord(..) ) where

import Database.Persist (Entity, Key, EntityField)

-- TODO: This entity stuff is morally just refinements on existing functions
-- from Persist, it would be nice to move this to a spec file.

-- TODO: There's some kind of weird name-resolution problem going on here: I
-- think it would make sense if these measures were named e.g. Core.entityKey,
-- but for some reason that breaks everything, as does auto-generating the
-- measures with e.g. {-@ measure entityKey @-}

{-@ measure entityKey :: Entity record -> Key record @-}

{-@ measure entityVal :: Entity record -> record @-}

{-@
data EntityFieldWrapper user record typ < querypolicy :: Entity record -> user -> Bool
                                        , selector :: Entity record -> typ -> Bool
                                        , flippedselector :: typ -> Entity record -> Bool
                                        , capability :: Entity record -> Bool
                                        , updatepolicy :: Entity record -> Entity record -> user -> Bool
                                        > = EntityFieldWrapper _
@-}

data EntityFieldWrapper user record typ = EntityFieldWrapper (EntityField record typ)
{-@ data variance EntityFieldWrapper invariant covariant covariant invariant invariant invariant invariant invariant @-}

{-@ data BinahRecord user record < p :: Entity record -> Bool
                                 , insertpolicy :: Entity record -> user -> Bool
                                 , querypolicy  :: Entity record -> user -> Bool
                                 > = BinahRecord _
@-}
data BinahRecord user record = BinahRecord record
{-@ data variance BinahRecord invariant invariant invariant invariant invariant @-}

{-@ measure currentUser :: Int -> user @-}