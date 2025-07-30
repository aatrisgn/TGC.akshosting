REGISTRY_NAME=$1
SOURCE_REGISTRY=registry.k8s.io
CONTROLLER_IMAGE=ingress-nginx/controller
CONTROLLER_TAG=v1.8.1
PATCH_IMAGE=ingress-nginx/kube-webhook-certgen
PATCH_TAG=v20230407
DEFAULTBACKEND_IMAGE=defaultbackend-amd64
DEFAULTBACKEND_TAG=1.5

az acr login --name $REGISTRY_NAME

CONTROLLER_TAG_EXISTS=$(az acr repository show-tags \
      --name $REGISTRY_NAME \
      --repository $CONTROLLER_IMAGE \
      --query "[?@=='$CONTROLLER_TAG']" \
      --output tsv)

if [ -z "$CONTROLLER_TAG_EXISTS" ]; then
    echo "importing $CONTROLLER_IMAGE:$CONTROLLER_TAG ..."
    az acr import --name $REGISTRY_NAME --source $SOURCE_REGISTRY/$CONTROLLER_IMAGE:$CONTROLLER_TAG --image $CONTROLLER_IMAGE:$CONTROLLER_TAG
    echo "imported $CONTROLLER_IMAGE:$CONTROLLER_TAG !"
else
    echo "$CONTROLLER_IMAGE:$CONTROLLER_TAG already imported. Skipping apply."
fi

PATCH_TAG_EXISTS=$(az acr repository show-tags \
      --name $REGISTRY_NAME \
      --repository $PATCH_IMAGE \
      --query "[?@=='$PATCH_TAG']" \
      --output tsv)

if [ -z "$PATCH_TAG_EXISTS" ]; then
    echo "importing $PATCH_IMAGE:$PATCH_TAG ..."
    az acr import --name $REGISTRY_NAME --source $SOURCE_REGISTRY/$PATCH_IMAGE:$PATCH_TAG --image $PATCH_IMAGE:$PATCH_TAG
    echo "imported $PATCH_IMAGE:$PATCH_TAG !"
else
    echo "$PATCH_IMAGE:$PATCH_TAG already imported. Skipping apply."
fi

DEFAULTBACKEND_TAG_EXISTS=$(az acr repository show-tags \
      --name $REGISTRY_NAME \
      --repository $DEFAULTBACKEND_IMAGE \
      --query "[?@=='$DEFAULTBACKEND_TAG']" \
      --output tsv)

if [ -z "$DEFAULTBACKEND_TAG_EXISTS" ]; then
    echo "importing $DEFAULTBACKEND_IMAGE:$DEFAULTBACKEND_TAG ..."
    az acr import --name $REGISTRY_NAME --source $SOURCE_REGISTRY/$DEFAULTBACKEND_IMAGE:$DEFAULTBACKEND_TAG --image $DEFAULTBACKEND_IMAGE:$DEFAULTBACKEND_TAG
    echo "imported $DEFAULTBACKEND_IMAGE:$DEFAULTBACKEND_TAG !"
else
    echo "$DEFAULTBACKEND_IMAGE:$DEFAULTBACKEND_TAG already imported. Skipping apply."
fi