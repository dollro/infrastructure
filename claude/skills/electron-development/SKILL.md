# Electron Development Skill

Comprehensive technical knowledge for building secure, performant cross-platform desktop applications with Electron.

---

## Security Implementation

### Context Isolation (MANDATORY)

Context isolation ensures that preload scripts and Electron's internal logic run in a separate JavaScript context from the website loaded in the renderer.

```javascript
// main.js - Creating a secure BrowserWindow
const { BrowserWindow } = require('electron');

const mainWindow = new BrowserWindow({
  width: 1200,
  height: 800,
  webPreferences: {
    // SECURITY: Must be enabled (default in Electron 12+)
    contextIsolation: true,

    // SECURITY: Must be disabled in renderer
    nodeIntegration: false,

    // SECURITY: Disable remote module
    enableRemoteModule: false,

    // SECURITY: Sandbox renderer processes
    sandbox: true,

    // Path to preload script
    preload: path.join(__dirname, 'preload.js'),

    // SECURITY: Enable web security
    webSecurity: true,

    // SECURITY: Disable webview tag unless needed
    webviewTag: false,
  }
});
```

### Preload Script API Exposure

Safely expose APIs to the renderer using contextBridge:

```javascript
// preload.js
const { contextBridge, ipcRenderer } = require('electron');

// Only expose specific, validated APIs
contextBridge.exposeInMainWorld('electronAPI', {
  // File operations with validation
  readFile: (filePath) => {
    // Validate path before sending to main
    if (!isValidPath(filePath)) {
      throw new Error('Invalid file path');
    }
    return ipcRenderer.invoke('file:read', filePath);
  },

  // One-way communication
  sendNotification: (title, body) => {
    ipcRenderer.send('notification:show', { title, body });
  },

  // Two-way communication with response
  saveFile: (filePath, content) => {
    return ipcRenderer.invoke('file:save', filePath, content);
  },

  // Subscribe to events from main
  onUpdateAvailable: (callback) => {
    ipcRenderer.on('update:available', (event, info) => callback(info));
  },

  // Remove listeners
  removeUpdateListener: () => {
    ipcRenderer.removeAllListeners('update:available');
  }
});

// Path validation helper
function isValidPath(filePath) {
  // Prevent path traversal attacks
  const normalized = path.normalize(filePath);
  const allowedPaths = [app.getPath('documents'), app.getPath('downloads')];
  return allowedPaths.some(allowed => normalized.startsWith(allowed));
}
```

### IPC Channel Validation

Secure IPC handling in the main process:

```javascript
// main.js
const { ipcMain, dialog, BrowserWindow } = require('electron');

// Define allowed channels
const ALLOWED_CHANNELS = new Set([
  'file:read',
  'file:save',
  'notification:show',
  'dialog:open',
]);

// Validate sender
function validateSender(event) {
  const senderFrame = event.senderFrame;
  const url = new URL(senderFrame.url);

  // Only accept from our app
  if (url.protocol !== 'file:' && url.protocol !== 'app:') {
    throw new Error('Invalid sender protocol');
  }

  return true;
}

// File read handler with validation
ipcMain.handle('file:read', async (event, filePath) => {
  validateSender(event);

  // Additional path validation
  const normalizedPath = path.normalize(filePath);
  if (normalizedPath.includes('..')) {
    throw new Error('Path traversal not allowed');
  }

  // Check file exists and is readable
  try {
    await fs.access(normalizedPath, fs.constants.R_OK);
    return await fs.readFile(normalizedPath, 'utf-8');
  } catch (error) {
    throw new Error(`Cannot read file: ${error.message}`);
  }
});

// File save handler
ipcMain.handle('file:save', async (event, filePath, content) => {
  validateSender(event);

  // Validate content size
  if (content.length > 10 * 1024 * 1024) { // 10MB limit
    throw new Error('Content too large');
  }

  // Use safe write with temp file
  const tempPath = `${filePath}.tmp`;
  await fs.writeFile(tempPath, content);
  await fs.rename(tempPath, filePath);

  return { success: true };
});
```

### Content Security Policy

Configure strict CSP for renderer content:

