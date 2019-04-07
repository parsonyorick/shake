{-# LANGUAGE ScopedTypeVariables #-}

module Test.Rattle(main) where

import Development.Rattle
import General.Extra
import System.FilePattern.Directory
import Development.Shake.FilePath
import Control.Exception
import Control.Monad
import Test.Type

main = testSimpleClean $ do
    let wipe = mapM removeFile_ =<< getDirectoryFiles "." ["*"]
    cs <- liftIO $ getDirectoryFiles "." [shakeRoot </> "src/Test/C/*.c"]
    let toO x = takeBaseName x <.> "o"
    let build = do
            forM_ cs $ \c -> cmd ["gcc","-o",toO c,"-c",c]
            cmd $ ["gcc","-o","Main" <.> exe] ++ map toO cs
            cmd ["./Main" <.> exe]

    putStrLn "Build 1: Expect everything"
    rattle rattleOptions build
    putStrLn "Build 2: Expect nothing"
    rattle rattleOptions build
    wipe
    putStrLn "Build 3: Expect cached (some speculation)"
    rattle rattleOptions build

    putStrLn "Build 4: Read/write hazard"
    handle (\(h :: Hazard) -> print h) $ do
        rattle rattleOptions $ do
            cmd ["./Main" <.> exe]
            cmd $ ["gcc"] ++ map toO cs ++ ["-o","Main" <.> exe]
        fail "Expected a hazard"

    putStrLn "Build 5: Rebuild after"
    rattle rattleOptions build