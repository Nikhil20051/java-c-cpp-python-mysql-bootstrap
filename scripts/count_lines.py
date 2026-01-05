import os
import datetime
import math
import re

# Configuration
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
output_file = os.path.join(project_root, "docs", "PROJECT_STATS.md")

# Extension Mapping & Comment Config
# Format: '.ext': {'lang': 'Name', 'comment_single': '//', 'comment_multi_start': '/*', 'comment_multi_end': '*/'}
LANG_CONFIG = {
    # C-Style
    '.c': {'lang': 'C', 'vals': ['//'], 'block': ('/*', '*/')},
    '.cpp': {'lang': 'C++', 'vals': ['//'], 'block': ('/*', '*/')},
    '.h': {'lang': 'C/C++ Header', 'vals': ['//'], 'block': ('/*', '*/')},
    '.hpp': {'lang': 'C++ Header', 'vals': ['//'], 'block': ('/*', '*/')},
    '.java': {'lang': 'Java', 'vals': ['//'], 'block': ('/*', '*/')},
    '.js': {'lang': 'JavaScript', 'vals': ['//'], 'block': ('/*', '*/')},
    '.ts': {'lang': 'TypeScript', 'vals': ['//'], 'block': ('/*', '*/')},
    '.css': {'lang': 'CSS', 'vals': [], 'block': ('/*', '*/')},
    # Hash-Style
    '.py': {'lang': 'Python', 'vals': ['#'], 'block': ('"""', '"""')},
    '.ps1': {'lang': 'PowerShell', 'vals': ['#'], 'block': ('<#', '#>')},
    '.sh': {'lang': 'Shell', 'vals': ['#'], 'block': None},
    '.yml': {'lang': 'YAML', 'vals': ['#'], 'block': None},
    '.yaml': {'lang': 'YAML', 'vals': ['#'], 'block': None},
    # Sql
    '.sql': {'lang': 'SQL', 'vals': ['--'], 'block': ('/*', '*/')},
    # Markup
    '.html': {'lang': 'HTML', 'vals': [], 'block': ('<!--', '-->')},
    '.md': {'lang': 'Markdown', 'vals': [], 'block': ('<!--', '-->')},
    '.json': {'lang': 'JSON', 'vals': [], 'block': None},
    '.xml': {'lang': 'XML', 'vals': [], 'block': ('<!--', '-->')},
    '.bat': {'lang': 'Batch', 'vals': ['REM', '::'], 'block': None},
    '.txt': {'lang': 'Text', 'vals': [], 'block': None}
}

IGNORED_DIRS = {
    '.git', '.vs', '.idea', '__pycache__', 'node_modules', 'bin', 'obj', 'lib', 
    'build', 'dist', '.target', '.gradle', 'cmake-build-debug', '.credentials-backup', '.update-backup'
}

def analyze_file_content(filepath, config):
    stats = {'lines': 0, 'code': 0, 'comments': 0, 'blanks': 0}
    
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            in_block = False
            for line in f:
                stats['lines'] += 1
                stripped = line.strip()
                
                if not stripped:
                    stats['blanks'] += 1
                    continue

                # Check block comments
                if config.get('block'):
                    start, end = config['block']
                    if in_block:
                        stats['comments'] += 1
                        if end in line:
                            in_block = False
                        continue
                    if start in line:
                        stats['comments'] += 1
                        if end not in line:
                            in_block = True
                        continue

                # Check single line comments
                is_comment = False
                for market in config.get('vals', []):
                    if stripped.startswith(market):
                        stats['comments'] += 1
                        is_comment = True
                        break
                
                if not is_comment:
                    stats['code'] += 1
                    
    except Exception:
        pass # Handle binary or read errors gracefully
        
    return stats

def get_fun_stats(total_lines, total_files):
    # Physical visualizations
    lines_per_page = 50
    pages = math.ceil(total_lines / lines_per_page)
    paper_thickness_mm = 0.1
    stack_height_mm = pages * paper_thickness_mm
    
    # Typing
    avg_wpm = 40
    words_per_line = 5
    typing_minutes = (total_lines * words_per_line) / avg_wpm
    
    return {
        "pages": pages,
        "stack_height_cm": round(stack_height_mm / 10, 2),
        "typing_hours": round(typing_minutes / 60, 1),
        "tree_impact": round(pages / 8333, 4) # very rough est: 1 tree = 8333 sheets
    }

