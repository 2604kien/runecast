"""Record only observed image-generation inputs and retained output hashes."""
from pathlib import Path
import hashlib,json
P=Path(__file__).resolve().parent
R=P.parents[3]
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
record={
 'asset':'home_tower','task':'RC-015','date':'2026-10-13',
 'tool':'built-in image_gen.imagegen','model':None,'model_version':None,'seed':None,
 'unknown_fields':'Tool did not expose model/version or seed. No invented values.',
 'reference_approval':'The supplied Home reference is owner-approved. These new reconstructed paintings are reference_guided, not independently owner-approved.',
 'rights_status':'unresolved; retained generation records do not establish shipping rights clearance',
 'source_audit':'No clean Home/tower production artwork was retained under source-assets or output/imagegen. Approved Home is a flattened reference with UI. Selected r004 pilot paint is Combat/crypt/UI, not a reusable Home painting. October13 cleanup does not establish a missing required Home source.',
 'generations':[
  {'id':'home-clean','purpose':'Fresh clean original Home illustration using the approved reference for visual direction; no reference screenshot crops used as production pixels','use_case':'stylized-concept','prompt':'home-clean.prompt.txt','inputs':[{'path':'output/imagegen/approved/home.png','sha256':sha(R/'output/imagegen/approved/home.png'),'role':'style/composition reference only'}],'output':'home-clean.png','sha256':sha(P/'home-clean.png'),'dimensions':[841,1870],'transparent_background':False,'original_tool_path':'C:/Users/nguye/.codex/generated_images/01a1305a-91f6-7ad2-9eb9-7a60c503a13d/exec-f918be78-9300-4d98-afdb-cccfb194c8d0.png','selected':False,'reason':'Moon/top framing did not survive the required short9:16 center cover; retained as immediate edit input'},
  {'id':'home-framed','purpose':'Targeted downward composition correction to protect moon/tower in9:16 cover','use_case':'precise-object-edit','prompt':'home-reframe.prompt.txt','inputs':[{'path':'home-clean.png','sha256':sha(P/'home-clean.png'),'role':'edit target'}],'output':'home-framed.png','sha256':sha(P/'home-framed.png'),'dimensions':[841,1870],'transparent_background':False,'original_tool_path':'C:/Users/nguye/.codex/generated_images/01a1305a-91f6-7ad2-9eb9-7a60c503a13d/exec-ef4b7422-fc51-4648-8d6a-804515dc549f.png','selected':True,'reason':'Complete moon disc and tower survive all three required center-cover crops'}
 ],
 'subsequent_authoring':'Pillow/NumPy under the user-requested asset production/export scope: aspect-preserving center cover to1440×3200; explicitly editable semantic region masks; eight-layer OpenRaster packaging; separate adjustable quiet-control tone; opaque720×1600 runtime export. No new typography, wordmark or UI was painted.',
 'brush_history':'Generated brushwork is flattened within semantic paint regions. Source provides regional repaint/recolour editability, not arbitrary object relocation or brush stroke history.',
 'retained_approved_references_unchanged':True,
 'approval_claim':False,'device_test_claim':False
}
(P/'generation-record.json').write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8')
print('Recorded2 built-in generations; observed inputs/output hashes, unknown model and seed.')
