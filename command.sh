docker pull sonarqube:6.2
docker run -p 9000:9000 --name sonarqube sonarqube:6.2

docker pull sonarqube:6.3.1
docker run -p 9000:9000 --name sonarqube sonarqube:6.3.1

docker pull docker.bintray.io/jfrog/artifactory-pro:latest
docker run -d -p 8081:8081 --name artifactory -v /artifactory:/var/opt/jfrog/artifactory docker.bintray.io/jfrog/artifactory-pro:latest