#!/usr/bin/env python3
"""Generate Death Island's original compact illustrated sprite library (no dependencies)."""

from pathlib import Path
import math
import random
from xml.etree import ElementTree

from storage import require_space

OUT = Path(__file__).resolve().parents[1] / "src/assets/illustrated"
INK = "#29382f"


def path(
    d: str, fill: str, stroke: str = INK, width: float = 2.0, extra: str = ""
) -> str:
    return f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{width}" stroke-linejoin="round" stroke-linecap="round" {extra}/>'


def ellipse(
    x: float,
    y: float,
    rx: float,
    ry: float,
    fill: str,
    stroke: str = "none",
    width: float = 1,
) -> str:
    opacity = ""
    if fill.startswith("#") and len(fill) == 9:
        opacity = f' fill-opacity="{int(fill[7:9], 16) / 255:.3f}"'
        fill = fill[:7]
    return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{fill}" stroke="{stroke}" stroke-width="{width}"{opacity}/>'


def gradient(name: str, light: str, dark: str) -> str:
    return f'<linearGradient id="{name}" x1="0" y1="0" x2="0.8" y2="1"><stop stop-color="{light}"/><stop offset="1" stop-color="{dark}"/></linearGradient>'


def save(
    name: str, body: str, width: int = 512, height: int = 512, defs: str = ""
) -> None:
    text = f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}"><defs>{defs}</defs>{body}</svg>\n'
    ElementTree.fromstring(text)
    (OUT / f"{name}.svg").write_text(text)


