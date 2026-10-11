import subprocess,json,time
from pathlib import Path
project=Path(r"Z:\process\godot-remake")
output=Path(r"Z:\process\scratch\effect_port_tests")
output.mkdir(parents=True,exist_ok=True)
suites=['duel','effects']+['effects'+str(i) for i in range(2,16)]+['battle_steps','ai_responses','ai_duel','board','board_effects','sword','janken','deck_editor','approximations','remaining_effect_ui','duel_presentation','discard_panel','native_battle','native_rules','native_targeting','native_coins','native_history','roll_animations']
results=[]
for name in suites:
 start=time.time()
 try:
  p=subprocess.run([r"Z:\godot\Godot_v4.7.1-stable_win64_console.exe",'--headless','--path',str(project),'-s','tests/test_'+name+'.gd'],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=90)
  text=p.stdout+p.stderr
  (output/(name+'.log')).write_text(text,encoding='utf-8')
  ok=p.returncode==0 and 'FAILED' not in text and 'Parse Error' not in text and 'SCRIPT ERROR' not in text
  summary=[l for l in text.splitlines() if 'tests:' in l or 'FAILED' in l or 'FAIL:' in l]
  result={'suite':name,'ok':ok,'exit':p.returncode,'seconds':round(time.time()-start,2),'summary':summary}
 except subprocess.TimeoutExpired:
  result={'suite':name,'ok':False,'timeout':True}
 results.append(result)
 print(json.dumps(result),flush=True)
(output/'results.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
raise SystemExit(0 if all(r['ok'] for r in results) else 1)
