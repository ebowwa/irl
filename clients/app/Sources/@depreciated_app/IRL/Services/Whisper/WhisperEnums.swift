//
//  WhisperEnums.swift
//  irl
//
//  Created by Elijah Arbee on 9/8/24.
//
import Foundation

enum TaskEnum: String, Codable, CaseIterable {
    case transcribe
    case translate
}

enum LanguageEnum: String, Codable, CaseIterable {
    case af, am, ar, as_, az, ba, be, bg, bn, bo, br, bs, ca, cs, cy, da, de, el, en, es, et, eu, fa, fi, fo, fr, gl, gu, ha, haw, he, hi, hr, ht, hu, hy, id, is_, it, ja, jw, ka, kk, km, kn, ko, la, lb, ln, lo, lt, lv, mg, mi, mk, ml, mn, mr, ms, mt, my, ne, nl, nn, no, oc, pa, pl, ps, pt, ro, ru, sa, sd, si, sk, sl, sn, so, sq, sr, su, sv, sw, ta, te, tg, th, tk, tl, tr, tt, uk, ur, uz, vi, yi, yo, yue, zh
}

enum ChunkLevelEnum: String, Codable {
    case segment
}

enum VersionEnum: String, Codable {
    case v3 = "3"
}
