const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 3000;
const AI_DIR = path.join(__dirname, '..');

const server = http.createServer((req, res) => {
    // API: GET /api/files?name=filename.md
    if (req.url.startsWith('/api/files') && req.method === 'GET') {
        const url = new URL(req.url, `http://localhost:${PORT}`);
        const fileName = url.searchParams.get('name');
        if (!fileName) {
            res.writeHead(400);
            return res.end('File name required');
        }
        const filePath = path.join(AI_DIR, fileName);
        fs.readFile(filePath, 'utf8', (err, data) => {
            if (err) {
                res.writeHead(404);
                return res.end('File not found');
            }
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ content: data }));
        });
        return;
    }

    // API: POST /api/files
    if (req.url === '/api/files' && req.method === 'POST') {
        let body = '';
        req.on('data', chunk => body += chunk);
        req.on('end', () => {
            try {
                const { name, content } = JSON.parse(body);
                const filePath = path.join(AI_DIR, name);
                fs.writeFile(filePath, content, 'utf8', (err) => {
                    if (err) {
                        res.writeHead(500);
                        return res.end('Error writing file');
                    }
                    res.writeHead(200);
                    res.end('Success');
                });
            } catch (e) {
                res.writeHead(400);
                res.end('Invalid JSON');
            }
        });
        return;
    }

    // Static Server: Serve index.html
    let filePath = path.join(__dirname, req.url === '/' ? 'index.html' : req.url);
    const ext = path.extname(filePath);
    let contentType = 'text/html';
    if (ext === '.js') contentType = 'text/javascript';
    if (ext === '.css') contentType = 'text/css';

    fs.readFile(filePath, (err, content) => {
        if (err) {
            res.writeHead(404);
            res.end('Not Found');
        } else {
            res.writeHead(200, { 'Content-Type': contentType });
            res.end(content);
        }
    });
});

server.listen(PORT, () => {
    const url = `http://localhost:${PORT}`;
    console.log(`[INFO] Harness Control Center running at ${url}`);
    
    // Auto-open browser
    const start = (process.platform === 'darwin' ? 'open' : process.platform === 'win32' ? 'start' : 'xdg-open');
    require('child_process').exec(`${start} ${url}`);
});
