#!/bin/bash

# ============================================================
# Digital Will API Test Flow
# Run this script to test the complete will creation flow
# ============================================================

# Configuration
BASE_URL="http://13.54.59.56:8000"
# Replace this with a valid token from your app
AUTH_TOKEN="eyJraWQiOiJkQnM0QUVYV3ByNWxuV2owTFYyWW03TlV4RDZvZ2c1dFBMdFBxbHRTazU4PSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI5OTBlMjQzOC0yMGYxLTcwOTQtZTljYi00YWZkODVkMDA2ZDYiLCJkZXZpY2Vfa2V5IjoiYXAtc291dGhlYXN0LTJfNzYzMTVjZmYtODM3OS00M2QxLTlkZjYtZmY3OTZjODFjZWIyIiwiaXNzIjoiaHR0cHM6XC9cL2NvZ25pdG8taWRwLmFwLXNvdXRoZWFzdC0yLmFtYXpvbmF3cy5jb21cL2FwLXNvdXRoZWFzdC0yX2FxczFObEtHRCIsImNsaWVudF9pZCI6IjY3cWtncTk5cGdra2pmbjVscDdoNTM0NnJwIiwib3JpZ2luX2p0aSI6IjQ0NTM2MzA0LWY4MWUtNGU2Yy04YjI0LWQzYjMwYzQyZGQ4YyIsImV2ZW50X2lkIjoiZDliMjE3NDAtM2IwMC00MDBlLTg1MGItNGEyYzg5ODY1ZjIyIiwidG9rZW5fdXNlIjoiYWNjZXNzIiwic2NvcGUiOiJhd3MuY29nbml0by5zaWduaW4udXNlci5hZG1pbiIsImF1dGhfdGltZSI6MTc2NTk0NzM1MiwiZXhwIjoxNzY2MDMzNzUyLCJpYXQiOjE3NjU5NDczNTIsImp0aSI6IjkxZTJlNDQ5LWMyNzUtNDkyMS05OTNhLWYxMGQxNWI4ZDNhMyIsInVzZXJuYW1lIjoiNTdlMjU3NmYtMjcwYS00ZjViLTg4MzYtNTVmYTU0YmRmMGMxIn0.cc_sUReZDko4fTKyIFjb-H2jFvmgTBTi5y9v8gfHDpOhKYcm2zGGAoa0x_39mzb52JrFrbKCNz7sP9lnam4RfOQ_yaDN54FcSUM8jcv6Xu98FdmLBEyT_3BWsKAuhkYOeWbmTTdW5klWAi6v9JEzKeMPARjDjv-GeVGKk_1C6L1mJsNO8miVtF6OLYF94FwYQRuxwSsvvhuVyTDOxZmqSx-A9gOHMPaloN633fry7OMGzXT00xEIJv-X4cUfLSQJotUNAOGuTPbadaUJ3cUJQdR-5EWLzXnkXOApJLpRtPiEiLC9Ri2I5uIyUuUHohFVNIoYrCGR_03jBAc-TA0uSQ"

# Common headers
HEADERS=(
  -H "Content-Type: application/json"
  -H "Accept: application/json"
  -H "Authorization: Bearer $AUTH_TOKEN"
)

echo "============================================================"
echo "Digital Will API Test Flow"
echo "Base URL: $BASE_URL"
echo "============================================================"
echo ""

# ============================================================
# STEP 1: Create Initial Will (Basic Details)
# Based on InitialWillRequest model from will_models.dart
# ============================================================
echo "📝 STEP 1: Creating Initial Will..."
echo "POST /will/initial"

INITIAL_WILL_RESPONSE=$(curl -s -X POST "$BASE_URL/will/initial" \
  "${HEADERS[@]}" \
  -d '{
    "has_capacity": true,
    "first_name": "John",
    "middle_name": "Michael",
    "last_name": "Doe",
    "dob": "1985-06-15",
    "address_line_1": "123 Test Street",
    "suburb": "Sydney",
    "postcode": "2000",
    "country": "Australia"
  }')

echo "Response: $INITIAL_WILL_RESPONSE"
echo ""

# Extract will_id from response (requires jq)
WILL_ID=$(echo $INITIAL_WILL_RESPONSE | jq -r '.data.will_id // empty')

if [ -z "$WILL_ID" ]; then
  echo "❌ Failed to create will. Check the response above."
  echo "If you need to use an existing will_id, set it below:"
  # Uncomment and set manually if needed:
  # WILL_ID="your-existing-will-id-here"
  exit 1
