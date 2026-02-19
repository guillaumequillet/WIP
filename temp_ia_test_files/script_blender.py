import bpy, json, os, mathutils

# --- CONFIGURATION ---
base_dir = "E:/PROG/RUBY/WIP/scenes/"
json_name = "scenes_data.json"
output_json = os.path.join(base_dir, json_name)

data = {"cameras": {}, "zones": [], "collisions": []}
scene = bpy.context.scene

# On reste sur Eevee pour un rendu rapide et fidèle au viewport
scene.render.engine = 'BLENDER_EEVEE_NEXT' if bpy.app.version >= (4, 2, 0) else 'BLENDER_EEVEE'

print("\n" + "="*30)
print("RENDU MANUEL : EXPORT DES CAMÉRAS")

# 1. PRÉPARATION DES MATÉRIAUX (Juste le BFC pour la propreté)
for mat in bpy.data.materials:
    if hasattr(mat, "use_backface_culling"):
        mat.use_backface_culling = True

# 2. MASQUAGE DES OBJETS TECHNIQUES AU RENDU
for obj in bpy.data.objects:
    if obj.name.startswith("Trigger") or "collision" in obj.name.lower():
        obj.hide_render = True 

# 3. BOUCLE DE RENDU
for obj in bpy.data.objects:
    if obj.type == 'CAMERA' and "TargetCam" in obj.name:
        scene.camera = obj
        img_path = os.path.join(base_dir, obj.name + ".png")
        scene.render.filepath = img_path
        
        # On utilise le rendu standard (F12) qui respecte tes "Hide in Render" (l'icône appareil photo)
        print(f"Rendu de l'image : {obj.name}.png")
        bpy.ops.render.render(write_still=True) 
        
        # Données pour le JSON
        loc = obj.location
        rot = obj.matrix_world.to_quaternion()
        target = loc + (rot @ mathutils.Vector((0.0, 0.0, -1.0)))
        
        data["cameras"][obj.name] = {
            "pos": [round(loc.x, 2), round(loc.y, 2), round(loc.z, 2)],
            "look_at": [round(target.x, 2), round(target.y, 2), round(target.z, 2)],
            "fov": round((obj.data.angle * 180) / 3.14159, 2)
        }

# 4. EXPORT DES COLLISIONS ET ZONES
for obj in bpy.data.objects:
    name_low = obj.name.lower()
    if "collision" in name_low and obj.type == 'MESH':
        mesh, matrix = obj.data, obj.matrix_world
        for face in mesh.polygons:
            verts = [matrix @ mesh.vertices[v].co for v in face.vertices]
            xs, ys = [v.x for v in verts], [v.y for v in verts]
            data["collisions"].append({
                "x_min": round(min(xs), 2), "x_max": round(max(xs), 2),
                "y_min": round(min(ys), 2), "y_max": round(max(ys), 2)
            })

    if obj.name.startswith("Trigger") and obj.type == 'MESH':
        target_cam = obj.name.replace("Trigger_", "")
        box = [obj.matrix_world @ mathutils.Vector(c) for c in obj.bound_box]
        xs, ys = [v.x for v in box], [v.y for v in box]
        data["zones"].append({
            "cam_id": target_cam,
            "x_min": round(min(xs), 2), "x_max": round(max(xs), 2),
            "y_min": round(min(ys), 2), "y_max": round(max(ys), 2)
        })

# 5. SAUVEGARDE
os.makedirs(base_dir, exist_ok=True)
with open(output_json, 'w') as f:
    json.dump(data, f, indent=4)

print("="*30)
print(f"TERMINÉ : {len(data['cameras'])} images prêtes.")