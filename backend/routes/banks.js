const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Get all connected banks for a user
router.get('/user/:userId/banks', async (req, res) => {
  try {
    const { userId } = req.params;

    // Find or create user
    let user = await prisma.user.findUnique({
      where: { userId },
      include: { banks: true }
    });

    if (!user) {
      user = await prisma.user.create({
        data: { userId },
        include: { banks: true }
      });
    }

    res.json({ banks: user.banks });
  } catch (error) {
    console.error('Error fetching banks:', error);
    res.status(500).json({ error: 'Failed to fetch banks', details: error.message });
  }
});

// Add or update a connected bank
router.post('/user/:userId/banks', async (req, res) => {
  try {
    const { userId } = req.params;
    const {
      institutionId,
      institutionName,
      accessToken,
      itemId,
      accountMask,
      accountType,
      logoUrl,
      nickname,
      accountIds = []
    } = req.body;

    if (!institutionId || !institutionName || !accessToken || !itemId) {
      return res.status(400).json({
        error: 'Missing required fields: institutionId, institutionName, accessToken, itemId'
      });
    }

    // Find or create user
    let user = await prisma.user.findUnique({
      where: { userId }
    });

    if (!user) {
      user = await prisma.user.create({
        data: { userId }
      });
    }

    // Check if bank already exists for this user
    const existingBank = await prisma.connectedBank.findFirst({
      where: {
        userId: user.id,
        institutionId
      }
    });

    let bank;
    if (existingBank) {
      // Update existing bank
      bank = await prisma.connectedBank.update({
        where: { id: existingBank.id },
        data: {
          institutionName,
          accessToken,
          itemId,
          accountMask,
          accountType,
          logoUrl,
          nickname,
          accountIds,
          status: 'connected',
          errorMessage: null,
          updatedAt: new Date()
        }
      });
    } else {
      // Create new bank
      bank = await prisma.connectedBank.create({
        data: {
          userId: user.id,
          institutionId,
          institutionName,
          accessToken,
          itemId,
          accountMask,
          accountType,
          logoUrl,
          nickname,
          accountIds,
          status: 'connected'
        }
      });
    }

    res.json({ bank });
  } catch (error) {
    console.error('Error saving bank:', error);
    res.status(500).json({ error: 'Failed to save bank', details: error.message });
  }
});

// Update bank status/sync info
router.patch('/user/:userId/banks/:institutionId', async (req, res) => {
  try {
    const { userId, institutionId } = req.params;
    const { status, lastSyncTransactionCount, errorMessage, nickname } = req.body;

    // Find user
    const user = await prisma.user.findUnique({
      where: { userId }
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Find bank
    const bank = await prisma.connectedBank.findFirst({
      where: {
        userId: user.id,
        institutionId
      }
    });

    if (!bank) {
      return res.status(404).json({ error: 'Bank not found' });
    }

    // Update bank
    const updatedBank = await prisma.connectedBank.update({
      where: { id: bank.id },
      data: {
        ...(status && { status }),
        ...(lastSyncTransactionCount !== undefined && { lastSyncTransactionCount }),
        ...(errorMessage !== undefined && { errorMessage }),
        ...(nickname !== undefined && { nickname }),
        ...(status === 'connected' && { lastSyncAt: new Date() }),
        updatedAt: new Date()
      }
    });

    res.json({ bank: updatedBank });
  } catch (error) {
    console.error('Error updating bank:', error);
    res.status(500).json({ error: 'Failed to update bank', details: error.message });
  }
});

// Delete a connected bank
router.delete('/user/:userId/banks/:institutionId', async (req, res) => {
  try {
    const { userId, institutionId } = req.params;

    // Find user
    const user = await prisma.user.findUnique({
      where: { userId }
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Find and delete bank
    const bank = await prisma.connectedBank.findFirst({
      where: {
        userId: user.id,
        institutionId
      }
    });

    if (!bank) {
      return res.status(404).json({ error: 'Bank not found' });
    }

    await prisma.connectedBank.delete({
      where: { id: bank.id }
    });

    res.json({ success: true, message: 'Bank disconnected' });
  } catch (error) {
    console.error('Error deleting bank:', error);
    res.status(500).json({ error: 'Failed to delete bank', details: error.message });
  }
});

module.exports = router;
