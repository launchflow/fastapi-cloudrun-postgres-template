
#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "gcloud CLI is not installed. Please install it first."
    exit 1
fi

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo "docker is not installed. Please install it first."
    exit 1
fi

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "terraform is not installed. Please install it first."
    exit 1
fi

print_status "Getting project IDs, service name, and location from Terraform state"

# Get the artifacts project ID
cd infra/environments/artifacts
ARTIFACTS_PROJECT_ID=$(terraform output -raw project_id)
cd ../../..

# Get the prod project ID, service name, and location
cd infra/environments/prod
PROD_PROJECT_ID=$(terraform output -raw project_id)
SERVICE_NAME=$(terraform output -raw service_name)
REGION=$(terraform output -raw location)
cd ../../..

# Configure Docker authentication
print_status "Configuring Docker authentication"
gcloud auth configure-docker ${REGION}-docker.pkg.dev

# Pull the dev image
print_status "Pulling dev image"
DEV_IMAGE="${REGION}-docker.pkg.dev/${ARTIFACTS_PROJECT_ID}/docker/${SERVICE_NAME}:dev"
docker pull ${DEV_IMAGE}

# Tag the image for production
print_status "Tagging image for production"
PROD_IMAGE="${REGION}-docker.pkg.dev/${ARTIFACTS_PROJECT_ID}/docker/${SERVICE_NAME}:prod"
docker tag ${DEV_IMAGE} ${PROD_IMAGE}

# Push the production image
print_status "Pushing production image"
docker push ${PROD_IMAGE}

# Confirm before deploying to production
echo -e "${RED}Are you sure you want to deploy to production? (y/N)${NC}"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
then
    print_status "Deploying to Cloud Run in production"
    gcloud run deploy ${SERVICE_NAME} \
        --project ${PROD_PROJECT_ID} \
        --image ${PROD_IMAGE} \
        --region ${REGION} \
        --platform managed

    print_status "Getting service URL"
    SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} \
        --project ${PROD_PROJECT_ID} \
        --region ${REGION} \
        --format='value(status.url)')

    echo -e "${GREEN}Deployment complete!${NC}"
    echo -e "${GREEN}Service URL: ${SERVICE_URL}${NC}"
else
    echo -e "${RED}Deployment cancelled${NC}"
    exit 1
fi
