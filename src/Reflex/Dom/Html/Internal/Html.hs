{-# LANGUAGE  FlexibleInstances, MultiParamTypeClasses, ScopedTypeVariables, NoMonomorphismRestriction, TupleSections, TemplateHaskell, StandaloneDeriving, GeneralizedNewtypeDeriving, UndecidableInstances, EmptyDataDecls #-}

module Reflex.Dom.Html.Internal.Html where

import Reflex.Dom
import Reflex.Dom.Class

import Reflex.Host.Class

import Control.Monad.Reader
import Control.Monad.Ref
import Control.Monad.Exception

import Reflex.Dom.Html.Internal.Tag

data Env = Env

newtype Html (cm :: ContentModel) m a = Html { unHtml :: ReaderT Env m a } deriving (Functor, Applicative, Monad, 
  HasDocument, HasWebView, MonadTrans, MonadFix, MonadAsyncException, MonadException, MonadIO)
 
runHtml_ :: Html e m a -> Env -> m a
runHtml_ html env = runReaderT (unHtml html) env

runHtml :: Html e m a -> m a
runHtml html = runHtml_ html Env
  

instance MonadRef m => MonadRef (Html e m) where
  type Ref (Html e m) = Ref m
  newRef = lift . newRef
  readRef = lift . readRef
  writeRef r = lift . writeRef r

deriving instance MonadReflexCreateTrigger t m => MonadReflexCreateTrigger t (Html e m)
deriving instance HasPostGui t h m => HasPostGui t h (Html e m) 
deriving instance MonadHold t m => MonadHold t (Html e m) 
deriving instance MonadSample t m => MonadSample t (Html e m) 

askEnv :: Monad m => Html e m Env
askEnv = Html $ ask  

instance MonadWidget t m => MonadWidget t (Html e m) where
  type WidgetHost (Html e m) = WidgetHost m
  type GuiAction (Html e m) = GuiAction m
  askParent = lift askParent
  
  subWidget n w = do
    r <- askEnv
    lift $ subWidget n $ runHtml_ w r
  subWidgetWithVoidActions n w = do
    r <- askEnv
    lift $ subWidgetWithVoidActions n $ runHtml_ w r
  liftWidgetHost = lift . liftWidgetHost
  schedulePostBuild = lift . schedulePostBuild
  addVoidAction = lift . addVoidAction
  getRunWidget = do
    r <- askEnv
    runWidget <- lift getRunWidget
    return $ \rootElement w -> do
      (a, postBuild, voidActions) <- runWidget rootElement $ runHtml_ w r
      return (a, postBuild, voidActions)
      
      
      