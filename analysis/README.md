# Sensory Survey 3D Procrustes Workflow

This generalized_procrustes_workflow loads data from experimental sessions specified by e.g.

```
subject = 'S113';                                                                % subject identifier
session = "2025-11-10";                                                          % session number or date
electrodes = [1 1 1 1 1 1 1 1 1 9 9 9 9 9 9 9 9 9 9];                            % electrodes activated at each trial
data_path_format = ".\\mesh_utils\\participant_251013\\Survey3D_%s_%s_*.json";   % regex to identify relevant Survey 3D .json files
```

and projects them onto both the source model used in the original Survey 3D annotation (specified in mesh_source and landmarks_source) and the target model for iterative procrustes morphing (specified in mesh_target and landmarks_target).

From there, the package can make basic comparisons across source and target annotation projections (e.g. Jaccard index calculation, oblique annotation quantification). It is intended for viewing and reviewing sensory data collected during brain-computer interface studies.

Note:
If the source is the default hand model, you can avoid manually locating the mesh and landmarks files by setting use_default_hand_source to true.
If the target is the default 2D hand palmar and dorsal illustrations, you can avoid manually locating the mesh and landmarks files by setting conform_to_2D_illustration to true.
If use_default_hand_source or conform_to_2D_illustration are false, running generalized_procrustes_workflow will prompt the user to navigate to and select the appropriate source and/or target mesh and landmarks files via graphical user interface.

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
"WuT"     % Wrist under thumb.
"WuP"     % Wrist under pinky.
"EoW"     % End of wrist.
```

An illustration of suggested placements of these landmarks relative to the source or target mesh is presented below. If desired, you can use the Survey 3D graphical user interface to produce an annotation hotspot file detailing the locations of these landmarks relative to the source and target meshes.

[ picture of recommended landmark placement for hand ]

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
```

An illustration of suggested placements of these landmarks relative to the source or target mesh is presented below. If desired, you can also specify these landmarks via the Survey 3D graphical user interface. If accessory landmarks (i.e. width markers) are not detailed in the source or target landmarks files, the system will auto determine finger widths at each of the relevant primary landmarks and use these in iterative procrustes transformations.

[ picture of recommended landmark placement for hand ]

## Specifying Arbitrary Landmarks

Though it was developed for hand annotations, Survey 3D need not be used for hand annotation exclusively. Users can import arbitrary 3D meshes for annotation, including meshes resulting from 3D scanning of real hands, feet, limbs, chests, faces, etc.

In order to perform procrustes transformations across arbitrary source and target meshes, arbitrary landmark specification is necessary. Custom landmark placement and naming can be performed using Survey 3D's graphical user interface. In order to morph between two arbitrary meshes, the same set of landmarks (and accessory landmarks, if applicable) must be defined for both the source and target mesh. Those landmark identifiers and their dependencies must be specified in generalized_procrustes_workflow.

## Hierarchical Dependency Definitions

Levels of dependency convey to the algorithm the relationship between landmarks, such that e.g. performing a counter-rotation about the index metacarpal joint to correct for a discrepancy in index finger flexion across source and target models will rotate not only areas of mesh near the Imcp landmark, but areas of mesh controlled by the anatomically connected Ipip landmark.

### The default/recommended dependency arrangement for hand models is:

```
dependencies = ["Tmcp", "Tpip";...
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
                "Pdip", "Pend"];

anchor_landmark = "EoW";
```

Iterative procrustes begins at the top of this list, extracts a row of landmark combinations (e.g. Tmcp, Tpip), finds all instances of these landmarks in the superset of primary and accessory landmarks (e.g. Tmcp, Tpip, Tpip_p, Tpip_t, Tmcp_p, Tmcp_t), finds the procrustes transformation (reflection excluded) that maximally aligns these landmarks in the source to the same landmarks in the target, and then rotates, translates, and scales these landmarks along with the source mesh vertices assigned to these landmarks by proximity. The landmark designated the anchor_landmark is forced to occupy the same XYZ location in the source and target meshes. In the case of the default hand scenario, the anchor landmark is the end of the wrist.
