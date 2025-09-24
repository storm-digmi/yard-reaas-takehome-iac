project_info = {
    name = "orbital-freight-podinfo"
}

aws_region = "eu-central-1"

lambda = {
    image_uri = "110090858036.dkr.ecr.eu-central-1.amazonaws.com/orbital-freight-podinfo-repo"
    memory_mb = 512
    timeout_seconds = 15
}