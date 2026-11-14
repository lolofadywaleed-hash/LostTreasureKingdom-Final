# Blender 4.x headless procedural asset pipeline for Lost Treasure Kingdom.
# Usage: blender -b --python tools/generate_epic_assets.py
import bpy, math, os, random, sys
from mathutils import Vector
random.seed(731)

ROOT = os.path.abspath(os.environ.get("EPIC_ASSET_ROOT", "assets/models/epic"))
def mat(name, color, metallic=0.0, rough=0.35, emission=None, strength=0.0):
    m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True
    p=m.node_tree.nodes.get("Principled BSDF"); p.inputs["Base Color"].default_value=(*color,1)
    p.inputs["Metallic"].default_value=metallic; p.inputs["Roughness"].default_value=rough
    if emission:
        p.inputs["Emission Color"].default_value=(*emission,1); p.inputs["Emission Strength"].default_value=strength
    return m
MARBLE=mat("Pearl white marble",(0.82,.88,.96),.18,.23)
GOLD=mat("Celestial gold",(.95,.57,.12),.78,.2,(1,.42,.06),.45)
GLOW=mat("Arcane cyan",(.02,.55,1),.25,.2,(.02,.55,1),4)
GREEN=mat("Spirit jade",(.04,.42,.13),.2,.28,(.04,1,.18),2.4)
LEAF=mat("Luminous leaf",(.12,.72,.27),.05,.3,(.1,1,.28),1.6)
BARK=mat("Ancient bark",(.19,.075,.035),.05,.82)
PURPLE=mat("Abyss violet",(.18,.025,.32),.35,.22,(.5,.04,1),3)
DARK=mat("Obsidian",(.018,.025,.05),.72,.26)
BLUE=mat("Storm crystal",(.025,.2,.8),.25,.16,(.03,.28,1),3)
FIRE=mat("Magma",(.55,.045,.008),.25,.22,(1,.12,.005),3.5)
IVORY=mat("Treasure ivory",(.94,.85,.63),.25,.24)
STONE=mat("Ancient stone",(.22,.25,.31),.12,.78)
def reset(name):
    bpy.ops.object.select_all(action="SELECT"); bpy.ops.object.delete(use_global=False)
    for d in bpy.data.materials: 
        if d.users==0: bpy.data.materials.remove(d)
    bpy.context.scene.name=name
def applymat(o,m):
    if m:o.data.materials.append(m)
    return o
def bevel(o,amount=.08):
    if o.type=="MESH":
        mod=o.modifiers.new("crafted bevel","BEVEL"); mod.width=amount; mod.segments=2
        o.modifiers.new("weighted corner normals","WEIGHTED_NORMAL")
    return o
def cube(n,loc,scale,m,bev=.06):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc); o=bpy.context.object; o.name=n; o.dimensions=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True); applymat(o,m); return bevel(o,bev)
def uv(n,loc,scale,m,seg=16,rings=10):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=rings, location=loc); o=bpy.context.object;o.name=n;o.scale=scale; applymat(o,m); bpy.ops.object.transform_apply(location=False,rotation=False,scale=True); return o
def ico(n,loc,scale,m,sub=2):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub,radius=1,location=loc);o=bpy.context.object;o.name=n;o.scale=scale;applymat(o,m);return bevel(o,.025)
def cyl(n,a,b,r1,m,r2=None,verts=12):
    a,b=Vector(a),Vector(b); d=b-a
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r1, radius2=(r1 if r2 is None else r2), depth=d.length, location=(a+b)/2)
    o=bpy.context.object;o.name=n;o.rotation_mode="QUATERNION";o.rotation_quaternion=d.to_track_quat("Z","Y");applymat(o,m);return bevel(o,.025)
def torus(n,loc,major,minor,m,rot=None):
    bpy.ops.mesh.primitive_torus_add(major_segments=32,minor_segments=8,location=loc,major_radius=major,minor_radius=minor)
    o=bpy.context.object;o.name=n
    if rot:o.rotation_euler=rot
    applymat(o,m);return o
