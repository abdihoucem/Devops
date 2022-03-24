data "template_file" "shell-script" {
   template = "${file("script/git.sh")}"  
}

data "template_file" "git_application_user_data" {
    template = "${file("templates/git_application_user_data.tpl")}"  
    vars {
        postgresql_database = "${aws_db_instance.gitlab_postgres.name}"
        postgresql_username = "${aws_db_instance.gitlab_postgres.username}"
        postgresql_password = "${var.gitlab_postgres_password}"
        postgresql_endpoint = "${aws_db_instance.gitlab_postgres.address}"
        redis_endpoint = "${aws_elasticache_replication_group.gitlab_redis.primary_endpoint_address}"
        cidr        = "${var.vpc_cidr}"
        gitlab_url   = "http://${aws_lb.alb_apps.dns_name}"
    }
}

data "template_cloudinit_config" "config" {
  gzip = false
  base64_encode = false

  part {
    filename = "gitlab_application_user_data.tpl"
    content_type = "text/x-shellscript"
    content = "${data.template_file.shell-script.rendered}"
  }

  part {
    content_type = "text/x-shellscript"
    content = "${data.template_file.shell-script.rendered}"
  } 
}

output "GitLab_One-Time_DB_Creation_Command-Primary_Only" {
      value = "force=yes; export force; gitlab-rake gitlab:setup"
  }

output "GitLab_One-Time_DB_Creation_Command-Primary_Only_2" {
      value = "sudo gitlab-ctl reconfigure"
  }

  output "Bastion Public IP" {
      value = "${aws_instance.bastion.public_ip}"
  }

output "Devops_Apps_Public_IP" {
      value = "${aws_lb.alb_apps.dns_name}"
  }




