#!/usr/bin/env node
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const https = require('https');
const os = require('os');

const GITHUB_REPO = 'CryoThrust/Sesh';
const APP_NAME = 'Sesh.app';
const INSTALL_DIR = '/Applications';

function getLatestReleaseUrl() {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'api.github.com',
      path: `/repos/${GITHUB_REPO}/releases/latest`,
      headers: { 'User-Agent': 'node' }
    };
    https.get(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          const dmgAsset = json.assets.find(a => a.name.endsWith('.dmg'));
          const zipAsset = json.assets.find(a => a.name.endsWith('.zip'));
          resolve({
            dmg: dmgAsset ? dmgAsset.browser_download_url : null,
            zip: zipAsset ? zipAsset.browser_download_url : null,
            tag: json.tag_name
          });
        } catch (e) {
          reject(e);
        }
      });
    }).on('error', reject);
  });
}

function downloadFile(url, dest) {
  return new Promise((resolve, reject) => {
    const file = fs.createWriteStream(dest);
    https.get(url, { headers: { 'User-Agent': 'node' } }, (res) => {
      if (res.statusCode === 302 || res.statusCode === 301) {
        downloadFile(res.headers.location, dest).then(resolve).catch(reject);
        return;
      }
      const total = parseInt(res.headers['content-length'], 10);
      let downloaded = 0;
      res.on('data', chunk => {
        downloaded += chunk.length;
        const pct = total ? Math.round(downloaded / total * 100) : '?';
        process.stdout.write(`\r  Downloading... ${pct}%`);
      });
      res.pipe(file);
      file.on('finish', () => {
        file.close();
        process.stdout.write('\n');
        resolve();
      });
    }).on('error', (e) => {
      fs.unlink(dest, () => {});
      reject(e);
    });
  });
}

async function install() {
  if (os.platform() !== 'darwin') {
    console.error('Error: Sesh only runs on macOS.');
    process.exit(1);
  }

  console.log('Sesh - Installer');
  console.log('=================\n');

  // Check if already installed
  const existingPath = path.join(INSTALL_DIR, APP_NAME);
  if (fs.existsSync(existingPath)) {
    console.log('Already installed at ' + existingPath);
    console.log('Run "sesh" to launch, or reinstall with --force');
    if (!process.argv.includes('--force')) return;
    console.log('Reinstalling...\n');
  }

  try {
    console.log('Fetching latest release info...');
    const release = await getLatestReleaseUrl();

    if (release.dmg) {
      const tmpFile = path.join(os.tmpdir(), 'Sesh.dmg');
      console.log('Downloading DMG...');
      await downloadFile(release.dmg, tmpFile);

      console.log('Mounting DMG...');
      const mountPoint = execSync(`hdiutil attach -nobrowse -quiet "${tmpFile}"`, { encoding: 'utf8' })
        .trim().split('\n').pop().split('\t')[0];

      const mountedApp = path.join(mountPoint.trim(), APP_NAME);
      if (fs.existsSync(mountedApp)) {
        console.log('Installing to /Applications...');
        execSync(`cp -R "${mountedApp}" "${INSTALL_DIR}/"`, { stdio: 'inherit' });
        console.log('Unmounting DMG...');
        execSync(`hdiutil detach -quiet "${mountPoint.trim()}"`, { stdio: 'pipe' });
      } else {
        console.log('App not found in DMG, trying ZIP...');
        execSync(`hdiutil detach -quiet "${mountPoint.trim()}"`, { stdio: 'pipe' });
        await installFromZip(release.zip);
      }
      fs.unlinkSync(tmpFile);
    } else if (release.zip) {
      await installFromZip(release.zip);
    }

    console.log('\nSesh installed!');
    console.log('  Open from Launchpad or /Applications/Sesh.app\n');
  } catch (e) {
    console.error('\nInstallation failed:', e.message);
    console.error('Download manually from:');
    console.error('  https://github.com/CryoThrust/Sesh/releases/latest');
    process.exit(1);
  }
}

async function installFromZip(zipUrl) {
  const tmpFile = path.join(os.tmpdir(), 'Sesh.zip');
  console.log('Downloading ZIP...');
  await downloadFile(zipUrl, tmpFile);

  console.log('Extracting...');
  const tmpDir = path.join(os.tmpdir(), 'Sesh-extract');
  execSync(`rm -rf "${tmpDir}" && mkdir -p "${tmpDir}"`);
  execSync(`unzip -q -o "${tmpFile}" -d "${tmpDir}"`, { stdio: 'pipe' });

  const extractedApp = path.join(tmpDir, APP_NAME);
  if (fs.existsSync(extractedApp)) {
    console.log('Installing to /Applications...');
    execSync(`cp -R "${extractedApp}" "${INSTALL_DIR}/"`, { stdio: 'inherit' });
  }

  execSync(`rm -rf "${tmpDir}"`);
  fs.unlinkSync(tmpFile);
}

install();
