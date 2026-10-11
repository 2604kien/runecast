// Raster inspection only; editable SVG files remain authoritative.
const fs = require('fs');
const path = require('path');
const sharp = require('C:/Users/nguye/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root = __dirname;
const output = path.join(root,'inspection_rasters');
fs.mkdirSync(output,{recursive:true});
(async () => {
  for (const size of [24,32,48,72,128,137]) {
    for(const name of ['spark','spark-monochrome','temporary-marker']) {
      await sharp(path.join(root,name+'.svg'),{density:144}).resize(size,size).png().toFile(path.join(output,`${name}-${size}.png`));
    }
    for(let r=0;r<4;r++) {
      await sharp(path.join(root,'preview_geometry',`spark-ports-r${r}.svg`),{density:144}).resize(size,size).png().toFile(path.join(output,`ports-r${r}-${size}.png`));
    }
  }
  console.log('Rasterized authored SVG glyphs at24/32/48/72/128/137 and exact ports for inspection.');
})();