```javascript
// main.js
const { session } = require('electron');

app.whenReady().then(() => {
  // Set CSP headers
  session.defaultSession.webRequest.onHeadersReceived((details, callback) => {
    callback({
      responseHeaders: {
        ...details.responseHeaders,
        'Content-Security-Policy': [
          "default-src 'self'",
          "script-src 'self'",
          "style-src 'self' 'unsafe-inline'", // Allow inline styles if needed
          "img-src 'self' data: https:",
          "font-src 'self'",
          "connect-src 'self' https://api.yourapp.com",
          "frame-src 'none'",
          "object-src 'none'",
          "base-uri 'self'",
        ].join('; ')
      }
    });
  });
});
```

### Secure Data Storage

```javascript
// Use electron-store with encryption for sensitive data
const Store = require('electron-store');
const { safeStorage } = require('electron');

// Encrypted store for sensitive data
class SecureStore {
  constructor() {
    this.store = new Store({
      name: 'secure-config',
      encryptionKey: 'your-encryption-key', // In production, derive from system
    });
  }

  // Store sensitive data using OS-level encryption
  async setSecure(key, value) {
    if (safeStorage.isEncryptionAvailable()) {
      const encrypted = safeStorage.encryptString(value);
      this.store.set(key, encrypted.toString('base64'));
    } else {
      // Fallback with warning
      console.warn('OS encryption not available');
      this.store.set(key, value);
    }
  }

  async getSecure(key) {
    const value = this.store.get(key);
    if (!value) return null;

    if (safeStorage.isEncryptionAvailable()) {
      const buffer = Buffer.from(value, 'base64');
      return safeStorage.decryptString(buffer);
    }
    return value;
  }
}
```

### Certificate Pinning

```javascript
// main.js
const { session } = require('electron');

// Pin certificates for your API
const PINNED_CERTS = {
  'api.yourapp.com': [
    'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=', // Primary
    'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=', // Backup
  ]
};

app.whenReady().then(() => {
  session.defaultSession.setCertificateVerifyProc((request, callback) => {
    const { hostname, certificate } = request;

    if (PINNED_CERTS[hostname]) {
      const certFingerprint = `sha256/${certificate.fingerprint}`;
      if (PINNED_CERTS[hostname].includes(certFingerprint)) {
        callback(0); // Certificate is trusted
      } else {
        callback(-2); // Certificate not trusted
      }
    } else {
      callback(-3); // Use default verification
    }
  });
});
```

---

## Process Architecture

### Main Process Responsibilities

```javascript
// main.js - Main process setup
const { app, BrowserWindow, Menu, Tray, nativeTheme } = require('electron');

class MainProcess {
  constructor() {
    this.mainWindow = null;
    this.tray = null;
    this.isQuitting = false;
  }

  async initialize() {
    // Single instance lock
    const gotLock = app.requestSingleInstanceLock();
    if (!gotLock) {
      app.quit();
      return;
    }

    app.on('second-instance', () => {
      if (this.mainWindow) {
        if (this.mainWindow.isMinimized()) this.mainWindow.restore();
        this.mainWindow.focus();
      }
    });

    await app.whenReady();

    this.createWindow();
    this.createMenu();
    this.createTray();
    this.setupIPC();
    this.setupUpdater();

    // Handle app lifecycle
    app.on('window-all-closed', () => {
      if (process.platform !== 'darwin') {
        app.quit();
      }
    });

    app.on('activate', () => {
      if (BrowserWindow.getAllWindows().length === 0) {
        this.createWindow();
      }
    });

    app.on('before-quit', () => {
      this.isQuitting = true;
    });
  }

  createWindow() {
    this.mainWindow = new BrowserWindow({
      width: 1200,
      height: 800,
      minWidth: 800,
      minHeight: 600,
      titleBarStyle: process.platform === 'darwin' ? 'hiddenInset' : 'default',
      backgroundColor: nativeTheme.shouldUseDarkColors ? '#1a1a1a' : '#ffffff',
      show: false, // Show when ready to prevent flash
      webPreferences: {
        preload: path.join(__dirname, 'preload.js'),
        contextIsolation: true,
        nodeIntegration: false,
        sandbox: true,
      }
    });

    // Restore window state
    this.restoreWindowState();

    // Show when ready
    this.mainWindow.once('ready-to-show', () => {
      this.mainWindow.show();
    });

    // Save state on close
    this.mainWindow.on('close', (event) => {
      if (!this.isQuitting && process.platform === 'darwin') {
        event.preventDefault();
        this.mainWindow.hide();
      } else {
        this.saveWindowState();
      }
    });

    // Load the app
    if (process.env.NODE_ENV === 'development') {
      this.mainWindow.loadURL('http://localhost:3000');
      this.mainWindow.webContents.openDevTools();
    } else {
      this.mainWindow.loadFile(path.join(__dirname, 'dist', 'index.html'));
    }
  }

  saveWindowState() {
    const bounds = this.mainWindow.getBounds();
    const isMaximized = this.mainWindow.isMaximized();
    store.set('windowState', { bounds, isMaximized });
  }

  restoreWindowState() {
    const state = store.get('windowState');
    if (state) {
      this.mainWindow.setBounds(state.bounds);
      if (state.isMaximized) {
        this.mainWindow.maximize();
      }
    }
  }
}

const mainProcess = new MainProcess();
mainProcess.initialize();
```

