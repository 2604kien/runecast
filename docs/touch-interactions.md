# Touch inspection and board editing

**October 9, 2026 — RC-008 interaction contract.** This describes the implemented screen controls. The dated [verification record](verification.md) and [project handoff](project-plan.md) own final results and completion status. Production gameplay, balance, ownership, random streams and historical experiment rules are unchanged.

## Tap, inspect and cancel

| Action | Result |
| --- | --- |
| Tap an effect rune in hand | Select that card instance. Tap an eligible board cell to install it. Its casting cost is not paid by inspection, selection or placement. |
| Tap a connector tool | Select Straight, Corner, Split or Join. Its button remains selected while placing multiple pieces. |
| Tap an installed piece with no placement selected | Select the cell for Rotate or Flip. A bright outline marks the selected cell. |
| Tap a production endpoint while a card/tool is selected | Safely select the endpoint and clear placement. The status explains its protection and current direction. |
| Hold a hand card, board piece or connector button | Open its inspector without the corresponding tap action. This works for techniques as well as effect runes. |
| Turn **Inspect: ON**, then tap an item | Open the same inspector. This discoverable alternative needs no hold timing and never places a card or activates a technique. Changing Inspect mode clears the prior placement/cell selection. |
| **Close** or Escape while inspecting | Close the panel. Inspect mode stays on if it was enabled. The closing gesture cannot activate a background control. |
| **Cancel selection** (shortened to **Cancel** on narrow screens) or Escape outside the inspector | Clear the selected card, tool and cell, remove placement previews and turn Inspect mode off. |

Normal short taps on **Focus** and **Conjure Spark** still activate the technique immediately through the guarded controller. There is no activation button inside a card inspector. To read a technique safely, hold it or enable Inspect before tapping it. Inspection never spends energy, consumes cards, creates cards, changes random streams or adds an Undo entry.

Rune cards retain their compact name/symbol/value faces. Costs and longer explanations belong in the dismissible panel; desktop tooltips remain supplementary. The enemy arena and board composition remain substantial, and there is no permanent forecast strip above Cast.

## Inspector content

The inspector reads a fresh detached controller snapshot. It shows the current name, kind, effect/value, energy cost and payment time; real input/output directions including rotation and wire reversal; permanent or temporary ownership; and the active profile's Cast/Pass cleanup. Connector inspection includes available/total stock or the historical unlimited-wire rule. Begin/End inspection includes their direction and whether the active profile permits Rotate.

Installed pieces report **powered from Begin**, **partially connected** when a Join still lacks an input, or **disconnected**. A powered upstream piece can coexist with an incomplete circuit: the inspector says that the circuit cannot Cast yet. This connection description does not change the model's Cast validity or cost calculation.

Descriptions honor the historical profiles. Locked endpoints remain locked, corner effect ports keep their actual shape, and persistent/consumed effects or temporary replacement wires use that profile's cleanup semantics. Production descriptions explain that all connectors clear, all installed permanent runes discard and all temporaries disappear after Cast/Pass, including disconnected pieces.

The panel fits inside the portrait viewport and its body scrolls independently. Its Close control stays outside the scrollable body. Pointer routing is restricted to the panel while it is open; dragging its content cannot scroll or activate the underlying board. Tab and directional button navigation stay among the panel's visible controls, and Enter cannot activate an old background focus. Escape still closes the panel.

## Placement and editing feedback

Selecting a card or tool marks eligible cells with a green **+** border and unavailable/protected cells with an **x** border. This preview is visible without hover. It is computed from snapshot data without calling a model command, spending stock or simulating an edit followed by Undo.

An eligible cell means the construction step is legal; it does not promise a complete, affordable or damaging Cast. Open paths, temporarily incomplete branches and disconnected pieces remain available for experimentation. An endpoint, a blocked historical cell or exhausted connector supply produces a concise reason in the status area. Choosing another action or refreshing changed model state clears obsolete feedback.

