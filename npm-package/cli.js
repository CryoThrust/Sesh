#!/usr/bin/env node
const { execSync } = require('child_process');
const fs = require('fs');

const APP_PATH = '/Applications/Sesh.app';

if (fs.existsSync(APP_PATH)) {
  execSync(`open "${APP_PATH}"`, { stdio: 'inherit' });
} else {
  console.log('Sesh is not installed.');
  console.log('Install with: npm install -g sesh-app');
  process.exit(1);
}
