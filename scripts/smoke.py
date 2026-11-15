#!/usr/bin/env python3
"""Authenticated native ingestion + SQL + persisted segments, never reseeded later."""
import base64,hashlib,json,os,pathlib,secrets,time,urllib.request,urllib.error
b=os.environ['BASE_URL'].rstrip('/');phase=os.environ['SMOKE_PHASE'];assert phase in ('boot','upgrade','redeploy')
p=pathlib.Path(__file__).with_name('state-'+hashlib.sha256(b.encode()).hexdigest()[:16]+'.json');password=os.environ['DRUID_ADMIN_PASSWORD']
def req(path,body=None,password=password,expected=(200,)):
 h={'Authorization':'Basic '+base64.b64encode(('admin:'+password).encode()).decode(),'Content-Type':'application/json'}
 q=urllib.request.Request(b+path,headers=h,data=None if body is None else json.dumps(body).encode())
 try:r=urllib.request.urlopen(q,timeout=60)
 except urllib.error.HTTPError as e:r=e
 with r:status=r.code;raw=r.read()
 assert status in expected,f'{path} unexpected status {status}'
 # Authentication failures are HTML, not JSON; status above is the negative assertion.
 return json.loads(raw) if raw and status==200 else None
assert req('/status/health') is True
req('/druid/v2/sql',{'query':'SELECT 1'},password='wrong-'+password,expected=(401,403))
if p.exists():s=json.loads(p.read_text())
else:
 assert phase=='boot','missing boot seed; refusing to recreate ingested data'
 marker='railway_'+secrets.token_hex(8);row={'timestamp':'2026-11-15T12:00:00Z','marker':marker,'value':'42'}
 spec={'type':'index_parallel','spec':{'dataSchema':{'dataSource':marker,'timestampSpec':{'column':'timestamp','format':'iso'},'dimensionsSpec':{'dimensions':['marker','value']},'granularitySpec':{'type':'uniform','segmentGranularity':'DAY','queryGranularity':'NONE','rollup':False}},'ioConfig':{'type':'index_parallel','inputSource':{'type':'inline','data':json.dumps(row)+'\n'},'inputFormat':{'type':'json'},'appendToExisting':False},'tuningConfig':{'type':'index_parallel','maxNumConcurrentSubTasks':1}}}
 task=req('/druid/indexer/v1/task',spec)['task'];s={'marker':marker,'task':task}
 p.write_text(json.dumps(s));p.chmod(0o600)
 if phase=='boot':
  end=time.monotonic()+480
  while time.monotonic()<end:
   status=req('/druid/indexer/v1/task/'+task+'/status')['status']['status']
   if status=='SUCCESS':break
   assert status!='FAILED','native ingestion task failed'
   time.sleep(5)
  else:raise AssertionError('native ingestion deadline exceeded')
end=time.monotonic()+180
while time.monotonic()<end:
 try:
  rows=req('/druid/v2/sql',{'query':'SELECT "marker", "value" FROM "'+s['marker']+'"'})
  if any(x.get('marker')==s['marker'] and str(x.get('value'))=='42' for x in rows):break
 except (AssertionError,urllib.error.URLError):pass
 time.sleep(5)
else:raise AssertionError('boot-created Druid segment missing through SQL')
print(json.dumps({'ok':True,'phase':phase,'native_ingestion_and_sql':True,'persisted_segment_verified':True}))
