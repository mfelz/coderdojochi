#!/bin/bash

if [[ "$1" == "staging" ]]; then

    echo " -- Deploying to staging..."
    cd /home/coderdojo/webapps/coderdojochi_staging/coderdojochi
    git checkout develop
    git pull origin develop

elif [[ "$1" == "production" ]]; then

    echo " -- Deploying to production..."
    cd /home/coderdojo/webapps/coderdojochi/coderdojochi
    git checkout master
    git pull origin master

elif [[ "$1" == "local" ]]; then

    echo " -- Starting local..."

else

    echo "Wrong deployment variable. deploy.sh (local|staging|production)"
    exit

fi

if [[ "$1" != "local" ]]; then
    echo " -- Activating environment"
    source ../bin/activate
fi

echo " -- Installing Django packages"
pip install -q -r requirements.txt --exists-action=s

if [[ $(pip list | grep 'South') ]]; then
    echo " -- Uninstall South"
    pip uninstall -q -y South
fi

if [[ "$1" == "local" && $(pip list | grep 'django_cron') ]]; then
    echo " -- Uninstall django_cron"
    pip uninstall -q -y django_cron
fi


echo " -- Installing node packages"
npm prune
npm install

if [[ "$1" == "local" ]]; then
    python manage.py makemigrations
    python manage.py migrate
    python manage.py syncdb
else
    ./node_modules/gulp/bin/gulp.js build
    python2.7 manage.py makemigrations
    python2.7 manage.py migrate
    python2.7 manage.py collectstatic --noinput

    echo " -- Restarting server"
    ../apache2/bin/stop
    sleep 2
    ../apache2/bin/start
fi
