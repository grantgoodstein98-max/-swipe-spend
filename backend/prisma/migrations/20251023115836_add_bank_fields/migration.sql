-- AlterTable
ALTER TABLE "ConnectedBank" ADD COLUMN IF NOT EXISTS "accountMask" TEXT,
ADD COLUMN IF NOT EXISTS "accountType" TEXT,
ADD COLUMN IF NOT EXISTS "logoUrl" TEXT,
ADD COLUMN IF NOT EXISTS "nickname" TEXT,
ADD COLUMN IF NOT EXISTS "lastSyncTransactionCount" INTEGER NOT NULL DEFAULT 0;

-- CreateIndex
CREATE INDEX IF NOT EXISTS "ConnectedBank_institutionId_idx" ON "ConnectedBank"("institutionId");
