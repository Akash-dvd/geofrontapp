# Custom Domain Setup - aksharaintelligence.com

## Overview

Map your Hostinger domain `aksharaintelligence.com` to your Firebase Hosting app.

## Step 1: Add Custom Domain in Firebase Console

1. Go to Firebase Console: https://console.firebase.google.com/
2. Select your project: **aksharaintelligence-41f4a**
3. Click **Hosting** in the left sidebar
4. Click **Add custom domain** button
5. Enter your domain: `aksharaintelligence.com`
6. Click **Continue**

Firebase will provide you with DNS records to add.

## Step 2: Get DNS Records from Firebase

After adding the domain, Firebase will show you DNS records like:

### For Root Domain (aksharaintelligence.com):
```
Type: A
Name: @
Value: 151.101.1.195
Value: 151.101.65.195
```

### For www Subdomain (www.aksharaintelligence.com):
```
Type: CNAME
Name: www
Value: aksharaintelligence-41f4a.web.app
```

**Note:** The actual IP addresses may be different. Use the ones Firebase provides.

## Step 3: Configure DNS in Hostinger

### Option A: Using Hostinger Control Panel (hPanel)

1. **Login to Hostinger:**
   - Go to https://hpanel.hostinger.com/
   - Login with your credentials

2. **Navigate to DNS Zone:**
   - Click on your domain: `aksharaintelligence.com`
   - Click **DNS Zone** or **DNS Records**

3. **Add A Records for Root Domain:**
   - Click **Add Record** or **+**
   - Type: `A`
   - Name: `@` (or leave empty for root)
   - Value: `151.101.1.195` (use IP from Firebase)
   - TTL: `14400` (or default)
   - Click **Add** or **Save**
   
   - Repeat for second A record:
   - Type: `A`
   - Name: `@`
   - Value: `151.101.65.195` (use second IP from Firebase)
   - Click **Add** or **Save**

4. **Add CNAME Record for www:**
   - Click **Add Record**
   - Type: `CNAME`
   - Name: `www`
   - Value: `aksharaintelligence-41f4a.web.app`
   - TTL: `14400`
   - Click **Add** or **Save**

5. **Remove Conflicting Records (if any):**
   - Delete any existing A records pointing to old servers
   - Delete any existing CNAME records for `@` or `www`

### Option B: Using Firebase CLI (Quick Method)

```powershell
# This will guide you through the process
firebase hosting:channel:deploy live
```

## Step 4: Verify Domain in Firebase

1. Go back to Firebase Console → Hosting
2. Your domain should show "Pending" status
3. Click **Verify** or wait for automatic verification
4. Firebase will check if DNS records are correct

**Verification can take:**
- Minimum: 5-10 minutes
- Maximum: 24-48 hours (due to DNS propagation)

## Step 5: SSL Certificate (Automatic)

Firebase automatically provisions a free SSL certificate once domain is verified.

- Status will change from "Pending" → "Connected"
- SSL certificate will be issued automatically
- Your site will be available at: https://aksharaintelligence.com

## DNS Record Summary

Add these records in Hostinger DNS:

| Type  | Name | Value/Target                          | TTL   |
|-------|------|---------------------------------------|-------|
| A     | @    | 151.101.1.195 (from Firebase)        | 14400 |
| A     | @    | 151.101.65.195 (from Firebase)       | 14400 |
| CNAME | www  | aksharaintelligence-41f4a.web.app    | 14400 |

## Troubleshooting

### Domain Shows "Pending" Status

**Check DNS propagation:**
```powershell
# Check A records
nslookup aksharaintelligence.com

# Check CNAME
nslookup www.aksharaintelligence.com
```

**Or use online tools:**
- https://dnschecker.org/
- https://mxtoolbox.com/SuperTool.aspx

### "Domain ownership could not be verified"

1. Make sure A records point to correct IPs
2. Wait 10-15 minutes for DNS to propagate
3. Click "Verify" again in Firebase Console

### Old Content Still Showing

- Clear browser cache (Ctrl+Shift+Delete)
- Try incognito/private mode
- Wait for DNS propagation (up to 48 hours)

### SSL Certificate Not Issued

- Wait up to 24 hours after verification
- Check domain status in Firebase Console
- Ensure no conflicting DNS records exist

## Verification Timeline

| Time      | Status                                    |
|-----------|-------------------------------------------|
| 0 min     | DNS records added in Hostinger           |
| 5-10 min  | DNS propagation begins                   |
| 15-30 min | Firebase can verify domain               |
| 1-2 hours | SSL certificate provisioned              |
| 24-48 hrs | Full global DNS propagation complete     |

## Testing Your Domain

### Check DNS:
```powershell
# Should return Firebase IPs
nslookup aksharaintelligence.com

# Should return Firebase CNAME
nslookup www.aksharaintelligence.com
```

### Test Website:
```powershell
# Once DNS propagates, test these URLs:
# http://aksharaintelligence.com
# https://aksharaintelligence.com
# http://www.aksharaintelligence.com
# https://www.aksharaintelligence.com
```

All should redirect to HTTPS and show your Flutter app.

## Post-Setup Configuration

### Redirect www to root (or vice versa):

Firebase automatically handles redirects. Configure in Firebase Console:
- Hosting → Domain settings → Redirects

### Force HTTPS:

Firebase automatically redirects HTTP to HTTPS.

## Alternative: Subdomain Only

If you want to keep root domain elsewhere and only use subdomain:

**Add only CNAME record:**
```
Type: CNAME
Name: app
Value: aksharaintelligence-41f4a.web.app
```

Then access via: `https://app.aksharaintelligence.com`

## Quick Reference - Hostinger DNS Settings

**Login:** https://hpanel.hostinger.com/

**DNS Zone Path:**
Hostinger → Domains → aksharaintelligence.com → DNS Zone

**Records to Add:**
1. A record: @ → 151.101.1.195
2. A record: @ → 151.101.65.195
3. CNAME: www → aksharaintelligence-41f4a.web.app

**Save changes and wait 10-30 minutes.**

## Firebase Console Link

Direct link to add domain:
https://console.firebase.google.com/project/aksharaintelligence-41f4a/hosting/main

## Support

- Firebase Hosting Docs: https://firebase.google.com/docs/hosting/custom-domain
- Hostinger DNS Guide: https://support.hostinger.com/en/articles/1583227-how-to-manage-dns-records
- DNS Checker: https://dnschecker.org/

## After Domain is Connected

Your Flutter app will be available at:
- ✅ https://aksharaintelligence.com
- ✅ https://www.aksharaintelligence.com
- ✅ https://aksharaintelligence-41f4a.web.app (still works)
- ✅ https://aksharaintelligence-41f4a.firebaseapp.com (still works)
