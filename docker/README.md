# Docker - PRO
* Ajouter ```rm /svc/RUNNING_PID``` au début du fichier /files/bin/start
## Application

1. Modification des fichiers (à définir)

    Il faut modifier l'URL du fichier app\controllers\BDDpackage\BDD.java par ```private String url = jdbc:postgresql://postgres/BD_Budget``` 

    Il faut aussi modifier l'URL du fichier conf/application.conf ```db.default.url="jdbc:postgresql://postgres/BD_Budget"```

2. Taper ```dist``` dans la console SBT sur Intellij

    Ceci permet de créer un ```SNAPSHOT.zip``` dans ```target/universal/```

3. Préparation pour le déployement

    Ces commandes doivent être tapée dans le dossier Source_projet. 
    
    ATTENTION: supprimez tous les fichiers qui se trouvent dans docker/app/files

    ```
    unzip -d docker/app/files target/universal/*-1.0-SNAPSHOT.zip
    mv docker/app/files/*/* docker/app/files
    rm docker/app/files/bin/*.bat
    mv docker/app/files/bin/* docker/app/files/bin/start
    ```
    
    Elles permettent de préparer les fichiers de l'application pour docker.
    
    **Ajouter ```rm /svc/RUNNING_PID``` au début du fichier /files/bin/start**
    
4. Base de données

    Si il y a eu une modification de la base de données, il faut mettre à jour le fichier bdd.sql en exportant 

5. Lancement de l'application sur le serveur

    Ouvrir docker dans le répertoire ```docker/app/``` et taper la commande ```docker-compose up```. Cette commande va appeler le fichier docker-compose.yml ainsi que Dockerfile. L'application va tourner en production sous docker.
    
Si on veut modifier des fichiers ou éteindre et relancer l'application, il faut supprimer les 2 containers pgsql_PRO et app_web_1 ainsi que leur image respective. 

## Sources

* https://elanderson.net/2018/02/setup-postgresql-on-windows-with-docker/

* https://medium.com/@shatil/play-framework-https-hello-world-with-docker-62963cf26daf

* https://stackoverflow.com/questions/53257416/dockerizing-play-framework
