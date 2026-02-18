import bpy, json, os, mathutils

# --- CONFIGURATION ---
base_dir = "E:/PROG/RUBY/WIP/scenes/"
output_json = os.path.join(base_dir, "scenes_data.json")

data = {"cameras": {}, "zones": [], "collisions": []}
scene = bpy.context.scene

print("\n" + "="*30)
print("DÉBUT DU RENDU ET EXPORT")

# 1. MASQUAGE DES OBJETS TECHNIQUES AU RENDU
for obj in bpy.data.objects:
    if obj.name.startswith("Trigger") or "collision" in obj.name.lower():
        obj.hide_render = True 

# 2. PARCOURS ET RENDU
for obj in bpy.data.objects:
    # --- RENDU ET DONNÉES CAMÉRAS ---
    if obj.type == 'CAMERA' and "TargetCam" in obj.name:
        scene.camera = obj
        img_name = obj.name + ".png"
        scene.render.filepath = os.path.join(base_dir, img_name)
        
        print(f"-> Rendu de {img_name}...")
        # CETTE LIGNE EST MAINTENANT ACTIVE :
        bpy.ops.render.render(write_still=True) 
        
        loc = obj.location
        rot = obj.matrix_world.to_quaternion()
        target = loc + (rot @ mathutils.Vector((0.0, 0.0, -1.0)))
        
        data["cameras"][obj.name] = {
            "pos": [round(loc.x, 2), round(loc.y, 2), round(loc.z, 2)],
            "look_at": [round(target.x, 2), round(target.y, 2), round(target.z, 2)],
            "fov": round((obj.data.angle * 180) / 3.14159, 2)
        }
    
    # --- EXPORT COLLISIONS (Faces individuelles pour ton "L") ---
    if "collision" in obj.name.lower() and obj.type == 'MESH':
        mesh, matrix = obj.data, obj.matrix_world
        for face in mesh.polygons:
            verts = [matrix @ mesh.vertices[v].co for v in face.vertices]
            xs, ys = [v.x for v in verts], [v.y for v in verts]
            data["collisions"].append({
                "x_min": round(min(xs), 2), "x_max": round(max(xs), 2),
                "y_min": round(min(ys), 2), "y_max": round(max(ys), 2)
            })

    # --- EXPORT TRIGGERS (Auto-lien via le nom) ---
    if obj.name.startswith("Trigger") and obj.type == 'MESH':
        # On enlève "Trigger_" pour trouver le nom de la caméra
        target_cam = obj.name.replace("Trigger_", "")
        
        box = [obj.matrix_world @ mathutils.Vector(c) for c in obj.bound_box]
        xs, ys = [v.x for v in box], [v.y for v in box]
        
        data["zones"].append({
            "cam_id": target_cam,
            "x_min": round(min(xs), 2), "x_max": round(max(xs), 2),
            "y_min": round(min(ys), 2), "y_max": round(max(ys), 2)
        })
        print(f"Trigger lié : {obj.name} -> {target_cam}")

# 3. SAUVEGARDE JSON
os.makedirs(base_dir, exist_ok=True)
with open(output_json, 'w') as f:
    json.dump(data, f, indent=4)

print(f"SUCCÈS : {len(data['cameras'])} PNG créés et JSON mis à jour.")
print("="*30)