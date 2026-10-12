# Touch inspection and board editing

**October 13, 2026 — current production interaction contract.** RC-016A migrates the RC-008 interaction foundation to the [accepted gameplay contract](gameplay-visual-contract.md): **Remove and Rotate only** for editing, detailed cards, live draw/discard counts and a persistent information bar above Cast. The visible **Pass turn** action occupies the former WIRING-label position beside the connector tools, as the owner requested. The dated [verification record](verification.md) and [project handoff](project-plan.md) own final results and completion status. Explicit historical profiles retain their older controls and directed rules; the full RC-016 art integration and physical-device testing remain separate.

## Tap, inspect and cancel

| Action | Result |
| --- | --- |
| Tap an effect rune in hand | Select that card instance. Tap an eligible board cell to install it. Tap the selected card again to clear selection. Its casting cost is not paid by inspection, selection or placement. |
| Tap a connector tool | Select Straight, Corner, Split or Join. Its button remains selected while placing multiple pieces; tap it again to clear selection. |
| Tap an installed piece with no placement selected | Select the cell for Rotate. A bright outline marks the selected cell. |
| Tap a production endpoint while a card/tool is selected | Safely select the endpoint and clear placement. The status explains its protection and current direction. |
| Hold a hand card, board piece or connector button | Open its inspector without the corresponding tap action. This works for techniques as well as effect runes. |
| Tap or keyboard-activate a hand card's **Info** button | Open that card's inspector without using the card. This separate focusable control needs no hold timing, including for techniques. |
| Press **I** on a focused piece/tool, or right-click it | Open its inspector without selecting, placing, rotating or activating it. |
| **Close** or Escape while inspecting | Close the panel and restore available originating focus. The closing gesture cannot activate a background control. |
| Escape outside the inspector, or tap the selected card/tool again | Clear the selected card, tool and cell and remove placement previews. There is no visible Cancel selection button in production. |

Normal short taps on **Focus** and **Conjure Spark** still activate the technique immediately through the guarded controller. There is no activation button inside a card inspector. To read a technique safely, use Info or hold it. Inspection never spends energy, consumes cards, creates cards, changes random streams or adds an edit-history entry.

Production hand cards use the existing RC-013 detailed component with live cost, name, symbol, type and short effect text, alongside RC-012 icons. Draw and Discard controls show live counts and open pile details. A live action log sits above the hand. The persistent damage/shield/cost/incoming bar above Cast opens circuit details and states invalid or unaffordable previews; it scrolls with the page rather than staying fixed to the viewport. Desktop tooltips remain supplementary.

## Inspector content

The inspector reads a fresh detached controller snapshot. It shows the current name, kind, effect/value, energy cost and payment time; rotated logical port directions without input/output polarity in production; permanent or temporary ownership; and the active profile's Cast/Pass cleanup. Connector inspection includes available/total stock or the historical unlimited-wire rule. Begin/End inspection includes their port direction and whether the active profile permits Rotate. Split has W/E/S and Join N/E/S before rotation; decorative glyph tips do not add ports.

Production pieces report their connection to Begin using the evaluator's reached component, even when construction is incomplete. A reached piece can coexist with an invalid circuit: the inspector says that the circuit cannot Cast yet. A valid circuit's active pieces and aggregation order come from the same evaluator. Disconnected pieces contribute no spell effect or cost. Historical Join descriptions retain the old partially-connected/input language only in their directed profiles.

Descriptions honor the historical profiles. Locked endpoints remain locked, corner effect ports keep their actual shape, and persistent/consumed effects or temporary replacement wires use that profile's cleanup semantics. Production descriptions explain that all connectors clear, all installed permanent runes discard and all temporaries disappear after Cast/Pass, including disconnected pieces.

The panel fits inside the portrait viewport and its body scrolls independently. Its Close control stays outside the scrollable body. Pointer routing is restricted to the panel while it is open; dragging its content cannot scroll or activate the underlying board. Tab and directional button navigation stay among the panel's visible controls, and Enter cannot activate an old background focus. Escape still closes the panel.

## Placement and editing feedback

Selecting a card or tool marks eligible cells with a green **+** border and unavailable/protected cells with an **x** border. This preview is visible without hover. It is computed from snapshot data without calling a model command, spending stock or simulating an edit followed by Undo.

An eligible cell means the construction step is legal; it does not promise a complete, affordable or damaging Cast. Open paths, temporarily incomplete branches and disconnected pieces remain available for experimentation. An endpoint, a blocked historical cell or exhausted connector supply produces a concise reason in the status area. Choosing another action or refreshing changed model state clears obsolete feedback.

| Control | Availability and behavior |
| --- | --- |
| **Rotate** | Enabled for a selected occupied editable piece, including endpoints only where the active profile permits it. Turns clockwise; endpoint feedback names the new direction. |
| **Remove** | Select the tool and tap an eligible occupied cell. Runes return to hand; connectors refund stock. Empty cells and endpoints reject it. Tap Remove again to clear selection. |
| Connector stock | Buttons show available / total and visually mute exhausted stock while remaining inspectable. Removal, replacement and rune-over-connector placement update the quantities immediately. Replacing a connector with its own kind is permitted even with no spare stock. |

Remove and Rotate use labeled controls and RC-012 icons, with enlarged editing targets. Disabled appearance communicates availability; view handlers and the combat controller still validate commands. Circuit details include reasons for unavailable editing actions on the selected cell. Production has no visible Flip, Undo, Inspect-mode, Cancel selection or Details / Pass control.

## Circuit details and Pass

