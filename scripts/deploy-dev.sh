
#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
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

# Get the dev project ID, service name, and location
cd infra/environments/dev
DEV_PROJECT_ID=$(terraform output -raw project_id)
SERVICE_NAME=$(terraform output -raw service_name)
REGION=$(terraform output -raw location)
cd ../../..

print_status "Configuring Docker authentication"
gcloud auth configure-docker ${REGION}-docker.pkg.dev

print_status "Building Docker image"
docker build --platform linux/amd64 -t ${REGION}-docker.pkg.dev/${ARTIFACTS_PROJECT_ID}/docker/${SERVICE_NAME}:dev .

print_status "Pushing Docker image"
docker push ${REGION}-docker.pkg.dev/${ARTIFACTS_PROJECT_ID}/docker/${SERVICE_NAME}:dev

print_status "Deploying to Cloud Run"
gcloud run deploy ${SERVICE_NAME} \
    --project ${DEV_PROJECT_ID} \
    --image ${REGION}-docker.pkg.dev/${ARTIFACTS_PROJECT_ID}/docker/${SERVICE_NAME}:dev \
    --region ${REGION} \
    --platform managed

print_status "Getting service URL"
SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} \
    --project ${DEV_PROJECT_ID} \
    --region ${REGION} \
    --format='value(status.url)')

echo -e "${GREEN}Deployment complete!${NC}"
echo -e "${GREEN}Service URL: ${SERVICE_URL}${NC}"