def survivor(companion: bool = False) -> None:
    defs = gradient("skin", "#f4d4af", "#b57f65") + gradient(
        "cloth", "#839b8e", "#304a4a"
    )
    defs += gradient("hair", "#7c4830", "#2f2724") + gradient(
        "leather", "#9a6b42", "#453b30"
    )
    defs += gradient("scarf", "#d77454", "#7f3833") + gradient(
        "metal", "#d4e7df", "#668c88"
    )
    if companion:
        defs = defs.replace("#f4d4af", "#dba77f").replace("#b57f65", "#885344")
        defs = defs.replace("#839b8e", "#b59e72").replace("#304a4a", "#665048")
        defs = defs.replace("#7c4830", "#333c48").replace("#d77454", "#829bad")
    frames = []
    poses = [
        (0, 0, 0, 0),
        (-9, 11, 10, -13),
        (11, -9, -12, 12),
        (-12, 8, -25, -65),
        (-8, 12, 25, -65),
        (0, 0, 0, -150),
        (-7, 6, 35, -55),
        (-27, 25, -42, -100),
    ]
    for index, (left_leg, right_leg, left_arm, right_arm) in enumerate(poses):
        body = ""
        # Scarf tail, braid and backpack sit behind the articulated figure.
        body += path("M98 153 Q65 190 72 264 L102 250 118 180Z", "url(#leather)")
        body += path("M95 159 Q77 189 42 201 L64 217 Q93 205 118 164Z", "url(#scarf)")
        body += path(
            "M107 123 Q78 138 88 184 Q85 209 78 218 L98 216 Q106 175 119 141Z",
            "url(#hair)",
        )
        for y in range(149, 214, 12):
            body += path(f"M87 {y} l14 8 -14 5", "none", "#ad7450", 1.4)
        for x, angle in [(110, left_leg), (143, right_leg)]:
            body += f'<g transform="rotate({angle} {x} 257)">'
            body += path(
                f"M{x - 13} 251 Q{x - 19} 289 {x - 11} 330 L{x - 10} 378 {x + 8} 379 {x + 14} 327 Q{x + 23} 281 {x + 14} 251Z",
                "url(#cloth)",
            )
            body += path(
                f"M{x - 9} 275 Q{x - 6} 305 {x + 4} 326 M{x - 6} 332 l12 4",
                "none",
                "#b2bfa4",
                1.5,
            )
            body += path(
                f"M{x - 12} 352 L{x + 12} 354 {x + 12} 392 Q{x + 32} 397 {x + 31} 408 L{x - 14} 408Z",
                "url(#leather)",
            )
            body += path(
                f"M{x - 14} 408 H{x + 30} M{x - 9} 369 l20 1 M{x - 8} 379 l18 1",
                "none",
                "#c8a56b",
                2,
            )
            body += path(f"M{x + 2} 358 h8 v9 h-8Z", "#d7bc78", "#4d4633", 1)
            body += "</g>"
        # Tailored jacket, linen undershirt and contrasting seams.
        body += path(
            "M101 150 L124 142 146 147 163 165 155 204 162 258 Q136 276 99 257 L104 211 92 173Z",
            "url(#cloth)",
        )
        body += path("M122 154 L136 153 145 230 120 251 111 216Z", "#dfd3ac")
        body += path(
            "M111 159 L112 201 103 238 M148 164 L153 211 148 243", "none", "#aec0a1", 2
        )
        body += path("M98 238 L159 234 161 248 99 253Z", "url(#leather)")
        body += path("M125 238 h16 v12 h-16Z", "#ddbd73", "#695637", 2)
        body += path("M129 240 h8 v7 h-8Z", "#4c4e3d", "none")
        body += path("M146 247 L165 246 167 275 148 279Z", "url(#leather)")
        body += path("M148 254 l17 -2 M155 262 v8", "none", "#c99c61", 1.8)
        body += path("M96 159 L111 158 153 233 143 237Z", "url(#leather)")
        body += path("M102 164 L147 233", "none", "#cfad73", 1.5)
        for x, angle, side in [(96, left_arm, -1), (157, right_arm, 1)]:
            body += f'<g transform="rotate({angle} {x} 169)">'
            body += path(
                f"M{x - 9} 163 Q{x + side * 15} 165 {x + side * 18} 205 L{x + side * 9} 224 {x - 7} 207Z",
                "url(#cloth)",
            )
            body += path(
                f"M{x + side * 9} 215 L{x + side * 18} 217 {x + side * 22} 258 Q{x + side * 11} 274 {x + side * 4} 257Z",
                "url(#skin)",
            )
            body += path(f"M{x + side * 8} 242 l14 0 2 16 -17 1Z", "url(#leather)")
            body += path(
                f"M{x + side * 8} 245 l12 1 M{x + side * 8} 251 l12 1",
                "none",
                "#c7a875",
                1.5,
            )
            if side == 1 and index in [4, 6]:
                body += path("M177 266 L202 170", "none", "#473a2a", 9)
                body += path("M178 262 L203 168", "none", "#b38a57", 4)
                if index == 6:
                    body += ellipse(208, 166, 12, 18, "#b99057", "#584b37", 2)
                else:
                    body += path(
                        "M199 174 Q220 155 232 171 L228 195 201 190Z", "url(#metal)"
                    )
                    body += path("M225 168 l-2 24", "none", "#eef5d9", 2)
            if side == 1 and index == 5:
                body += path(
                    "M162 238 Q151 255 165 277 L182 277 Q194 253 181 238Z", "#688e87"
                )
                body += path("M164 237 h18 v8 h-18Z", "#c7ae73")
            body += "</g>"
        # Adult proportions, hand-drawn facial features and copper hair.
        body += path("M119 131 L117 152 Q133 165 145 149 L141 126Z", "url(#skin)")
        body += path(
            "M105 90 Q108 65 137 67 Q160 70 161 103 L172 118 162 121 Q161 142 141 147 L116 132Z",
            "url(#skin)",
        )
        body += ellipse(109, 113, 8, 12, "url(#skin)", INK, 1.5)
        body += path(
            "M106 109 Q112 105 111 116 M156 121 l-5 3 M146 133 q9 3 14 -2",
            "none",
            "#8c5444",
            1.5,
        )
        body += path(
            "M136 108 Q146 102 155 109 Q146 117 137 113Z", "#eee5cf", "#3f3c33", 1.6
        )
        body += ellipse(147, 110, 3.4, 5.0, "#537c66") + ellipse(
            148, 110, 1.5, 4, "#27352e"
        )
        body += ellipse(148, 108, 1, 1.4, "#ffffff")
        body += path("M134 102 Q145 97 155 102", "none", "#4c332a", 2.4)
        body += path(
            "M102 118 Q89 84 111 67 Q140 48 157 74 L164 97 Q143 88 131 78 Q126 101 113 110 L109 126Z",
            "url(#hair)",
        )
        body += path(
            "M110 80 Q116 63 140 67 M119 76 Q131 78 146 90 M102 90 Q99 103 109 113",
            "none",
            "#b47a50",
            1.8,
        )
        body += path(
            "M108 139 Q128 154 147 143 L154 156 138 172 109 158Z", "url(#scarf)"
        )
        body += path("M115 151 L139 158 146 151", "none", "#f0b07a", 1.8)
        body += ellipse(112, 124, 2.4, 3.2, "#ead08a", "#715e37", 1)
        if index == 3:
            body += path("M239 204 L239 149", "none", "#826444", 7)
            body += path("M234 150 L232 84 240 62 246 85 244 150Z", "url(#metal)")
            body += path("M240 70 V146", "none", "#eff0cb", 2)
            body += path("M226 153 H252", "none", "#d9b776", 5)
        if index == 7:
            body = f'<g transform="translate(-28 82) rotate(-23 128 270)">{body}</g>'
        frames.append(f'<g transform="translate({index * 256} 0)">{body}</g>')
    save("Mara" if companion else "Survivor", "".join(frames), 2048, 448, defs)


