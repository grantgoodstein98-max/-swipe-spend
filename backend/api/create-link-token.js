const { Configuration, PlaidApi, PlaidEnvironments } = require('plaid');

module.exports = async (req, res) => {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader('Access-Control-Allow-Headers', 'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version');

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    // Debug: Log environment variables (remove in production)
    console.log('PLAID_CLIENT_ID exists:', !!process.env.PLAID_CLIENT_ID);
    console.log('PLAID_SECRET exists:', !!process.env.PLAID_SECRET);

    if (!process.env.PLAID_CLIENT_ID || !process.env.PLAID_SECRET) {
      throw new Error('Missing Plaid credentials in environment variables');
    }

    const configuration = new Configuration({
      basePath: PlaidEnvironments.sandbox,
      baseOptions: {
        headers: {
          'PLAID-CLIENT-ID': process.env.PLAID_CLIENT_ID,
          'PLAID-SECRET': process.env.PLAID_SECRET,
        },
      },
    });

    const plaidClient = new PlaidApi(configuration);
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
    res.status(200).json({ link_token: response.data.link_token });
  } catch (error) {
    console.error('Error creating link token:', error);
    console.error('Error details:', error.response?.data);
    res.status(500).json({
      error: 'Failed to create link token',
      details: error.response?.data || error.message
    });
  }
};
