# Censor Faces
*#Update_2.1*

### What is this for?

This addon is a modification of the original add-on [Censored Faces of the Players](https://steamcommunity.com/sharedfiles/filedetails/?id=3298244860) from [RG Studio](https://steamcommunity.com/id/DemonCraft4). In this version, the method of handling censorship was changed, allowing it to be adapted for use on the faces of non-player characters (NPCs).

### What has already been implemented?
Full support for NPCs and ragdolls, as well as partial support for players. The ability to use different censorship methods and various additional features. There is also support for a Toolgun tool for the exclusion list and developer options. More details on GitHub.

- Support for NPCs, ragdolls, and players  
- Support for different censorship methods  
- Support for filters and exclusion lists  
- Ability to change the censorship size  
- Developer features

### List of Commands

1. **`pp_censor_faces`** *(default: 0)*
   Enables or disables the main face censorship effect for players and NPCs.
   **0** — disabled, **1** — enabled.

2. **`pp_censor_faces_size`** *(default: 64)*
   Size of the censor area on the face. Used to scale the effect (e.g., mosaic size).

3. **`pp_censor_faces_effect`** *(default: "mosaic")*
   Selects the visual effect used for censorship. Available options:

   * `"mosaic"` — pixelation effect;
   * `"square"` — black square;
   * `"white Square"` — white square;
   * `"glitch"` — glitch effect.

4. **`pp_censor_regdoll_blur`** *(default: 0)*
   Enables face blur on **ragdolls** (dead player/NPC bodies).

5. **`pp_blur_enabled`** *(default: 0)*
   Enables or disables the **blur size slider**.
   If disabled, `pp_censor_faces_blur_size` is ignored.

6. **`pp_censor_faces_blur_size`** *(default: 5)*
   Intensity of the blur effect, if selected.
   Range: **0** to **10**.

7. **`pp_censor_faces_allied_npcs`** *(default: 0)*
   NPC filter: if enabled, censorship applies **only to allied NPCs**.

8. **`pp_censor_players`** *(default: 1)*
   Enables face censorship for **players**.

9. **`pp_censor_npc`** *(default: 1)*
   Enables face censorship for **NPCs (non-player characters)**.

10. **`pp_new_size_handler`** *(default: 1)*
    Enables the **new logic** for calculating censor area size.
    Designed for more accurate positioning and scaling.

11. **pp\_censor\_faces\_only** (default: `0`)
   When enabled, only face regions will be censored.

   * `0` – disabled
   * `1` – censor faces only

### What are the plans for the future?
I also in the future, I will update this section.

---
### Links
> *  [censor_faces.zip](https://github.com/user-attachments/files/20777328/censor_faces.zip)
> *  [GitHub](https://github.com/diopop1/Censor-faces-for-NPC-Garry-s-Mod)
> *  [YouTube](www.youtube.com/@diopop1)
> *  [Steam](https://steamcommunity.com/id/diopop/)

