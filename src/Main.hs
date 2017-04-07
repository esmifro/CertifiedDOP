-----------------------------------------------------------------------------
--
-- Module      :  Main
-- Copyright   :
-- License     :  AllRightsReserved
--
-- Maintainer  :  Vitor Rodrigues
-- Stability   :
-- Portability :
--
-- |
--
-----------------------------------------------------------------------------
{-# LANGUAGE CPP #-}
{-# LANGUAGE DeriveDataTypeable #-}
module Main (
    main
) where

import Functions
import Operations
import Safety

import System.Console.CmdArgs
import System.Directory
import Control.Monad
import Criterion.Main
import System.IO.Unsafe

data Diffy = Certify {oldrpmdir :: FilePath, newrpmdir :: FilePath, workdir :: FilePath,
                      deltarpm :: FilePath, resolve :: Bool }
           | Apply {deltarpm :: FilePath,  workdir :: FilePath, resolve :: Bool }
           deriving (Data,Typeable,Show,Eq)

makedeltarpm = Certify
    {oldrpmdir = def &= help "Old Autotools project directory" &= typDir
    ,newrpmdir = def &= help "New Autotools project directory" &= typDir
    ,workdir = ("./data/"::FilePath) &= help "Set working project directory" &= typDir
    ,deltarpm = "ecall_delta-1.0-1.i686.drpm" &= help "Delta RPM file" &= typFile
    ,resolve = False &= help "Resolve Undefined (U) symbols"
    } &= help "Create a certified deltarpm from two rpms"

applydeltarpm = Apply
    {deltarpm = def &= typ "DELTAFILE" &= typFile -- &= argPos 0
    ,workdir = ("./data/"::FilePath) &= help "Set working project directory" &= typDir
    ,resolve = False &= help "Resolve Undefined (U) symbols"
    } &= help "Reconstruct an rpm from a deltarpm (safe operation)"

mode = cmdArgsMode $
        modes [makedeltarpm,applydeltarpm] &= help "Create and Apply Certified Delta RPMs"
        &= program "delta-cert" &= summary "DeltaCert 0.0.1" &= verbosity



main = do
       line <- cmdArgsRun mode
       case line of
            Certify oldrpm newrpm workdir deltarpm resolve ->
                do
                setSafetyLevel (if resolve then Level2 else Level1)
                ex <- doesDirectoryExist workdir
                when (not ex)
                     (error ("directive \"DELTADIR\" is invalid. mkdir (?)"))
                --manual test
                --test_certify oldrpm newrpm workdir deltarpm
                runCertify2 oldrpm newrpm workdir deltarpm
            Apply deltarpm workdir resolve ->
                do
                setSafetyLevel (if resolve then Level2 else Level1)
                ex <- doesDirectoryExist workdir
                when (not ex)
                     (error ("directive \"DELTADIR\" is invalid. mkdir (?)"))
                --maual test
                --test_apply workdir deltarpm
                let runner a = let exit = unsafePerformIO $ runApply2 workdir deltarpm
                               in exit
                    result = runner 0
                putStrLn (show result)