fi

echo "✅ Will created with ID: $WILL_ID"
echo ""

# ============================================================
# STEP 2: Get Initial Will (Verify creation)
# ============================================================
echo "📝 STEP 2: Getting Initial Will..."
echo "GET /will/initial?will_id=$WILL_ID"

curl -s -X GET "$BASE_URL/will/initial?will_id=$WILL_ID" \
  "${HEADERS[@]}" | jq .

echo ""

# ============================================================
# STEP 3: Create Family Initial (Relationship Status)
# Based on FamilyInitialRequest model from family_models.dart
# ============================================================
echo "📝 STEP 3: Creating Family Initial (Relationship Status)..."
echo "POST /will/family/initial"

curl -s -X POST "$BASE_URL/will/family/initial" \
  "${HEADERS[@]}" \
  -d "{
    \"will_id\": \"$WILL_ID\",
    \"relationship_status\": \"MARRIED\",
    \"has_previous_relationship\": true,
    \"can_include_former_partner\": true
  }" | jq .

echo ""

# ============================================================
# STEP 4: Get Family Initial (Verify creation)
# ============================================================
echo "📝 STEP 4: Getting Family Initial..."
echo "GET /will/family/initial?will_id=$WILL_ID"

curl -s -X GET "$BASE_URL/will/family/initial?will_id=$WILL_ID" \
  "${HEADERS[@]}" | jq .

echo ""

# ============================================================
# STEP 5: Add Former Partner
# Based on FormerPartnerRequest model - uses nested former_partner object
# ============================================================
echo "📝 STEP 5: Adding Former Partner..."
echo "POST /will/family/former-partner"

curl -s -X POST "$BASE_URL/will/family/former-partner" \
  "${HEADERS[@]}" \
  -d "{
    \"will_id\": \"$WILL_ID\",
    \"former_partner\": {
      \"first_name\": \"Jane\",
      \"middle_name\": \"Marie\",
      \"last_name\": \"Smith\",
      \"email\": \"jane.smith@example.com\",
      \"mobile\": \"+61412345678\"
    }
  }" | jq .

echo ""

# ============================================================
# STEP 6: Get Former Partners
# ============================================================
echo "📝 STEP 6: Getting Former Partners..."
echo "GET /will/family/former-partner?will_id=$WILL_ID"

curl -s -X GET "$BASE_URL/will/family/former-partner?will_id=$WILL_ID" \
  "${HEADERS[@]}" | jq .

echo ""

# ============================================================
# STEP 7: Add Dependent Person
# Based on DependentPersonRequest model - uses nested dependent object
# ============================================================
echo "📝 STEP 7: Adding Dependent Person..."
echo "POST /will/family/dependent/person"

curl -s -X POST "$BASE_URL/will/family/dependent/person" \
  "${HEADERS[@]}" \
  -d "{
    \"will_id\": \"$WILL_ID\",
    \"dependent\": {
      \"first_name\": \"Tommy\",
      \"middle_name\": \"James\",
      \"last_name\": \"Doe\",
      \"email\": \"tommy.doe@example.com\",
      \"mobile\": \"+61412345679\",
      \"relation\": \"SON\",
      \"is_minor\": true
    },
    \"guardian\": {
      \"first_name\": \"Sarah\",
      \"middle_name\": \"Ann\",
      \"last_name\": \"Johnson\",
      \"email\": \"sarah.johnson@example.com\",
      \"mobile\": \"+61412345680\"
    }
  }" | jq .

echo ""

# ============================================================
# STEP 8: Get Dependent Persons
# ============================================================
echo "📝 STEP 8: Getting Dependent Persons..."
echo "GET /will/family/dependent/person?will_id=$WILL_ID"

curl -s -X GET "$BASE_URL/will/family/dependent/person?will_id=$WILL_ID" \
  "${HEADERS[@]}" | jq .

echo ""

# ============================================================
# STEP 9: Add Pet
# Based on PetRequest model - uses nested caretaker object
# ============================================================
echo "📝 STEP 9: Adding Pet..."
echo "POST /will/family/dependent/pet"

curl -s -X POST "$BASE_URL/will/family/dependent/pet" \
  "${HEADERS[@]}" \
  -d "{
    \"will_id\": \"$WILL_ID\",
    \"animal_name\": \"Max\",
    \"animal_category\": \"DOG\",
    \"caretaker\": {
      \"first_name\": \"Robert\",
      \"middle_name\": \"Lee\",
      \"last_name\": \"Wilson\",
      \"email\": \"robert.wilson@example.com\",
      \"mobile\": \"+61412345681\",
      \"instruction\": \"Please take care of my pet.\"
    }
  }" | jq .

