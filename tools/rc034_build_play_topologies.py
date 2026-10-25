"""Build excluded legal circuit witnesses for the RC-034 ordinary-resource player.

Enumerates simple paths and single Split/Join diamonds on the unchanged 4x4
board. This is verification search, never shipped gameplay or seed rerolling.
"""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
NEIGHBORS = [[n for n in (c-4 if c >= 4 else -1, c+1 if c%4<3 else -1,
                         c+4 if c<12 else -1, c-1 if c%4 else -1) if n>=0] for c in range(16)]
def direction(a,b):
    return {-4:0,1:1,4:2,-1:3}[b-a]
def paths(start,end):
    result=[]
    def walk(path,mask):
        if path[-1]==end:
            result.append(tuple(path)); return
        for n in NEIGHBORS[path[-1]]:
            if not mask & (1<<n): walk(path+[n],mask|(1<<n))
    walk([start],1<<start)
    return result
def build(start,end):
    found={}
    options=paths(start,end)
    def add(first,second=None):
        edges={}
        for path in (first,) if second is None else (first,second):
            for a,b in zip(path,path[1:]):
                edges.setdefault(a,set()).add(b); edges.setdefault(b,set()).add(a)
        if len(edges[start])!=1 or len(edges[end])!=1: return
        split=join=-1
        if second is not None:
            k=0
            while first[k]==second[k]: k+=1
            split=first[k-1]
            j=-1
            while first[j]==second[j]: j-=1
            join=first[j+1]
            if set(first[k:j+1 or None]) & set(second[k:j+1 or None]): return
        pieces=[]; slots=[]; corners=0
        prefix=set(first[:first.index(split)]) if split>=0 else set()
        for cell,ns in sorted(edges.items()):
            ports=sorted(direction(cell,n) for n in ns)
            if cell==start: kind='begin'
            elif cell==end: kind='end'
            elif cell==split: kind='split'
            elif cell==join: kind='join'
            elif len(ports)!=2: return
            elif (ports[0]+2)%4==ports[1]:
                kind='straight'; slots.append([cell,2 if cell in prefix else 1])
            else: kind='corner'; corners+=1
            pieces.append({'cell':cell,'kind':kind,'ports':ports})
        if corners>4: return
        doubled=sum(m==2 for _,m in slots)
        key=(corners,len(slots)-doubled,doubled,int(second is not None))
        found.setdefault(key,{'pieces':pieces,'slots':slots,'corners':corners,'splits':int(second is not None)})
    for p in options: add(p)
    for i,p in enumerate(options):
        for q in options[i+1:]: add(p,q)
    return list(found.values())
if __name__=='__main__':
    result={}
    for start in range(16):
        for end in range(16):
            if start!=end: result[f'{start}:{end}']=build(start,end)
        print(f'Built start {start}',flush=True)
    target=ROOT/'tests/fixtures/rc034/play-topologies.json'
    target.parent.mkdir(parents=True,exist_ok=True)
    target.write_text(json.dumps(result,separators=(',',':'))+'\n')
    print(f'{sum(map(len,result.values()))} topology witnesses; {target.stat().st_size} bytes')
