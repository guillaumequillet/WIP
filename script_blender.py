import bpy
import json
import os
import mathutils

# --- CONFIGURATION ---
FILE_PATH = "E:/PROG/RUBY/WIP/scenes/scenes_data.json"
RENDER_PATH = "E:/PROG/RUBY/WIP/scenes"

data = {
    "cameras": {},
    "zones": []
}

def clean_val(val):
    return round(float(val), 2)

# 1. RÉGLAGES DU RENDU (FOND NOIR OPAQUE)
scene = bpy.context.scene
scene.render.film_transparent = False  # Désactive la transparence (Alpha)
scene.render.image_settings.color_mode = 'RGB' # Force l'absence d'alpha

# Réglage de la couleur du monde en noir
if scene.world:
    scene.world.use_nodes = True
    nodes = scene.world.node_tree.nodes
    bg_node = nodes.get("Background")
    if bg_node:
        bg_node.inputs[0].default_value = (0, 0, 0, 1) # Noir (R, G, B, A)

# 2. EXPORT DES CAMÉRAS
for obj in bpy.data.objects:
    if obj.type == 'CAMERA':
        mw = obj.matrix_world
        pos = mw.to_translation()
        forward = mathutils.Vector((0, 0, -1))
        target = mw @ forward
        
        data["cameras"][obj.name] = {
            "pos": [clean_val(pos.x), clean_val(pos.y), clean_val(pos.z)],
            "look_at": [clean_val(target.x), clean_val(target.y), clean_val(target.z)],
            "fov": clean_val(bpy.data.cameras[obj.data.name].angle * 57.2958)
        }

# 3. EXPORT DES ZONES (Triggers)
for obj in bpy.data.objects:
    if obj.name.startswith("Trigger_"):
        cam_id = obj.name.replace("Trigger_", "")
        mw = obj.matrix_world
        world_corners = [mw @ mathutils.Vector(corner) for corner in obj.bound_box]
        x_coords = [v.x for v in world_corners]
        y_coords = [v.y for v in world_corners]
        
        data["zones"].append({
            "cam_id": cam_id,
            "x_min": clean_val(min(x_coords)),
            "x_max": clean_val(max(x_coords)),
            "y_min": clean_val(min(y_coords)),
            "y_max": clean_val(max(y_coords))
        })

# 4. SAUVEGARDE DU JSON
with open(FILE_PATH, 'w') as f:
    json.dump(data, f, indent=4)

# 5. RENDU DES IMAGES
for cam_name in data["cameras"]:
    cam_obj = bpy.data.objects[cam_name]
    scene.camera = cam_obj
    scene.render.filepath = os.path.join(RENDER_PATH, cam_name + ".png")
    
    # On cache les triggers pour le rendu
    for obj in bpy.data.objects:
        if obj.name.startswith("Trigger_"):
            obj.hide_render = True
            
    bpy.ops.render.render(write_still=True)
    print(f"Rendu terminé : {cam_name}.png (Fond Noir)")

print("Export et Rendus terminés.")