const sharp=require('C:/Users/nguye/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const path=require('path');
(async()=>{for(const name of ['spark','spark-monochrome'])for(const n of [24,32,48,62,80,128])await sharp(path.join(__dirname,name+'.svg'),{density:288}).resize(n,n).png().toFile(path.join(__dirname,name+'-'+n+'.png'));})();