def curve(n,pts,r,m,cyclic=False):
    cu=bpy.data.curves.new(n,"CURVE");cu.dimensions="3D";cu.bevel_depth=r;cu.bevel_resolution=3
    sp=cu.splines.new("BEZIER");sp.bezier_points.add(len(pts)-1)
    for p,co in zip(sp.bezier_points,pts):p.co=co;p.handle_left_type="AUTO";p.handle_right_type="AUTO"
    sp.use_cyclic_u=cyclic;o=bpy.data.objects.new(n,cu);bpy.context.collection.objects.link(o);applymat(o,m);return o
def export(filename):
    os.makedirs(ROOT,exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=os.path.join(ROOT,filename),export_format="GLB",use_selection=True,export_apply=True,export_yup=True)
def cloud_ring(z,rad,count,scale):
    for i in range(count):
        a=2*math.pi*i/count;uv("ethereal cloud",(math.cos(a)*rad,math.sin(a)*rad,z),(scale,scale*.72,scale*.48),MARBLE,12,8)
def citadel():
    reset("Celestial Citadel")
    # floating island strata and underside rock teeth
    cyl("floating marble foundation",(0,0,-.25),(0,0,.35),4.5,MARBLE,3.9,48)
    cyl("gold foundation band",(0,0,-.08),(0,0,.06),4.56,GOLD,4.56,48)
    for i in range(22):
        a=i*math.tau/22; x,y=3.1*math.cos(a),3.1*math.sin(a)
        cyl("craggy floating underside",(x,y,-.35),(x*.8,y*.8,-1.5-random.random()),.38,STONE,.04,7)
    # central palace
    cube("grand palace keep",(0,0,1.1),(2.4,2.1,1.8),MARBLE,.12)
    for x in [-.75,0,.75]:
        for y in [-.65,.65]:
            cyl("golden tower",(x,y,1.8),(x,y,3.5 if x==0 else 2.9),.28,GOLD,.12,12)
            uv("tower crystal",(x,y,3.62 if x==0 else 3.02),(.16,.16,.28),GLOW)
    for x,y,h in [(-1.35,-1.1,2.6),(1.35,-1.1,2.6),(-1.35,1.1,2.6),(1.35,1.1,2.6),(0,0,4.1)]:
        cyl("spire",(x,y,1.7),(x,y,h),.34,MARBLE,.025,12)
        torus("spire gold ring",(x,y,2.05),.34,.045,GOLD)
    for z in [.45,.7]:
        cube("terrace",(0,0,z),(3.5,3.1,.16),MARBLE,.08)
    for i in range(8):
        a=math.tau*i/8;x,y=3.25*math.cos(a),3.25*math.sin(a)
        cyl("satellite island",(x,y,.0),(x,y,.65),.65,MARBLE,.35,8)
        ico("island crystal",(x,y,.9),(.25,.25,.42),GLOW)
    for x in [-2.1,2.1]:
        curve("waterfall ribbon",[(x,0,.25),(x*1.03,0,-.55),(x*1.08,.1,-1.5)],.09,GLOW)
    cloud_ring(-1.8,4.7,18,.48);export("celestial_citadel.glb")
def spirit_tree():
    reset("Ancient Spirit Tree")
    cyl("trunk base",(0,0,0),(0,0,2.8),.72,BARK,.43,16)
    for i in range(9):
        a=math.tau*i/9
        curve("crystal root",[(0,0,.25),(.8*math.cos(a),.8*math.sin(a),.12),(1.55*math.cos(a),1.55*math.sin(a),.04)],.13,BLUE)
    for i in range(11):
        a=math.tau*i/11; z=1.7+(i%4)*.35
        end=(2.2*math.cos(a),2.2*math.sin(a),4.3+random.random()*1.3)
        curve("twisting bough",[(0,0,z),(.7*math.cos(a),.7*math.sin(a),z+1),end],.18 if i%3 else .24,BARK)
        for j in range(9):
            t=random.random();p=(end[0]*t,end[1]*t,end[2]*t)
            uv("spirit leaf",p,(.22,.12,.36),LEAF,12,8)
    uv("heart crystal",(0,0,2.5),(.38,.38,.55),GLOW)
    for i in range(12):
        a=math.tau*i/12;ico("root crystal",(1.25*math.cos(a),1.25*math.sin(a),.28),(.18,.18,.5),BLUE)
    export("ancient_spirit_tree.glb")
