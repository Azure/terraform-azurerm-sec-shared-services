set -ex

SUFFIX=$1

az group delete --name be-$SUFFIX --yes &
az group delete --name rg-net-ss-$SUFFIX --yes &
az group delete --name rg-sec-ss-$SUFFIX --yes &
az group delete --name rg-data-ss-$SUFFIX --yes &

wait

rm -Rf .terraform
rm -Rf terraform-azurerm-remote-state/.terraform
rm backend.*
rm terraform.tfstate*

