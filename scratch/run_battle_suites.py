import json, subprocess
from pathlib import Path
root=Path('Z:/process/godot-remake')
results=[]
for i,p in enumerate(sorted((root/'tests').glob('test_*.gd')),1):
    try:
        r=subprocess.run(['Z:/godot/Godot_v4.7.1-stable_win64_console.exe','--headless','--path',str(root),'-s',str(p)],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=75)
        out=r.stdout+r.stderr
        ok=r.returncode==0 and 'FAIL' not in out and 'SCRIPT ERROR' not in out
    except subprocess.TimeoutExpired as e:
        ok=False;out=str(e)
    results.append({'suite':p.name,'ok':ok,'output':out})
    if not ok or i%5==0: print(f'{i}: {p.name}: {"OK" if ok else "FAILED"}',flush=True)
Path('Z:/process/scratch/battle_suite_results.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
print(f'{sum(x["ok"] for x in results)}/{len(results)} suites passed',flush=True)
