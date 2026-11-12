#!/usr/bin/env python3
import json, os, subprocess, urllib.request, urllib.error
from pathlib import Path
API='https://api.deepseek.com/chat/completions'
def run(*a): return subprocess.check_output(a,text=True,stderr=subprocess.STDOUT)
def context():
 paths=run('git','ls-files').splitlines(); priority=('scripts/blender/','scenes/ships/','scenes/combat/','scripts/combat/','scripts/flight/','tests/','.github/workflows/','docs/','project.godot','README.md'); paths.sort(key=lambda p:(not any(p.startswith(x) or p==x for x in priority),p)); out=[]; used=0
 for p in paths:
  name=Path(p).name.lower()
  if any(x in p for x in ('.git/','.godot/','build/','assets/','.png','.glb','.blend','.fbx','.zip','.exe','.pck')) or name.startswith('.env') or any(x in name for x in ('secret','credential','token','id_rsa','keystore')) or name.endswith(('.pem','.key','.p12','.pfx')) or not Path(p).is_file(): continue
  try: s=Path(p).read_text(encoding='utf-8')
  except (UnicodeDecodeError,OSError): continue
  block='\n\n===== FILE: '+p+' =====\n'+s[:18000]
  if used+len(block)>180000: continue
  out.append(block); used+=len(block)
 return ''.join(out)
def main():
 key=os.environ.get('DEEPSEEK_API_KEY'); task=Path(os.environ.get('DEEPSEEK_TASK_FILE','docs/deepseek/MISSION_01_FLEET.md'))
 if not key: raise SystemExit('Missing DEEPSEEK_API_KEY repository secret')
 prompt='You are a senior Godot and Blender engineer. Return only a git-apply-compatible unified diff. No markdown fences, no binary files, no secrets or repository security changes.\n\nMISSION:\n'+task.read_text(encoding='utf-8')+'\n\nREPOSITORY CONTEXT:\n'+context()
 body={'model':os.environ.get('DEEPSEEK_MODEL','deepseek-flash'),'messages':[{'role':'system','content':'Implement the mission as a safe complete patch.'},{'role':'user','content':prompt}],'thinking':{'type':'enabled'},'reasoning_effort':'high','stream':False,'max_tokens':24000}
 req=urllib.request.Request(API,data=json.dumps(body).encode(),headers={'Authorization':'Bearer '+key,'Content-Type':'application/json'},method='POST')
 try:
  with urllib.request.urlopen(req,timeout=900) as r: data=json.loads(r.read().decode())
 except urllib.error.HTTPError as e: raise SystemExit('DeepSeek HTTP '+str(e.code)+': '+e.read().decode('utf-8','replace')[:2500])
 answer=data['choices'][0]['message'].get('content') or ''
 if answer.startswith('```'): answer=answer.split('\n',1)[-1].rsplit('```',1)[0]
 if 'diff --git ' not in answer: raise SystemExit('No unified diff returned; nothing changed')
 Path('/tmp/deepseek.patch').write_text(answer[answer.index('diff --git '):],encoding='utf-8')
 subprocess.run(['git','apply','--check','/tmp/deepseek.patch'],check=True); subprocess.run(['git','apply','--whitespace=nowarn','/tmp/deepseek.patch'],check=True)
 print('DEEPSEEK_PATCH_APPLIED'); print('MODEL:',data.get('model')); print('USAGE:',json.dumps(data.get('usage',{}))); print(run('git','diff','--name-only'))
if __name__=='__main__': main()
