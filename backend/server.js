const express = require('express');
const cors = require('cors');
const { Configuration, PlaidApi, PlaidEnvironments } = require('plaid');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Import routes
const banksRouter = require('./routes/banks');

// Plaid client configuration
const plaidEnv = process.env.PLAID_ENV || 'sandbox';
const configuration = new Configuration({
  basePath: plaidEnv === 'production' ? PlaidEnvironments.production : PlaidEnvironments.sandbox,
  baseOptions: {
    headers: {
      'PLAID-CLIENT-ID': process.env.PLAID_CLIENT_ID || '68f2cbfc7c634d00204cb232',
      'PLAID-SECRET': process.env.PLAID_SECRET || 'df8aa2b45882f657705cbdd554a839',
    },
  },
});

const plaidClient = new PlaidApi(configuration);

// Store access tokens (in production, use a database)
let accessTokens = {};

// Health check endpoint
app.get('/', (req, res) => {
  res.json({ message: 'Plaid Backend Server Running', status: 'OK' });
});

// Bank sync routes
app.use('/api', banksRouter);

// Create link token
app.post('/api/plaid/create_link_token', async (req, res) => {
  try {
    const userId = req.body.userId || `user-${Date.now()}`;

    const request = {
      user: {
        client_user_id: userId,
      },
      client_name: 'Swipe Finance',
      products: ['transactions'],
      country_codes: ['US'],
      language: 'en',
    };

    const response = await plaidClient.linkTokenCreate(request);
    res.json({ link_token: response.data.link_token });
  } catch (error) {
    console.error('Error creating link token:', error);
    res.status(500).json({
      error: 'Failed to create link token',
      details: error.response?.data || error.message
    });
  }
});

// Exchange public token for access token
app.post('/api/plaid/exchange_token', async (req, res) => {
  try {
    const { public_token, userId } = req.body;

    const response = await plaidClient.itemPublicTokenExchange({
      public_token,
    });

    const accessToken = response.data.access_token;
    const itemId = response.data.item_id;

    // Store access token (in production, use a database)
    accessTokens[userId] = accessToken;

    res.json({
      success: true,
      item_id: itemId,
    });
  } catch (error) {
    console.error('Error exchanging token:', error);
    res.status(500).json({
      error: 'Failed to exchange token',
      details: error.response?.data || error.message
    });
  }
});

// Get transactions
app.post('/api/plaid/transactions', async (req, res) => {
  try {
    const { userId, start_date, end_date } = req.body;
    const accessToken = accessTokens[userId];

    if (!accessToken) {
      return res.status(400).json({ error: 'No access token found. Please link your bank account first.' });
    }

    const request = {
      access_token: accessToken,
      start_date: start_date || new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
      end_date: end_date || new Date().toISOString().split('T')[0],
    };

    const response = await plaidClient.transactionsGet(request);

    res.json({
      transactions: response.data.transactions,
      total_transactions: response.data.total_transactions,
    });
  } catch (error) {
    console.error('Error fetching transactions:', error);
    res.status(500).json({
      error: 'Failed to fetch transactions',
      details: error.response?.data || error.message
    });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`=� Plaid Backend Server running on http://localhost:${PORT}`);
  console.log(`=� Environment: ${process.env.PLAID_ENV || 'sandbox'}`);
  console.log(`\nAvailable endpoints:`);
  console.log(`  GET  /                              - Health check`);
  console.log(`  POST /api/plaid/create_link_token   - Create Plaid Link token`);
  console.log(`  POST /api/plaid/exchange_token      - Exchange public token`);
  console.log(`  POST /api/plaid/transactions        - Get transactions`);
});
