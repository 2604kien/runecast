"""Apply the owner's Store/shop-room distinction to existing shared asset mappings."""
import csv
from pathlib import Path

root = Path(__file__).resolve().parents[1]
path = root / 'docs/asset-consumers.csv'
with path.open(encoding='utf-8-sig', newline='') as f:
    reader = csv.DictReader(f)
    fields = reader.fieldnames
    rows = list(reader)
assets = ['ui_frames','button_frames','rune_frames','ui_state_overlays','ui_dialog_scrim','ui_theme','font_ui','font_display']
for row in rows:
    if row['consumer_id'] == 'screen_menu':
        row['required_states'] = 'turquoise_Resume;navy_Options;navy_Store;Store_unavailable_visual_sample;navy_Quit;quit_confirm_checkpoint_replay'
        row['notes'] = 'October12 owner clarification: Menu Store is a separate item-purchase destination, not gated by shop-room presence. RC-013 corrected isolated presentation; actual availability/purchase policy awaits RC-024A and implementation RC-029A/RC-032.'
    elif row['consumer_id'] == 'screen_shop':
        row['notes'] = 'Shop-room services occupy the main screen on room entry. This run-scoped screen is separate from the Menu Store; existing room Gold/services are not automatically Store purchase rules.'
    elif row['consumer_id'] == 'room_shop':
        row['notes'] = 'Entering this route room opens screen_shop as the main screen; the Menu Store opens a separate destination.'
if not any(row['consumer_id'] == 'screen_store' for row in rows):
    rows.append(dict(zip(fields, ['screen_store','screen',';'.join(assets),'menu_entry;separate_from_shop_room;catalog_and_purchase_rules_pending','RC-024A;RC-029A;RC-032','RC-042','Planned separate Store for in-game runes perks and relics. Shared UI assets already exist; Store catalog, currency, purchase persistence and availability remain undecided. No implemented Store or new content art is implied.'])))
with path.open('w',encoding='utf-8',newline='') as f:
    writer=csv.DictWriter(f,fieldnames=fields,quoting=csv.QUOTE_ALL)
    writer.writeheader()
    writer.writerows(rows)

path=root/'docs/asset-inventory.csv'
with path.open(encoding='utf-8-sig',newline='') as f:
    reader=csv.DictReader(f)
    fields=reader.fieldnames
    rows=list(reader)
for row in rows:
    if row['id'] not in assets: continue
    # Preserve all_screens shorthand; otherwise record the explicit planned consumer.
    for field in ['consumer_ids','consumers']:
        if field in row and row[field]!='all_screens' and 'screen_store' not in row[field].split(';'):
            row[field]+=';screen_store'
    if row['id']=='ui_theme' and 'October12 corrected Menu label Store' not in row['notes']:
        row['notes']+=' October12 corrected Menu label Store and removed shop-room availability coupling; original renders remain historical, corrected evidence in output/art/rc-013/store-clarification/.'
with path.open('w',encoding='utf-8',newline='') as f:
    writer=csv.DictWriter(f,fieldnames=fields,quoting=csv.QUOTE_ALL)
    writer.writeheader()
    writer.writerows(rows)
