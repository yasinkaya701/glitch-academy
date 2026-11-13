# YKS Campaign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the existing Godot project into a navigable YKS campaign with truthful TYT/AYT/YDT routes, subject-specific playable missions, story progression, and a polished observatory control center.

**Architecture:** Keep existing mission scenes and `MissionDefinition` resources. Add a focused micro-mission layer for courses without full scenes, and a campaign layer that owns saved progress and story flags. Present these through one route-aware control center over the existing 3D observatory.

**Tech Stack:** Godot 4.7.2, GDScript, TSCN/TRES, existing autoload theme and PNG/SVG assets.

**Spec:** `docs/superpowers/specs/2026-11-13-yks-campaign-design.md`

## Global Constraints

- Preserve existing playable scene IDs and scientific mechanics.
- TYT, AYT, and YDT remain distinct; YDT is optional.
- Each target course gets a unique learning objective and interaction content.
- Long explanatory menu paragraphs and decorative label stacks are disallowed.
- Use the current observatory palette and shared UI theme.
- Campaign completion must not require off-area subjects.
- Verify Godot loads the project and existing/new campaign flows at 1280×720.

## Review Focus

- Switching route after a selection should not launch a stale mission; assert selection clears or remains valid.
- A null/unfinished scene must never be advertised as playable; assert state metadata and start guard.
- YDT completion must not unlock or block TYT/AYT finales; assert independent route state.
- Existing LGS/class routes must keep their filter semantics; assert catalog membership.
- Story beats must fire once at the intended evidence threshold; assert save/reload and replay behavior.

### Task 1: Subject-specific playable mini-missions

**Files:** `stations/yks/` new mission scene, script, subject data/resources, and focused GDScript tests. Avoid control-center changes.

- [ ] Implement the compact interaction scene with clearly distinct interaction patterns and one-sentence instructions.
- [ ] Add unique, source-backed Turkish content for Turkish reading, literature, TYT foundational mathematics, geometry, chemistry, TYT biology, history, geography, philosophy, religion/culture, psychology, sociology, logic, and YDT English.
- [ ] Each definition stores one measurable learning target, a one-sentence instruction, a distinct answer set, failure feedback, and completion feedback. Support at least `choice`, `sequence`, and `pair` interaction modes.
- [ ] Verify every mission has a valid interaction, answer path, failure feedback, and completion signal.

### Task 2: Route-aware campaign hub and progress

**Files:** `scenes/control_center.tscn`, `scripts/control_center.gd`, `scripts/mission_definition.gd`, campaign state script/resource and save tests.

- [ ] Add unified YKS entry and TYT/AYT/YDT paths while preserving class/LGS.
- [ ] Use route-separated, state-coded YKS navigation, auto-select the next incomplete task, and keep curriculum detail optional.
- [ ] Track completion and story evidence per route, persist it, and guard unavailable missions.

### Task 3: MERİDYEN story and ending hooks

**Files:** `scripts/control_center.gd`, campaign/story modules, `scenes/intro/` or new focused narrative scenes, `stations/heart/` integration tests only if needed.

- [ ] Add short, skippable campaign beats for first suspicion, archive signature, betrayal, Life Protocol, Heart Room and final Three Suns confrontation.
- [ ] Trigger beats from completed evidence missions, including the existing Heart Room; preserve its mechanics.
- [ ] Offer an ending reachable from suitable TYT, AYT or social/language paths without requiring all content.

### Task 4: Integration and visual quality pass

**Files:** relevant tests, `docs/` route/story notes, targeted UI assets.

- [ ] Integrate mini-mission definitions into route catalogs and map states without marking incomplete resources playable.
- [ ] Check keyboard navigation, retry, hub return, route switching, text fit, contrast and 1280×720 layout.
- [ ] Run focused Godot flow tests plus the existing YKS mission regressions; report exact commands and results.