Activate the persistent forecast above Cast to open the current circuit message, available energy, casting cost, damage/shield and expected incoming attack. Invalid and unaffordable forecasts remain inspectable while preparation is available; an unaffordable preview cannot Cast.

The visible **Pass turn** control is first in the wiring row, beside Straight, Corner, Split and Join. It opens a confirmation with the live enemy attack, no spell/shield, full board/hand cleanup and next-turn behavior. Only **Confirm Pass / enemy acts** sends the guarded Pass command. Cancel/Escape dismisses it. It remains available with an incomplete circuit or empty hand. Production does not depend on Menu or the circuit-details panel to end a turn without casting.

## Scrolling and gesture thresholds

Thresholds are centralized in [`touch_router.gd`](../scripts/ui/touch_router.gd):

| Setting | Value and meaning |
| --- | --- |
| `LONG_PRESS_SECONDS` | **0.45 seconds / 450 ms** while held without a cancelled gesture. Inspection fires once, and release cannot also tap. |
| `MOVE_THRESHOLD` | **18 logical viewport pixels** from the initial position. Reaching this distance permanently cancels the pending tap/hold for that gesture, even if the finger later returns. |
| Scroll direction | At the movement threshold, the larger displacement chooses horizontal or vertical; ties choose vertical. That axis remains locked until release. |
| Pointer ownership | The first pointer owns the gesture. Additional fingers cannot steal it or create another action, including when the first finger lifts first. |
| Emulation identity | Godot's emulated device ID **-1** does not create a second action alongside the physical mouse/touch stream. |

Distances use the game's logical viewport coordinates, not desktop window pixels. Horizontal dragging over the hand scrolls the hand; vertical dragging over the hand or board scrolls the page. Crossing the movement threshold cancels use/inspection even if there is no room to scroll farther. Large hands remain accessible by horizontal scrolling, and cards outside a clipped scroll area cannot be targeted through the clip.

Mouse presses use the same tap/hold/drag arbitration. Keyboard focus/activation and Escape remain available. Native text inputs, selectors and scrollbars retain their GUI handling. Guide, Map, Menu and experiment-record dialogs suspend the background router while open. Suspension consumes background input; each native Window receives its own viewport's input. The bounded Guide/Map body has its own scroll router, while native dialog buttons keep their normal GUI activation.

## Lifecycle and state ownership

Selection, inspector visibility, placement borders and gesture timing live only in the UI; Inspect mode is retained for explicit historical screens. [`inspection_data.gd`](../scripts/ui/inspection_data.gd) owns read-only descriptions and availability explanations; [`main.gd`](../scripts/ui/main.gd) owns selection/modal state; the router owns one pending pointer gesture. The existing controller remains the authoritative command guard.

Every screen refresh cancels pending gesture callbacks. Any changed snapshot or busy presentation closes the inspector and clears old feedback; consumed hand UIDs are removed from selection. Turn, encounter generation or battle-state changes and presentation start clear all selection and Inspect mode. Undo, Restart, Exact replay and experiment relaunch explicitly clear them too. Startup failure closes inspection and disables gameplay. Focus loss, presentation cancellation/refresh and scene teardown invalidate pending gestures; teardown also disposes the controller.

Cancellation advances a generation counter and clears callbacks while retaining ownership of the physical stream until release. On application or native-window focus loss, the router also clears tracked pointers because the OS may omit their releases; a fresh foreground gesture can then start normally, while an old emulated release remains suppressed. Stale holds, old controls, duplicate releases and a release after modal dismissal cannot target a new card, place a piece or unlock presentation. Opening or closing a modal also invalidates its pending callbacks. Inspection panels close when their source state changes instead of keeping an obsolete UID or board description actionable.

## Historical controls and verification

Explicit historical training/experiment screens retain compact cards, Rotate/Flip/Undo/Erase, Inspect mode, Cancel selection and Details / Pass plus Menu Pass. Inspect-mode taps never activate techniques; Close retains that mode, and Cancel selection clears it. Those profiles keep directed port descriptions and their original cleanup behavior. Their UI and fixtures are not instructions for current production controls.

The October 9 RC-008 pre-edit baseline passed **1063 core checks and 333 UI checks**. Its final verification passed **1063 core / 503 UI checks**, plus **82 rendered interaction/capture checks** (73 repeated scene checks and nine screenshot saves), all with zero failures. These historical counts describe the prior controls, not RC-016A completion. Their command results and captures remain in the dated [RC-008 verification entry](verification.md#october-9-2026--rc-008-touch-inspection-complete); current migration evidence belongs in the separate RC-016A entry.

[`inspection_data_tests.gd`](../tests/inspection_data_tests.gd) checks live content, stock, directions, power status, historical permissions/cleanup and purity including all three random streams and Undo. [`touch_router_tests.gd`](../tests/touch_router_tests.gd) checks arbitration and cancellation with deterministic time. [`ui_touch_tests.gd`](../tests/ui_touch_tests.gd) routes **synthetic** touch/mouse events through the actual scene/viewport; [`ui_touch_capture.gd`](../tests/ui_touch_capture.gd) runs that coverage with separate capture destinations. Tests disable automatic timing and advance the same hold path explicitly rather than waiting for fragile wall-clock delays.

Synthetic events and desktop screenshots do not establish physical-device usability. A native Windows input attempt returned `SendInput` **0 of 1**, `GetLastError` **87**, and its recovery capture was unreliable; manual native interaction remains unverified. No physical touch device was available. Android/iOS gesture feel, device scaling, safe areas and platform acceptance remain with the relevant platform tasks; RC-008 does not complete RC-021, RC-022, RC-023 or RC-044.
