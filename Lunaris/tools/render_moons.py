from pathlib import Path
import argparse, math, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
ROOT=Path(__file__).resolve().parents[1]; OUT=ROOT/'resources/drawables'
parser=argparse.ArgumentParser(); parser.add_argument('--moon',type=Path,help='Full disk lunar image, centered on black'); args=parser.parse_args()
N=360; R=108; C=(180,222); T=220; K=64; S=2
Y,X=np.mgrid[0:N,0:N]; dist=np.hypot(X-C[0],Y-C[1]); edge=np.hypot(X-180,Y-180)
v=np.clip((180-edge)/9,0,1)
# Soft blue nebula and limb halo. The stars are artwork, not a real sky map.
cloud=np.exp(-((X-150)**2/22000+(Y-200)**2/23000))
lanes=np.exp(-((Y-90-0.53*X-11*np.sin(X/45))/24)**2)*0.6+np.exp(-((Y-170+0.40*X)/32)**2)*0.4
rngnp=np.random.default_rng(1947)
noise=Image.fromarray(np.uint8(rngnp.random((22,22))*255)).resize((N,N),Image.Resampling.BICUBIC)
noise=np.asarray(noise)/255.0
halo=np.exp(-((dist-R)/9)**2)
base=np.stack([(2.5*cloud+5*lanes*noise+8*halo)*v,(5*cloud+14*lanes*noise+19*halo)*v,(12*cloud+31*lanes*noise+39*halo)*v],axis=-1)
bg=Image.fromarray(np.uint8(np.clip(base,0,255))); d=ImageDraw.Draw(bg); rng=random.Random(1947)
points=[]
for i in range(12000):
 if len(points)>=700: break
 x,y=rng.randrange(5,355),rng.randrange(5,355)
 if (x-180)**2+(y-180)**2>175**2 or (x-180)**2+(y-222)**2<(R+2)**2: continue
 # Continuous starfield: transparent glyphs no longer need exclusion rectangles.
 if any((x-a)**2+(y-b)**2<4 for a,b in points): continue
 points.append((x,y))
 b=rng.choices([67,105,150,195,235,255],[14,23,28,22,11,2])[0]
 warm=rng.random()<0.12
 color=(b,min(255,int(b*.84)),int(b*.65)) if warm else (int(b*.80),int(b*.91),min(255,b+16))
 if b>=195:
  # Bright cores and a restrained 3–7px diffraction cross.
  length=3 if b>=235 else 1
  for j in range(length,0,-1):
   f=(0.12 if j==3 else 0.22 if j==2 else 0.55)
   c=tuple(int(k*f) for k in color)
   for dx,dy in [(-j,0),(j,0),(0,-j),(0,j)]: d.point((x+dx,y+dy),fill=c)
 if b==255:
  for dx,dy in [(-1,-1),(1,-1),(-1,1),(1,1)]: d.point((x+dx,y+dy),fill=tuple(int(k*.24) for k in color))
 d.point((x,y),fill=color)
# Use a common sky palette and exact indexed sky pixels outside every lunar disk.
qsky=bg.quantize(colors=96,dither=Image.Dither.NONE); qsky.save(OUT/'sky.png',optimize=True)
box=(C[0]-T//2,C[1]-T//2,C[0]+T//2,C[1]+T//2)
sky_tile=qsky.crop(box); sky_idx=np.array(sky_tile); sky_rgb=np.asarray(sky_tile.convert('RGB'),dtype=float)
D=T*S; yy,xx=np.mgrid[0:D,0:D]; x=(xx+0.5-D/2)/(R*S); y=(yy+0.5-D/2)/(R*S); rr=x*x+y*y; z=np.sqrt(np.maximum(0,1-rr)); inside=rr<=1
if args.moon:
 raw=Image.open(args.moon).convert('RGB'); a=np.asarray(raw); ys,xs=np.where(a.max(2)>28); raw=raw.crop((xs.min(),ys.min(),xs.max()+1,ys.max()+1))
else: raw=Image.open(ROOT/'tools/concept-moon-crop.png').convert('RGB')
raw=np.asarray(raw.resize((2*R*S,2*R*S),Image.Resampling.LANCZOS),dtype=float)
if not args.moon:
 gray=raw@np.array([.299,.587,.114]); raw=np.stack([gray*1.025,gray*.995,gray*.96],axis=-1)
tex=np.zeros((D,D,3),float); off=(T-2*R)*S//2; tex[off:off+2*R*S,off:off+2*R*S]=raw
# Antialias the moon boundary, but retain exact sky pixels away from the edge.
alpha=np.asarray(Image.fromarray(np.uint8(inside)*255).resize((T,T),Image.Resampling.LANCZOS),dtype=float)/255.0
sky_palette=qsky.getpalette()[:96*3]
for k in range(K):
 a=2*math.pi*k/K; dot=x*math.sin(a)-z*math.cos(a)
 bright=np.clip(dot*8,0,1)*(0.28+0.72*np.power(np.clip(dot,0,1),0.38)); shade=0.045+0.955*bright
 rgb=np.clip(tex*shade[...,None]+np.array([2,5,10])[None,None,:]*(1-bright[...,None]),0,255)
 # Composite at supersampled resolution for the limb.
 b=np.asarray(sky_tile.convert('RGB').resize((D,D),Image.Resampling.BILINEAR),dtype=float)
 rgb=np.where(inside[...,None],rgb,b)
 small=Image.fromarray(np.uint8(rgb)).resize((T,T),Image.Resampling.LANCZOS)
 q=small.quantize(colors=128,dither=Image.Dither.NONE)
 idx=np.where(alpha>0,np.asarray(q,dtype=np.uint16)+96,sky_idx).astype(np.uint8)
 tile=Image.fromarray(idx,mode='P'); pal=sky_palette+q.getpalette()[:128*3]; tile.putpalette(pal+[0]*(768-len(pal))); tile.save(OUT/f'moon{k:02}.png',optimize=True)
