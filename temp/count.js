const fs = require('fs');
const path = require('path');

function walk(dir, ext, files = []) {
  for (const name of fs.readdirSync(dir)) {
    const p = path.join(dir, name);
    if (fs.statSync(p).isDirectory()) walk(p, ext, files);
    else if (p.endsWith(ext)) files.push(p);
  }
  return files;
}

function stripComments(content) {
  return content
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .replace(/\/\/.*$/gm, '');
}

function analyze(files) {
  let total = { files: 0, lines: 0, nonEmpty: 0, codeLike: 0 };
  console.log('file,lines,nonEmpty,codeLike');
  for (const f of files) {
    const content = fs.readFileSync(f, 'utf8');
    const lines = content.split(/\r?\n/);
    const nonEmpty = lines.filter(l => l.trim() !== '').length;
    const codeLike = stripComments(content).split(/\r?\n/).filter(l => l.trim() !== '').length;
    total.files++;
    total.lines += lines.length;
    total.nonEmpty += nonEmpty;
    total.codeLike += codeLike;
    console.log(`${path.relative(process.cwd(), f)},${lines.length},${nonEmpty},${codeLike}`);
  }
  console.log('');
  console.log('TOTAL', `files=${total.files}`, `lines=${total.lines}`, `nonEmpty=${total.nonEmpty}`, `codeLike=${total.codeLike}`);
}

const contractsDir = path.join(process.cwd(), 'contracts');
if (!fs.existsSync(contractsDir)) {
  console.error('contracts/ directory not found. Run this from project root.');
  process.exit(1);
}
const files = walk(contractsDir, '.sol');
analyze(files);