### Renderer Process Isolation

```javascript
// renderer.js - Runs in isolated context
// NO access to Node.js or Electron APIs directly

// Access only through exposed API
async function loadDocument(filePath) {
  try {
    const content = await window.electronAPI.readFile(filePath);
    renderDocument(content);
  } catch (error) {
    showError('Failed to load document', error.message);
  }
}

// Subscribe to main process events
window.electronAPI.onUpdateAvailable((info) => {
  showUpdateNotification(info.version);
});

// Cleanup on unload
window.addEventListener('unload', () => {
  window.electronAPI.removeUpdateListener();
});
```

### Worker Thread Utilization

For CPU-intensive tasks, use worker threads in main process:

```javascript
// main.js
const { Worker } = require('worker_threads');

class WorkerPool {
  constructor(workerScript, poolSize = 4) {
    this.workers = [];
    this.queue = [];

    for (let i = 0; i < poolSize; i++) {
      this.workers.push({
        worker: new Worker(workerScript),
        busy: false
      });
    }
  }

  execute(data) {
    return new Promise((resolve, reject) => {
      const availableWorker = this.workers.find(w => !w.busy);

      if (availableWorker) {
        this.runTask(availableWorker, data, resolve, reject);
      } else {
        this.queue.push({ data, resolve, reject });
      }
    });
  }

  runTask(workerInfo, data, resolve, reject) {
    workerInfo.busy = true;

    const handleMessage = (result) => {
      workerInfo.busy = false;
      workerInfo.worker.off('message', handleMessage);
      workerInfo.worker.off('error', handleError);
      resolve(result);
      this.processQueue();
    };

    const handleError = (error) => {
      workerInfo.busy = false;
      workerInfo.worker.off('message', handleMessage);
      workerInfo.worker.off('error', handleError);
      reject(error);
      this.processQueue();
    };

    workerInfo.worker.on('message', handleMessage);
    workerInfo.worker.on('error', handleError);
    workerInfo.worker.postMessage(data);
  }

  processQueue() {
    if (this.queue.length === 0) return;

    const availableWorker = this.workers.find(w => !w.busy);
    if (availableWorker) {
      const { data, resolve, reject } = this.queue.shift();
      this.runTask(availableWorker, data, resolve, reject);
    }
  }
}

// worker.js
const { parentPort } = require('worker_threads');

parentPort.on('message', (data) => {
  // CPU-intensive work here
  const result = processData(data);
  parentPort.postMessage(result);
});
```

### Memory Leak Prevention

```javascript
// Proper cleanup patterns
class ResourceManager {
  constructor() {
    this.subscriptions = [];
    this.timers = [];
    this.windows = new Set();
  }

  addSubscription(unsubscribeFn) {
    this.subscriptions.push(unsubscribeFn);
  }

  addTimer(timerId) {
    this.timers.push(timerId);
  }

  trackWindow(window) {
    this.windows.add(window);
    window.on('closed', () => {
      this.windows.delete(window);
    });
  }

  cleanup() {
    // Clear all subscriptions
    this.subscriptions.forEach(unsub => unsub());
    this.subscriptions = [];

    // Clear all timers
    this.timers.forEach(id => clearInterval(id));
    this.timers = [];

    // Close remaining windows
    this.windows.forEach(win => {
      if (!win.isDestroyed()) {
        win.destroy();
      }
    });
    this.windows.clear();
  }
}

// Usage
const resources = new ResourceManager();

// Track IPC listeners
const handler = (event, data) => processData(data);
ipcMain.on('channel', handler);
resources.addSubscription(() => ipcMain.removeListener('channel', handler));

// Track timers
const timerId = setInterval(checkForUpdates, 60000);
resources.addTimer(timerId);

// Cleanup on quit
app.on('will-quit', () => {
  resources.cleanup();
});
```

