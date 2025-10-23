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
console.log('🔧 Plaid Configuration:');
console.log('   Environment:', plaidEnv);
console.log('   Base Path:', plaidEnv === 'production' ? 'PRODUCTION' : 'SANDBOX');
console.log('   Client ID:', process.env.PLAID_CLIENT_ID ? process.env.PLAID_CLIENT_ID.substring(0, 8) + '...' : 'NOT SET');
console.log('   Secret:', process.env.PLAID_SECRET ? '***' + process.env.PLAID_SECRET.substring(process.env.PLAID_SECRET.length - 4) : 'NOT SET');

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
      access_token: accessToken,
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
    const { userId, institutionId, start_date, end_date } = req.body;
    console.log('📥 Transaction request:', { userId, institutionId, start_date, end_date });

    // Fetch access token from database
    const { PrismaClient } = require('@prisma/client');
    const prisma = new PrismaClient();

    const user = await prisma.user.findUnique({
      where: { userId },
      include: { banks: true }
    });

    console.log('👤 User found:', user ? `Yes (${user.banks.length} banks)` : 'No');

    if (!user || user.banks.length === 0) {
      console.log('❌ No banks connected for user:', userId);
      return res.status(400).json({ error: 'No banks connected. Please link your bank account first.' });
    }

    // If institutionId specified, use that bank's token; otherwise use first bank
    const bank = institutionId
      ? user.banks.find(b => b.institutionId === institutionId)
      : user.banks[0];

    if (!bank) {
      console.log('❌ Bank not found:', institutionId);
      return res.status(400).json({ error: 'Bank not found.' });
    }

    console.log('🏦 Using bank:', bank.institutionName, '(ID:', bank.institutionId + ')');

    const request = {
      access_token: bank.accessToken,
      start_date: start_date || new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
      end_date: end_date || new Date().toISOString().split('T')[0],
    };

    console.log('📅 Date range:', request.start_date, 'to', request.end_date);
    console.log('🔑 Calling Plaid API with access token:', bank.accessToken.substring(0, 15) + '...');

    const response = await plaidClient.transactionsGet(request);

    console.log('✅ Plaid response:', response.data.total_transactions, 'total transactions');
    console.log('📊 Transactions:', response.data.transactions.length, 'returned');

    if (response.data.transactions.length > 0) {
      console.log('💰 Sample transaction:', {
        name: response.data.transactions[0].name,
        amount: response.data.transactions[0].amount,
        date: response.data.transactions[0].date
      });
    }

    res.json({
      transactions: response.data.transactions,
      total_transactions: response.data.total_transactions,
    });

    await prisma.$disconnect();
  } catch (error) {
    console.error('❌ Error fetching transactions:', error);
    console.error('Error name:', error.name);
    console.error('Error message:', error.message);
    console.error('Error stack:', error.stack);
    if (error.response) {
      console.error('Plaid API error response:', JSON.stringify(error.response.data, null, 2));
    }

    res.status(500).json({
      error: 'Failed to fetch transactions',
      errorName: error.name,
      message: error.message,
      plaidError: error.response?.data,
      stack: process.env.NODE_ENV === 'production' ? undefined : error.stack
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
