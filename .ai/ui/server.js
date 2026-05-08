/**
 * AI Harness Control Center — Server
 * 역할: .ai/ 파일 읽기·쓰기 API + 정적 파일 서빙 + Compliance Auto-Logger + Security Scanner
 * 보안: Path Traversal 방지, 파일명 Whitelist, Origin 체크
 * 수정일: 2026-05-08
 */

const http = require('http');
const fs   = require('fs');
const path = require('path');

const PORT   = 3000;
const AI_DIR = path.resolve(__dirname, '..');
const ROOT   = path.resolve(AI_DIR, '..'); // 프로젝트 루트 (하네스 상위)

// ─── Whitelist ───
const ALLOWED_FILES = /^[A-Z][A-Z0-9_]*\.md$/;

// ─── Compliance Auto-Logger ───
const auditRules = {
  C01_fluff:      /(안녕|죄송합니다|감사합니다)/,
  C03_id_missing: /^(?!\[(PLAN|CODE|INFO|ANALYSIS|QUESTION|REF|CAUTION|CRITICAL|CONFIDENCE|MODE)\])/,
  T03_key_leak:   /(sk-[a-z0-9]{20,}|ghp_[a-zA-Z0-9]{36}|Bearer\s[A-Za-z0-9\-._~+\/]+=*)/i,
  T05_danger_cmd: /(rm\s+-rf|del\s+\/f|DROP\s+TABLE|chmod\s+777)/i,
};

function checkCompliance(text) {
  return Object.entries(auditRules).filter(([,re]) => re.test(text)).map(([id]) => id);
}

function appendComplianceLog(violations, context) {
  if (!violations.length) return;
  const entry = `\n- [${new Date().toISOString()}] 위반 감지 (${context}): ${violations.join(', ')}`;
  fs.appendFile(path.join(AI_DIR, 'COMPLIANCE_LOG.md'), entry, () => {});
}

// ─── 안전한 경로 검증 ───
function resolveSafePath(fileName) {
  if (!ALLOWED_FILES.test(fileName)) return null;
  const resolved = path.resolve(AI_DIR, fileName);
  if (!resolved.startsWith(AI_DIR + path.sep) && resolved !== AI_DIR) return null;
  return resolved;
}

// ════════════════════════════════════════
// SECURITY SCANNER
// ════════════════════════════════════════

// 스캔 제외 폴더
const SCAN_EXCLUDE_DIRS = new Set(['.ai', 'node_modules', '.git', '.next', 'dist', 'build', '.cache', 'coverage', '__pycache__']);

// 스캔 대상 확장자
const SCAN_EXTENSIONS  = new Set(['.js', '.ts', '.tsx', '.jsx', '.mjs', '.cjs', '.py', '.json', '.env', '.yaml', '.yml', '.sh']);

