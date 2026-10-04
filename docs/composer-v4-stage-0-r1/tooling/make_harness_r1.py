import csv,sys,json
R=sys.argv[1]; out_dir=sys.argv[2]
VP={"390x844":"phone","360x740":"narrow","375x834":"splitNarrow","600x834":"split600","834x1194":"tabletP","1194x834":"tabletL","1280x800":"desktop"}
out=[]
for r in csv.DictReader(open(R+"/screenshot-plan-r1.csv")):
    m=r["modifiers"]; w,h=r["size"].split("x")
    vals=dict(vp=VP[r["size"]],scheme=r["scheme"],preset=r["preset"],rtl="rtl" in m,hw="hwkb" in m,zoom="1.5" if "1.5" in m else "1",rm=False)
    html=f'''<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link rel="stylesheet" href="../styles.css">
<style>html,body{{margin:0;padding:0;background:#E9E8EE;overflow:hidden}}</style>
</helmet>
<dc-import name="FmComposer4" viewport="{{{{ vp }}}}" scheme="{{{{ scheme }}}}" preset="{{{{ preset }}}}" rtl="{{{{ rtl }}}}" hwkb="{{{{ hw }}}}" zoom="{{{{ zoom }}}}" reduced-motion="{{{{ rm }}}}" hint-size="{w}px,{h}px"></dc-import>
</x-dc>
<script type="text/x-dc" data-dc-script>
class Component extends DCLogic {{
  renderVals() {{ return {json.dumps(vals)}; }}
}}
</script>
</body>
</html>
'''
    fn=f"_shot_{r['shot_id']}.dc.html"; open(f"{out_dir}/mockups/{fn}","w").write(html)
    out.append((r["shot_id"],fn,w,h,r["filename"],json.dumps(vals)))
json.dump(out,open(out_dir+"/shots.json","w"),indent=0); print(len(out))
