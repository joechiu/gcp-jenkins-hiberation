node {
    project = "cloud-platforms"
    playbook= "create-vms.yml"
    task = "gcp"
    repositoryUrl = "https://github.com/joehmchiu/${project}.git"
    branch = "master"
    msg = "Create VMs in GCP"

    stage 'Git Update'
    node() {
        git url: repositoryUrl, credentialsId: "gcp-2019", branch: branch
        sh "ls -ltrhR"
    }

    stage 'Preload check and run'
    node() {
	sh "sudo sh ./lib/run.sh"
    }

    load "/opt/bin/jenkins-run.groovy"
}
