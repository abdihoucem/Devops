resource "aws_lb" "alb_apps" {
  name = "private-apps-alb"
  subnets = [ "${aws_subnet.public-subnet.id}","${aws_subnet.public-subnet2.id}"]
  security_groups = [ "${aws_security_group.sg_git.id}","${aws_security_group.sg_jenkins.id}" ]
  internal = false
  load_balancer_type = "application"
  tags = {
    Environment = "dev"
  }
}

resource "aws_lb_target_group" "jenkins-master-8080" {
  name        = "jenkins-master-8080"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = "${aws_vpc.default.id}"
  health_check {
    path = "/"
    interval = 8
    healthy_threshold = 2
    unhealthy_threshold = 2
    matcher = "200,302"
  }
}

resource "aws_lb_target_group" "git-80" {
  name        = "git-80"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "${aws_vpc.default.id}"
  health_check {
    path = "/"
    interval = 8
    healthy_threshold = 2
    unhealthy_threshold = 2
    matcher = "200,302"
  }
}

resource "aws_lb_listener" "jenkins-master-8080" {
  load_balancer_arn = "${aws_lb.alb_apps.id}"
  port        = 8080
  protocol    = "HTTP"
  default_action {
      target_group_arn = "${aws_lb_target_group.jenkins-master-8080.id}"
      type = "forward"
  }
}

resource "aws_lb_listener" "git-80" {
  load_balancer_arn = "${aws_lb.alb_apps.id}"
  port        = 80
  protocol    = "HTTP"
  default_action {
      target_group_arn = "${aws_lb_target_group.git-80.id}"
      type = "forward"
  }
}

resource "aws_launch_configuration" "git" {
  name_prefix = "git-"
  image_id = "${data.aws_ami.amzn.id}"
  instance_type = "t3.medium"
  key_name = "${aws_key_pair.default.id}"
  security_groups = ["${aws_security_group.sg_git.id}"]
  associate_public_ip_address = false
  user_data = "${data.template_cloudinit_config.config.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.ec2-readonly-profile.name}"
  root_block_device {
    volume_size = "${var.root_block_device_size}"
  }
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_type = "${var.data_volume_type}"
    volume_size = "${var.data_volume_size}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "jenkins-master" {
  name_prefix = "jenkins-master-"
  image_id = "${data.aws_ami.amzn.id}"
  instance_type = "t3.medium"
  key_name = "${aws_key_pair.default.id}"
  security_groups = ["${aws_security_group.sg_jenkins.id}"]
  associate_public_ip_address = false
  user_data = "${file("scripts/jenkins-master.sh")}"
  iam_instance_profile = "${aws_iam_instance_profile.ec2-readonly-profile.name}"
  root_block_device {
    volume_size = "${var.root_block_device_size}"
  }
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_type = "${var.data_volume_type}"
    volume_size = "${var.data_volume_size}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "jenkins-slave" {
  name_prefix = "jenkins-slave-"
  image_id = "${data.aws_ami.amzn.id}"
  instance_type = "t3.medium"
  key_name = "${aws_key_pair.default.id}"
  security_groups = ["${aws_security_group.sg_jenkins.id}"]
  associate_public_ip_address = false
  user_data = "${file("scripts/jenkins-slave.sh")}"
  root_block_device {
    volume_size = "${var.root_block_device_size}"
  }
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_type = "${var.data_volume_type}"
    volume_size = "${var.data_volume_size}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "jenkins-master" {
  name                      = "jenkins-master"
  max_size                  = "${var.asg_jenkins_master_max}"
  min_size                  = "${var.asg_jenkins_master_min}"
  desired_capacity          = "${var.asg_jenkins_master_desired}"
  launch_configuration      = "${aws_launch_configuration.jenkins-master.name}"
  vpc_zone_identifier       = ["${aws_subnet.private-subnet.id}","${aws_subnet.private-subnet.id}"]
  target_group_arns = aws_lb_tar
  tag {
    key                 = "foo"
    value               = "bar"
    propagate_at_launch = true
  }
}