def portal():
    reset("Dimensional Portal")
    torus("gold portal arch",(0,0,1.8),1.7,.19,GOLD,(math.pi/2,0,0))
    torus("inner energy ring",(0,-.03,1.8),1.42,.055,GLOW,(math.pi/2,0,0))
    cube("portal plinth",(0,0,.08),(3.6,.65,.35),STONE,.12)
    for i in range(9):
        a=math.tau*i/9
        ico("floating rune stone",(2*math.cos(a),.05,1.8+2*math.sin(a)),(.18,.16,.3),PURPLE)
    uv("galactic core",(0,.12,1.8),(1.28,.08,1.28),PURPLE,32,20)
    for i in range(6):
        a=i*1.7;curve("galaxy spiral",[(.2*math.cos(a),-.02,1.8+.2*math.sin(a)),(.7*math.cos(a+1),-.04,1.8+.7*math.sin(a+1)),(1.1*math.cos(a+2),-.06,1.8+1.1*math.sin(a+2))],.025,GLOW)
    export("dimensional_portal.glb")
def crystals():
    reset("Floating Crystal Rocks")
    for i in range(7):
        a=math.tau*i/7;r=1.5+(i%3)*.55;x,y=r*math.cos(a),r*math.sin(a);z=.3+(i%2)*.5
        ico("floating meteor",(x,y,z),(.8,.65,.65),STONE,2)
        for j in range(3):
            cyl("crystal shard",(x+(j-1)*.18,y,z),(x+(j-1)*.28,y,z+1+random.random()),.22,BLUE,.01,6)
        curve("energy vein",[(x-.5,y,z),(x,y-.15,z+.18),(x+.5,y,z)],.035,PURPLE)
    export("floating_crystal_rocks.glb")
def sword(filename,element):
    reset(filename)
    if element=="nature": blade,glow=GREEN,LEAF
    else: blade,glow=FIRE,GOLD
    # blade vertical along Z, hilt below
    cyl("pommel",(0,0,-1.8),(0,0,-1.55),.18,GOLD,.12,8)
    cyl("grip",(0,0,-1.58),(0,0,-.72),.11,DARK,.11,8)
    cube("crossguard",(0,0,-.68),(1.25,.2,.16),GOLD,.08)
    cyl("blade core",(0,0,-.62),(0,0,1.55),.32,blade,.015,6)
    cyl("central luminous fuller",(0,-.2,-.35),(0,-.2,1.25),.055,glow,.008,6)
    for side in [-1,1]:
        curve("enchanted wrapping vine",[(side*.12,0,-.4),(side*.4,.02,.1),(side*.23,0,.55),(side*.12,0,1.0)],.055,glow)
        for z in [.0,.5,1.0]:
            uv("elemental leaf or ember",(side*.3,0,z),(.12,.07,.22),glow,10,6)
    export(filename)
def spear():
    reset("Lightning Energy Spear")
    cyl("spear shaft",(0,0,-2.1),(0,0,1.7),.095,DARK,.075,10)
    for z in [-1.4,-.6,.2,1.0]:torus("gold shaft collar",(0,0,z),.12,.035,GOLD)
    cyl("crystal spearhead",(0,0,1.2),(0,0,2.3),.36,BLUE,.015,6)
    for s in [-1,1]:
        curve("lightning arc",[(0,0,-.2),(s*.25,.04,.25),(s*.1,.02,.8),(s*.35,0,1.3)],.035,GLOW)
    export("lightning_energy_spear.glb")