def tree(palm: bool) -> None:
    rng = random.Random(31 if palm else 17)
    defs = gradient("bark", "#bd955c", "#574b35") + gradient(
        "leaf", "#9bac56", "#275c44"
    )
    body = ellipse(256, 478, 112, 20, "#203b2b33")
    body += path(
        "M227 477 Q254 370 238 288 Q229 227 262 139 L286 148 Q258 255 277 319 Q284 404 269 478Z",
        "url(#bark)",
        "#414732",
        3,
    )
    for y in range(230, 470, 19):
        body += path(f"M242 {y} q13 9 32 4 M244 {y + 5} l22 4", "none", "#635b3d", 2)
    if palm:
        for i, angle in enumerate([-115, -79, -42, -9, 26, 63, 103, 145, 181]):
            leaf = path(
                "M261 175 Q315 70 452 145 Q350 117 282 179 Q366 162 453 191 Q347 188 261 187Z",
                "url(#leaf)",
                "#264f37",
                2.5,
            )
            leaf += path("M266 179 Q356 139 442 156", "none", "#c1c777", 2.5)
            for t in range(8):
                x = 298 + t * 17
                leaf += path(
                    f"M{x} {162 - t % 3 * 3} l15 20 M{x} {158 - t % 3 * 3} l6 -18",
                    "none",
                    "#466e40",
                    1.6,
                )
            body += f'<g transform="rotate({angle} 263 173)">{leaf}</g>'
        for x, y in [(251, 188), (270, 196), (282, 180)]:
            body += ellipse(x, y, 13, 17, "#867242", "#4a5133", 2)
    else:
        for index in range(27):
            x, y = rng.uniform(83, 425), rng.uniform(70, 250)
            rx, ry = rng.uniform(37, 66), rng.uniform(30, 53)
            color = ["#335d3e", "#4d7944", "#688e4d", "#81994f"][index % 4]
            body += path(
                f"M{x - rx} {y} Q{x - rx - 15} {y - ry} {x - 10} {y - ry} Q{x + rx} {y - ry - 13} {x + rx} {y} Q{x + rx + 15} {y + ry} {x} {y + ry} Q{x - rx} {y + ry + 10} {x - rx} {y}Z",
                color,
                "#35533a",
                2,
            )
            body += path(
                f"M{x - rx / 2} {y - ry / 3} q{rx / 2} {-ry / 2} {rx} 1",
                "none",
                "#a3b26a",
                1.4,
            )
            for leaf in range(6):
                lx, ly = (
                    x + rng.uniform(-rx * 0.7, rx * 0.7),
                    y + rng.uniform(-ry * 0.6, ry * 0.6),
                )
                body += path(
                    f"M{lx} {ly} q-5 -11 9 -9 q6 10 -9 9Z", "#91a862", "#527640", 0.8
                )
    save("Palm" if palm else "Tree", body, 512, 512, defs)


