#!/bin/bash
echo $'\n================== Commit ==================\n'
git commit -v -am "commit pull"
echo $'\n=================== Pull ===================\n'
git fetch --tags
git pull -v origin master
echo $'\n=================== Done ===================\n'
read -p "Type enter to quit..."