---

## Native OS Integration

### System Menu Bar

```javascript
const { Menu, app, shell } = require('electron');

function createApplicationMenu(mainWindow) {
  const isMac = process.platform === 'darwin';

  const template = [
    // App menu (macOS only)
    ...(isMac ? [{
      label: app.name,
      submenu: [
        { role: 'about' },
        { type: 'separator' },
        {
          label: 'Preferences...',
          accelerator: 'Cmd+,',
          click: () => mainWindow.webContents.send('menu:preferences')
        },
        { type: 'separator' },
        { role: 'services' },
        { type: 'separator' },
        { role: 'hide' },
        { role: 'hideOthers' },
        { role: 'unhide' },
        { type: 'separator' },
        { role: 'quit' }
      ]
    }] : []),

    // File menu
    {
      label: 'File',
      submenu: [
        {
          label: 'New',
          accelerator: 'CmdOrCtrl+N',
          click: () => mainWindow.webContents.send('menu:new')
        },
        {
          label: 'Open...',
          accelerator: 'CmdOrCtrl+O',
          click: async () => {
            const { filePaths } = await dialog.showOpenDialog(mainWindow, {
              properties: ['openFile'],
              filters: [{ name: 'Documents', extensions: ['txt', 'md'] }]
            });
            if (filePaths.length > 0) {
              mainWindow.webContents.send('menu:open', filePaths[0]);
            }
          }
        },
        { type: 'separator' },
        {
          label: 'Save',
          accelerator: 'CmdOrCtrl+S',
          click: () => mainWindow.webContents.send('menu:save')
        },
        { type: 'separator' },
        isMac ? { role: 'close' } : { role: 'quit' }
      ]
    },

    // Edit menu
    {
      label: 'Edit',
      submenu: [
        { role: 'undo' },
        { role: 'redo' },
        { type: 'separator' },
        { role: 'cut' },
        { role: 'copy' },
        { role: 'paste' },
        ...(isMac ? [
          { role: 'pasteAndMatchStyle' },
          { role: 'delete' },
          { role: 'selectAll' },
        ] : [
          { role: 'delete' },
          { type: 'separator' },
          { role: 'selectAll' }
        ])
      ]
    },

    // View menu
    {
      label: 'View',
      submenu: [
        { role: 'reload' },
        { role: 'forceReload' },
        { role: 'toggleDevTools' },
        { type: 'separator' },
        { role: 'resetZoom' },
        { role: 'zoomIn' },
        { role: 'zoomOut' },
        { type: 'separator' },
        { role: 'togglefullscreen' }
      ]
    },

    // Help menu
    {
      label: 'Help',
      submenu: [
        {
          label: 'Documentation',
          click: () => shell.openExternal('https://yourapp.com/docs')
        },
        {
          label: 'Report Issue',
          click: () => shell.openExternal('https://github.com/yourapp/issues')
        }
      ]
    }
  ];

  const menu = Menu.buildFromTemplate(template);
  Menu.setApplicationMenu(menu);
}
```

### Context Menus

```javascript
// preload.js - Expose context menu API
contextBridge.exposeInMainWorld('electronAPI', {
  showContextMenu: (menuId, data) => {
    ipcRenderer.send('context-menu:show', menuId, data);
  }
});

// main.js - Handle context menu
ipcMain.on('context-menu:show', (event, menuId, data) => {
  const window = BrowserWindow.fromWebContents(event.sender);

  const menus = {
    'text-selection': [
      { label: 'Copy', role: 'copy' },
      { label: 'Cut', role: 'cut' },
      { label: 'Paste', role: 'paste' },
      { type: 'separator' },
      {
        label: 'Search Google',
        click: () => {
          shell.openExternal(`https://google.com/search?q=${encodeURIComponent(data.text)}`);
        }
      }
    ],
    'file-item': [
      {
        label: 'Open',
        click: () => event.sender.send('context-menu:action', 'open', data)
      },
      {
        label: 'Delete',
        click: () => event.sender.send('context-menu:action', 'delete', data)
      },
      { type: 'separator' },
      {
        label: 'Show in Finder',
        click: () => shell.showItemInFolder(data.path)
      }
    ]
  };

  const template = menus[menuId] || [];
  const menu = Menu.buildFromTemplate(template);
  menu.popup({ window });
});