def rock(crystal: bool = False, ore: bool = False) -> str:
    body = ellipse(133, 169, 108, 16, "#243a3033")
    body += path(
        "M25 139 L39 84 91 39 162 29 216 78 237 139 210 163 65 174Z",
        "#798681",
        "#3b524b",
        3,
    )
    body += path("M39 84 L91 39 162 29 146 86 102 112Z", "#b0b8a0", "#748775", 1.5)
    body += path("M146 86 L216 78 237 139 182 154 169 115Z", "#5b716c", "#4a635a", 1.5)
    body += path(
        "M48 136 L102 112 146 86 M91 39 L98 75 82 89 M109 134 l12 19 28 -6",
        "none",
        "#465f56",
        2,
    )
    for i in range(12):
        body += ellipse(
            46 + i * 9,
            150 + (i % 3) * 4,
            9,
            3,
            ["#587447", "#7e8e4f", "#a0a866"][i % 3],
        )
    if ore:
        body += path(
            "M81 69 L112 87 130 75 151 112 177 99 193 133", "none", "#c7986c", 7
        )
        body += path("M83 67 L113 84 130 75 150 108", "none", "#f4cf95", 2)
    if crystal:
        for x, y, h in [(101, 122, 80), (154, 128, 102), (186, 136, 65), (65, 131, 49)]:
            body += path(
                f"M{x - 13} {y} L{x - 20} {y - h + 19} {x - 4} {y - h} {x + 15} {y - h + 20} {x + 10} {y}Z",
                "#66b9ab",
                "#335e61",
                2,
            )
            body += path(
                f"M{x - 4} {y - h} L{x} {y - 8} {x + 10} {y} {x + 15} {y - h + 20}Z",
                "#c5efce",
                "#78c6b4",
                1,
            )
    return body


def wood() -> str:
    return (
        ellipse(128, 138, 112, 15, "#32432e33")
        + path(
            "M23 133 Q61 101 83 108 L158 59 182 27 196 35 181 72 215 67 232 80 189 91 164 91 98 133 63 144Z",
            "#967346",
            "#514933",
            3,
        )
        + path(
            "M33 129 L82 119 169 76 188 39 M94 127 L175 84 216 77 M57 135 l24 -8",
            "none",
            "#d3b57b",
            3,
        )
        + ellipse(142, 91, 13, 6, "#62563a", "#c0a16c", 2)
    )


def fern(berries: bool = False) -> str:
    body = ellipse(128, 166, 104, 14, "#283e2933")
    for angle in [-70, -45, -20, 0, 25, 50, 72]:
        stem = path("M128 169 Q104 102 132 25", "none", "#677d39", 4)
        for y in range(42, 149, 16):
            reach = min(47, (y - 22) * 0.45)
            stem += path(
                f"M123 {y + 15} Q{123 - reach} {y - 10} {117 - reach} {y + 1} Q101 {y + 22} 126 {y + 25} Q154 {y + 15} {134 + reach} {y - 8} Q145 {y - 8} 123 {y + 15}Z",
                "#6c984e",
                "#3c653e",
                1.2,
            )
            stem += path(
                f"M123 {y + 15} L{120 - reach} {y + 1} M126 {y + 21} L{132 + reach} {y - 4}",
                "none",
                "#b5c578",
                1,
            )
        body += f'<g transform="rotate({angle} 128 169)">{stem}</g>'
    if berries:
        for x, y in [(83, 96), (98, 78), (161, 109), (144, 62), (112, 135), (67, 122)]:
            body += ellipse(x, y, 8, 8, "#ad535d", "#533e44", 1.4) + ellipse(
                x - 2, y - 3, 2, 2, "#f8ad8d"
            )
    return body


