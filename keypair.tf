resource "aws_key_pair" "default" {
    key_name = "ec2_key_pair"
    public_key = "${fille("${var.key_path}")}"  
}