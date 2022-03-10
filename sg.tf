ressource "aws_security_group" "efs-general" {
    name = "sg_efs_general"
    description ="Allow incomming NFS ports"
    ingress {
        from_port = 2049
        to_port = 2049
        protocol = "tcp"
        cidr_blocks = ["${var.private_subnet_2a_cidr}","${var.private_subnet_2b_cidr}"]
    }
    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["${var.private_subnet_2a_cidr}","${var.private_subnet_2b_cidr}"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    vpc_id = "${aws_vpc.default.id}"
    tags {
        Name = "EFS SG"
    }
}