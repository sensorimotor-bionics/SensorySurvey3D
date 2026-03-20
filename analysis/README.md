# Sensory Survey 3D Procrustes Workflow

## Overview

Use general_data_extraction.m to parse a set of .json annotation files into a readable .mat structure according to an experimental log (e.g. 113 Visit Notes.xlsx in the example_data folder).

An example of how to perform morphs of 3D models to 2D illustrations is presented in demo_two_dim_to_three_dim.m. Function calls toward the end of that file also produce the plots presented in Figure 3 of the accompanying publication. In order to successfully generate the plots, you must add the Swarm function from ChartsWithCharles (https://github.com/CMGreenspon/ChartsWithCharles) to path.

An example of how to perform morphs of 3D custom meshes to 3D intermediary models is presented in demo_three_dim_to_three_dim.m. Function calls toward the end of that file illustrate how to view both raw annotations (on custom meshes) and projected annotations (on the intermediary mesh).

Both demo_two_dim_to_three_dim.m and demo_three_dim_to_three_dim.m demonstrate launch of the electrode-wise and row-wise annotation viewer GUIs.

### Functions included in the general_utils folder can:
- Parse stored annotations and view projected fields on the appropriate mesh (launch_annotation_viewers).
- Morph a source 3D mesh to a target 2D illustration (morph_source_to_target) and flatten 3D annotations into 2D colormaps for comparison to the target illustration (flatten_3D_annotations).
- Morph a source 3D mesh to a target 3D mesh (morph_source_to_target) and provide a matrix for annotation projection between meshes.
- Compute the jaccard index between source and target 2D colormaps (compute_jaccard).
- Quantify the obliqueness of 3D annotations (quantify_oblique_annotations).

### Notes:
- When designing your own processing workflow, if the target is the default 2D hand palmar/dorsal illustration, you can avoid manually locating the mesh and landmarks files by setting conform_to_2D_illustration to true. If conform_to_2D_illustration is false, running morph_source_to_target will prompt you to navigate to and select the appropriate target mesh and landmarks files via graphical user interface (GUI). If the target model is not a hand, you will also be asked to specify the name of the bottom-most, top-most, left-most, and right-most landmark in your model to standardize viewing perspective.

## Specifying Hand Landmarks

### Recommended primary landmarks for hand models include:

```
%% ID     Description
"Tend"    % Thumb endpoint: the very tip of the thumb.
"Tpip"    % Thumb proximal interphalangeal: the joint just below the thumbnail.
"Tmcp"    % Thumb metacarpal: the knuckle of the thumb.
"Iend"    % Index endpoint: the very tip of the index finger.
"Idip"    % Index distal interphalangeal: the joint just below the index fingernail.
"Ipip"    % Index proximal interpalangeal: the joint between the Idip and the knuckle of the index finger.
"Imcp"    % Index metacarpal: the knuckle of the index finger.
"Mend"    % Middle endpoint: the very tip of the middle finger.
"Mdip"    % Middle distal interphalangeal: the joint just below the middle fingernail.
"Mpip"    % Middle proximal interpalangeal: the joint between the Mdip and the knuckle of the middle finger.
"Mmcp"    % Middle metacarpal: the knuckle of the middle finger.
"Rend"    % Ring endpoint: the very tip of the ring finger.
"Rdip"    % Ring distal interphalangeal: the joint just below the ring fingernail.
"Rpip"    % Ring proximal interpalangeal: the joint between the Rdip and the knuckle of the ring finger.
"Rmcp"    % Ring metacarpal: the knuckle of the ring finger.
"Pend"    % Pinky endpoint: the very tip of the pinky finger.
"Pdip"    % Pinky distal interphalangeal: the joint just below the pinky fingernail.
"Ppip"    % Pinky proximal interpalangeal: the joint between the Pdip and the knuckle of the pinky finger.
"Pmcp"    % Pinky metacarpal: the knuckle of the pinky finger.
"MpP"     % Middle of the hand, palmar side.
"MpD"     % Middle of the hand, dorsal side.
"EoW"     % End of wrist.
```

An illustration of suggested placements of these landmarks relative to the source or target mesh is presented below. Primary landmarks are represented by red dots. If desired, you can use the Survey 3D "landmarks" functionality to produce a file detailing the locations of these landmarks on a custom model. In order for custom landmark definitions to be compatible with the default 2D and 3D models included with Survey 3D, all primary and accessory landmarks described on this page must be defined.

<img width="500" height="651" alt="Screenshot 2025-11-26 at 3 35 56 PM" src="https://github.com/user-attachments/assets/42964523-a471-4e05-827c-abb1821ad77f" /> <br>
Figure 1: Suggested primary (red dot) and accessory (blue and magenta x) landmarks illustrated on the palmar 2D hand illustration. <br>

<img width="500" height="538" alt="Screenshot 2025-11-26 at 3 36 29 PM" src="https://github.com/user-attachments/assets/f6ccf24c-338a-4cae-9686-76c65a12fd79" /> <br>
Figure 2: Suggested primary (red dot) and accessory (blue and magenta x) landmarks illustrated on the default 3D hand mesh. Landmarks labeled in white are internal to the mesh. <br>

EDIT: Primary landmark "WuP" in the above illustrations has been moved to the accessory list and renamed to "EoW_p." Primary landmark "WuT" has been moved to the accessory list and renamed to "EoW_t." Two additional accessory markers have also been defined: "MpP_t", at the webbing between the thumb and index fingers, and "MpP_p," at the widest part of the palm beneath the pinky.

### Recommended accessory landmarks for hand models are width markers, including:

```
%% ID         Description
"Tpip_p"      % Tpip width marker, pinky side.
"Tpip_t"      % Tpip width marker, thumb side.
"Tmcp_p"      % Tmcp width marker, pinky side.
"Tmcp_t"      % Tmcp width marker, thumb side.
"Idip_p"      % Idip width marker, pinky side.
"Idip_t"      % Idip width marker, thumb side.
"Ipip_p"      % Ipip width marker, pinky side.
"Ipip_t"      % Ipip width marker, thumb side.
"Mdip_p"      % Mdip width marker, pinky side.
"Mdip_t"      % Mdip width marker, thumb side.
"Mpip_p"      % Mpip width marker, pinky side.
"Mpip_t"      % Mpip width marker, thumb side.
"Rdip_p"      % Rdip width marker, pinky side.
"Rdip_t"      % Rdip width marker, thumb side.
"Rpip_p"      % Rpip width marker, pinky side.
"Rpip_t"      % Rpip width marker, thumb side.
"Pdip_p"      % Pdip width marker, pinky side.
"Pdip_t"      % Pdip width marker, thumb side.
"Ppip_p"      % Ppip width marker, pinky side.
"Ppip_t"      % Ppip width marker, thumb side.
"EoW_p"       % Wrist under pinky.
"EoW_t"       % Wrist under thumb.
"Imcp_p"      % Imcp width marker, pinky side.
"Imcp_t"      % Imcp width marker, thumb side.
"Mmcp_p"      % Mmcp width marker, pinky side.
"Mmcp_t"      % Mmcp width marker, thumb side.
"Rmcp_p"      % Rmcp width marker, pinky side.
"Rmcp_t"      % Rmcp width marker, thumb side.
"Pmcp_p"      % Pmcp width marker, pinky side.
"Pmcp_t"      % Pmcp width marker, thumb side.
"MpP_p"       % Middle of the hand, palmar side width marker, pinky side.
"MpP_t"       % Middle of the hand, palmar side width marker, thumb side.
```

In the placement illustrations above, accessory landmarks with "\_p" modifiers are marked with a blue x. Accessory landmarks with "\_t" modifiers are marked with a magenta x.

## Specifying Arbitrary Landmarks

Though it was developed for hand annotations, Survey 3D need not be used for hand annotation exclusively. Users can import arbitrary 3D meshes for annotation, including meshes resulting from 3D scanning of real hands, feet, limbs, chests, faces, etc.

In order to perform procrustes transformations across arbitrary source and target meshes, arbitrary landmark specification is necessary. Survey 3D's aforementioned "landmarks" functionality allows you to specify the names of the landmarks that you define, so it can be used with custom models of anything, not just hands. In order to morph between two arbitrary meshes, however, the same set of landmarks (and accessory landmarks, if applicable) must be defined for both the source and target mesh. Moreover, those landmark identifiers and their dependencies must be specified in your workflow (see either demo file for an example).

## Hierarchical Dependency Definitions

Levels of dependency convey to the algorithm the relationship between landmarks, such that e.g. performing a counter-rotation about the index metacarpal joint to correct for a discrepancy in index finger flexion across source and target models will rotate not only areas of mesh near the Imcp landmark, but areas of mesh controlled by the anatomically connected Ipip landmark.

### The default/recommended dependency arrangement for hand models is:

```
dependencies = ["MpP", "Tmcp";...
                "MpD", "Imcp";...
                "EoW", "Pmcp";...
                "Tmcp", "Tpip";...
                "Tpip", "Tend";...
                "Imcp", "Ipip";...
                "Ipip", "Idip";...
                "Idip", "Iend";...
                "Mmcp", "Mpip";...
                "Mpip", "Mdip";...
                "Mdip", "Mend";...
                "Rmcp", "Rpip";...
                "Rpip", "Rdip";...
                "Rdip", "Rend";...
                "Pmcp", "Ppip";...
                "Ppip", "Pdip";...
                "Pdip", "Pend";...
                "EoW, "MpP"];

anchor_landmark = "EoW";
```

Iterative procrustes begins at the top of this list, extracts a row of landmark combinations (e.g. Tmcp, Tpip), finds all instances of these landmarks in the superset of primary and accessory landmarks (e.g. Tmcp, Tpip, Tpip_p, Tpip_t, Tmcp_p, Tmcp_t), finds the procrustes transformation (reflection excluded) that maximally aligns these landmarks in the source to the same landmarks in the target, and then rotates, translates, and scales these landmarks along with the source mesh vertices assigned to these landmarks by proximity. The landmark designated the anchor_landmark is forced to occupy the same XYZ location in the source and target meshes. In the case of the default hand scenario, the anchor landmark is the end of the wrist.
