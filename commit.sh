hugo
sleep 2
cd public
git add .
git commit -m "$1"
git pull origin master
git push origin master
