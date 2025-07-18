pipeline {
    options
    {
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }
    agent any
    environment 
    {
        TERRAFORM_ACTION = "${Terraform_Action}"
        SELECT_ENV = "${Select_Env}"
        AWS_PROFILE = "default"
        AWS_SDK_LOAD_CONFIG=1
    }
    stages {
        stage("Preparation") {
            steps {
                script {
                    sh"""
                    cd terraform
                    #terraform init -plugin-dir=/opt/mnt/jenkins/tfplugin -no-color
                    terraform init -no-color
                   """
                }
            }
        }
        stage("Execution") {
            steps {
                script {
                    if (TERRAFORM_ACTION == "apply") {
                        if (SELECT_ENV == "dev") {   
                        sh"""
                        cd terraform
                        terraform workspace select dev || terraform workspace new dev
                        terraform apply -auto-approve -no-color
                        """
                    }
                    else if (SELECT_ENV == "stag"){
                        sh"""
                        cd terraform
                        terraform workspace select stag || terraform workspace new stag
                        terraform apply -auto-approve -no-color
                        """
                    }
                    else if (SELECT_ENV == "prod") 
                    {
                        sh"""
                        cd terraform
                        terraform workspace select prod || terraform workspace new prod
                        terraform apply -auto-approve -no-color
                        """
                    }

                    }
                    else if (TERRAFORM_ACTION == "destroy") {
                        if (SELECT_ENV == "dev") {   
                        sh"""
                        cd terraform
                        terraform plan -destroy -no-color
                        """
                        timeout(time:1, unit:"HOURS") {
                            input message:"Are you sure you wish to destroy this infrastructure: ?"
                        }
                        sh"""
                        cd terraform
                        terraform workspace select dev || terraform workspace new dev
                        terraform destroy -auto-approve -no-color
                        """
                    }
                    else if (SELECT_ENV == "stag"){
                        sh"""
                        cd terraform
                        terraform plan -destroy -no-color
                        """
                        timeout(time:1, unit:"HOURS") {
                            input message:"Are you sure you wish to destroy this infrastructure: ?"
                        }
                        sh"""
                        cd terraform
                        terraform workspace select stag || terraform workspace new stag
                        terraform destroy -auto-approve -no-color
                        """
                    }
                    else if (SELECT_ENV == "prod") 
                    {
                        sh"""
                        cd terraform
                        terraform plan -destroy -no-color
                        """
                        timeout(time:1, unit:"HOURS") {
                            input message:"Are you sure you wish to destroy this infrastructure: ?"
                        }
                        sh"""
                        cd terraform
                        terraform workspace select prod || terraform workspace new prod
                        terraform destroy -auto-approve -no-color
                        """
                    }
                    }
                    else {
                        if (TERRAFORM_ACTION == "plan") {
                        if (SELECT_ENV == "dev") {   
                        sh"""
                        cd terraform
                        terraform workspace select dev || terraform workspace new dev
                        terraform plan -no-color
                        """
                    }
                    else if (SELECT_ENV == "stag"){
                        sh"""
                        cd terraform
                        terraform workspace select stag || terraform workspace new stag
                        terraform plan -no-color
                        """
                    }
                    else if (SELECT_ENV == "prod") 
                    {
                        sh"""
                        cd terraform
                        terraform workspace select prod || terraform workspace new prod
                        terraform plan -no-color
                        """
                            }
                        }
                    }
                }
            }
        }
    }
}
