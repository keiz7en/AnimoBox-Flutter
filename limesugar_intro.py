from manim import *
import numpy as np

LIME = ManimColor("#78C850")
LIME_S = ManimColor("#A0E070")
SUGAR = ManimColor("#FFFAE6")
DIM = ManimColor("#888888")

class LimeSugarIntro(Scene):
    def construct(self):
        self.camera.background_color = "#090a0c"

        # === PHASE 1: Particles fly in (0-0.8s) ===
        particles = VGroup()
        for i in range(40):
            r_val = np.random.random()
            c = LIME.interpolate(LIME_S, r_val)
            dot = Dot(
                point=[np.random.uniform(-7, 7), np.random.uniform(-4, 4), 0],
                radius=np.random.uniform(0.02, 0.06),
                color=c,
                fill_opacity=0.6,
            )
            particles.add(dot)

        targets = [
            np.array([np.random.uniform(-2.5, 2.5), np.random.uniform(-0.8, 0.8), 0])
            for _ in range(40)
        ]

        self.play(
            *[p.animate.move_to(targets[i]).set_fill(opacity=0.9) for i, p in enumerate(particles)],
            run_time=0.8,
            rate_func=smooth,
        )

        # === PHASE 2: Burst ring (0.8-1.3s) ===
        ring1 = Circle(radius=0.1, color=LIME, stroke_width=3, fill_opacity=0)
        ring2 = Circle(radius=0.1, color=LIME_S, stroke_width=2, fill_opacity=0)

        self.play(Create(ring1), run_time=0.25)
        ring2.scale(8)
        self.play(
            ring1.animate.scale(14).set_stroke(opacity=0, width=0.3),
            FadeIn(ring2),
            run_time=0.45,
            rate_func=rush_from,
        )
        self.remove(ring1, ring2)

        # === PHASE 3: Lime slice forms (1.3-1.7s) ===
        R = 1.8
        outer = Circle(radius=R, color=LIME, fill_opacity=0.9, stroke_width=0)
        inner = Circle(radius=R * 0.82, color=LIME_S, fill_opacity=0.95, stroke_width=0)
        core = Circle(radius=R * 0.2, color=SUGAR, fill_opacity=1, stroke_width=0)

        segs = VGroup()
        for i in range(6):
            a = i * 60 * DEGREES
            line = Line(
                start=0.35 * R * np.array([np.cos(a), np.sin(a), 0]),
                end=R * 0.85 * np.array([np.cos(a), np.sin(a), 0]),
                color=SUGAR, stroke_width=2.5, stroke_opacity=0.9,
            )
            segs.add(line)

        self.play(FadeIn(outer, scale=0.3), run_time=0.25)
        self.play(FadeIn(inner, scale=0.5), FadeIn(core, scale=0.3), FadeIn(segs, lag_ratio=0.05), run_time=0.35)

        # === PHASE 4: Sugar crystals (1.7-2.1s) ===
        crystals = VGroup()
        np.random.seed(42)
        for _ in range(25):
            ang = np.random.uniform(0, TAU)
            dist = np.random.uniform(0.4, 1.4) * R
            px = dist * np.cos(ang)
            py = dist * np.sin(ang)
            if px**2 + py**2 < (R * 0.75)**2:
                sz = np.random.uniform(0.04, 0.1)
                sq = Square(side_length=sz, color=WHITE, fill_opacity=0.8, stroke_width=0)
                sq.move_to([px, py, 0]).rotate(np.random.uniform(0, PI / 2))
                crystals.add(sq)

        self.play(LaggedStart(*[FadeIn(c, scale=2) for c in crystals], lag_ratio=0.03), run_time=0.4)

        # === PHASE 5: "LimeSugar" text (2.1-2.5s) ===
        title_ref = Text("LimeSugar", font_size=72, color=LIME, weight=BOLD).next_to(outer, DOWN, buff=0.6)
        chars = VGroup()
        text = "LimeSugar"
        total_w = len(text) * 0.62
        start_x = title_ref.get_center()[0] - total_w / 2
        for i, ch in enumerate(text):
            c = Text(ch, font_size=72, color=LIME, weight=BOLD)
            c.move_to([start_x + i * 0.62, title_ref.get_center()[1], 0])
            chars.add(c)

        self.play(LaggedStart(*[FadeIn(c, shift=UP * 0.2) for c in chars], lag_ratio=0.04), run_time=0.4)

        # === PHASE 6: Subtitle (2.5-2.7s) ===
        sub = Text("ANIME  ·  DRAMA  ·  HOLLYWOOD", font_size=18, color=DIM)
        sub.next_to(chars, DOWN, buff=0.3)
        self.play(FadeIn(sub, shift=UP * 0.1), run_time=0.2)

        # === PHASE 7: Glow (2.7-2.9s) ===
        glow = Circle(radius=R * 1.3, color=LIME, fill_opacity=0, stroke_width=0)
        self.play(FadeIn(glow, scale=0.8), glow.animate.scale(1.5).set_fill(opacity=0.08), run_time=0.2, rate_func=rush_from)
        self.play(glow.animate.scale(0.9).set_fill(opacity=0.15), run_time=0.15)

        self.wait(0.1)

        # === PHASE 8: Exit ===
        everything = VGroup(particles, outer, inner, core, segs, crystals, chars, sub, glow)
        self.play(FadeOut(everything, scale=0.95), run_time=0.3)
