import fs from 'node:fs';

const xmlPath = new URL('./_ecology_unzip/word/document.xml', import.meta.url);
const outPath = new URL('./_ecology_flow_plain.txt', import.meta.url);

const xml = fs.readFileSync(xmlPath, 'utf8');
const re =
  /<w:t[^>]*xml:space="preserve"[^>]*>([\s\S]*?)<\/w:t>|<w:t[^>]*>([\s\S]*?)<\/w:t>/g;
function decodeEntities(s) {
  return s
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"');
}

/** w:t 里可能有 <w:tab/>、<w:br/> 等，只保留可读文本 */
function flattenWtInner(raw) {
  let s = raw.replace(/<w:tab[^/]*\/>\s*/g, '\t');
  s = s.replace(/<w:br[^/]*\/>\s*/g, '\n');
  s = s.replace(/<[^>]+>/g, '');
  return decodeEntities(s);
}

const parts = [];
let m;
while ((m = re.exec(xml)) !== null) {
  const raw = m[1] !== undefined ? m[1] : m[2];
  if (!raw) continue;
  parts.push(flattenWtInner(raw));
}
const text = parts.join('');
fs.writeFileSync(outPath, text, 'utf8');
console.log('segments', parts.length, 'chars', text.length);
