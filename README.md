# To run the app in EC2

```bash
$ cd terraform
$ terraform init
$ terraform apply
```

## To Test

`terraform output ip_address`

get ip and access http://IP:8000/ in the browser

## To ssh

`terraform output ssh_private_key`

save key in pem file
`chmod 400 <pem_file>`

`ssh -i <pem_file> ubuntu@<IP>`
