#!/usr/bin/env node
const fs = require('fs');

const APP_PATH = '/Applications/Sesh.app';

if (fs.existsSync(APP_PATH)) {
  try {
    require('child_process').execSync(`rm -rf "${APP_PATH}"`, { stdio: 'inherit' });
    console.log('Sesh uninstalled.');
  } catch (e) {
    console.error('Failed to remove. Try: sudo rm -rf /Applications/Sesh.app');
  }
} else {
  console.log('Sesh is not installed.');
}
