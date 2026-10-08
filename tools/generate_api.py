from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'src'
DOCS = ROOT / 'website' / 'docs' / 'api'
NAV = ROOT / 'website' / 'docs' / 'api' / 'SUMMARY.md'
PATTERN = re.compile(r'^---\s*@([\w]+)(?:\s+(.*))?$')
LINK = re.compile(r'\b(tad(?:\.[A-Za-z_]\w*)+)\b')

def parse(path):
    entries, block = [], []
    for line in path.read_text(encoding='utf-8').splitlines() + ['']:
        if line.startswith('---'):
            block.append(line)
        elif block:
            entry = {'params': [], 'returns': [], 'fields': [], 'example': []}
            example = False
            for comment in block:
                m = PATTERN.match(comment)
                if m:
                    tag, val = m.group(1), (m.group(2) or '').strip()
                    if tag in ('function', 'method', 'class', 'module'):
                        entry['kind'], entry['name'] = tag, val
                    elif tag in ('summary', 'description'):
                        entry[tag] = val
                    elif tag == 'param':
                        p = val.split(' ', 2)
                        if len(p) == 3: entry['params'].append(p)
                    elif tag == 'return':
                        p = val.split(' ', 2)
                        if len(p) == 3:
                            entry['returns'].append(tuple(p))
                        elif len(p) == 2:
                            entry['returns'].append(('', p[0], p[1]))
                        elif p:
                            entry['returns'].append(('', p[0], ''))
                    elif tag == 'field':
                        p = val.split(' ', 2)
                        if len(p) == 3: entry['fields'].append(p)
                    elif tag == 'example':
                        example = True
                elif example:
                    entry['example'].append(comment[4:] if comment.startswith('--- ') else '')
            if 'kind' in entry:
                entry['signature'] = line.strip() if line.lstrip().startswith('function ') else None
                entries.append(entry)
            block = []
    return entries

def url_path(entry):
    parts = entry['name'].replace(':', '.').split('.')
    if entry['kind'] == 'module': return Path(*parts[1:]) / 'index.md'
    if entry['kind'] == 'class': return Path(*parts[1:]) / 'index.md'
    if entry['kind'] == 'method': return Path(*parts[1:]).with_suffix('.md')
    return Path(*parts[1:]).with_suffix('.md')

def overview_tables(entry, known):
    """Build linked member tables from the documented public API."""
    name = entry['name']
    sections = []
    if entry['kind'] == 'module':
        groups = [('Functions', 'function', lambda e: e['name'].rsplit('.', 1)[0] == name),
                  ('Classes', 'class', lambda e: e['name'].rsplit('.', 1)[0] == name)]
    elif entry['kind'] == 'class':
        groups = [('Methods', 'method', lambda e: e['name'].rsplit(':', 1)[0] == name)]
    else:
        return sections
    for heading, kind, belongs in groups:
        members = sorted((e for e in known.values() if e['kind'] == kind and belongs(e)), key=lambda e: e['name'].lower())
        sections += [f'## {heading}', '', f'| {"Class" if heading == "Classes" else heading[:-1]} | Description |', '| --- | --- |']
        for member in members:
            short = member['name'].split(':')[-1].split('.')[-1]
            desc = member.get('summary', '').replace('|', r'\|').replace('\n', ' ')
            sections.append(f'| [`{short}`]({relative_link(entry, member)}) | {desc} |')
        if not members:
            sections.append('| — | None documented. |')
        sections.append('')
    return sections

def syntax(entry):
    """Build a public-facing call signature from documented names and parameters."""
    public = entry['name']
    if entry['kind'] == 'method':
        public = 'source:' + public.rsplit(':', 1)[-1]
    args = ', '.join(param[0] for param in entry['params'])
    call = f'{public}({args})'
    returns = [name for name, typ, _ in entry['returns'] if typ != 'nil']
    if returns:
        names = [name or f'result{i + 1}' for i, name in enumerate(returns)]
        return f'{", ".join(names)} = {call}'
    return call


def render(entry, known):
    name = entry['name']
    def linked(value):
        return LINK.sub(lambda m: f'[{m.group(0)}]({{}})' if False else (f'[`{m.group(0)}`]({relative_link(entry,known[m.group(0)])})' if m.group(0) in known and m.group(0)!=name else f'`{m.group(0)}`'), value)
    lines = [f'# {name}', '', entry.get('summary', ''), '']
    if entry.get('description'): lines += [entry['description'], '']
    lines += overview_tables(entry, known)
    if entry['kind'] in ('function','method'):
        lines += ['## Syntax', '', '```lua', syntax(entry), '```', '']
        lines += ['## Arguments', '']
        if entry['params']:
            lines += ['| Name | Type | Description |', '| --- | --- | --- |']
            lines += [f'| `{p}` | {linked(t)} | {d} |' for p,t,d in entry['params']]
        else: lines += ['None.']
        lines += ['', '## Returns', '']
        returns = [(n, t, d) for n, t, d in entry['returns'] if t != 'nil']
        if returns:
            lines += ['| Name | Type | Description |', '| --- | --- | --- |']
            lines += [f'| `{n or "result"}` | {linked(t)} | {d} |' for n, t, d in returns]
        else:
            lines += ['Nothing.']
    if entry['fields']:
        lines += ['', '## Fields', '', '| Name | Type | Description |', '| --- | --- | --- |']
        lines += [f'| `{p}` | {linked(t)} | {d} |' for p,t,d in entry['fields']]
    if entry['example']:
        lines += ['', '## Example', '', '```lua', *entry['example'], '```']
    return '\n'.join(lines).rstrip()+'\n'

def relative_link(src, target):
    import os
    from pathlib import PurePosixPath
    src_dir = url_path(src).parent
    target_path = url_path(target)
    return os.path.relpath(str(target_path), str(src_dir)).replace('\\','/')

def main():
    entries = [e for path in sorted(SOURCE.rglob('*.lua')) for e in parse(path)]
    entries.sort(key=lambda e: e['name'].lower())
    known = {e['name']: e for e in entries}
    for e in entries:
        path = DOCS / url_path(e)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(render(e, known), encoding='utf-8')
    # literate-nav plugin consumes SUMMARY.md; nested entries produce nested sidebar groups.
    modules = [e for e in entries if e['kind']=='module']
    nav = ['# API Reference', '']
    for module in modules:
        name = module['name']
        nav += [f'- [{name}]({url_path(module).as_posix()})']
        functions = [e for e in entries if e['kind']=='function' and e['name'].startswith(name+'.')]
        classes = [e for e in entries if e['kind']=='class' and e['name'].startswith(name+'.')]
        if functions:
            nav += [f'    - [Functions]({url_path(module).as_posix()})']
            nav += [f'        - [{e["name"].split(".")[-1]}]({url_path(e).as_posix()})' for e in functions]
        if classes:
            nav += [f'    - [Classes]({url_path(module).as_posix()})']
            for c in classes:
                nav += [f'        - [{c["name"].split(".")[-1]}]({url_path(c).as_posix()})']
                methods = [e for e in entries if e['kind']=='method' and e['name'].startswith(c['name']+':')]
                nav += [f'            - [{e["name"].split(":")[-1]}]({url_path(e).as_posix()})' for e in methods]
    NAV.write_text('\n'.join(nav)+'\n',encoding='utf-8')
    print(f'Generated {len(entries)} pages and {NAV}')

if __name__ == '__main__': main()
