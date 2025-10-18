# Swipe Finance Backend Server

Simple Express.js backend to handle Plaid API calls securely.

## Setup

1. **Install dependencies**:
   ```bash
   npm install
   ```

2. **Configure environment variables**:
   - The `.env` file is already configured with your Plaid sandbox credentials
   - No changes needed for testing

3. **Start the server**:
   ```bash
   npm start
   ```

   The server will run on `http://localhost:3000`

## API Endpoints

### Health Check
```
GET /
```
Returns server status

### Create Link Token
```
POST /api/plaid/create_link_token
Body: { "userId": "user-123" }
```
Creates a Plaid Link token for the frontend

### Exchange Public Token
```
POST /api/plaid/exchange_token
Body: {
  "public_token": "public-sandbox-xxx",
  "userId": "user-123"
}
```
Exchanges public token for access token

### Get Transactions
```
POST /api/plaid/transactions
Body: {
  "userId": "user-123",
  "start_date": "2024-01-01",
  "end_date": "2024-12-31"
}
```
Fetches transactions from Plaid

## Testing

1. Start the server: `npm start`
2. Visit `http://localhost:3000` to check if it's running
3. The Flutter app will automatically connect to this backend

## Environment Variables

- `PLAID_CLIENT_ID`: Your Plaid client ID (already set)
- `PLAID_SECRET`: Your Plaid secret (already set)
- `PLAID_ENV`: Environment (sandbox/development/production)
- `PORT`: Server port (default: 3000)

## Security Notes

  **Important**:
- Never commit the `.env` file to Git (add it to `.gitignore`)
- Never expose Plaid secrets in client-side code
- For production, use environment variables on your hosting platform
- Implement proper authentication and authorization