// renderer.js - Trigger context menu
document.addEventListener('contextmenu', (event) => {
  event.preventDefault();

  const selection = window.getSelection().toString();
  if (selection) {
    window.electronAPI.showContextMenu('text-selection', { text: selection });
  } else if (event.target.dataset.filePath) {
    window.electronAPI.showContextMenu('file-item', {
      path: event.target.dataset.filePath
    });
  }
});
```

### File Associations

```javascript
// package.json - electron-builder configuration
{
  "build": {
    "fileAssociations": [
      {
        "ext": "myapp",
        "name": "MyApp Document",
        "description": "MyApp Document File",
        "mimeType": "application/x-myapp",
        "role": "Editor",
        "icon": "icons/document.icns"
      }
    ],
    "protocols": [
      {
        "name": "MyApp Protocol",
        "schemes": ["myapp"]
      }
    ]
  }
}

// main.js - Handle file open events
app.on('open-file', (event, filePath) => {
  event.preventDefault();

  if (mainWindow) {
    mainWindow.webContents.send('file:open-external', filePath);
  } else {
    // Store for when window is ready
    global.fileToOpen = filePath;
  }
});

// Handle protocol URLs
app.on('open-url', (event, url) => {
  event.preventDefault();

  const parsed = new URL(url);
  if (parsed.protocol === 'myapp:') {
    handleProtocolAction(parsed);
  }
});

// Windows: Handle via command line arguments
app.on('second-instance', (event, argv) => {
  const filePath = argv.find(arg => arg.endsWith('.myapp'));
  if (filePath && mainWindow) {
    mainWindow.webContents.send('file:open-external', filePath);
    mainWindow.focus();
  }
});
```

### System Tray

```javascript
const { Tray, Menu, nativeImage } = require('electron');

class TrayManager {
  constructor(mainWindow) {
    this.mainWindow = mainWindow;
    this.tray = null;
  }

  create() {
    // Create tray icon
    const iconPath = process.platform === 'darwin'
      ? 'icons/trayTemplate.png'  // Template image for macOS
      : 'icons/tray.png';

    const icon = nativeImage.createFromPath(iconPath);
    this.tray = new Tray(icon);

    // Set tooltip
    this.tray.setToolTip('MyApp');

    // Create context menu
    this.updateContextMenu();

    // Handle click
    this.tray.on('click', () => {
      if (this.mainWindow.isVisible()) {
        this.mainWindow.hide();
      } else {
        this.mainWindow.show();
        this.mainWindow.focus();
      }
    });

    // Handle double-click (Windows)
    this.tray.on('double-click', () => {
      this.mainWindow.show();
      this.mainWindow.focus();
    });
  }

  updateContextMenu(status = 'idle') {
    const statusIcons = {
      idle: '',
      syncing: '',
      error: ''
    };

    const contextMenu = Menu.buildFromTemplate([
      {
        label: `Status: ${statusIcons[status]} ${status}`,
        enabled: false
      },
      { type: 'separator' },
      {
        label: 'Open MyApp',
        click: () => {
          this.mainWindow.show();
          this.mainWindow.focus();
        }
      },
      {
        label: 'Preferences...',
        click: () => {
          this.mainWindow.show();
          this.mainWindow.webContents.send('menu:preferences');
        }
      },
      { type: 'separator' },
      {
        label: 'Quit',
        click: () => app.quit()
      }
    ]);

    this.tray.setContextMenu(contextMenu);
  }

  // Update icon for different states
  setIcon(state) {
    const icons = {
      normal: 'icons/tray.png',
      notification: 'icons/tray-notification.png',
      syncing: 'icons/tray-syncing.png'
    };

    const icon = nativeImage.createFromPath(icons[state] || icons.normal);
    this.tray.setImage(icon);
  }

  destroy() {
    if (this.tray) {
      this.tray.destroy();
      this.tray = null;
    }
  }
}
```

### Native Notifications

```javascript
const { Notification, nativeImage } = require('electron');

class NotificationManager {
  constructor() {
    // Check if notifications are supported
    this.isSupported = Notification.isSupported();
  }

  show({ title, body, icon, actions, urgency = 'normal' }) {
    if (!this.isSupported) {
      console.warn('Notifications not supported on this platform');
      return null;
    }

    const notification = new Notification({
      title,
      body,
      icon: icon ? nativeImage.createFromPath(icon) : undefined,
      urgency, // 'low', 'normal', 'critical'
      silent: urgency === 'low',
      actions: actions || [],
      hasReply: false,
    });

    notification.on('click', () => {
      // Focus the app window
      if (mainWindow) {
        mainWindow.show();
        mainWindow.focus();
      }
    });

    notification.on('action', (event, index) => {
      // Handle action button clicks
      if (actions && actions[index]) {
        actions[index].callback?.();
      }
    });

    notification.show();
    return notification;
  }

