# File: socket/whisper_constants.py
from enum import Enum

class TaskEnum(str, Enum):
    transcribe = "transcribe"
    translate = "translate"

class WhisperAvailableLanguagesEnum(str, Enum):
    af = "af"
    am = "am"
    ar = "ar"
    as_ = "as"
    az = "az"
    ba = "ba"
    be = "be"
    bg = "bg"
    bn = "bn"
    bo = "bo"
    br = "br"
    bs = "bs"
    ca = "ca"
    cs = "cs"
    cy = "cy"
    da = "da"
    de = "de"
    el = "el"
    en = "en"
    es = "es"
    et = "et"
    eu = "eu"
    fa = "fa"
    fi = "fi"
    fo = "fo"
    fr = "fr"
    gl = "gl"
    gu = "gu"
    ha = "ha"
    haw = "haw"
    he = "he"
    hi = "hi"
    hr = "hr"
    ht = "ht"
    hu = "hu"
    hy = "hy"
    id = "id"
    is_ = "is"
    it = "it"
    ja = "ja"
    jw = "jw"
    ka = "ka"
    kk = "kk"
    km = "km"
    kn = "kn"
    ko = "ko"
    la = "la"
    lb = "lb"
    ln = "ln"
    lo = "lo"
    lt = "lt"
    lv = "lv"
    mg = "mg"
    mi = "mi"
    mk = "mk"
    ml = "ml"
    mn = "mn"
    mr = "mr"
    ms = "ms"
    mt = "mt"
    my = "my"
    ne = "ne"
    nl = "nl"
    nn = "nn"
    no = "no"
    oc = "oc"
    pa = "pa"
    pl = "pl"
    ps = "ps"
    pt = "pt"
    ro = "ro"
    ru = "ru"
    sa = "sa"
    sd = "sd"
    si = "si"
    sk = "sk"
    sl = "sl"
    sn = "sn"
    so = "so"
    sq = "sq"
    sr = "sr"
    su = "su"
    sv = "sv"
    sw = "sw"
    ta = "ta"
    te = "te"
    tg = "tg"
    th = "th"
    tk = "tk"
    tl = "tl"
    tr = "tr"
    tt = "tt"
    uk = "uk"
    ur = "ur"
    uz = "uz"
    vi = "vi"
    yi = "yi"
    yo = "yo"
    yue = "yue"
    zh = "zh"

class ChunkLevelEnum(str, Enum):
    segment = "segment"

class VersionEnum(str, Enum):
    v3 = "3"
