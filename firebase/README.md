# Firebase Deployment Scripts

This folder contains scripts for building and deploying the Flutter web app to Firebase Hosting.

## Quick Start

### 1. Install Firebase CLI

```powershell
npm install -g firebase-tools
```

### 2. Login to Firebase

```powershell
firebase login
```

### 3. Build and Deploy

```powershell
.\firebase\build-and-deploy.ps1
```

## Scripts

### build-and-deploy.ps1
Complete build and deployment pipeline:
1. Cleans previous builds
2. Gets dependencies
3. Builds web app (release, cloud mode)
4. Deploys to Firebase Hosting

**Usage:**
```powershell
.\firebase\build-and-deploy.ps1
```

### build-web.ps1
Just builds the web app without deploying:
- Good for testing builds locally
- Useful for inspecting build output
- Shows build size statistics

**Usage:**
```powershell
.\firebase\build-web.ps1
```

## Configuration Files (Root Level)

These must stay at project root:

- **firebase.json** - Firebase Hosting configuration
- **.firebaserc** - Project ID configuration

## Deployment URLs

After deployment, your app is available at:
- https://aksharaintelligence-41f4a.web.app
- https://aksharaintelligence-41f4a.firebaseapp.com

## Detailed Documentation

See [DEPLOYMENT.md](../DEPLOYMENT.md) for complete documentation including:
- Manual build commands
- Build configurations
- Testing locally
- Troubleshooting
- CI/CD setup