def structure(kind: str) -> str:
    body = ellipse(190, 295, 158, 20, "#29372933")
    if kind in ["campfire", "forge"]:
        if kind == "forge":
            body += path(
                "M60 279 L58 146 109 70 254 70 313 146 311 278Z",
                "#707c73",
                "#394e49",
                4,
            )
            for y in [115, 150, 185, 220, 255]:
                body += path(
                    f"M66 {y} H302 M{110 if y % 2 else 150} {y} v-33 M235 {y} v-33",
                    "none",
                    "#b2b8a1",
                    4,
                )
            body += path(
                "M137 280 V198 Q185 145 239 200 V281Z", "#2e3634", "#c39d65", 5
            )
        else:
            for i in range(10):
                angle = i * math.tau / 10
                body += ellipse(
                    189 + 98 * math.cos(angle),
                    269 + 28 * math.sin(angle),
                    24,
                    15,
                    "#8f9580",
                    "#4a6153",
                    2,
                )
            body += path("M108 276 L256 245 M119 241 L245 282", "none", "#684e33", 16)
            body += path("M108 272 L256 241 M119 238 L245 278", "none", "#b28c53", 3)
        body += path(
            "M145 268 Q110 231 160 190 Q142 159 182 124 Q185 178 215 187 Q224 165 234 162 Q272 229 224 270Z",
            "#d4753f",
            "#774b35",
            2,
        )
        body += path(
            "M161 267 Q137 232 180 191 Q172 225 196 224 Q213 209 214 189 Q247 243 213 272Z",
            "#efbc61",
            "none",
        )
        body += path("M175 265 Q164 247 187 228 Q208 245 206 267Z", "#fff1b1", "none")
        if kind == "campfire":
            body += path(
                "M73 292 L190 69 316 293 M191 72 L180 292", "none", "#56432d", 10
            )
            body += path("M76 292 L190 72 310 288", "none", "#b79a63", 3)
            body += path("M190 84 V158 M144 178 Q186 133 232 175", "none", "#38433c", 4)
            body += path(
                "M137 172 Q135 226 185 234 Q235 227 240 172Z", "#445c55", "#263d35", 3
            )
            body += ellipse(189, 172, 51, 12, "#aca886", "#344a40", 3)
    elif kind == "workbench":
        body += path(
            "M57 153 L58 288 81 293 91 166 M281 164 L284 291 311 282 305 150",
            "#765737",
            "#453f2f",
            3,
        )
        body += path(
            "M40 137 L109 100 338 133 279 180 43 162Z", "#a58350", "#4a4832", 3
        )
        body += path("M43 162 L279 180 279 198 44 180Z", "#6f5436")
        body += path(
            "M95 119 L314 146 M66 137 L296 166 M75 159 l200 17 M80 255 L289 265",
            "none",
            "#d8b97b",
            3,
        )
        body += path("M148 108 L218 140 M223 101 L191 132", "none", "#4a4937", 9)
        body += path("M190 88 L221 98 232 123 205 127Z", "#85958b")
        body += path("M86 125 L111 134 131 121 174 136 161 147 101 147Z", "#bcc8ab")
        body += path("M255 153 Q259 97 284 101 L309 157", "none", "#846b43", 5)
    elif kind == "foundation":
        body += path("M40 204 L188 119 354 194 208 290Z", "#ad8a54", "#504b33", 3)
        for i in range(7):
            body += path(
                f"M{46 + i * 22} {208 - i * 12} L{213 + i * 22} {282 - i * 12}",
                "none",
                "#5d5839",
                3,
            )
            body += path(
                f"M{48 + i * 22} {204 - i * 12} L{215 + i * 22} {278 - i * 12}",
                "none",
                "#d0ae72",
                2,
            )
    elif kind == "roof":
        body += path("M14 135 L174 30 365 119 218 222Z", "#75865a", "#3c553e", 4)
        for i in range(22):
            body += path(
                f"M{24 + i * 7} {137 - i * 4.5} l190 84 -5 13",
                "none",
                ["#a5a16a", "#586e48", "#d0ba7a"][i % 3],
                4,
            )
    elif kind == "wall":
        body += path("M38 78 L230 103 229 280 37 252Z", "#96724a", "#504531", 3)
        for i in range(10):
            body += path(f"M{45 + i * 19} {82 + i * 2.5} v170", "none", "#d1ae6e", 4)
        body += path("M39 112 L229 141 M39 217 L229 246", "none", "#5c5334", 8)
    else:
        body += path("M86 280 V78 L282 100 V285 M94 87 L274 109", "none", "#765738", 15)
        body += path("M102 107 L179 117 V284 L103 277Z", "#a17a48", "#574b32", 3)
        body += path(
            "M122 112 V278 M153 117 V280 M106 138 L174 153 M107 250 L174 266",
            "none",
            "#dec084",
            3,
        )
    return body


