// Canvas Offline Web 代理服务器
// 解决 CORS 问题

const express = require('express');
const fetch = require('node-fetch');
const path = require('path');
const cors = require('cors');

const app = express();
const PORT = 3000;
const CANVAS_BASE = 'https://canvas.westlake.edu.cn';

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'build', 'web')));

// 代理 Canvas API 请求
app.all('/api/*', async (req, res) => {
    try {
        const token = req.headers.authorization?.replace('Bearer ', '');
        if (!token) {
            return res.status(401).json({ error: '未授权' });
        }

        const canvasUrl = CANVAS_BASE + req.url;
        console.log(`代理请求：${canvasUrl}`);

        const response = await fetch(canvasUrl, {
            method: req.method,
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json',
            },
            body: req.method !== 'GET' && req.method !== 'HEAD' ? JSON.stringify(req.body) : undefined,
        });

        const data = await response.json();
        res.json(data);
    } catch (error) {
        console.error('代理错误:', error);
        res.status(500).json({ error: error.message });
    }
});

// 启动服务器
app.listen(PORT, () => {
    console.log(`
╔════════════════════════════════════════════════════════╗
║   Canvas Offline 代理服务器已启动                        ║
║                                                        ║
║   访问地址：http://localhost:${PORT}                     ║
║   API 代理：http://localhost:${PORT}/api/*               ║
║                                                        ║
║   按 Ctrl+C 停止服务器                                  ║
╚════════════════════════════════════════════════════════╝
    `);
});