echo ""

# ============================================================
# STEP 10: Get Pets
# ============================================================
echo "📝 STEP 10: Getting Pets..."
echo "GET /will/family/dependent/pet?will_id=$WILL_ID"

curl -s -X GET "$BASE_URL/will/family/dependent/pet?will_id=$WILL_ID" \
  "${HEADERS[@]}" | jq .

echo ""

# ============================================================
# STEP 11: Add Beneficiary
# Based on BeneficiaryPersonRequest model - uses nested beneficiary object
# ============================================================
echo "📝 STEP 11: Adding Beneficiary..."
echo "POST /will/family/beneficiary/person"

BENEFICIARY_RESPONSE=$(curl -s -X POST "$BASE_URL/will/family/beneficiary/person" \
  "${HEADERS[@]}" \
  -d "{
    \"will_id\": \"$WILL_ID\",
    \"beneficiary\": {
      \"first_name\": \"Michael\",
      \"middle_name\": \"David\",
      \"last_name\": \"Brown\",
      \"email\": \"michael.brown@example.com\",
      \"mobile\": \"+61412345682\",
      \"relation\": \"NEPHEW\",
      \"is_minor\": false,
      \"dob\": \"1990-03-15\",
      \"include_reason\": \"He is my beloved nephew\"
    }
  }")

echo "$BENEFICIARY_RESPONSE" | jq .
BENEFICIARY_ID=$(echo $BENEFICIARY_RESPONSE | jq -r '.data.beneficiary_id // .data.id // empty')
echo "Beneficiary ID: $BENEFICIARY_ID"
echo ""

# ============================================================
# STEP 12: Get Beneficiaries
# ============================================================
echo "📝 STEP 12: Getting Beneficiaries..."
echo "GET /will/family/beneficiary/person?will_id=$WILL_ID"

curl -s -X GET "$BASE_URL/will/family/beneficiary/person?will_id=$WILL_ID" \
  "${HEADERS[@]}" | jq .

echo ""

# ============================================================
# STEP 13: Get Charities List
# ============================================================
echo "📝 STEP 13: Getting Charities List..."
echo "GET /will/charity"

curl -s -X GET "$BASE_URL/will/charity" \
  "${HEADERS[@]}" | jq .

echo ""

# ============================================================
# STEP 14: Add Beneficiary Charity
# Based on BeneficiaryCharityRequest - uses charity_ids array
# ============================================================
echo "📝 STEP 14: Adding Beneficiary Charity..."
echo "POST /will/family/beneficiary/charity"

curl -s -X POST "$BASE_URL/will/family/beneficiary/charity" \
  "${HEADERS[@]}" \
  -d "{
    \"will_id\": \"$WILL_ID\",
    \"charity_ids\": [\"1\", \"2\"]
  }" | jq .

echo ""

# ============================================================
# STEP 15: Get Beneficiary Charities
# ============================================================
echo "📝 STEP 15: Getting Beneficiary Charities..."
echo "GET /will/family/beneficiary/charity?will_id=$WILL_ID"

curl -s -X GET "$BASE_URL/will/family/beneficiary/charity?will_id=$WILL_ID" \
  "${HEADERS[@]}" | jq .

echo ""

# ============================================================
# STEP 16: Add Asset
# Based on WillAssetCreate schema - includes asset_type, institution, description
# ============================================================
echo "📝 STEP 16: Adding Asset..."
echo "POST /will/asset"

ASSET_RESPONSE=$(curl -s -X POST "$BASE_URL/will/asset" \
  "${HEADERS[@]}" \
  -d "{
    \"will_id\": \"$WILL_ID\",
    \"asset_type\": \"PROPERTY\",
    \"institution\": \"CBA\",
    \"description\": \"Family home at 123 Main Street, Sydney NSW 2000\"
  }")

echo "$ASSET_RESPONSE" | jq .
ASSET_ID=$(echo $ASSET_RESPONSE | jq -r '.data.asset_id // .data.id // empty')
echo "Asset ID: $ASSET_ID"
echo ""

# ============================================================
# STEP 17: Add Another Asset (Financial)
# ============================================================
echo "📝 STEP 17: Adding Another Asset (Financial)..."
echo "POST /will/asset"

