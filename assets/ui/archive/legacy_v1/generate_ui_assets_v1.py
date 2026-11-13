#!/usr/bin/env python3
"""Generate deterministic, transparent UI sprites for Yanlış Dünya.

Uses only Python's standard library. All colors are authored in sRGB RGBA.
"""
from __future__ import annotations

import math
import os
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
UI = ROOT / "assets" / "ui"
ICONS = UI / "icons"
WORLD = ROOT / "assets" / "world"

NAVY = (15, 24, 36)
PANEL = (15, 24, 36)
STEEL = (76, 101, 119)
STEEL_LIGHT = (118, 147, 163)
CYAN = (103, 222, 230)
MAGENTA = (196, 112, 180)
AMBER = (242, 177, 82)
GREEN = (105, 218, 155)
RED = (229, 100, 90)
PALE = (232, 241, 242)


class Canvas:
    def __init__(self, w: int, h: int):
        self.w, self.h = w, h
        self.p = bytearray(w * h * 4)

    def over(self, x: int, y: int, color):
        if x < 0 or y < 0 or x >= self.w or y >= self.h:
            return
        i = (y * self.w + x) * 4
        r, g, b, a = color if len(color) == 4 else (*color, 255)
        if a <= 0:
            return
        da = self.p[i + 3]
        oa = a + da * (255 - a) // 255
        if oa == 0:
            return
        self.p[i] = (r * a + self.p[i] * da * (255 - a) // 255) // oa
        self.p[i + 1] = (g * a + self.p[i + 1] * da * (255 - a) // 255) // oa
        self.p[i + 2] = (b * a + self.p[i + 2] * da * (255 - a) // 255) // oa
        self.p[i + 3] = oa

    def rect(self, x, y, w, h, color):
        for yy in range(max(0, y), min(self.h, y + h)):
            for xx in range(max(0, x), min(self.w, x + w)):
                self.over(xx, yy, color)

    def grad_rect(self, x, y, w, h, top, bottom):
        for yy in range(max(0, y), min(self.h, y + h)):
            t = 0 if h <= 1 else (yy - y) / (h - 1)
            c = tuple(round(top[i] * (1 - t) + bottom[i] * t) for i in range(4))
            self.rect(x, yy, w, 1, c)

    def rounded(self, x, y, w, h, r, color, outline=None, thick=1, cut=0):
        x0, y0 = max(0, x), max(0, y)
        x1, y1 = min(self.w, x + w), min(self.h, y + h)
        for yy in range(y0, y1):
            for xx in range(x0, x1):
                dx = min(xx - x, x + w - 1 - xx)
                dy = min(yy - y, y + h - 1 - yy)
                inside = True
                if dx < r and dy < r:
                    inside = (r - dx) ** 2 + (r - dy) ** 2 <= r * r
                if cut and ((xx < x + cut and yy < y + cut and xx - x + yy - y < cut) or
                            (xx >= x + w - cut and yy >= y + h - cut and
                             x + w - 1 - xx + y + h - 1 - yy < cut)):
                    inside = False
                if not inside:
                    continue
                if outline is not None and (xx - x < thick or x + w - 1 - xx < thick or
                                            yy - y < thick or y + h - 1 - yy < thick):
                    self.over(xx, yy, outline)
                else:
                    self.over(xx, yy, color)

    def circle(self, cx, cy, r, color, outline=None, thick=1):
        rr = r * r
        for y in range(max(0, cy - r), min(self.h, cy + r + 1)):
            for x in range(max(0, cx - r), min(self.w, cx + r + 1)):
                d = (x - cx) ** 2 + (y - cy) ** 2
                if d <= rr:
                    if outline is not None and d >= max(0, r - thick) ** 2:
                        self.over(x, y, outline)
                    else:
                        self.over(x, y, color)

    def ellipse(self, cx, cy, rx, ry, color, outline=None, thick=1):
        if rx <= 0 or ry <= 0:
            return
        for y in range(max(0, cy - ry), min(self.h, cy + ry + 1)):
            for x in range(max(0, cx - rx), min(self.w, cx + rx + 1)):
                d = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2
                if d <= 1:
                    inner = ((x - cx) / max(1, rx - thick)) ** 2 + ((y - cy) / max(1, ry - thick)) ** 2
                    self.over(x, y, outline if outline is not None and inner >= 1 else color)

    def line(self, x1, y1, x2, y2, color, width=2):
        rad = max(0.5, width / 2)
        minx, maxx = int(min(x1, x2) - rad - 1), int(max(x1, x2) + rad + 1)
        miny, maxy = int(min(y1, y2) - rad - 1), int(max(y1, y2) + rad + 1)
        vx, vy = x2 - x1, y2 - y1
        ll = vx * vx + vy * vy
        for y in range(max(0, miny), min(self.h, maxy + 1)):
            for x in range(max(0, minx), min(self.w, maxx + 1)):
                t = 0 if ll == 0 else max(0, min(1, ((x - x1) * vx + (y - y1) * vy) / ll))
                dx, dy = x - (x1 + t * vx), y - (y1 + t * vy)
                if dx * dx + dy * dy <= rad * rad:
                    self.over(x, y, color)

    def poly(self, pts, color, outline=None, width=1):
        if len(pts) < 3:
            return
        miny = max(0, int(min(y for _, y in pts)))
        maxy = min(self.h - 1, int(max(y for _, y in pts)) + 1)
        for y in range(miny, maxy + 1):
            xs = []
            for i in range(len(pts)):
                x1, y1 = pts[i]
                x2, y2 = pts[(i + 1) % len(pts)]
                if (y1 <= y < y2) or (y2 <= y < y1):
                    xs.append(x1 + (y - y1) * (x2 - x1) / (y2 - y1))
            xs.sort()
            for i in range(0, len(xs) - 1, 2):
                for x in range(max(0, int(xs[i])), min(self.w, int(xs[i + 1]) + 1)):
                    self.over(x, y, color)
        if outline:
            for i in range(len(pts)):
                self.line(*pts[i], *pts[(i + 1) % len(pts)], outline, width)

    def save(self, path: Path):
        path.parent.mkdir(parents=True, exist_ok=True)
        raw = bytearray()
        stride = self.w * 4
        for y in range(self.h):
            raw.append(0)
            raw.extend(self.p[y * stride:(y + 1) * stride])
        def chunk(tag, data):
            return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xffffffff)
        png = b"\x89PNG\r\n\x1a\n"
        png += chunk(b"IHDR", struct.pack(">2I5B", self.w, self.h, 8, 6, 0, 0, 0))
        png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
        png += chunk(b"IEND", b"")
        path.write_bytes(png)


def save_button(name, size, primary=False, state="normal", skip=False):
    w, h = size
    c = Canvas(w, h)
    if primary:
        fill = (57, 45, 31, 242); border = (AMBER[0], AMBER[1], AMBER[2], 240)
        glow = (AMBER[0], AMBER[1], AMBER[2], 55)
    elif skip:
        fill = (21, 31, 43, 190); border = (STEEL_LIGHT[0], STEEL_LIGHT[1], STEEL_LIGHT[2], 150)
        glow = (CYAN[0], CYAN[1], CYAN[2], 20)
    else:
        fill = (24, 37, 51, 232); border = (STEEL_LIGHT[0], STEEL_LIGHT[1], STEEL_LIGHT[2], 190)
        glow = (CYAN[0], CYAN[1], CYAN[2], 36)
    if state == "hover":
        border = (*CYAN, 245); glow = (*CYAN, 85)
    elif state == "pressed":
        fill = (10, 18, 28, 245); border = (AMBER if primary else CYAN) + (220,)
    elif state == "disabled":
        fill = (31, 40, 48, 135); border = (105, 122, 132, 145); glow = (0, 0, 0, 0)
    cut = max(5, h // 5)
    c.rounded(3, 3, w - 6, h - 6, 9, glow, None, cut=cut)
    c.rounded(5, 5, w - 10, h - 10, 7, fill, border, thick=max(1, h // 32), cut=cut)
    hi = (211, 236, 239, 100 if state != "disabled" else 45)
    c.line(12, 10, w - cut - 6, 10, hi, max(1, h // 40))
    c.line(8, h // 2, 8, h - 14, (CYAN if not primary else AMBER) + (75,), 1)
    if state == "disabled":
        dash = (142, 151, 156, 160)
        for x in range(cut + 8, w - cut - 8, max(8, h // 4)):
            c.line(x, h - 7, min(x + h // 8, w - cut), h - 7, dash, 1)
    elif state == "pressed":
        c.line(12, h - 10, w - cut - 8, h - 10, (0, 0, 0, 100), max(1, h // 30))
    c.save(UI / name)


def panel(name, w, h, info=False):
    c = Canvas(w, h)
    c.rounded(2, 2, w - 4, h - 4, 18, (15, 24, 36, 208), (103, 222, 230, 205), 2, cut=24)
    c.line(28, 3, w - 34, 3, (225, 242, 244, 105), 1)
    c.line(4, 28, 4, h - 30, (103, 222, 230, 105), 1)
    if info:
        c.rounded(7, 7, w - 14, 64, 14, (34, 51, 67, 205), (242, 177, 82, 210), 2, cut=18)
        c.line(28, 74, w - 24, 74, (103, 222, 230, 110), 1)
    c.save(UI / name)


def draw_icon(key, c, s=128, color=PALE):
    k = s / 128
    def L(a, b, d, e, w=3, col=None): c.line(round(a*k), round(b*k), round(d*k), round(e*k), (*((col or color)), 255), max(1, round(w*k)))
    def C(x, y, r, fill=(0,0,0,0), outline=color, w=3): c.circle(round(x*k),round(y*k),round(r*k),fill,(*outline,255),max(1,round(w*k)))
    def E(x,y,rx,ry,fill=(0,0,0,0),outline=color,w=3): c.ellipse(round(x*k),round(y*k),round(rx*k),round(ry*k),fill,(*outline,255),max(1,round(w*k)))
    def P(points, fill=(0,0,0,0), outline=color,w=3):
        pts=[(round(x*k),round(y*k)) for x,y in points]
        c.poly(pts,(*fill,255) if len(fill)==3 else fill,(*outline,255),max(1,round(w*k)))
    if key == "seasons":
        C(63,64,36); L(44,28,83,101); L(59,27,87,96); E(64,64,55,20); L(51,20,83,108,2,CYAN)
        for x,y in [(42,40),(73,51),(49,81),(75,84)]: C(x,y,2,color,color,1)
    elif key == "measurement":
        P([(25,92),(92,25),(105,38),(38,105)]); 
        for i in range(7):
            t=i/6; x=31+61*t; y=98-61*t
            L(x,y,x-3,y-10 if i%2 else y-15,2)
    elif key == "vectors":
        L(27,101,27,25); L(27,101,105,101); L(27,101,84,42)
        L(27,25,23,35); L(27,25,31,35); L(105,101,94,97); L(105,101,94,105); L(84,42,73,45); L(84,42,81,53)
        C(27,101,3,color,color,1)
    elif key == "bridge":
        P([(27,95),(91,95),(91,32)]); L(27,95,91,32); P([(34,92),(52,92),(52,75),(34,75)]); P([(58,68),(76,68),(76,51),(58,51)])
        L(25,101,98,101,2,CYAN)
    elif key == "prism":
        P([(27,90),(64,29),(101,90)]); L(18,60,42,60); L(42,60,76,50); L(76,50,108,35,2,CYAN); L(76,50,108,62,2,MAGENTA)
    elif key == "free_fall":
        C(64,50,14,(232,241,242,0),color,3); L(64,16,64,27); L(54,81,64,100); L(74,81,64,100); L(44,83,56,92); L(84,83,72,92)
        L(64,2,64,15,2,CYAN); L(54,7,54,18,2,MAGENTA); L(74,7,74,18,2,MAGENTA)
    elif key == "indicator":
        P([(42,22),(86,22),(81,90),(73,105),(55,105),(47,90)]); L(44,32,84,32); L(49,76,80,76,3,CYAN); L(49,76,52,92,2); L(78,76,75,92,2)
    elif key == "heart":
        pts=[(64,101),(28,72),(22,52),(29,34),(45,29),(58,39),(64,48),(71,37),(86,29),(103,37),(109,54),(102,72),(64,101)]
        P(pts); L(26,59,46,59); L(46,59,54,48); L(54,48,66,72); L(66,72,75,55); L(75,55,83,59); L(83,59,104,59,2,CYAN)
    elif key == "pressure":
        C(64,62,38); C(64,62,3,color,color,1); L(64,62,88,42,4,AMBER); L(64,24,64,31); L(26,62,33,62); L(95,62,102,62); P([(49,101),(79,101),(73,111),(55,111)])
    elif key == "route_class":
        P([(20,38),(58,46),(64,52),(70,46),(108,38),(108,86),(70,95),(64,100),(58,95),(20,86)]); L(64,52,64,94); L(28,47,55,54); L(99,47,73,54)
    elif key == "route_lgs":
        P([(64,16),(101,36),(94,82),(64,108),(34,82),(27,36)]); L(45,44,82,44); L(45,44,45,82); L(45,64,75,64); L(75,64,75,82); L(45,82,75,82)
    elif key == "route_tyt":
        P([(64,22),(105,96),(23,96)]); L(45,77,83,77); L(52,63,76,63); L(59,49,69,49)
    elif key == "route_ayt":
        E(64,64,39,15); E(64,64,39,15); L(35,94,93,34,2,CYAN); L(34,34,94,94,2,MAGENTA); C(64,64,6,AMBER,AMBER,1)
    elif key == "state_playable":
        C(32,32,26,(15,24,36,0),color,3); P([(26,17),(26,47),(48,32)],color,color,1)
    elif key == "state_ready":
        P([(32,4),(40,20),(58,8),(55,28),(62,32),(55,38),(58,57),(40,44),(32,60),(24,44),(6,57),(9,38),(2,32),(9,28),(6,8),(24,20)])
        C(32,32,5,AMBER,AMBER,1)
    elif key == "state_repaired":
        P([(32,2),(58,15),(54,43),(32,62),(10,43),(6,15)],(15,50,40,0),GREEN,3); L(17,32,27,42,4,GREEN); L(27,42,47,21,4,GREEN)
    elif key == "flow_arrow":
        P([(6,23),(81,23),(81,8),(122,32),(81,56),(81,41),(6,41)],color,color,1)


def icon_file(key, size=128, color=PALE, path=None):
    c=Canvas(size,size); draw_icon(key,c,size,color); c.save(path or ICONS/(key+".png"))


def make_plinth():
    c=Canvas(1024,1024)
    c.ellipse(512,745,405,190,(4,9,16,105),None)
    c.ellipse(512,704,382,170,(37,53,66,255),(122,151,165,255),10)
    c.ellipse(512,690,344,144,(18,31,45,255),(76,105,123,255),7)
    c.ellipse(512,674,316,119,(44,60,72,255),(118,144,155,255),6)
    c.ellipse(512,661,286,96,(19,32,46,255),(71,99,116,255),5)
    c.ellipse(512,646,250,69,(29,44,57,255),(242,177,82,255),4)
    c.ellipse(512,632,223,52,(21,34,48,255),(83,110,125,255),3)
    # top inlay and perspective clamps
    for a in range(0,360,45):
        x=512+int(340*math.cos(math.radians(a))); y=697+int(138*math.sin(math.radians(a)))
        c.ellipse(x,y,22,11,(52,70,83,255),(134,156,168,255),2)
        c.circle(x,y,3,(242,177,82,255))
    for a in range(210,331,30):
        x=512+int(235*math.cos(math.radians(a))); y=644+int(54*math.sin(math.radians(a)))
        c.circle(x,y,4,(242,177,82,220))
    c.save(WORLD/"station_plinth.png")


def make_frame():
    w,h=1920,1080; c=Canvas(w,h)
    # border-only composition; transparent center remains available for scene/UI.
    c.rect(0,0,w,28,(14,23,34,230)); c.rect(0,h-30,w,30,(14,23,34,230))
    c.rect(0,0,32,h,(14,23,34,235)); c.rect(w-32,0,32,h,(14,23,34,235))
    c.rect(32,25,w-64,3,(112,142,157,190)); c.rect(32,h-33,w-64,3,(73,97,112,200))
    c.rect(31,31,3,h-62,(73,97,112,210)); c.rect(w-34,31,3,h-62,(73,97,112,210))
    # interior viewport and right information bay separators
    c.rect(1410,33,4,h-66,(103,222,230,160)); c.rect(1415,33,2,h-66,(242,177,82,90))
    for x,y in [(24,24),(w-24,24),(24,h-24),(w-24,h-24),(1411,72),(1411,h-72)]:
        c.circle(x,y,9,(35,50,62,255),(132,154,166,255),2); c.circle(x,y,2,(242,177,82,230))
    # cropped mechanical corner brackets
    for x,y,dx,dy in [(40,40,1,1),(w-40,40,-1,1),(40,h-40,1,-1),(w-40,h-40,-1,-1)]:
        c.line(x,y,x+dx*40,y,(*CYAN,170),2); c.line(x,y,x,y+dy*34,(*CYAN,170),2)
    c.save(UI/"bg_mission_frame.png")


def make_intro_plate():
    w,h=1280,360; c=Canvas(w,h)
    pts=[(26,18),(1253,18),(1262,34),(1250,325),(1223,342),(112,342),(96,334),(78,340),(62,330),(26,334),(18,310),(26,250),(18,220),(28,185),(18,155),(30,115),(21,81),(29,48)]
    c.poly(pts,(17,28,41,235),(118,145,156,220),3)
    c.poly([(42,31),(1237,31),(1243,47),(1232,302),(1210,322),(112,322),(92,315),(75,322),(53,311)],(23,36,49,95),(103,222,230,120),1)
    c.line(47,47,1168,47,(217,231,235,125),2)
    # crack and red fault lamp on the left edge
    c.line(83,14,66,79,(159,178,188,240),3); c.line(66,79,86,109,(159,178,188,240),2); c.line(66,79,39,94,(159,178,188,200),2)
    c.ellipse(94,62,18,14,(100,15,18,220),(229,100,90,245),2); c.circle(94,62,6,(255,91,77,255))
    c.line(1150,315,1215,248,(103,222,230,105),2)
    c.save(UI/"intro_title_plate.png")


def main():
    for d in (UI, ICONS, WORLD): d.mkdir(parents=True,exist_ok=True)
    panel("panel_glass.png",512,512)
    panel("panel_info.png",512,768,True)
    for state in ("normal","hover","pressed","disabled"):
        save_button(f"btn_{state}.png",(256,64),state=state)
        save_button(f"btn_primary_{state}.png",(320,72),primary=True,state=state)
    for state in ("normal","hover"):
        save_button(f"btn_skip_{state}.png",(160,44),skip=True,state=state)
    for name,active in (("tab_active.png",True),("tab_idle.png",False)):
        c=Canvas(192,48); c.rounded(2,2,188,44,7,(20,32,45,230),(103,222,230,155),1,cut=9)
        if active: c.rect(11,43,170,3,(*AMBER,255)); c.line(11,5,180,5,(*AMBER,90),1)
        else: c.line(11,43,180,43,(95,118,132,130),1)
        c.save(UI/name)
    for name,selected in (("list_row_idle.png",False),("list_row_selected.png",True)):
        c=Canvas(512,56); c.rounded(1,1,510,54,8,(20,32,45,225),(87,111,128,140),1,cut=10)
        if selected: c.rect(1,7,4,42,(*AMBER,255)); c.rect(8,2,70,2,(*AMBER,85)); c.line(17,52,498,52,(*AMBER,90),1)
        else: c.line(14,52,498,52,(88,108,123,115),1)
        c.save(UI/name)
    # Distinct status badge silhouettes.
    c=Canvas(48,48); c.circle(24,24,21,(18,43,39,245),(*GREEN,255),3); c.line(12,24,21,33,(*GREEN,255),4); c.line(21,33,37,14,(*GREEN,255),4); c.save(UI/"badge_done.png")
    c=Canvas(48,48); c.poly([(24,2),(44,12),(41,35),(24,46),(7,35),(4,12)],(20,31,43,245),(*STEEL_LIGHT,255),2); c.rounded(14,20,20,16,4,(55,71,82,255),(*PALE,255),2); c.ellipse(24,19,9,8,(0,0,0,0),(*PALE,255),2); c.line(24,27,24,31,(*PALE,255),2); c.save(UI/"badge_locked.png")
    c=Canvas(48,48); c.poly([(24,2),(29,14),(44,14),(33,24),(38,42),(24,32),(10,42),(15,24),(4,14),(19,14)],(47,39,25,250),(*AMBER,255),2); c.circle(24,24,4,(*AMBER,255)); c.save(UI/"badge_ready.png")
    for key in ("seasons","measurement","vectors","bridge","prism","free_fall","indicator","heart","pressure"):
        icon_file(key)
    for key in ("route_class","route_lgs","route_tyt","route_ayt"):
        icon_file(key,128,PALE,ICONS/(key+".png"))
    for key in ("state_playable","state_ready","state_repaired"):
        color=GREEN if key=="state_repaired" else (AMBER if key=="state_ready" else CYAN)
        icon_file(key,64,color,ICONS/(key+".png"))
    flow=Canvas(128,64)
    flow.poly([(6,23),(81,23),(81,8),(122,32),(81,56),(81,41),(6,41)],(*PALE,255),(*PALE,255),1)
    flow.save(UI/"flow_arrow.png")
    make_plinth(); make_frame(); make_intro_plate()
    (UI/"FONT_ASSETS.md").write_text("""# Font asset note\n\nThe local system has no bundled OFL family containing a complete Latin Extended set and a mono companion, and the installed system fonts are not redistributable. Font binaries were not copied. Recommended family for integration: IBM Plex Sans (headings/body) and IBM Plex Mono (formulas), both under the SIL Open Font License; obtain from the official Google Fonts repository and include its OFL.txt when font files can be added.\n\nTurkish coverage required: İ, ı, Ş, Ğ, Ç, Ö, Ü.\n""",encoding="utf-8")


if __name__ == "__main__":
    main()
