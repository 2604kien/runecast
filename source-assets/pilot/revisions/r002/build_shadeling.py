"""Separate the reference-guided r002 painting; reuse the isolated motion study."""
from pathlib import Path
import hashlib, json

P = Path(__file__).resolve().parent
root = P.parents[3]
old = root / 'source-assets/pilot/shadeling/assemble_shadeling.py'
code = old.read_text(encoding='utf-8')
code = code.replace("PILOT = HERE.parent\nROOT = PILOT.parent.parent", "PILOT = HERE\nROOT = HERE.parents[3]")
code = code.replace("ROOT / 'output/art/rc-011'", "ROOT / 'output/art/rc-011/r002'")
code = code.replace("raw/neutral-generation.png", "raw/shadeling.png").replace("raw/neutral.prompt.txt", "raw/shadeling.prompt.txt")
start = code.index('polys = {')
end = code.index('\ndef pmask', start)
code = code[:start] + '''polys = {
 'lantern': [(134,348),(193,344),(189,385),(245,333),(282,323),(311,353),(300,399),(293,448),(334,473),(338,522),(328,564),(335,649),(356,681),(337,714),(317,735),(274,754),(197,743),(143,712),(123,685),(128,650),(142,510),(125,499),(112,574),(96,568),(105,476)],
 'lantern_arm': [(147,252),(232,227),(273,236),(315,280),(381,304),(425,284),(470,300),(510,340),(526,401),(500,470),(461,483),(424,521),(392,579),(361,604),(329,575),(292,459),(286,409),(244,381),(180,381),(142,343)],
 'glass': [(154,521),(170,516),(166,637),(147,646)],
 'glass_main': [(176,517),(290,506),(310,650),(171,665)],
 'shoulder_underlap': [(432,295),(479,306),(510,341),(524,399),(502,463),(462,479),(440,424)],
}
''' + code[end:]
code = code.replace('scale=720/(1190-54)', 'scale=720/(1176-83)').replace('origin=(716.0,1188.0)', 'origin=(695.0,1175.0)')
code = code.replace("'#242233'", "'#32243c'")
code = code.replace('RC-011 Shadeling r001', 'RC-011 Shadeling r002')
code = code.replace("'revision':'r001'", "'revision':'r002'")
for a,b in [('(685,651)','(642,660)'),('(615,307)','(598,290)'),('(304,432)','(247,352)'),('(546,468)','(474,352)'),('(287,459)','(265,354)'),('(293,727)','(240,605)')]:
    code = code.replace(a,b)
code = code.replace('[.42,.46,.48]', '[.46,.62,.66]').replace('b=s==.46','b=s==.66')
code = code.replace('Same ground datum; center proposal 0.46. Arena reference 680 x 300, foot (340,233).', 'Reference comparison requires larger art: 0.62–0.66. Foot anchor remains (256,448).')
code = code.replace('output/art/rc-011/pilot-', 'output/art/rc-011/r002/pilot-')
# Persist the exact resulting editable assembly source for repeatable provenance.
(P/'assemble_shadeling.py').write_text(code, encoding='utf-8')
exec(compile(code, str(P/'assemble_shadeling.py'), 'exec'), {'__file__':str(P/'assemble_shadeling.py'), '__name__':'__main__'})
mp = P/'metadata.json'
m = json.loads(mp.read_text())
m['generation']['referenced_image_paths'] = ['output/imagegen/approved/combat.png']
m['generation']['reference_sha256'] = hashlib.sha256((root/'output/imagegen/approved/combat.png').read_bytes()).hexdigest()
m['generation']['original_tool_output'] = 'C:/Users/nguye/.codex/generated_images/01a125b7-21db-7683-ac68-ba49d0b1e8d3/exec-0fa585a0-7d90-47df-94e9-ebd961c5df2b.png'
m['review_status'] = 'r002 correction candidate; r001 visual pass withdrawn; no owner acceptance or exact-match claim'
m['display_scale'] = {'r001':0.46,'r002_comparison':0.64,'reason':'Reference character is substantially more prominent; canvas and foot anchor retained.'}
mp.write_text(json.dumps(m,indent=2)+'\n', encoding='utf-8')
