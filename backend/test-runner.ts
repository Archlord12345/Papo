import * as fs from 'fs';
import * as path from 'path';
import { execSync } from 'child_process';

const schemaPath = path.join(__dirname, 'prisma', 'schema.prisma');
const sqliteEnv = { ...process.env, DATABASE_URL: 'file:./dev.db' };

function run() {
  console.log('🔄 Swapping Prisma provider to sqlite for local tests...');
  const originalSchema = fs.readFileSync(schemaPath, 'utf-8');
  const sqliteSchema = originalSchema.replace('provider = "postgresql"', 'provider = "sqlite"');
  fs.writeFileSync(schemaPath, sqliteSchema);
  let failed = false;

  try {
    console.log('⚙️ Regenerating Prisma Client for SQLite...');
    execSync('npx prisma generate', {
      stdio: 'inherit',
      cwd: __dirname,
      env: sqliteEnv,
    });

    console.log('🗃️ Applying SQLite schema...');
    execSync('npx prisma db push', {
      stdio: 'inherit',
      cwd: __dirname,
      env: sqliteEnv,
    });

    console.log('⚡ Running verification script...');
    execSync('npx ts-node verify-backend.ts', {
      stdio: 'inherit',
      cwd: __dirname,
      env: sqliteEnv,
    });
    console.log('✅ Verification script completed.');
  } catch (error: any) {
    failed = true;
    console.error('❌ Test execution failed:', error.message);
  } finally {
    console.log('🔄 Reverting Prisma provider back to postgresql...');
    fs.writeFileSync(schemaPath, originalSchema);
    console.log('⚙️ Regenerating Prisma Client for PostgreSQL...');
    execSync('npx prisma generate', { stdio: 'inherit', cwd: __dirname, env: sqliteEnv });
    console.log('✅ Revert complete.');
  }

  if (failed) {
    process.exitCode = 1;
  }
}

run();
