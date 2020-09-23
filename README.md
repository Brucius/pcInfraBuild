# pcInfraBuild
This terraform template is useful for creating a quick windows VM in Azure cloud. It uses windows 10 pro with build version 1909 that supports wsl environment backend for docker community edition.

Machine specs are as follow:
vCPU      - 2
RAM       - 8GB
Location  - southeastasia

## To plan
```
terraform plan -out=pcInfra
```

## To apply
```
terraform apply -var 'admin_username=namehere' -var 'admin_password=p@sswordhere'
```
