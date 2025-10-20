// Helper JavaScript file to load and expose Plaid SDK
// This ensures Plaid is available in the global scope for Flutter to access

(function() {
  'use strict';

  console.log('🔧 Plaid loader script starting...');

  // Function to check if Plaid is loaded
  function checkPlaidLoaded() {
    if (window.Plaid) {
      console.log('✅ Plaid SDK is available');
      window.plaidReady = true;
      return true;
    } else {
      console.log('⏳ Waiting for Plaid SDK...');
      window.plaidReady = false;
      return false;
    }
  }

  // Check immediately
  checkPlaidLoaded();

  // Also check after a delay in case it loads later
  setTimeout(checkPlaidLoaded, 1000);
  setTimeout(checkPlaidLoaded, 2000);

  // Expose a helper function for Flutter to check Plaid status
  window.isPlaidReady = function() {
    return !!window.Plaid;
  };

  // Expose a wrapper function to create Plaid Link
  window.createPlaidLink = function(config) {
    if (!window.Plaid) {
      throw new Error('Plaid SDK not loaded');
    }
    return window.Plaid.create(config);
  };

  console.log('🔧 Plaid loader script finished');
})();