  // Convenience methods
  info(title, body) {
    return this.show({ title, body, urgency: 'normal' });
  }

  success(title, body) {
    return this.show({
      title,
      body,
      icon: 'icons/success.png',
      urgency: 'low'
    });
  }

  error(title, body) {
    return this.show({
      title,
      body,
      icon: 'icons/error.png',
      urgency: 'critical'
    });
  }
}
```

---

## Auto-Update System

### Update Server Setup

```javascript
// Using electron-updater with GitHub releases
const { autoUpdater } = require('electron-updater');

class UpdateManager {
  constructor(mainWindow) {
    this.mainWindow = mainWindow;

    // Configure logging
    autoUpdater.logger = require('electron-log');
    autoUpdater.logger.transports.file.level = 'info';

    // Configure auto-updater
    autoUpdater.autoDownload = false;
    autoUpdater.autoInstallOnAppQuit = true;

    this.setupEventHandlers();
  }

  setupEventHandlers() {
    autoUpdater.on('checking-for-update', () => {
      this.sendStatus('checking');
    });

    autoUpdater.on('update-available', (info) => {
      this.sendStatus('available', info);

      // Optionally auto-download
      // autoUpdater.downloadUpdate();
    });

    autoUpdater.on('update-not-available', (info) => {
      this.sendStatus('not-available', info);
    });

    autoUpdater.on('download-progress', (progress) => {
      this.sendStatus('downloading', {
        percent: progress.percent,
        bytesPerSecond: progress.bytesPerSecond,
        transferred: progress.transferred,
        total: progress.total
      });
    });

    autoUpdater.on('update-downloaded', (info) => {
      this.sendStatus('downloaded', info);

      // Show notification
      new Notification({
        title: 'Update Ready',
        body: `Version ${info.version} is ready to install. Restart to update.`
      }).show();
    });

    autoUpdater.on('error', (error) => {
      this.sendStatus('error', { message: error.message });
    });
  }

  sendStatus(status, data = {}) {
    if (this.mainWindow && !this.mainWindow.isDestroyed()) {
      this.mainWindow.webContents.send('update:status', { status, ...data });
    }
  }

  async checkForUpdates() {
    try {
      await autoUpdater.checkForUpdates();
    } catch (error) {
      console.error('Update check failed:', error);
    }
  }

  async downloadUpdate() {
    try {
      await autoUpdater.downloadUpdate();
    } catch (error) {
      console.error('Update download failed:', error);
    }
  }

  quitAndInstall() {
    autoUpdater.quitAndInstall(false, true);
  }
}

// IPC handlers
ipcMain.handle('update:check', () => updateManager.checkForUpdates());
ipcMain.handle('update:download', () => updateManager.downloadUpdate());
ipcMain.handle('update:install', () => updateManager.quitAndInstall());
```

### Differential Updates

```javascript
// electron-builder.yml
publish:
  - provider: github
    owner: your-org
    repo: your-app
    releaseType: release

# Enable differential updates
nsis:
  differentialPackage: true

mac:
  # Enable code signing for auto-updates
  hardenedRuntime: true
  gatekeeperAssess: false
  entitlements: entitlements.mac.plist
  entitlementsInherit: entitlements.mac.plist
```

### Rollback Mechanism

```javascript
// Store previous version for rollback
const Store = require('electron-store');
const store = new Store();

class VersionManager {
  savePreviousVersion() {
    const currentVersion = app.getVersion();
    const previousVersions = store.get('previousVersions', []);

    // Keep last 3 versions
    previousVersions.unshift(currentVersion);
    store.set('previousVersions', previousVersions.slice(0, 3));
  }

  getPreviousVersions() {
    return store.get('previousVersions', []);
  }

  // Manual rollback would require server-side support
  // or keeping old installers available
}

