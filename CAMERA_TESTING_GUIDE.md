# Camera Testing Guide for AccountabiliBuddies Web

## Prerequisites for Camera Access on Web

Camera access in web browsers requires specific conditions to be met for security reasons:

1. **Secure Context Required**: The page must be served over:
   - HTTPS (e.g., `https://yourdomain.com`)
   - localhost (e.g., `http://localhost:port`)
   - 127.0.0.1 (e.g., `http://127.0.0.1:port`)

2. **Browser Permissions**: The user must grant camera permissions when prompted

## Testing Steps

### 1. Test Camera Permissions First

Before testing in the Flutter app, verify your browser can access the camera:

```bash
# Open the camera test page in your browser
open web/camera_test.html
```

Or navigate to: `http://localhost:YOUR_PORT/camera_test.html`

This test page will:
- Check if you're in a secure context
- Test camera permission requests
- Show debug information
- Allow you to start/stop camera and take photos

### 2. Run Flutter Web with HTTPS (Recommended)

For production-like testing with HTTPS:

```bash
# Install mkcert (if not already installed)
brew install mkcert

# Create local certificates
mkcert -install
mkcert localhost 127.0.0.1

# Run Flutter web with certificates
flutter run -d chrome --web-port=8080 --web-hostname=localhost \
  --web-browser-flag="--allow-insecure-localhost" \
  --web-browser-flag="--disable-web-security"
```

### 3. Run Flutter Web on Localhost (Simpler)

For development testing:

```bash
# Run on localhost (camera will work)
flutter run -d chrome --web-port=8080 --web-hostname=localhost

# Or with hot reload
flutter run -d chrome --web-port=8080 --web-hostname=localhost --hot
```

### 4. Common Issues and Solutions

#### Issue: Camera not working in Chrome
**Solution**: Ensure you're accessing via `localhost` or `https://`, not `http://your-ip-address`

#### Issue: Permission denied
**Solution**: 
1. Click the camera icon in the browser's address bar
2. Select "Always allow" for camera permissions
3. Reload the page

#### Issue: Camera already in use
**Solution**: Close other applications using the camera (Zoom, Skype, etc.)

## Implementation Details

The updated `ProofCaptureSheet` now includes:

1. **Protocol Detection**: Warns users if not on HTTPS/localhost
2. **Better Error Messages**: Specific messages for common camera issues
3. **Fallback Options**: Suggests using gallery if camera fails
4. **Web-Specific UI**: Shows helpful hints for web users

## Browser Compatibility

| Browser | Camera Support | Notes |
|---------|---------------|-------|
| Chrome | ✅ Excellent | Recommended for testing |
| Firefox | ✅ Good | May need to allow permissions |
| Safari | ✅ Good | Requires macOS 11+ or iOS 14.3+ |
| Edge | ✅ Good | Based on Chromium |

## Production Deployment

For production, ensure your web app is served over HTTPS. Camera access will not work on HTTP (except localhost).

## Testing Checklist

- [ ] Run `camera_test.html` to verify browser camera access
- [ ] Start Flutter web on localhost
- [ ] Test "Take Photo" button in ProofCaptureSheet
- [ ] Test "Choose from Gallery" option
- [ ] Verify error messages appear correctly
- [ ] Test on different browsers
- [ ] Test with camera already in use (should show error)
- [ ] Test denying camera permission (should show error with fallback option)

## Code Changes Summary

1. **Enhanced Error Handling**: Added specific error messages for common camera issues
2. **Protocol Detection**: Warns about HTTPS requirement
3. **Web-Specific UI**: Added helpful hints for web users
4. **Fallback Options**: Automatically suggests gallery if camera fails
5. **Better Permissions**: Added meta tags in `index.html` for camera permissions

## Next Steps

After verifying camera works:
1. Test the full proof submission flow
2. Verify images upload correctly to Firebase Storage
3. Test on mobile web browsers
4. Consider adding image compression for web