def animal(kind: str) -> str:
    if kind == "spider":
        body = ""
        for sign in [-1, 1]:
            for i in range(4):
                body += path(
                    f"M190 {125 + i * 10} L{190 + sign * (90 + i * 8)} {80 + i * 28} {190 + sign * (124 - i * 6)} {221 - i * 5}",
                    "none",
                    "#393c46",
                    12,
                )
                body += path(
                    f"M190 {125 + i * 10} L{190 + sign * (90 + i * 8)} {80 + i * 28}",
                    "none",
                    "#8e747e",
                    3,
                )
        body += ellipse(170, 125, 66, 61, "#66596a", "#343b40", 4) + ellipse(
            225, 172, 38, 30, "#4a4454", "#323a3a", 3
        )
        for x in [204, 218, 232, 243]:
            body += ellipse(x, 168, 4, 5, "#f4b575")
        return body
    wolf = kind == "wolf"
    defs_color = "#919e9b" if wolf else "#8a6d53"
    body = ellipse(188, 230, 145, 15, "#2d3d3233")
    body += path(
        "M94 161 L84 227 110 230 135 165 M215 165 L225 231 251 231 248 158",
        "#524c42",
        INK,
        3,
    )
    body += path(
        "M95 169 Q46 136 63 99 Q124 56 228 89 L275 114 291 181 Q210 215 120 184Z",
        defs_color,
        INK,
        3,
    )
    body += path(
        "M70 124 Q132 85 221 113 L235 161 Q159 179 95 157Z",
        "#b09b79" if not wolf else "#c2c7b7",
        "none",
    )
    body += path(
        "M243 104 L267 67 293 88 320 113 351 152 338 190 292 196 250 171Z",
        defs_color,
        INK,
        3,
    )
    body += path(
        "M261 92 L265 47 289 85 M287 88 L307 55 308 107",
        "#746551" if not wolf else "#707f7e",
        INK,
        3,
    )
    body += ellipse(304, 128, 6, 4, "#edd3a0", INK, 2) + ellipse(
        306, 128, 2, 3, "#29352d"
    )
    body += path("M324 146 L352 151 348 172 329 174Z", "#4c4640", INK, 2)
    body += path("M292 168 Q305 194 325 172", "none", "#efe3ba", 6)
    body += path("M70 113 Q32 86 23 106 Q21 125 46 121", "none", defs_color, 12)
    for x in range(91, 234, 13):
        body += path(
            f"M{x} 107 l8 -17 M{x} 123 l9 -9",
            "none",
            "#534e41" if not wolf else "#647672",
            1.5,
        )
    return body