def boss():
    reset("Shadow Lord Boss")
    # stylized armored silhouette, torso, limbs, helmet, horns
    uv("armored torso",(0,0,1.5),(.72,.42,.95),DARK)
    uv("chest violet core",(0,-.4,1.65),(.23,.08,.28),PURPLE)
    uv("helmet",(0,0,2.65),(.48,.42,.55),DARK)
    for x in [-.19,.19]:uv("glowing eye",(x,-.39,2.7),(.09,.05,.07),PURPLE)
    for s in [-1,1]:
        cyl("horn",(s*.25,0,2.95),(s*.62,0,3.65),.16,DARK,.01,8)
        uv("shoulder armor",(s*.8,0,2.05),(.48,.5,.38),DARK)
        cyl("arm",(s*.8,0,1.9),(s*1.05,0,.9),.22,DARK,.14,10)
        cyl("leg",(s*.32,0,.9),(s*.38,0,-.2),.25,DARK,.16,10)
        curve("cape torn edge",[(s*.35,.25,2.4),(s*.9,.3,1.5),(s*1.1,.25,.3),(s*.8,.25,-.6)],.06,PURPLE)
    cube("waist armor",(0,0,.75),(1.1,.55,.32),DARK,.1)
    export("shadow_lord_boss.glb")
def minion():
    reset("Cursed Minion")
    uv("floating skull",(0,0,0),(.62,.48,.58),STONE,20,14)
    for x in [-.22,.22]:uv("eye socket",(x,-.43,.1),(.15,.08,.17),BLUE)
    cube("jaw",(0,-.03,-.42),(.55,.42,.2),DARK,.1)
    for i in range(7):
        a=math.tau*i/7
        curve("blue flame tendril",[(.4*math.cos(a),0,.2*math.sin(a)),(.7*math.cos(a),0,.3+.2*math.sin(a)),(.45*math.cos(a),0,.8+.15*math.sin(a))],.07,GLOW)
    export("cursed_minion.glb")
def chest():
    reset("Divine Treasure Chest")
    cube("ivory chest body",(0,0,.55),(2.2,1.25,1.0),IVORY,.18)
    cube("gold lower rim",(0,-.01,.12),(2.28,1.3,.16),GOLD,.05)
    # domed lid represented by layered beveled blocks
    cube("lid base",(0,0,1.12),(2.28,1.32,.22),GOLD,.1)
    uv("arched ivory lid",(0,0,1.28),(1.12,.67,.48),IVORY,24,12)
    cube("front gold lock",(0,-.68,.78),(.38,.12,.48),GOLD,.06)
    ico("star crystal",(0,-.77,.83),(.16,.07,.16),GLOW,2)
    for x in [-.85,.85]:
        for z in [.35,1.25]:cube("corner gold reinforcement",(x,-.65,z),(.16,.12,.28),GOLD,.035)
    for i in range(8):
        a=math.tau*i/8;ico("floating coin",(1.55*math.cos(a),.1,1.1+.35*math.sin(a)),(.13,.04,.13),GOLD,2)
    for x in [-.65,0,.65]:torus("rune medallion",(x,-.67,.55),.13,.025,GOLD,(math.pi/2,0,0))
    export("divine_treasure_chest.glb")
def coin():
    reset("Mystical Coin")
    cyl("gold coin",(0,0,-.08),(0,0,.08),.72,GOLD,None,64)
    torus("raised coin rim",(0,0,.09),.61,.045,IVORY)
    ico("star emblem",(0,0,.13),(.28,.28,.07),GLOW,2)
    for i in range(8):
        a=math.tau*i/8;uv("engraved dot",(.48*math.cos(a),.48*math.sin(a),.11),(.035,.035,.025),IVORY,8,6)
    export("mystical_coin.glb")
BUILDERS=[citadel,spirit_tree,portal,crystals,lambda:sword("nature_spirit_sword.glb","nature"),lambda:sword("blazing_fire_sword.glb","fire"),spear,boss,minion,chest,coin]
if __name__=="__main__":
    for build in BUILDERS:
        build()
        print("EXPORTED", os.path.join(ROOT, bpy.context.scene.name), flush=True)
    print("EPIC_ASSETS_COMPLETE",ROOT,flush=True)