def generate_mermaid_pie(lang_stats):
    chart = "```mermaid\npie title Language Distribution (Lines)\n"
    # Filter small langs for cleaner chart
    sorted_langs = sorted(lang_stats.items(), key=lambda x: x[1]['lines'], reverse=True)
    
    for lang, data in sorted_langs[:8]: # Top 8 only
        if data['lines'] > 0:
            chart += f'    "{lang}" : {data["lines"]}\n'
    chart += "```"
    return chart

def generate_mermaid_bar(top_files):
    chart = "```mermaid\nxychart-beta\n    title Top 5 Largest Files\n    x-axis [Files]\n    y-axis \"Lines\"\n    bar ["
    
    # Sanitize names slightly for chart
    names = []
    values = []
    for path, lines in top_files:
        name = os.path.basename(path)
        names.append(name)
        values.append(lines)
        
    chart += ", ".join([str(v) for v in values])
    chart += "]\n```"
    # Note: xy-chart is beta/less supported, fallback to simple bar if needed, 
    # but let's stick to standard markdown tables if mermaid fails, or use a simple gantt workaround?
    # standard mermaid 'gantt' isn't great. Let's use specific classDiagram text or just stick to the Pie chart which is reliable.
    # Actually, let's use a text-based bar chart for reliability alongside Mermaid Pie.
    return chart

def main():
    stats = {
        "total": {'lines': 0, 'code': 0, 'comments': 0, 'blanks': 0},
        "file_count": 0,
        "by_lang": {},
        "largest_files": [] 
    }

    print(f"Analyzing {project_root}...")

    for root, dirs, files in os.walk(project_root):
        dirs[:] = [d for d in dirs if d not in IGNORED_DIRS]
        
        for file in files:
            ext = os.path.splitext(file)[1].lower()
            if ext in LANG_CONFIG:
                config = LANG_CONFIG[ext]
                lang = config['lang']
                filepath = os.path.join(root, file)
                
                f_stats = analyze_file_content(filepath, config)
                
                # Totals
                for k in stats["total"]:
                    stats["total"][k] += f_stats[k]
                stats["file_count"] += 1
                
                # Per Lang
                if lang not in stats["by_lang"]:
                    stats["by_lang"][lang] = {'lines': 0, 'code': 0, 'files': 0}
                stats["by_lang"][lang]['lines'] += f_stats['lines']
                stats["by_lang"][lang]['code'] += f_stats['code']
                stats["by_lang"][lang]['files'] += 1
                
                # Largest
                rel_path = os.path.relpath(filepath, project_root)
                stats["largest_files"].append((rel_path, f_stats['lines']))

    stats["largest_files"].sort(key=lambda x: x[1], reverse=True)
    top_files = stats["largest_files"][:5]
    
    fun = get_fun_stats(stats["total"]['lines'], stats["file_count"])
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    # Generate Content
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    
    header = """# 📊 Project Statistics & Insights

> "Data beats opinion."

| Timestamp | Total Lines | Code vs Comments | 🌲 Paper Estimate |
|---|---|---|---|
"""
    
    # Calc ratios
    t_lines = stats['total']['lines']
    code_pct = (stats['total']['code'] / t_lines * 100) if t_lines else 0
    comm_pct = (stats['total']['comments'] / t_lines * 100) if t_lines else 0
    
    row = f"| {timestamp} | **{t_lines:,}** | {code_pct:.1f}% / {comm_pct:.1f}% | {fun['pages']:,} pages |\n"
    
    if not os.path.exists(output_file):
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(header)
            
    with open(output_file, 'a', encoding='utf-8') as f:
        f.write(row)
        
    details = f"""
<details>
<summary><strong>📈 Deep Dive: {timestamp} (Visuals included)</strong></summary>

### 🥧 Language Breakdown
{generate_mermaid_pie(stats['by_lang'])}

### 🏗️ Physical & Fun Metrics
| Metric | Value | Context |
|---|---|---|
| **Stack Height** | {fun['stack_height_cm']} cm | Height if printed on A4 paper |
| **Typing Time** | {fun['typing_hours']} hours | Pure typing time (no thinking!) at 40 WPM |
| **Tree Cost** | {fun['tree_impact']} trees | Environmental impact of printing this |
| **Avg File Size** | {int(t_lines / stats['file_count']) if stats['file_count'] else 0} lines | Complexity indicator |

### 🏆 Largest Files (The Monoliths)
| Rank | File | Lines |
|---|---|---|
"""
    for i, (name, lines) in enumerate(top_files, 1):
        details += f"| {i} | `{name}` | **{lines:,}** |\n"

    details += "\n</details>\n\n---\n"
    
    with open(output_file, 'a', encoding='utf-8') as f:
        f.write(details)

    print(f"Analysis complete. Charts generated in {output_file}")

if __name__ == "__main__":
    main()
