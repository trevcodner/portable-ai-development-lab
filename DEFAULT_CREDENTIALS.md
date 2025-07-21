# Default Test Credentials

For convenience, all services in the Portable AI Development Lab use the same default test credentials.

## Universal Login
- **Username**: `testuser`
- **Password**: `testpass123`
- **Email**: `test@example.com` (where required)

## Service Access

### N8N Automation (http://localhost:5678)
- **Username**: testuser
- **Password**: testpass123
- **Access**: Full workflow creation and management

### Open WebUI (http://localhost:3000)
- **First Visit**: Create account with any credentials
- **Suggested**: Use the same testuser/testpass123 for consistency
- **Access**: Full AI model interaction

## Security Notes

⚠️ **Important**: These are default test credentials for local development only.

### For Production Use:
1. **Change all default passwords immediately**
2. **Use strong, unique passwords**
3. **Enable proper authentication**
4. **Consider VPN access for remote use**

### Local Lab Security:
- Services only accessible from localhost by default
- No external network exposure
- AI processing stays on your machine
- No data sent to external services

## Changing Credentials

### N8N:
1. Open http://localhost:5678
2. Go to Settings → Users
3. Change password for testuser or create new admin

### Open WebUI:
1. Open http://localhost:3000
2. Click profile/settings
3. Update password or create new admin account

---
**Default Setup**: testuser / testpass123
**Security**: Change for production use
**Scope**: Local development environment only
