# Building in Xcode - Scheme Guide

## Available Xcode Schemes

Your Xcode workspace now has separate schemes for each flavor:

### 1. **Runner** (Production)
- Bundle ID: `com.techinorm.metafter`
- Display Name: "Metafter"
- Configurations:
  - Debug → Production
  - Release → Production  
  - Profile → Production

### 2. **Runner-DEV** (Development)
- Bundle ID: `com.techinorm.metafter.dev`
- Display Name: "Metafter DEV"
- Configurations:
  - Debug-dev
  - Release-dev

### 3. **Runner-UAT** (UAT)
- Bundle ID: `com.techinorm.metafter.uat`
- Display Name: "Metafter UAT"
- Configurations:
  - Debug-uat
  - Release-uat

## How to Build in Xcode

### Step 1: Select the Scheme
1. Open `ios/Runner.xcworkspace` in Xcode
2. At the top toolbar, click on the scheme selector (it shows the current scheme name)
3. Choose the flavor you want:
   - **Runner** for Production
   - **Runner-DEV** for DEV
   - **Runner-UAT** for UAT

### Step 2: Archive and Export

#### For Development/Testing (Ad-hoc Distribution)
1. Select your scheme (e.g., Runner-DEV or Runner-UAT)
2. Menu: **Product → Archive**
3. When archive completes, the Organizer window opens
4. Select your archive
5. Click **Distribute App**
6. Choose **Development**
7. Follow prompts to export

#### For TestFlight/App Store
1. Select your scheme (e.g., Runner-DEV or Runner-UAT)
2. Menu: **Product → Archive**
3. When archive completes, the Organizer window opens
4. Select your archive
5. Click **Distribute App**
6. Choose **App Store Connect**
7. Choose **Upload** (to upload directly) or **Export** (to save IPA for later upload)
8. Follow prompts

## Verifying the Scheme Configuration

Before archiving, you can verify the bundle ID:

1. Select your scheme (e.g., Runner-UAT)
2. Menu: **Product → Scheme → Edit Scheme**
3. Select **Archive** on the left
4. Check **Build Configuration** (should be Release-dev or Release-uat)
5. Close the scheme editor
6. Menu: **Product → Build**
7. Check the build log - you should see bundle identifier in the output

## Troubleshooting

### Issue: Archive shows wrong bundle ID
**Solution**: Make sure you selected the correct scheme (Runner-DEV or Runner-UAT), not just "Runner"

### Issue: Xcode doesn't show the new schemes
**Solution**: 
1. Close Xcode completely
2. Delete derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*`
3. Reopen `ios/Runner.xcworkspace` in Xcode
4. Check scheme selector again

### Issue: Build fails with "Bundle identifier missing"
**Solution**:
1. Close Xcode
2. Run: `cd ios && ./restore-flavor-configs.sh`
3. Reopen workspace in Xcode

### Issue: Xcode shows old bundle ID even with correct scheme
**Solution**:
1. Clean build folder: **Product → Clean Build Folder** (Shift+Cmd+K)
2. Quit Xcode
3. Delete derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*`
4. Reopen workspace
5. Try archive again

## Scheme Configuration Details

Each scheme is configured to use the appropriate build configuration:

| Scheme | Debug Config | Release Config (Archive) |
|--------|-------------|-------------------------|
| Runner | Debug | Release |
| Runner-DEV | Debug-dev | Release-dev |
| Runner-UAT | Debug-uat | Release-uat |

This ensures that when you archive with **Runner-DEV**, it automatically uses the **Release-dev** configuration with the DEV bundle ID.

## Best Practice

For consistency and to avoid confusion:
- Use **Runner-DEV** scheme when building DEV flavor
- Use **Runner-UAT** scheme when building UAT flavor
- Use **Runner** scheme when building Production flavor

The scheme name tells you exactly which flavor you're building.

## Alternative: Use Build Scripts

If you prefer command-line builds over Xcode GUI, use the build scripts:

```bash
# DEV
./build-dev-testflight.sh

# UAT
./build-uat-testflight.sh

# Production
./build-appstore.sh
```

These scripts handle all the configuration automatically.
