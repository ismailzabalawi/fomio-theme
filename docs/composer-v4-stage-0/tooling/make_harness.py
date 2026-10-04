import csv,sys,os,json
B=sys.argv[1]
VP={"390x844":"phone","360x740":"narrow","375x834":"splitNarrow","600x834":"split600","834x1194":"tabletP","1194x834":"tabletL","1280x800":"desktop"}
# preset per shot (review frame -> preset/route mapping from 06 Composer ROWS)
PRE={"M1":"M1","M2":"M2","M3":"M3","C05":"C05","C09":"C09","TAB-9":"C03","C07-4":"C07-4","C07-6":"C07-6","C10-2":"C10-2","C10-4":"C10-4","C06-3":"C06-3","C06-4":"C06-4","C06-6":"C06-6","C06-7":"C06-7","C08-1":"C08-1","C08-4":"C08-4","C08-8":"C08-8","C08-10":"C08-10","C12-1":"C12-1","C12-4":"C12-4","C12-5":"C12-5","C15-1":"C15-1","C15-3":"C15-3","C13-4":"C13-4","C19-3":"C19-3","C19-4":"C19-4","C16-1":"C16-1","C16-4":"C16-4","C17":"C17","C18-4":"C18-4","TAB-1":"M2","TAB-3":"M2","TAB-4":"M3","TAB-5":"M2","TAB-6":"M2","TAB-8":"C08-1","D-1":"C01","C11":"C11","A-1":"C04","A-4-D":"R1","A-5":"L1","M5":"M5"}
rows=list(csv.DictReader(open(B+"/composer-v4-screenshot-plan.csv")))
out=[]
for r in rows:
    fr=r["frame_or_route"]; key=fr.split(" ")[0]
    if r["shot_id"]=="S07": preset="C06-3"
    elif r["shot_id"]=="S41": preset="C12-4"
    else: preset=PRE[key]
    mods=r["modifiers"]
    p=dict(viewport=VP[r["size"]],scheme=r["scheme"],preset=preset,rtl="rtl" in mods,hwkb="hwkb" in mods,zoom="1.5" if "1.5" in mods else "1",rm=False)
    w,h=r["size"].split("x")
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
  renderVals() {{ return {json.dumps(dict(vp=p["viewport"],scheme=p["scheme"],preset=preset,rtl=p["rtl"],hw=p["hwkb"],zoom=p["zoom"],rm=False))}; }}
}}
</script>
</body>
</html>
'''
    fn=f"_shot_{r['shot_id']}.dc.html"
    open(f"{B}/render/mockups/{fn}","w").write(html)
    out.append((r["shot_id"],fn,w,h,r["filename"],json.dumps(p)))
json.dump(out,open(B+"/render/shots.json","w"),indent=0)
print(len(out))
