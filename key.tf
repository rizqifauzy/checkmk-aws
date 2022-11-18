resource "aws_key_pair" "terraform-key" {
  key_name   = "terraform-key"
  public_key = file(var.PATH_TO_PUBLIC_KEY)
}