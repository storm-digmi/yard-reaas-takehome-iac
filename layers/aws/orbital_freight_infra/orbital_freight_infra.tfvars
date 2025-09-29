project_info = {
    name = "orbital-freight-podinfo"
}

aws_region = "eu-central-1"

lambda = {
    image_uri = "110090858036.dkr.ecr.eu-central-1.amazonaws.com/orbital-freight-podinfo-repo@sha256:fbd00c80112b5bc89598fd67c4d3507d6a790e1790679c3d6452c1aee6054c21"
    memory_mb = 512
    timeout_seconds = 15
}

image_tag = "latest"

alerts_email = "a.pindozzi@reply.it"