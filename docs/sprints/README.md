# Sprints

How we build: one sprint at a time, tracked on GitHub (a milestone per sprint, a user story per
feature, acceptance criteria in each story).

1. **Plan**: pick the sprint's stories; write `sprint-NN.md` (goal, stories, playtest checklist).
2. **Build**: tests first, then the feature; headless tests green; screenshots checked off-screen.
   Visible self-playing test runs (`--demo`) only when BB1 asks.
3. **Playtest**: BB1 plays the sandboxed build (Desktop shortcut "Great Works (sandboxed)").
4. **Retro**: what worked, what didn't, what changes; written at the bottom of `sprint-NN.md`.
5. **Merge** and move to the next sprint.

Overview map: https://claude.ai/artifact/B8S3su3KEHhPqwC9oaKcTV

## Design rules so far
- One world per region of the Essentials list, each a Majula-like hub with its own music and mood.
- Fidelity rises world by world: Greece 320x180 (PS1-like), Rome 640x360 (PS2-like), sharper after.
- One place per teacher; each book is a lesson in that place; each lesson finished opens a new part
  of the place, and the teacher remembers you (like several stars in one Mario world).
- The teacher leads: plain words, one point at a time, asks you to say it in your own words; the
  tablet fills only from your own words. No quizzes, no fail states.
- Every book mastered builds toward the Tower of the Reformed Man, one tier per world.
- The look (2026-10-15, `docs/the-look.md`): every place built against a saturated sky, one tall
  landmark per place, terraces with carved edges and railings, props in clumps, a warm low key
  light with the fog tinted to the horizon and the dark below. Chunky forms at the world's fidelity.