// Check for update issues on startup
app.on('ready', () => {
  const lastVersion = store.get('lastSuccessfulVersion');
  const currentVersion = app.getVersion();

  if (lastVersion && lastVersion !== currentVersion) {
    // New version, mark as pending validation
    store.set('pendingValidation', true);

    // If app crashes within first 5 minutes, consider rollback
    setTimeout(() => {
      store.set('pendingValidation', false);
      store.set('lastSuccessfulVersion', currentVersion);
    }, 5 * 60 * 1000);
  }
});
```

---

## Performance Optimization

### Startup Time Optimization

```javascript
// 1. Defer non-critical initialization
const criticalInit = () => {
  // Only what's needed to show the window
  createWindow();
};

const deferredInit = () => {
  // Initialize after window is shown
  setupAnalytics();
  checkForUpdates();
  loadPlugins();
};

app.whenReady().then(async () => {
  criticalInit();

  // Defer non-critical work
  setTimeout(deferredInit, 1000);
});

// 2. Use v8 snapshots for faster startup
// In package.json build config:
{
  "build": {
    "electronCompile": true,
    "nodeGypRebuild": false
  }
}

// 3. Lazy load modules
let heavyModule;
function getHeavyModule() {
  if (!heavyModule) {
    heavyModule = require('heavy-module');
  }
  return heavyModule;
}

// 4. Preload critical assets
const preloadAssets = async () => {
  const critical = ['main.css', 'app.js', 'icons/logo.png'];
  await Promise.all(critical.map(asset =>
    fetch(asset).then(r => r.blob())
  ));
};
```

### Memory Management

```javascript
// Monitor memory usage
const v8 = require('v8');

function logMemoryUsage() {
  const heapStats = v8.getHeapStatistics();
  const used = process.memoryUsage();

  console.log('Memory Usage:', {
    heapUsed: `${Math.round(heapStats.used_heap_size / 1024 / 1024)}MB`,
    heapTotal: `${Math.round(heapStats.total_heap_size / 1024 / 1024)}MB`,
    rss: `${Math.round(used.rss / 1024 / 1024)}MB`,
    external: `${Math.round(used.external / 1024 / 1024)}MB`
  });
}

// Run garbage collection when memory is high
function checkMemoryPressure() {
  const used = process.memoryUsage();
  const heapUsedMB = used.heapUsed / 1024 / 1024;

  if (heapUsedMB > 150) { // 150MB threshold
    if (global.gc) {
      global.gc();
    }
  }
}

setInterval(checkMemoryPressure, 30000);

// Enable GC access (run with --expose-gc flag)
// In package.json:
{
  "scripts": {
    "start": "electron --expose-gc ."
  }
}
```

### GPU Acceleration

```javascript
// Enable hardware acceleration
app.commandLine.appendSwitch('enable-gpu-rasterization');
app.commandLine.appendSwitch('enable-zero-copy');

// Disable for problematic systems
if (store.get('disableHardwareAcceleration')) {
  app.disableHardwareAcceleration();
}

// Check GPU info
app.whenReady().then(() => {
  const gpuInfo = app.getGPUInfo('basic');
  gpuInfo.then(info => {
    console.log('GPU Info:', info);
  });
});

// Handle GPU process crash
app.on('gpu-process-crashed', (event, killed) => {
  console.error('GPU process crashed', { killed });

  // Offer to disable hardware acceleration
  dialog.showMessageBox({
    type: 'error',
    title: 'GPU Error',
    message: 'The graphics process crashed. Would you like to disable hardware acceleration?',
    buttons: ['Disable & Restart', 'Ignore']
  }).then(({ response }) => {
    if (response === 0) {
      store.set('disableHardwareAcceleration', true);
      app.relaunch();
      app.exit();
    }
  });
});
```

---

## Build Configuration

### Multi-Platform Builds

```yaml
# electron-builder.yml
appId: com.yourcompany.yourapp
productName: YourApp
copyright: Copyright 2024 Your Company

directories:
  buildResources: build
  output: dist

files:
  - "**/*"
  - "!**/*.{md,txt,map}"
  - "!**/node_modules/*/{test,__tests__,tests}/**"
  - "!**/node_modules/.cache/**"

mac:
  category: public.app-category.productivity
  icon: build/icon.icns
  hardenedRuntime: true
  gatekeeperAssess: false
  entitlements: build/entitlements.mac.plist
  entitlementsInherit: build/entitlements.mac.plist
  target:
    - target: dmg
      arch: [universal]
    - target: zip
      arch: [universal]

win:
  icon: build/icon.ico
  target:
    - target: nsis
      arch: [x64, arm64]
    - target: portable
      arch: [x64]

