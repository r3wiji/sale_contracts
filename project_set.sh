#!/bin/bash
echo $'\n================== Commit ==================\n'
git commit -v -am "commit push"
echo $'\n=================== Pull ===================\n'
git fetch --tags
git pull -v origin master
echo $'\n=================== Push ===================\n'
git push -v origin master --tags
echo $'\n=================== Done ===================\n'
read -p "Type enter to quit"
