#!/bin/bash

rm -f Maze.zip Maze.love

zip Maze.zip *.lua Painted.ttf background.png tileset.png
mv Maze.zip Maze.love

# Copy Love file

mv Maze.love dist/love

# Make OSX package

pushd dist/osx
unzip Maze-OSX.zip

cp ../love/Maze.love Maze.app/Contents/Resources/Maze.love

rm -f Maze-OSX.zip
zip -r Maze-OSX.zip Maze.app
rm -rf Maze.app
popd

# Make w32 package

pushd dist/w32

cat love.exe ../love/Maze.love > Maze.exe
rm -f Maze-w32.zip
rm -rf Maze
mkdir Maze
cp *.dll Maze.exe Maze
zip -r Maze-w32.zip Maze
rm -rf Maze.exe Maze

popd
