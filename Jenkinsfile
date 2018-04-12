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
        sh "${W_M2_HOME}/bin/mvn versions:set -DnewVersion=$BN -DgenerateBackupPoms=false"                

        echo "Create a new branch with name release_${BN} ..."
        def W_GIT_HOME = tool 'Git'
        sh "${W_GIT_HOME} checkout -b release_${BN}"

        echo 'Stash the project source code ...'
        stash includes: '**', excludes: '**/TestPlan.jmx', name: 'SOURCE_CODE'
    }    
}

parallel UnitTests:{
    node ("TestMachine-ut") {
            echo 'Hello TestMachine-ut ...'
            //we can also use: withEnv(['M2_HOME=/usr/share/maven', 'JAVA_HOME=/usr']) {}
            env.M2_HOME = '/usr/share/maven'
            env.JAVA_HOME = '/usr'	 

            stage('Run-ut') {           
                 echo 'Unstash the project source code ...'
                 unstash 'SOURCE_CODE'	                                                       
                                
                // echo 'Run the unit tests ...'
                // sh "'${M2_HOME}/bin/mvn' clean test"   

                echo 'Run the unit tests (and Jacoco) ...'
                sh "'${M2_HOME}/bin/mvn' clean test-compile jacoco:prepare-agent test -Djacoco.destFile=target/jacoco.exec"   
                //rtMaven.run pom: 'pom.xml', goals: 'clean test-compile jacoco:prepare-agent test -Djacoco.destFile=target/jacoco.exec'

                echo 'Run the Jacoco code coverage report for unit tests ...'
                step([$class: 'JacocoPublisher', canComputeNew: false, defaultEncoding: '', healthy: '', 
                        pattern: '**/target/jacoco.exec', unHealthy: ''])
			
                echo 'Stash Jacoco-ut exec ...'
                stash includes: '**/target/jacoco.exec', name: 'JACOCO_UT' 
            
                // echo 'jUnit report (surefire) ...'
                // junit allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml'
                // currentBuild.result='SUCCESS'
            }
    }
},
IntegrationTests:{
    node ("TestMachine-it") {
            // we can also use: withEnv(['M2_HOME=/usr/share/maven', 'JAVA_HOME=/usr']) {}        
            env.M2_HOME = '/usr/share/maven'
            env.JAVA_HOME = '/usr'
        
            stage('Run-it') {
            
                echo 'Unstash the project source code ...'
                unstash 'SOURCE_CODE'
            
                echo 'Start postgresql ...'
                sh 'echo jenkins | sudo -S /etc/init.d/postgresql start'
                            
                echo 'Run the integration tests (and Jacoco) ...'
                sh "'${M2_HOME}/bin/mvn' clean package jacoco:prepare-agent verify -DskipUTs=true -Djacoco.destFile=target/jacoco-it.exec"
                // rtMaven.run pom: 'pom.xml', goals: 'clean package jacoco:prepare-agent verify -DskipUTs=true -Djacoco.destFile=target/jacoco-it.exec'

                echo 'Run the Jacoco code coverage report for integration tests ...'
                step([$class: 'JacocoPublisher', canComputeNew: false, defaultEncoding: '', healthy: '', 
                        pattern: '**/target/jacoco-it.exec', unHealthy: ''])
			
                echo 'Stash Jacoco-it exec ...'
                stash includes: '**/target/jacoco-it.exec', name: 'JACOCO_IT'
            
                // echo 'jUnit report (failsafe) ...'
                // junit allowEmptyResults: true, testResults: '**/target/failsafe-reports/*.xml'          
            }
    }
},
failFast: true



    


