#!/usr/bin/env stack
{- stack runghc
  --resolver lts-11.14
  --install-ghc
  --package shake
-}

import Development.Shake
import Development.Shake.Command
import Development.Shake.FilePath
import Development.Shake.Util

-- TODO
-- 1. loop through cover_letters and require pdf for each .tex there.
-- 2. if a user runs ./build company_name and cover_letters/company_name does
-- not exist, do the logic found in new_coverletter.sh
main :: IO ()
main = shakeArgs shakeOptions{shakeFiles="dist"} $ do
  let targets = [ "awesome-cv.pdf"
                , "classic-cv.pdf"
                , "kjh-cv.pdf"
                ]
  want ["dist" </> target | target <- targets]

  "dist/*.pdf" %> \out -> do
    let n = takeBaseName out
    need =<< fmap (n </>) <$> getDirectoryFiles n ["//*"]
    command_
      [Cwd n, EchoStdout True, EchoStderr True]
      "xelatex"
      ["-output-directory", "../dist", "-jobname", n, "main.tex"]

  phony "clean" $ do
    putNormal "Cleaning files in dist"
    removeFilesAfter "dist" ["//*"]

  phony "artifacts" $ do
    need ["dist" </> target | target <- targets]
    putNormal "Copying targets from dist to artifacts"
    mapM_ (uncurry copyFileChanged) $
      [("dist" </> t, "artifacts" </> t) | t <- targets]