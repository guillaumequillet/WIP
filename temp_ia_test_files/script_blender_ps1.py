import bpy

def setup_true_320_render():
    scene = bpy.context.scene
    
    # --- 1. RÉSOLUTION DE RENDU (L'INTERNE) ---
    # On rend en 640x480 pour la qualité
    scene.render.resolution_x = 640
    scene.render.resolution_y = 480
    scene.render.resolution_percentage = 100
    
    # Anti-aliasing interne
    scene.render.filter_size = 1.5
    scene.view_settings.view_transform = 'Standard'

    # --- 2. COMPOSITEUR (FORÇAGE DU 320x240) ---
    scene.use_nodes = True
    nt = scene.node_tree
    while nt.nodes: nt.nodes.remove(nt.nodes[0])
    
    rl = nt.nodes.new('CompositorNodeRLayers')
    comp = nt.nodes.new('CompositorNodeComposite')

    # Le noeud Scale force la dimension physique de la sortie
    scale = nt.nodes.new('CompositorNodeScale')
    scale.space = 'ABSOLUTE'
    scale.inputs[1].default_value = 320 # Largeur finale réelle
    scale.inputs[2].default_value = 240 # Hauteur finale réelle
    
    # Note : On ne met PAS de noeud Transform (Nearest) ici pour garder le lissage
    nt.links.new(rl.outputs['Image'], scale.inputs[0])
    nt.links.new(scale.outputs[0], comp.inputs[0])

    # --- 3. RÉSOLUTION DE SORTIE (L'EXTERNE) ---
    # On règle ces valeurs sur 320x240 pour que le fichier image soit à la bonne taille
    scene.render.resolution_x = 320
    scene.render.resolution_y = 240

    print("LOG : Sortie physique forcée en 320x240 (via upscale 640px).")

setup_true_320_render()