linux:
  icon: build/icons
  category: Utility
  target:
    - target: AppImage
      arch: [x64, arm64]
    - target: deb
      arch: [x64]
    - target: rpm
      arch: [x64]

nsis:
  oneClick: false
  perMachine: false
  allowToChangeInstallationDirectory: true
  installerIcon: build/icon.ico
  uninstallerIcon: build/icon.ico
  license: LICENSE

dmg:
  contents:
    - x: 130
      y: 220
    - x: 410
      y: 220
      type: link
      path: /Applications

publish:
  - provider: github
    releaseType: release
```

### Native Dependency Handling

```javascript
// postinstall script for native modules
// scripts/postinstall.js
const { execSync } = require('child_process');
const path = require('path');

const electronVersion = require('electron/package.json').version;

// Rebuild native modules for Electron
console.log(`Rebuilding native modules for Electron ${electronVersion}...`);

execSync(
  `npx electron-rebuild -v ${electronVersion} -m ${path.resolve(__dirname, '..')}`,
  { stdio: 'inherit' }
);

console.log('Native modules rebuilt successfully');
```

### CI/CD Integration

```yaml
# .github/workflows/build.yml
name: Build and Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    strategy:
      matrix:
        include:
          - os: macos-latest
            platform: mac
          - os: ubuntu-latest
            platform: linux
          - os: windows-latest
            platform: win

    runs-on: ${{ matrix.os }}

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build

      # macOS signing
      - name: Import Code Signing Certificate (macOS)
        if: matrix.platform == 'mac'
        env:
          MACOS_CERTIFICATE: ${{ secrets.MACOS_CERTIFICATE }}
          MACOS_CERTIFICATE_PWD: ${{ secrets.MACOS_CERTIFICATE_PWD }}
        run: |
          echo $MACOS_CERTIFICATE | base64 --decode > certificate.p12
          security create-keychain -p "" build.keychain
          security import certificate.p12 -k build.keychain -P $MACOS_CERTIFICATE_PWD -T /usr/bin/codesign
          security set-key-partition-list -S apple-tool:,apple: -k "" build.keychain

      # Build Electron app
      - name: Build Electron
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          APPLE_ID: ${{ secrets.APPLE_ID }}
          APPLE_APP_SPECIFIC_PASSWORD: ${{ secrets.APPLE_APP_SPECIFIC_PASSWORD }}
          APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
        run: npm run electron:build -- --${{ matrix.platform }}

      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: ${{ matrix.platform }}-build
          path: dist/*
```

---

## Debugging and Diagnostics

### DevTools Integration

```javascript
// Toggle DevTools based on environment
if (process.env.NODE_ENV === 'development') {
  mainWindow.webContents.openDevTools({ mode: 'detach' });
}

// Add DevTools extension
const { session } = require('electron');

app.whenReady().then(async () => {
  // Install React DevTools
  try {
    const reactDevToolsPath = path.join(
      os.homedir(),
      'Library/Application Support/Google/Chrome/Default/Extensions/fmkadmapgofadopljbjfkapdkoienihi'
    );
    await session.defaultSession.loadExtension(reactDevToolsPath);
  } catch (error) {
    console.log('React DevTools not found');
  }
});

// Custom DevTools menu item
{
  label: 'Developer',
  submenu: [
    {
      label: 'Toggle DevTools',
      accelerator: process.platform === 'darwin' ? 'Alt+Cmd+I' : 'Ctrl+Shift+I',
      click: () => mainWindow.webContents.toggleDevTools()
    },
    {
      label: 'Open Process Manager',
      click: () => app.showProcessMonitor()
    }
  ]
}
```

### Crash Reporting

```javascript
const { crashReporter } = require('electron');

// Initialize crash reporter
crashReporter.start({
  productName: 'YourApp',
  companyName: 'YourCompany',
  submitURL: 'https://your-crash-server.com/submit',
  uploadToServer: true,
  extra: {
    version: app.getVersion(),
    platform: process.platform
  }
});

// Log crashes locally too
process.on('uncaughtException', (error) => {
  console.error('Uncaught exception:', error);

  // Log to file
  const logPath = path.join(app.getPath('logs'), 'crash.log');
  fs.appendFileSync(logPath, `${new Date().toISOString()}: ${error.stack}\n`);

  // Show error dialog
  dialog.showErrorBox('Application Error', error.message);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled rejection:', reason);
});
```

---

> **Related Skill:** For backend integration with Electron apps, see `/home/rodo/.claude/skills/fullstack-development/SKILL.md`
