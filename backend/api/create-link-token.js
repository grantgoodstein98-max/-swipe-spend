const { Configuration, PlaidApi, PlaidEnvironments, Products, CountryCode } = require('plaid');

module.exports = async (req, res) => {
  // Enable CORS - must be set before any response
  res.setHeader('Access-Control-Allow-Credentials', 'true');
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader('Access-Control-Allow-Headers', 'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version');

  // Handle OPTIONS preflight request
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    // Debug: Log environment variables
    console.log('PLAID_CLIENT_ID exists:', !!process.env.PLAID_CLIENT_ID);
    console.log('PLAID_SECRET exists:', !!process.env.PLAID_SECRET);
    console.log('PLAID_CLIENT_ID value:', process.env.PLAID_CLIENT_ID?.substring(0, 8) + '...');

    if (!process.env.PLAID_CLIENT_ID || !process.env.PLAID_SECRET) {
      throw new Error('Missing Plaid credentials in environment variables');
    }

    // Correct configuration for Plaid SDK v39
    const configuration = new Configuration({
      basePath: PlaidEnvironments.sandbox,
      baseOptions: {
        headers: {
          'PLAID-CLIENT-ID': process.env.PLAID_CLIENT_ID,
          'PLAID-SECRET': process.env.PLAID_SECRET,
        },
      },
    });

    const client = new PlaidApi(configuration);
    const userId = req.body.userId || `user-${Date.now()}`;

    // Create link token request
    const request = {
      user: {
        client_user_id: userId,
      },
      client_name: 'Swipe Finance',
      products: [Products.Transactions],
      country_codes: [CountryCode.Us],
      language: 'en',
    };

    console.log('Creating link token with request:', JSON.stringify(request, null, 2));

    const response = await client.linkTokenCreate(request);

    console.log('Link token created successfully');

    res.status(200).json({ link_token: response.data.link_token });
  } catch (error) {
    console.error('Error creating link token:', error);
    console.error('Error response:', error.response?.data);
    console.error('Error message:', error.message);

    res.status(500).json({
      error: 'Failed to create link token',
      details: error.response?.data || error.message
    });
  }
};
