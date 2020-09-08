const cache = require('@actions/cache');
const core = require('@actions/core');
const exec = require('@actions/exec');
const fs = require('fs');
const path = require('path');

const key = core.getInput('key', { required: true})

async function exec(script, args) {
  var srcDir = path.dirname(__filename)
  await exec.exec(script, args)
}

function printInfo(s) {
  console.log('\x1b[34m', s, '\x1b[0m')
}

const paths = [
  '/nix/store/',
  '/nix/var/nix/profiles/per-user/' + process.env.USER + '/profile/bin',
  '/nix/var/nix/profiles/default/bin/',
  '/nix/var/nix/profiles/per-user/root/channels'
]

async function restoreCache() {
  // TODO: Parse restorekeys from input.
  printInfo('Restoring cache for key: ' + key)
  const restoreKeys = []
  const cacheKey = cache.restoreCache(paths, key, restoreKeys)
  if (cacheKey === undefined) {
    printInfo('No cache found for given key')
  } else {
    printInfo('Cache restored')
  }
  return cacheKey
}

async function saveCache(cacheKey) {
  if (cacheKey === undefined) {
    printInfo('Saving cache with key: ' + key)
    await cache.saveCache(paths, key)
  }
}

async function installWithNix(cacheKey) {
  // Doing this in a separate step to let Bash load the env vars in the next step.
  if (cacheKey === undefined) {
    printInfo('Installing with Nix')
    await exec('core.sh', ['install-with-nix'])
  } else {
    printInfo('Installing from cache')
    await exec('core.sh', ['install-from-cache'])
  }
}

(async function run() {
  printInfo('Preparing restore')
  await exec('core.sh', ['prepare-restore'])

  const cacheKey = await restoreCache()

  await installWithNix(cacheKey)

  printInfo('Preparing save')
  await exec('core.sh', ['prepare-save'])

  await saveCache(cacheKey)

// Run the async function and exit on error.
})().catch(e => { console.error(e); process.exit(1) })