curl -s -X POST "$BASE_URL/will/asset" \
  "${HEADERS[@]}" \
  -d "{
    \"will_id\": \"$WILL_ID\",
    \"asset_type\": \"FINANCIAL\",
    \"institution\": \"AustralianSuper\",
    \"description\": \"Superannuation account with AustralianSuper, approximately $250,000\"
  }" | jq .

echo ""

# ============================================================
# STEP 18: Get All Assets
# ============================================================
echo "📝 STEP 18: Getting All Assets..."
echo "GET /will/asset?will_id=$WILL_ID"

curl -s -X GET "$BASE_URL/will/asset?will_id=$WILL_ID" \
  "${HEADERS[@]}" | jq .

echo ""

# ============================================================
# STEP 19: Create Gift (Initial Question - Yes)
# Based on WillGiftCreate schema - includes leave_gift boolean
# ============================================================
echo "📝 STEP 19: Creating Gift (Answer: Yes)..."
echo "POST /will/gift"

GIFT_RESPONSE=$(curl -s -X POST "$BASE_URL/will/gift" \
  "${HEADERS[@]}" \
  -d "{
    \"will_id\": \"$WILL_ID\",
    \"leave_gift\": true,
    \"gift_type\": \"SPECIFIC_ITEM\"
  }")

echo "$GIFT_RESPONSE" | jq .
GIFT_ID=$(echo $GIFT_RESPONSE | jq -r '.data.gift_id // .data.id // empty')
echo "Gift ID: $GIFT_ID"
echo ""

# ============================================================
# STEP 20: Get Gift
# ============================================================
echo "📝 STEP 20: Getting Gift..."
echo "GET /will/gift?will_id=$WILL_ID"

curl -s -X GET "$BASE_URL/will/gift?will_id=$WILL_ID" \
  "${HEADERS[@]}" | jq .

echo ""

# ============================================================
# STEP 21: Add Gift Beneficiary
# Based on GiftReceiverCreate schema - uses nested gift_receiver object
# ============================================================
echo "📝 STEP 21: Adding Gift Beneficiary..."
echo "POST /will/gift/beneficiary"

GIFT_BENEFICIARY_RESPONSE=$(curl -s -X POST "$BASE_URL/will/gift/beneficiary" \
  "${HEADERS[@]}" \
  -d "{
    \"will_id\": \"$WILL_ID\",
    \"gift_receiver\": {
      \"first_name\": \"Emma\",
      \"middle_name\": \"Louise\",
      \"last_name\": \"Johnson\",
      \"email\": \"emma.johnson@example.com\",
      \"mobile\": \"+61412345683\",
      \"relation\": \"NIECE\",
      \"is_minor\": false,
      \"dob\": \"1995-08-20\"
    }
  }")

echo "$GIFT_BENEFICIARY_RESPONSE" | jq .
GIFT_BENEFICIARY_ID=$(echo $GIFT_BENEFICIARY_RESPONSE | jq -r '.data.gift_beneficiary_id // .data.id // empty')
echo "Gift Beneficiary ID: $GIFT_BENEFICIARY_ID"
echo ""

# ============================================================
# STEP 22: Get Gift Beneficiaries
# ============================================================
echo "📝 STEP 22: Getting Gift Beneficiaries..."
echo "GET /will/gift/beneficiary?will_id=$WILL_ID"

curl -s -X GET "$BASE_URL/will/gift/beneficiary?will_id=$WILL_ID" \
  "${HEADERS[@]}" | jq .

echo ""

# ============================================================
# STEP 23: Get All Wills
# ============================================================
echo "📝 STEP 23: Getting All Wills..."
# ============================================================
# STEP 23: Get All Wills
# ============================================================
echo "📝 STEP 23: Getting All Wills..."
echo "GET /will/all"

curl -s -X GET "$BASE_URL/will/all" \
  "${HEADERS[@]}" | jq .

echo ""

# ============================================================
# SUMMARY
# ============================================================
echo "============================================================"
echo "✅ API Test Flow Complete!"
echo "Will ID used: $WILL_ID"
echo ""
echo "📊 Summary of Created Items:"
echo "  - Will ID: $WILL_ID"
echo "  - Beneficiary ID: $BENEFICIARY_ID"
echo "  - Asset ID: $ASSET_ID"
echo "  - Gift ID: $GIFT_ID"
echo "  - Gift Beneficiary ID: $GIFT_BENEFICIARY_ID"
echo "============================================================"
echo ""
echo "To run individual requests, copy the curl commands above."
echo "Remember to replace AUTH_TOKEN with a valid token from the app."
