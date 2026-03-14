const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');
const fetch = require('node-fetch');

const CANVAS_BASE = 'https://canvas.westlake.edu.cn';

let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    minWidth: 800,
    minHeight: 600,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      nodeIntegration: false,
      contextIsolation: true,
    },
    icon: path.join(__dirname, 'build/web/icons/Icon-512.png'),
  });

  // 加载 Flutter Web 构建
  mainWindow.loadFile(path.join(__dirname, 'build/web/index.html'));
  
  // 开发模式打开开发者工具
  // mainWindow.webContents.openDevTools();

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

app.whenReady().then(() => {
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

// Canvas API 代理（解决 CORS 问题）
ipcMain.handle('canvas-api', async (event, { endpoint, token, method = 'GET', body = null }) => {
  try {
    const url = CANVAS_BASE + '/api/v1' + endpoint;
    console.log(`Canvas API: ${method} ${url}`);

    const options = {
      method,
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
    };

    if (body && method !== 'GET') {
      options.body = JSON.stringify(body);
    }

    const response = await fetch(url, options);
    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.errors?.[0]?.message || `API Error: ${response.status}`);
    }

    return { success: true, data };
  } catch (error) {
    console.error('Canvas API 错误:', error);
    return { success: false, error: error.message };
  }
});

// 文件下载
ipcMain.handle('download-file', async (event, { url, token, filename }) => {
  try {
    const response = await fetch(url, {
      headers: {
        'Authorization': `Bearer ${token}`,
      },
    });

    if (!response.ok) {
      throw new Error('下载失败');
    }

    const buffer = await response.buffer();
    return { success: true, buffer: buffer.toString('base64') };
  } catch (error) {
    return { success: false, error: error.message };
  }
});