// 탐지 패턴 정의
const SCAN_PATTERNS = [
  // 하드코딩 시크릿
  { id: 'S01', sev: 'CRITICAL', label: '하드코딩된 API Key 의심',
    re: /(sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{36}|AKIA[A-Z0-9]{16}|AIza[0-9A-Za-z\-_]{35})/,
    skip: ['.env'] },
  { id: 'S02', sev: 'HIGH', label: '패스워드 직접 할당',
    re: /(?:password|passwd|pwd|secret|api_key|apikey)\s*[:=]\s*['"`][^'"`\s]{4,}/i,
    skip: ['.env', '.env.example'] },
  { id: 'S03', sev: 'HIGH', label: 'Bearer 토큰 하드코딩',
    re: /Bearer\s+[A-Za-z0-9\-._~+\/]{20,}/i,
    skip: [] },

  // 위험 코드 패턴
  { id: 'S04', sev: 'HIGH', label: 'eval() 사용',
    re: /\beval\s*\(/,
    skip: [] },
  { id: 'S05', sev: 'HIGH', label: 'dangerouslySetInnerHTML 사용',
    re: /dangerouslySetInnerHTML/,
    skip: [] },
  { id: 'S06', sev: 'MEDIUM', label: 'child_process.exec 직접 사용',
    re: /\.exec\s*\(\s*(?:req|params|query|body|input)/,
    skip: [] },
  { id: 'S07', sev: 'MEDIUM', label: 'SQL 문자열 직접 조합',
    re: /(?:SELECT|INSERT|UPDATE|DELETE).+?\+\s*(?:req|params|query|body|input)/i,
    skip: [] },
  { id: 'S08', sev: 'MEDIUM', label: 'console.log에 민감 변수 출력',
    re: /console\.log\s*\(.*(?:password|secret|token|key|jwt)/i,
    skip: [] },

  // 설정 문제
  { id: 'S09', sev: 'MEDIUM', label: 'CORS 와일드카드 허용',
    re: /Access-Control-Allow-Origin['":\s]+\*/,
    skip: [] },
  { id: 'S10', sev: 'LOW', label: 'HTTP 사용 (HTTPS 아님)',
    re: /http:\/\/(?!localhost|127\.0\.0\.1)/,
    skip: [] },
  { id: 'S11', sev: 'LOW', label: 'TODO/FIXME 보안 관련 주석',
    re: /\/\/\s*(?:TODO|FIXME|HACK|XXX).{0,60}(?:auth|password|secret|token|security)/i,
    skip: [] },
];

// 파일 목록 재귀 수집
function collectFiles(dir, results = []) {
  let entries;
  try { entries = fs.readdirSync(dir, { withFileTypes: true }); }
  catch { return results; }

  for (const entry of entries) {
    if (entry.name.startsWith('.') && entry.name !== '.env') {
      // .env 파일은 포함, 나머지 숨김파일 제외 (단 .gitignore는 체크)
      if (entry.name !== '.gitignore' && entry.name !== '.env.example') continue;
    }
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (!SCAN_EXCLUDE_DIRS.has(entry.name)) collectFiles(full, results);
    } else {
      const ext = path.extname(entry.name).toLowerCase();
      const base = path.basename(entry.name);
      if (SCAN_EXTENSIONS.has(ext) || base.startsWith('.env')) results.push(full);
    }
  }
  return results;
}

// 프로젝트 루트 결정 (ROOT가 AI_DIR 와 같으면 AI_DIR 자체를 루트로)
function getProjectRoot() {
  // .ai 폴더가 루트 바로 아래에 있으므로 루트 = AI_DIR의 부모
  const root = path.dirname(AI_DIR);
  return root;
}

// 스캔 실행
function runSecurityScan() {
  const projectRoot = getProjectRoot();
  const files = collectFiles(projectRoot);
  const findings = [];
  let scannedCount = 0;

  // .gitignore에 .env 포함 여부 체크
  const gitignorePath = path.join(projectRoot, '.gitignore');
  if (fs.existsSync(gitignorePath)) {
    const gi = fs.readFileSync(gitignorePath, 'utf8');
    if (!/^\.env/m.test(gi)) {
      findings.push({ id:'S00', sev:'HIGH', file:'.gitignore', line:'-', label:'.env가 .gitignore에 없음', match:'(파일 전체 확인)' });
    }
  } else {
    findings.push({ id:'S00', sev:'HIGH', file:'(없음)', line:'-', label:'.gitignore 파일 자체가 없음', match:'(파일 없음)' });
  }

  for (const filePath of files) {
    const relPath = path.relative(projectRoot, filePath);
    const ext = path.extname(filePath).toLowerCase();
    const base = path.basename(filePath);
    let lines;
    try {
      const content = fs.readFileSync(filePath, 'utf8');
      lines = content.split('\n');
    } catch { continue; }

    scannedCount++;

    for (const pattern of SCAN_PATTERNS) {
      // skip 확장자
      if (pattern.skip.some(s => base === s || base.startsWith(s))) continue;

      lines.forEach((line, idx) => {
        if (pattern.re.test(line)) {
          const match = (line.match(pattern.re) || [''])[0].slice(0, 60);
          findings.push({
            id: pattern.id,
            sev: pattern.sev,
            file: relPath,
            line: idx + 1,
            label: pattern.label,
            match: match.replace(/./g, (c, i) => i > 6 ? '*' : c), // 뒷부분 마스킹
          });
        }
      });
    }
  }

  return { scannedCount, fileCount: files.length, findings, scannedAt: new Date().toISOString(), projectRoot };
}

// 스캔 결과 → SECURITY_AUDIT.md 저장
function saveSecurityAudit(result) {
  const { scannedCount, findings, scannedAt, projectRoot } = result;

  const criticals = findings.filter(f => f.sev === 'CRITICAL');
  const highs     = findings.filter(f => f.sev === 'HIGH');
  const mediums   = findings.filter(f => f.sev === 'MEDIUM');
  const lows      = findings.filter(f => f.sev === 'LOW');

  const status = criticals.length > 0 ? 'CRITICAL' : highs.length > 0 ? 'AT RISK' : mediums.length > 0 ? 'CAUTION' : 'SAFE';

  const findingLines = findings.length === 0
    ? '- 탐지된 항목 없음.'
    : findings.map(f => `- [${f.sev}] [${f.id}] ${f.file} L${f.line} — ${f.label} \`${f.match}\``).join('\n');

  const summary = [
    criticals.length > 0 && `CRITICAL ${criticals.length}건`,
    highs.length     > 0 && `HIGH ${highs.length}건`,
    mediums.length   > 0 && `MEDIUM ${mediums.length}건`,
    lows.length      > 0 && `LOW ${lows.length}건`,
  ].filter(Boolean).join(', ') || '이상 없음';

  const content =
`# SECURITY AUDIT REPORT
<!-- AI Harness Security Scanner 자동 생성. [${scannedAt}] -->

## Summary
- **Status**: ${status}
- **스캔 일시**: ${scannedAt}
- **프로젝트 루트**: ${projectRoot}
- **스캔 파일 수**: ${scannedCount}개
- **탐지 결과**: ${summary}

## Details
${findingLines}

## 탐지 기준
| ID | 심각도 | 설명 |
|---|---|---|
| S00 | HIGH | .env가 .gitignore에 없음 |
| S01 | CRITICAL | 하드코딩된 API Key 의심 |
| S02 | HIGH | 패스워드 직접 할당 |
| S03 | HIGH | Bearer 토큰 하드코딩 |
| S04 | HIGH | eval() 사용 |
| S05 | HIGH | dangerouslySetInnerHTML 사용 |
| S06 | MEDIUM | child_process.exec 직접 사용 |
| S07 | MEDIUM | SQL 문자열 직접 조합 |
| S08 | MEDIUM | console.log에 민감 변수 출력 |
| S09 | MEDIUM | CORS 와일드카드 허용 |
| S10 | LOW | HTTP 사용 (HTTPS 아님) |
| S11 | LOW | 보안 관련 TODO/FIXME 주석 |
`;

  fs.writeFileSync(path.join(AI_DIR, 'SECURITY_AUDIT.md'), content, 'utf8');
  return { status, summary, findings };
}

// ════════════════════════════════════════
// HTTP SERVER
// ════════════════════════════════════════
const server = http.createServer((req, res) => {
  const origin = req.headers['origin'] || req.headers['host'] || '';
  const isLocal = origin.includes('localhost') || origin.includes('127.0.0.1') || origin === '';

  res.setHeader('Access-Control-Allow-Origin', 'http://localhost:' + PORT);
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') { res.writeHead(204); return res.end(); }
  if (!isLocal) { res.writeHead(403); return res.end('[CRITICAL] 외부 Origin 차단.'); }

  // GET /api/files
  if (req.url.startsWith('/api/files') && req.method === 'GET') {
    const url = new URL(req.url, `http://localhost:${PORT}`);
    const filePath = resolveSafePath(url.searchParams.get('name'));
    if (!filePath) { res.writeHead(403, {'Content-Type':'application/json'}); return res.end(JSON.stringify({error:'[CRITICAL] 허용되지 않은 파일명.'})); }
    fs.readFile(filePath, 'utf8', (err, data) => {
      if (err) { res.writeHead(404, {'Content-Type':'application/json'}); return res.end(JSON.stringify({error:'File not found'})); }
      res.writeHead(200, {'Content-Type':'application/json'});
      res.end(JSON.stringify({content: data}));
    });
    return;
  }

  // POST /api/files
  if (req.url === '/api/files' && req.method === 'POST') {
    let body = '';
    req.on('data', c => { body += c; });
    req.on('end', () => {
      try {
        const { name, content } = JSON.parse(body);
        const violations = checkCompliance(content);
        if (violations.length) appendComplianceLog(violations, `POST /api/files?name=${name}`);
        const filePath = resolveSafePath(name);
        if (!filePath) { res.writeHead(403); return res.end('[CRITICAL] 허용되지 않은 파일명.'); }
        fs.writeFile(filePath, content, 'utf8', err => {
          if (err) { res.writeHead(500); return res.end('Error writing file'); }
          res.writeHead(200, {'Content-Type':'application/json'});
          res.end(JSON.stringify({success: true, violations}));
        });
      } catch { res.writeHead(400); res.end('Invalid JSON'); }
    });
    return;
  }

  // POST /api/compliance-check
  if (req.url === '/api/compliance-check' && req.method === 'POST') {
    let body = '';
    req.on('data', c => { body += c; });
    req.on('end', () => {
      try {
        const { text, context } = JSON.parse(body);
        const violations = checkCompliance(text);
        appendComplianceLog(violations, context || 'manual-check');
        res.writeHead(200, {'Content-Type':'application/json'});
        res.end(JSON.stringify({violations, compliant: violations.length === 0}));
      } catch { res.writeHead(400); res.end('Invalid JSON'); }
    });
    return;
  }

  // POST /api/scan — 보안 스캔 실행
  if (req.url === '/api/scan' && req.method === 'POST') {
    try {
      const result  = runSecurityScan();
      const saved   = saveSecurityAudit(result);
      res.writeHead(200, {'Content-Type':'application/json'});
      res.end(JSON.stringify({
        status:       saved.status,
        summary:      saved.summary,
        scannedCount: result.scannedCount,
        fileCount:    result.fileCount,
        findings:     saved.findings,
        scannedAt:    result.scannedAt,
      }));
    } catch (e) {
      res.writeHead(500, {'Content-Type':'application/json'});
      res.end(JSON.stringify({error: e.message}));
    }
    return;
  }

  // 정적 파일 서빙
  const filePath = path.join(__dirname, req.url === '/' ? 'index.html' : req.url);
  const contentTypes = {'.html':'text/html', '.js':'text/javascript', '.css':'text/css'};
  fs.readFile(filePath, (err, content) => {
    if (err) { res.writeHead(404); res.end('Not Found'); }
    else { res.writeHead(200, {'Content-Type': contentTypes[path.extname(filePath)] || 'text/plain'}); res.end(content); }
  });
});

server.listen(PORT, () => {
  console.log(`[INFO] Harness Control Center: http://localhost:${PORT}`);
  console.log(`[INFO] Project root: ${getProjectRoot()}`);
  console.log(`[INFO] Security: Path Traversal ON | Whitelist ON | Origin Check ON | Scanner ON`);
  console.log(`[INFO] Compliance Auto-Logger: ON`);
  const start = process.platform === 'darwin' ? 'open' : process.platform === 'win32' ? 'start' : 'xdg-open';
  require('child_process').exec(`${start} http://localhost:${PORT}`);
});
