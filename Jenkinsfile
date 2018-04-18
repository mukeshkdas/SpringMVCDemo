// change the project version (don't rely on version from pom.xml)
env.BN = VersionNumber([
    versionNumberString : '${BUILD_MONTH}.${BUILDS_TODAY}.${BUILD_NUMBER}', 
    projectStartDate : '2018-04-07', 
    versionPrefix : 'v1.'
])

node("master")
{
        stage("Provision"){
        
        echo 'PIPELINE STARTED'
        echo "checkout source code from GitHub......"
        git credentialsId: 'JenkinsSSH', url: 'git@github.com:mukeshkdas/SpringMVCDemo.git'

        echo 'Change the project version ...'
        def W_M2_HOME = tool 'maven3'
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
            
                 echo 'jUnit report (surefire) ...'
                 junit allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml'
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
            
                 echo 'jUnit report (failsafe) ...'
                 junit allowEmptyResults: true, testResults: '**/target/failsafe-reports/*.xml'          
            }
    }
},
failFast: true

node ("TestMachine-ut") {
    
    // we can also use: withEnv(['M2_HOME=/usr/share/maven', 'JAVA_HOME=/usr']) {}
    env.MAVEN_HOME = '/usr/share/maven'
    env.M2_HOME = '/usr/share/maven'
    env.JAVA_HOME = '/usr'
    
    // echo 'Preparing Artifactory to resolve dependencies ...'          
    // def server = Artifactory.server('artifactory')       
    // def rtMaven = Artifactory.newMavenBuild()
    // rtMaven.opts = '-Xms1024m -Xmx4096m'
    // rtMaven.resolver server: server, releaseRepo: 'virtual-repo', snapshotRepo: 'virtual-repo'
    
    stage('SCA') {
        echo 'Unstash the project source code ...'
        unstash 'SOURCE_CODE'

        echo 'Executing Maven test-compile ...'
         sh "'${M2_HOME}/bin/mvn' clean test-compile"
        //rtMaven.run pom: 'pom.xml', goals: 'clean test-compile'
    }    
    
    parallel Findbugs:{
        stage('Findbugs') {    
            echo 'Running Findbugs ...'
            sh "'${M2_HOME}/bin/mvn' findbugs:findbugs"
            //rtMaven.run pom: 'pom.xml', goals: 'findbugs:findbugs'
            step([$class: 'FindBugsPublisher', canComputeNew: false, defaultEncoding: '', 
                    excludePattern: '', healthy: '', includePattern: '', pattern: '**/target/findbugsXml.xml', unHealthy: ''])
            
        }
    },
    Checkstyle:{
        stage('Checkstyle') {            
            echo 'Running Checkstyle ...'
            sh "'${M2_HOME}/bin/mvn' checkstyle:check"
            //rtMaven.run pom: 'pom.xml', goals: 'checkstyle:check'
            step([$class: 'CheckStylePublisher', canComputeNew: false, defaultEncoding: '', 
                    healthy: '', pattern: '**/target/checkstyle-result.xml', unHealthy: ''])            
        }
    },
    Pmd:{
        stage('Pmd') {         
            echo 'Running PMD ...'		
            sh "'${M2_HOME}/bin/mvn' pmd:pmd"
            // rtMaven.run pom: 'pom.xml', goals: 'pmd:pmd'
            step([$class: 'PmdPublisher', canComputeNew: false, defaultEncoding: '', 
                    healthy: '', pattern: '**/target/pmd.xml', unHealthy: ''])            
        }
    },
    TaskScanner:{
        stage('TaskScanner'){
            echo 'Running TaskRunner ...'
            // step([$class: 'TasksPublisher', canComputeNew: false, defaultEncoding: '', 
            //         excludePattern: '', healthy: '', high: 'TODO,TO DO,FIXME', low: '', normal: '', pattern: '**/*.java', unHealthy: ''])

            openTasks canComputeNew: false, defaultEncoding: '', excludePattern: '', healthy: '', high: 'TODO,TO DO,FIXME', low: '', normal: '', pattern: '**/*.java', unHealthy: ''
        }
    },
    failFast: false
	
    stage('CombinedAnalysis'){
        echo 'Running Analysis publisher ...'
        step([$class: 'AnalysisPublisher', canComputeNew: false, defaultEncoding: '', healthy: '', unHealthy: ''])
    }
}

