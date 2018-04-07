node("master")
{
    // change the project version (don't rely on version from pom.xml)
    env.BN = VersionNumber([
        versionNumberString : '${BUILD_MONTH}.${BUILDS_TODAY}.${BUILD_NUMBER}', 
        projectStartDate : '2018-04-07', 
        versionPrefix : 'v1.'
    ])

    stage("Provision"){
        echo 'PIPELINE STARTED'

        echo "checkout source code from GitHub......"
        git credentialsId: 'JenkinsSSH', url: 'git@github.com:mukeshkdas/SpringMVCDemo.git'

        echo 'Change the project version ...'
        def W_M2_HOME = tool 'Maven'
        bat "${W_M2_HOME}\\bin\\mvn versions:set -DnewVersion=$BN -DgenerateBackupPoms=false"                
    }    
}