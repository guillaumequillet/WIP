import bpy

def setup_outline_render():
    scene = bpy.context.scene
    
    # 1. Activer Freestyle
    scene.render.use_freestyle = True
    
    # 2. Configurer l'épaisseur (1 pixel fixe)
    scene.render.line_thickness_mode = 'ABSOLUTE'
    scene.render.line_thickness = 1.0
    
    # 3. Accéder (ou créer) au LineSet
    # On vérifie si une vue Freestyle existe, sinon on la crée
    if not scene.view_layers[0].freestyle_settings.linesets:
        lineset = scene.view_layers[0].freestyle_settings.linesets.new("Outline")
    else:
        lineset = scene.view_layers[0].freestyle_settings.linesets[0]
        
    # 4. Paramètres de détection des bords
    lineset.select_silhouette = True
    lineset.select_crease = True
    lineset.select_border = True
    lineset.select_edge_mark = False
    
    # 5. Forcer la couleur noire et l'opacité
    lineset.linestyle.color = (0, 0, 0)
    lineset.linestyle.alpha = 1.0

    print("Contour 1px Noir configuré.")

setup_outline_render()