def extras() -> None:
    save("Rock", rock(), 256, 192)
    save("Ore", rock(ore=True), 256, 192)
    save("Crystal", rock(crystal=True), 256, 192)
    save("Driftwood", wood(), 256, 160)
    save("Fern", fern(), 256, 192)
    save("Berries", fern(True), 256, 192)
    for kind in [
        "campfire",
        "workbench",
        "forge",
        "foundation",
        "wall",
        "roof",
        "door",
    ]:
        save(kind.capitalize(), structure(kind), 384, 320)
    for kind in ["boar", "wolf", "spider"]:
        save(kind.capitalize(), animal(kind), 384, 256)
    shadow = '<radialGradient id="s"><stop stop-color="#172d24" stop-opacity=".42"/><stop offset="1" stop-color="#172d24" stop-opacity="0"/></radialGradient>'
    save("Shadow", ellipse(64, 32, 63, 31, "url(#s)"), 128, 64, shadow)
    save(
        "Spring",
        ellipse(128, 126, 116, 45, "#668e6a")
        + ellipse(128, 123, 101, 35, "#83c4bc", "#cfdbc0", 3)
        + path(
            "M44 120 Q81 99 115 115 T210 119 M57 135 Q111 117 174 137",
            "none",
            "#d2e9cd",
            3,
        )
        + f'<g transform="translate(154 81) scale(.35)">{rock()}</g>',
        256,
        192,
    )
    save(
        "Crate",
        path("M33 84 L131 44 224 78 222 159 119 185 33 148Z", "#987a4e", INK, 3)
        + path(
            "M34 84 L121 118 224 78 M121 118 V185 M50 97 L50 151 M79 109 L79 160 M146 111 V176 M190 94 V165",
            "none",
            "#d3b47c",
            4,
        )
        + path("M37 141 L215 91 M39 95 L113 175", "none", "#574f39", 8),
        256,
        192,
    )
    sign = (
        path("M119 96 L124 305 145 307 140 87Z", "#80663e", INK, 3)
        + path("M47 89 L252 58 288 96 58 130Z", "#a98a53", INK, 3)
        + path("M55 99 L256 80 M68 111 L256 96", "none", "#d9bf80", 3)
        + path("M145 82 l64 0 -15 -12 M209 82 l-15 16", "none", "#445c43", 6)
    )
    save("Signpost", sign, 320, 320)
    beacon = (
        path(
            "M103 361 L163 40 213 360 M124 251 H203 M133 183 H191 M148 111 H178 M125 252 L190 183 147 110 178 110",
            "none",
            "#737e70",
            10,
        )
        + path("M60 101 L164 40 264 108 M165 40 V14", "none", "#c4b887", 7)
        + path("M108 321 H215 V372 H108Z", "#846a47", INK, 4)
        + path("M126 337 H162 V357 H126Z", "#bfce9e", INK, 3)
        + ellipse(190, 345, 9, 9, "#d4a56a", INK, 2)
    )
    save("Beacon", beacon, 320, 384)
    # A stone guardian with carved armor, a crest and turquoise seams.
    guard = ""
    for x in [88, 152]:
        guard += path(
            f"M{x} 269 L{x - 9} 385 {x + 35} 403 {x + 45} 391 {x + 30} 272Z",
            "#647f73",
            INK,
            4,
        )
    guard += path(
        "M60 157 L119 115 196 141 222 219 191 276 105 296 57 237Z", "#7e9780", INK, 4
    )
    guard += path(
        "M96 165 L143 151 182 176 171 244 124 268 101 223Z", "#abb595", INK, 3
    )
    guard += path(
        "M92 163 L131 174 157 161 175 197 147 224 166 247 M129 179 L128 228 109 243",
        "none",
        "#69d0b4",
        4,
    )
    guard += path(
        "M116 115 L95 80 106 32 151 14 190 48 186 102 153 134Z", "#9cae91", INK, 4
    )
    guard += path("M106 58 L176 67 176 84 110 76Z", "#344e48", INK, 3) + path(
        "M118 68 L133 69 M150 72 L164 74", "none", "#a4f0c7", 5
    )
    guard += path(
        "M56 174 L28 265 61 291 89 216 M196 169 L229 199 217 282 186 277",
        "#6b8573",
        INK,
        4,
    )
    save("Guardian", guard, 256, 448)
    # Weathered camp boat with ribs and torn canvas.
    boat = path("M32 218 Q153 325 458 176 L426 279 Q191 384 67 287Z", "#84613e", INK, 4)
    boat += path(
        "M33 218 Q210 284 458 176 L426 212 Q228 317 47 246Z", "#bd9b63", INK, 4
    )
    for x in range(110, 411, 43):
        boat += path(
            f"M{x} {280 - (x - 110) * 0.2} l-13 -52 7 -16", "none", "#5e5037", 9
        )
    boat += path("M218 262 L241 48 M108 143 L359 127", "none", "#6d5639", 8)
    boat += path(
        "M244 52 Q186 94 121 136 L183 149 163 173 246 162 273 177 289 141 331 133 286 121Z",
        "#d0c7a1",
        INK,
        3,
    )
    boat += path("M232 71 L216 142 M266 127 l32 5", "none", "#a69b78", 2)
    save("Wreck", boat, 512, 384)
    shelter = ellipse(257, 414, 208, 22, "#203b2b33")
    shelter += path("M68 251 L237 167 443 246 273 424 68 377Z", "#745f3b", INK, 4)
    shelter += path("M77 224 L281 278 V416 L79 372Z", "#b08e56", INK, 4)
    shelter += path("M281 278 L443 184 V353 L281 416Z", "#806b43", INK, 4)
    for x in range(93, 277, 19):
        shelter += path(
            f"M{x} {228 + (x - 93) * 0.26} V{375 + (x - 93) * 0.2}",
            "none",
            "#d1b57a",
            3,
        )
    shelter += path("M136 390 V275 L226 299 V409Z", "#344438", INK, 4)
    shelter += path("M140 281 L174 293 V394 L141 389Z", "#8a764c", INK, 2)
    shelter += path("M180 379 L226 392 215 401 177 389Z", "#c7bc88", INK, 1.5)
    shelter += path("M38 224 L228 68 479 174 288 302Z", "#627e4c", INK, 4)
    for index in range(25):
        x, y = 47 + index * 7.2, 223 - index * 5.75
        shelter += path(
            f"M{x} {y} l245 78  -4 8",
            "none",
            ["#adab6d", "#7a8e53", "#c2b47a"][index % 3],
            4,
        )
    shelter += path("M78 234 V373 M279 307 V422 M444 205 V354", "none", "#584e33", 9)
    shelter += path("M80 237 V369 M281 309 V418", "none", "#d7bd7d", 2)
    save("Shelter", shelter, 512, 448)


