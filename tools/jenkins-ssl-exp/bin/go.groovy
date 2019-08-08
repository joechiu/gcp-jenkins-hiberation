node {
    project = "cloud-platforms"
    path = 'tools'
	taskdir = '/opt/tasks'
    task = 'jenkins-ssl-exp'
	command = "sh init.sh"
    repositoryUrl = "https://github.com/joehmchiu/cloud-platforms.git"
    branch = "master"
    msg = "Certificate Alert Mail"

	// loading and running jenkins tasks 
	workspace = pwd()
	ok = '\u2705'
	no = '\u274C'

    stage 'Git Update'
    node() {
        git url: repositoryUrl, credentialsId: "dac2018", branch: branch
        sh "ls -ltrhR"
    }

    // load "/opt/bin/jenkins-run.groovy"
	stage 'Confirm Task'
	node() {
		timeout(time: 30, unit: 'SECONDS') {
			input "${msg}?"
		}
	}

	stage 'Init Working Env'
	node() {
		sh "sudo sh /opt/bin/init.sh ${project} '${task}'"
		sh "sudo cp -rf '${path}/${task}' ${taskdir}/${project}/."
	}

	stage 'Check List'
	node() {
		echo "${ok} Check Workspace: ${workspace}/"
		sh "ls -ltrh /tmp/env/"
		echo "${ok} Check Ansible Availability"
		sh 'which ansible'
		echo "${ok} Check Ansible Version"
		sh 'sudo ansible --version'
		echo "${no} Something's wrong..."
		echo '$&@*&%#)(*#@(*_)*&%#*^@&$)*'
	}

	stage "${msg}"
	node() {
		sh "cd '${taskdir}/${project}/${task}';sudo ${command}"
	}
	
	stage "Task Finalized"
	node() {
		sh "sudo sh /opt/bin/log.sh '${msg}'"
		sh "sudo sh /opt/bin/fin.sh ${project} ${task}"
	}
}

