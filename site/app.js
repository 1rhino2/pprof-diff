function formatBytes(n) {
  if (n === 0) return '0 B';
  const sign = n < 0 ? '-' : '+';
  let v = Math.abs(n);
  const units = ['B', 'KiB', 'MiB', 'GiB'];
  let u = 0;
  while (v >= 1024 && u < units.length - 1) {
    v /= 1024;
    u += 1;
  }
  if (u === 0) return sign + v + ' ' + units[0];
  return sign + v.toFixed(1) + ' ' + units[u];
}

function formatCount(n) {
  if (n > 0) return '+' + n;
  if (n < 0) return String(n);
  return '0';
}

function rowHtml(d, i) {
  const bc = d.d_bytes >= 0 ? 'pos' : 'neg';
  const oc = d.d_objects >= 0 ? 'pos' : 'neg';
  return `<tr>
    <td>${i + 1}</td>
    <td class="key">${escapeHtml(d.key)}</td>
    <td class="num ${bc}">${formatBytes(d.d_bytes)}</td>
    <td class="num ${oc}">${formatCount(d.d_objects)}</td>
  </tr>`;
}

function escapeHtml(s) {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function section(title, rows) {
  let body;
  if (!rows || rows.length === 0) {
    body = '<div class="empty">(none)</div>';
  } else {
    body = `<table>
      <thead><tr>
        <th>#</th><th>Key</th><th>Delta bytes</th><th>Delta objs</th>
      </tr></thead>
      <tbody>${rows.map((r, i) => rowHtml(r, i)).join('')}</tbody>
    </table>`;
  }
  return `<section class="panel"><h2>${escapeHtml(title)}</h2>${body}</section>`;
}

function render(data) {
  const root = document.getElementById('report');
  root.innerHTML =
    section('Grew', data.grew) +
    section('Shrank', data.shrank) +
    section('Vanished', data.vanished) +
    section('Appeared', data.appeared);
}

async function loadDemo() {
  const res = await fetch('demo.json');
  if (!res.ok) throw new Error('demo.json missing');
  render(await res.json());
}

function loadFile(file) {
  const reader = new FileReader();
  reader.onload = () => {
    try {
      render(JSON.parse(reader.result));
    } catch (e) {
      alert('Invalid JSON: ' + e.message);
    }
  };
  reader.readAsText(file);
}

document.getElementById('demo-btn').addEventListener('click', () => {
  loadDemo().catch((e) => alert(e.message));
});

document.getElementById('json-file').addEventListener('change', (ev) => {
  const f = ev.target.files[0];
  if (f) loadFile(f);
});

loadDemo().catch(() => {
  document.getElementById('report').innerHTML =
    '<div class="empty">Load demo.json failed. Use the file picker with output from pprof-diff --json.</div>';
});