node("TestMachine-ut") {
    
    // we can also use: withEnv(['M2_HOME=/usr/share/maven', 'JAVA_HOME=/usr']) {}
    env.MAVEN_HOME = '/usr/share/maven'
    env.M2_HOME = '/usr/share/maven'
    env.JAVA_HOME = '/usr'
    
    stage('Run-Sonar') {     
        echo 'Run sonar:sonar ...'
	
        unstash 'SOURCE_CODE'           
        unstash 'JACOCO_UT'
        unstash 'JACOCO_IT'
           
        sh "'${M2_HOME}/bin/mvn' test-compile sonar:sonar -Dsonar.host.url=http://sonarqube:9000 -Dmaven.clean.skip=true"      
        // sh "'${M2_HOME}/bin/mvn' test-compile sonar:sonar -Dsonar.host.url=http://139.59.90.202:9000 -Dmaven.clean.skip=true" 
        // rtMaven.run pom: 'pom.xml', goals: 'test-compile sonar:sonar -Dsonar.host.url=http://localhost:9000 -Dmaven.clean.skip=true'
    }    

    stage("Publish-Snapshot") {        
        echo 'Preparing Artifactory to resolve dependencies ...'         

        def server = Artifactory.server('artifactory')       
        def rtMaven = Artifactory.newMavenBuild()
        rtMaven.opts = '-Xms1024m -Xmx4096m'    
        rtMaven.deployer server: server, releaseRepo: 'snapshot-repo', snapshotRepo: 'snapshot-repo'
        
        echo 'Publish SNAPSHOT war ...'	              
        def buildInfo = rtMaven.run pom: 'pom.xml', goals: 'clean install -DskipTests'
        server.publishBuildInfo buildInfo
      }
}  
    
node ("master") {
    echo 'Stash the performance tests ...'
    stash includes: '**/TestPlan.jmx', name: 'JMETER_TESTS' 
}

node("PfMachine-jm") {
    
    stage("Start-Payara") {     
        echo 'Starting Payara server ...'
        sh 'echo jenkins | sudo -S /opt/payara41/bin/asadmin start-domain'
    }
    
    stage ("Download-WAR") {
        echo 'Download the application WAR ...'
        
        def downloadWAR = """{
            "files": [{
                "pattern": "snapshot-repo/javaee/SpringMVCDemo/${BN}/*.war",
                "target": "war/"
            }]
        }"""
        
        def server = Artifactory.server('artifactory')
        server.download(downloadWAR)
    }
    
    stage ("Deploy-WAR") {
        echo 'Deploy the application WAR in Payara server ...'
        sh "echo jenkins | sudo -S /opt/payara41/bin/asadmin deploy --contextroot '/SpringMVCDemo' ${WORKSPACE}/war/javaee/SpringMVCDemo/${BN}/SpringMVCDemo-${BN}.war"        
    }
    
    stage ("Deploy-JMeter-Tests") {
        echo 'Unstash JMeter tests ...'
        unstash 'JMETER_TESTS'
    }        
    
    stage ("Run-JMeter-Tests") {
        echo 'Run the JMeter tests ...'
        
        sh "/opt/jmeter/bin/jmeter.sh -Jduration=600 -n -t ${WORKSPACE}/TestPlan.jmx -l ${WORKSPACE}/results.jtl"
        performanceReport compareBuildPrevious: true, configType: 'ART', errorFailedThreshold: 0, errorUnstableResponseTimeThreshold: '', 
        errorUnstableThreshold: 0, failBuildIfNoResultFile: false, ignoreFailedBuilds: true, ignoreUnstableBuilds: true, 
        modeOfThreshold: false, modePerformancePerTestCase: true, modeThroughput: true, nthBuildNumber: 0, 
        parsers: [[$class: 'JMeterParser', glob: "${WORKSPACE}/results.jtl"]], 
        relativeFailedThresholdNegative: 0, relativeFailedThresholdPositive: 0, relativeUnstableThresholdNegative: 0, 
        relativeUnstableThresholdPositive: 0
    }
    
    stage("Promote to staging"){
        echo 'Promoting application from SNAPSHOT to STAGING ...'
        
        def server = Artifactory.server('artifactory')
        def promotionConfig = [
            // Mandatory parameters
        'buildName'          : 'test-job2',
        'buildNumber'        : BUILD_NUMBER,
        'targetRepo'         : 'staging-repo',

            // Optional parameters
        'comment'            : 'Promoting to staging ....',
        'sourceRepo'         : 'snapshot-repo',
        'status'             : 'Staging',
        'includeDependencies': false,
        'copy'               : true,
        'failFast'           : true
        ]

        // Promote build
        server.promote promotionConfig
    }
}

// QA, UAT, ... nodes (e.g. EC2 instances, local machines, etc)
echo 'Running in QA node ...'
echo 'Running in UAT node ...'

echo 'Promoting application from STAGING to RELEASE ...'
stage("Promote to release"){
    def server = Artifactory.server('artifactory')
    def promotionConfig = [
        // Mandatory parameters
        'buildName'          : 'test-job2',
        'buildNumber'        : BUILD_NUMBER,
        'targetRepo'         : 'release-repo',

        // Optional parameters
        'comment'            : 'Promoting to release ....',
        'sourceRepo'         : 'staging-repo',
        'status'             : 'Release',
        'includeDependencies': false,
        'copy'               : true,
        'failFast'           : true
    ]

    // Promote build
    server.promote promotionConfig
}