def tiles() -> None:
    rng = random.Random(191)
    for name, base, colors in [
        ("Sand", "#c6b280", ["#d9c795", "#a99d71", "#e8d6a1"]),
        ("Grass", "#61754a", ["#7d8f55", "#4c6543", "#97a166"]),
        ("Stone", "#78857a", ["#929b86", "#626f69", "#a6ab93"]),
    ]:
        body = f'<rect width="256" height="256" fill="{base}"/>'
        for index in range(170):
            x, y = rng.randrange(256), rng.randrange(256)
            color = colors[index % 3]
            if name == "Grass":
                body += path(
                    f"M{x} {y} q-5 -8 -3 -13 M{x} {y} q3 -10 8 -12", "none", color, 1.2
                )
            else:
                body += ellipse(x, y, rng.randrange(1, 7), rng.randrange(1, 3), color)
        save(name, body, 256, 256)
    foam = ""
    for y in [28, 55, 87]:
        foam += path(
            f"M0 {y} Q64 {y - 17} 128 {y} T256 {y}",
            "none",
            "#e3edcf",
            3,
            extra='opacity=".65"',
        )
    save("Foam", foam, 256, 128)


def main() -> None:
    require_space()
    OUT.mkdir(parents=True, exist_ok=True)
    survivor()
    survivor(True)
    tree(True)
    tree(False)
    extras()
    tiles()
    print(
        f"Illustrated assets: {sum(p.stat().st_size for p in OUT.glob('*.svg')) / 1024:.1f} KiB"
    )


if __name__ == "__main__":
    main()
