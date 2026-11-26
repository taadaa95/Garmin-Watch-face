from pathlib import Path
import argparse, math, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
ROOT=Path(__file__).resolve().parents[1]; OUT=ROOT/'resources/drawables'
parser=argparse.ArgumentParser(); parser.add_argument('--moon',type=Path,help='Full disk lunar image, centered on black'); args=parser.parse_args()
N=360; R=90; C=(180,224); T=204; K=64
Y,X=np.mgrid[0:N,0:N]; dist=np.hypot(X-180,Y-224); edge=np.hypot(X-180,Y-180)
# Subtle navy vignette and halo, black near perimeter
v=np.clip((180-edge)/28,0,1); base=np.zeros((N,N,3),float)
cloud=np.exp(-((X-150)**2/11500+(Y-220)**2/18000)); halo=np.exp(-((dist-R)/14)**2)*0.65
for j,c in enumerate([5,11,24]): base[:,:,j]=(c*cloud+halo*[11,23,40][j])*v
bg=Image.fromarray(np.uint8(np.clip(base,0,255)))
d=ImageDraw.Draw(bg); rng=random.Random(1947)
# More visible stars, with a few brighter points and tiny diffraction spikes.
# Keep clear of opaque clock bitmaps and the small data labels.
points=[]
for i in range(2200):
 if len(points)>=245: break
 x,y=rng.randrange(9,351),rng.randrange(8,352)
 if (x-180)**2+(y-180)**2>171**2 or (x-180)**2+(y-224)**2<94**2: continue
 if (48<=y<=123 and 40<=x<=320) or (29<=y<=48 and 105<=x<=255): continue
 if (165<=y<=225 and (x<76 or x>284)) or (310<=y<=345 and 68<=x<=292): continue
 if any((x-a)**2+(y-b)**2<9 for a,b in points): continue
 points.append((x,y))
 b=rng.choices([46,65,88,118,155,205,239],[15,25,26,18,10,5,1])[0]
 color=(int(b*.80),int(b*.89),min(255,b+12))
 d.point((x,y),fill=color)
 if b>=205:
  glow=(int(b*.24),int(b*.34),int(b*.48))
  d.line((x-2,y,x+2,y),fill=glow); d.line((x,y-2,x,y+2),fill=glow)
  d.point((x,y),fill=color)
  for dx,dy in [(-1,0),(1,0),(0,-1),(0,1)]: d.point((x+dx,y+dy),fill=(int(b*.48),int(b*.57),int(b*.72)))
bg.quantize(colors=96).save(OUT/'sky.png',optimize=True)
# 4x supersampling for a crisp limb and smooth terminator
S=2; D=T*S; yy,xx=np.mgrid[0:D,0:D]; x=(xx+0.5-D/2)/(R*S); y=(yy+0.5-D/2)/(R*S); rr=x*x+y*y; z=np.sqrt(np.maximum(0,1-rr)); inside=rr<=1
if args.moon:
 raw=Image.open(args.moon).convert('RGB'); a=np.asarray(raw); mask=a.max(2)>28; ys,xs=np.where(mask); raw=raw.crop((xs.min(),ys.min(),xs.max()+1,ys.max()+1)).resize((2*R*S,2*R*S),Image.Resampling.LANCZOS)
else:
 # The approved concept has an already lit gibbous Moon and a footer masking the bottom.
 # Approximate neutral albedo; recover shadowed/obscured areas by blending mirrored texture.
 raw=Image.open(ROOT/'tools/concept-moon-crop.png').convert('RGB').resize((2*R*S,2*R*S),Image.Resampling.LANCZOS)
tex=np.zeros((D,D,3),float); off=(T-2*R)*S//2; tex[off:off+2*R*S,off:off+2*R*S]=np.asarray(raw).astype(float)
if not args.moon:
 # Crop's actual visible disc is slightly elliptical; remove dark/bottom baked-in elements.
 # Sample only upper, well-lit artwork; reconstruct bottom and dark limb using reflections.
 raw=np.asarray(raw).astype(float); n=raw.shape[0]; Y0,X0=np.mgrid[0:n,0:n]; nx=(X0-n/2)/(n/2); ny=(Y0-n/2)/(n/2)
 # replace very bottom (footer) with mirrored upper terrain, softly blend at seam
 blend=np.clip((ny-0.55)/0.17,0,1)[...,None]; raw=raw*(1-blend)+raw[::-1,:,:]*blend
 # use mirrored detail on the dim left and lift approximate gibbous shading
 blend=np.clip((-nx-0.30)/0.48,0,1)[...,None]; raw=raw*(1-blend)+raw[:,::-1,:]*blend
 # preserve texture, not original orange/gold coloration
 gray=raw@np.array([.299,.587,.114]); light=np.clip(gray,20,250); raw=np.stack([light*1.025,light*0.99,light*.94],axis=-1)
 tex[off:off+2*R*S,off:off+2*R*S]=raw
# reuse exact decoded background, making square edges invisible
bg=Image.open(OUT/'sky.png').convert('RGB'); tile=bg.crop((C[0]-T//2,C[1]-T//2,C[0]+T//2,C[1]+T//2)).resize((D,D),Image.Resampling.BILINEAR); b=np.asarray(tile).astype(float)
for k in range(K):
 a=2*math.pi*k/K
 # North-up approximation: waxing lights right side, waning lights left side.
 dot=x*math.sin(a)-z*math.cos(a)
 # Light physically follows the sphere; low earthshine reveals unlit outline.
 bright=np.clip(dot*8,0,1)*(0.28+0.72*np.power(np.clip(dot,0,1),0.38)); shade=0.045+0.955*bright
 out=tex*shade[...,None]+np.array([2,5,10])[None,None,:]*(1-bright[...,None]); out=np.where(inside[...,None],out,b)
 out=Image.fromarray(np.uint8(np.clip(out,0,255))).resize((T,T),Image.Resampling.LANCZOS)
 out.quantize(colors=96,dither=Image.Dither.FLOYDSTEINBERG).save(OUT/f'moon{k:02}.png',optimize=True)