| Control | Availability and behavior |
| --- | --- |
| **Rotate** | Enabled for a selected occupied editable piece, including endpoints only where the active profile permits it. Turns clockwise; endpoint feedback names the new direction. |
| **Flip** | Enabled only for selected Straight or Corner wires. Reverses their input/output direction. |
| **Undo** | Enabled only when actual edit history exists. Restores board, hand and derived stock together, then clears selection. It cannot cross technique or turn boundaries. |
| **Erase** | Select the tool and tap an eligible occupied cell. Runes return to hand; connectors refund stock. Empty cells, endpoints and blocked cells reject it. |
| Connector stock | Buttons show available / total and visually mute exhausted stock while remaining inspectable. Erase, replacement, rune-over-connector placement and Undo update the quantities immediately. Replacing a connector with its own kind is permitted even with no spare stock. |

Rotate, Flip, Undo and Erase use labeled controls, with enlarged editing targets. Disabled appearance communicates availability; view handlers and the combat controller still validate commands. **Details / Pass** includes reasons for unavailable editing actions on the selected cell.

## Circuit details and Pass

**Details / Pass** opens the current circuit message, available energy, casting cost, damage/shield and expected incoming attack. It remains usable with an incomplete circuit or empty hand. **Pass turn…** first opens a confirmation explaining the enemy attack and applicable cleanup; only **Confirm Pass / enemy acts** sends the guarded Pass command. Close/Escape cancels that confirmation. The existing Menu Pass path remains available.

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

Selection, inspector visibility, Inspect mode, placement borders and gesture timing live only in the UI. [`inspection_data.gd`](../scripts/ui/inspection_data.gd) owns read-only descriptions and availability explanations; [`main.gd`](../scripts/ui/main.gd) owns selection/modal state; the router owns one pending pointer gesture. The existing controller remains the authoritative command guard.

Every screen refresh cancels pending gesture callbacks. Any changed snapshot or busy presentation closes the inspector and clears old feedback; consumed hand UIDs are removed from selection. Turn, encounter generation or battle-state changes and presentation start clear all selection and Inspect mode. Undo, Restart, Exact replay and experiment relaunch explicitly clear them too. Startup failure closes inspection and disables gameplay. Focus loss, presentation cancellation/refresh and scene teardown invalidate pending gestures; teardown also disposes the controller.

Cancellation advances a generation counter and clears callbacks while retaining ownership of the physical stream until release. On application or native-window focus loss, the router also clears tracked pointers because the OS may omit their releases; a fresh foreground gesture can then start normally, while an old emulated release remains suppressed. Stale holds, old controls, duplicate releases and a release after modal dismissal cannot target a new card, place a piece or unlock presentation. Opening or closing a modal also invalidates its pending callbacks. Inspection panels close when their source state changes instead of keeping an obsolete UID or board description actionable.

## Verification and remaining device work

The fresh pre-edit baseline passed **1063 core checks and 333 UI checks**. Final verification passes **1063 core / 503 UI checks**, plus **82 rendered interaction/capture checks** (73 repeated scene checks and nine screenshot saves), all with zero failures. Current command results, representative normal/smaller portrait captures and RC-008 completion are recorded in the dated [verification entry](verification.md#october-9-2026--rc-008-touch-inspection-complete); historical logs, screenshots and raw experiment records are preserved separately from new RC-008 output.

[`inspection_data_tests.gd`](../tests/inspection_data_tests.gd) checks live content, stock, directions, power status, historical permissions/cleanup and purity including all three random streams and Undo. [`touch_router_tests.gd`](../tests/touch_router_tests.gd) checks arbitration and cancellation with deterministic time. [`ui_touch_tests.gd`](../tests/ui_touch_tests.gd) routes **synthetic** touch/mouse events through the actual scene/viewport; [`ui_touch_capture.gd`](../tests/ui_touch_capture.gd) runs that coverage with separate capture destinations. Tests disable automatic timing and advance the same hold path explicitly rather than waiting for fragile wall-clock delays.

Synthetic events and desktop screenshots do not establish physical-device usability. A native Windows input attempt returned `SendInput` **0 of 1**, `GetLastError` **87**, and its recovery capture was unreliable; manual native interaction remains unverified. No physical touch device was available. Android/iOS gesture feel, device scaling, safe areas and platform acceptance remain with the relevant platform tasks; RC-008 does not complete RC-021, RC-022, RC-023 or RC-044.
