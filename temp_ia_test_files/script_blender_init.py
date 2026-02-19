import bpy

def setup_minimal_scene():
    # 1. Nettoyage de la scène initiale (optionnel)
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()
    
    # Supprimer les collections existantes pour repartir de zéro
    for col in bpy.data.collections:
        bpy.data.collections.remove(col)

    # 2. Création de la collection "geometry"
    geom_col = bpy.data.collections.new("geometry")
    bpy.context.scene.collection.children.link(geom_col)
    
    # Ajout d'un cube dans geometry
    bpy.ops.mesh.primitive_cube_add(size=2, location=(0, 0, 1))
    cube = bpy.context.active_object
    cube.name = "Cube_Decor"
    geom_col.objects.link(cube)
    bpy.context.scene.collection.objects.unlink(cube) # Déplacer de la racine vers la collection

    # 3. Création de la collection "collisions"
    col_col = bpy.data.collections.new("collisions")
    bpy.context.scene.collection.children.link(col_col)
    
    # Ajout d'un cube de collision (nommé col_xxx pour ton moteur)
    bpy.ops.mesh.primitive_cube_add(size=2, location=(0, 0, 1))
    collision_obj = bpy.context.active_object
    collision_obj.name = "col_cube_main"
    col_col.objects.link(collision_obj)
    bpy.context.scene.collection.objects.unlink(collision_obj)

    # 4. Création de la collection "cameras"
    cam_col = bpy.data.collections.new("cameras")
    bpy.context.scene.collection.children.link(cam_col)
    
    # Création de la cible (Empty)
    target_obj = bpy.data.objects.new("CameraTarget", None)
    target_obj.location = (0, 0, 0)
    cam_col.objects.link(target_obj)
    
    # Création de la Caméra
    cam_data = bpy.data.cameras.new("TargetCam")
    cam_obj = bpy.data.objects.new("TargetCam", cam_data)
    cam_obj.location = (10, -10, 5)
    cam_col.objects.link(cam_obj)
    
    # Ajout de la contrainte Track To vers la cible
    constraint = cam_obj.constraints.new(type='TRACK_TO')
    constraint.target = target_obj
    constraint.track_axis = 'TRACK_NEGATIVE_Z'
    constraint.up_axis = 'UP_Y'
    
    # Création du plan de Trigger (Trigger_TargetCam)
    bpy.ops.mesh.primitive_plane_add(size=5, location=(0, 0, 0.01))
    trigger_plane = bpy.context.active_object
    trigger_plane.name = "Trigger_TargetCam"
    cam_col.objects.link(trigger_plane)
    bpy.context.scene.collection.objects.unlink(trigger_plane)

    print("Scène minimaliste créée avec succès !")

# Lancer le setup
setup_minimal_scene()