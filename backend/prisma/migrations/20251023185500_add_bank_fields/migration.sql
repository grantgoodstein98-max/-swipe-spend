-- AlterTable
ALTER TABLE "ConnectedBank" ADD COLUMN "accountMask" TEXT,
ADD COLUMN "accountType" TEXT,
ADD COLUMN "logoUrl" TEXT,
ADD COLUMN "nickname" TEXT,
ADD COLUMN "lastSyncTransactionCount" INTEGER NOT NULL DEFAULT 0;

-- CreateIndex
CREATE INDEX "ConnectedBank_institutionId_idx" ON "ConnectedBank"("institutionId");
