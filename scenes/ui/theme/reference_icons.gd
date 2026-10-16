extends RefCounted
## Combat-only atlas views. Cleanly separable approved glyphs use the original
## painting and contour masks; other glyphs retain the GPT Image sprite sheet.
## Regions change sampling, never source pixels; shared SVGs stay independent.
const ATLAS = preload("res://assets/ui/combat/reference/icons.png")
const SOURCE_SIZE := Vector2(1448, 1086)
const NAVIGATION_ATLAS = preload("res://assets/ui/combat/reference/approved-atlas.png")
const NAVIGATION_MASK = preload("res://assets/ui/combat/reference/navigation_mask.gdshader")
const NAVIGATION_SOURCE_SIZE := Vector2(841, 1870)
const NAVIGATION_REGIONS := {
	"menu": Rect2(118, 1790, 49, 42),
	"map": Rect2(295, 1788, 63, 45),
	"guide": Rect2(478, 1788, 67, 46),
	"sound_on": Rect2(665, 1788, 61, 46),
}
const RESOURCE_REGIONS := {
	"begin": Rect2(123, 663, 96, 94),
	"health": Rect2(63, 521, 51, 46),
	"energy": Rect2(376, 522, 32, 45),
	"shield": Rect2(395, 1426, 50, 52),
	"focus": Rect2(575, 1430, 66, 45),
}
const RESOURCE_CONTOURS := {
	# The Begin ring is intact. Follow its painted edge at the right so the
	# baked gold wire stays outside this sample; its caption remains live.
	"begin": [[Vector2(155,665),Vector2(170,663.5),Vector2(185,666),Vector2(194,670),Vector2(201,675),Vector2(207,681),Vector2(212,689),Vector2(215,696),Vector2(217.5,703),Vector2(217,710),Vector2(216,714),Vector2(215.2,718),Vector2(214.2,722),Vector2(213.5,724),Vector2(212.5,728),Vector2(209,734),Vector2(205.5,739),Vector2(200,744),Vector2(194,748),Vector2(187,751.5),Vector2(177,755.5),Vector2(166,755.5),Vector2(155,752.5),Vector2(145,748),Vector2(138,742),Vector2(133,736),Vector2(129,730),Vector2(126,722),Vector2(124,713),Vector2(123.5,704),Vector2(125,696),Vector2(127,688),Vector2(131,681),Vector2(136,676),Vector2(143,670)]],
	"health": [[Vector2(65,533),Vector2(68,527),Vector2(73,523),Vector2(78,522),Vector2(82,524),Vector2(88,532),Vector2(93,527),Vector2(98,524),Vector2(103,523),Vector2(108,527),Vector2(111,533),Vector2(112,539),Vector2(110,545),Vector2(106,550),Vector2(99,556),Vector2(88,565),Vector2(85,563),Vector2(79,557),Vector2(72,552),Vector2(67,546),Vector2(64,539)]],
	"energy": [[Vector2(392,522),Vector2(406,535),Vector2(406,554),Vector2(393,565),Vector2(377,554),Vector2(377,535)]],
	"shield": [[Vector2(419,1427),Vector2(425,1434),Vector2(432,1437),Vector2(444,1437),Vector2(443,1450),Vector2(441,1461),Vector2(431,1470),Vector2(420,1478),Vector2(409,1470),Vector2(400,1463),Vector2(397,1450),Vector2(396,1436),Vector2(406,1436),Vector2(413,1432)]],
	"focus": [[Vector2(576,1439),Vector2(582,1437),Vector2(584,1433),Vector2(591,1431),Vector2(600,1432),Vector2(608,1437),Vector2(615,1433),Vector2(622,1431),Vector2(630,1432),Vector2(632,1437),Vector2(638,1438),Vector2(640,1470),Vector2(618,1468),Vector2(608,1474),Vector2(599,1470),Vector2(577,1472)]],
}
# Contours follow the approved gold paint and its immediate dark outline.
# Disconnected Menu bars and Sound waves do not carry background rectangles.
const NAVIGATION_CONTOURS := {
	"menu": [
		[Vector2(119,1791),Vector2(165,1791),Vector2(166,1792),Vector2(166,1799),Vector2(165,1800),Vector2(119,1800),Vector2(118,1799),Vector2(118,1792)],
		[Vector2(119,1806),Vector2(165,1806),Vector2(166,1807),Vector2(166,1815),Vector2(165,1816),Vector2(119,1816),Vector2(118,1815),Vector2(118,1807)],
		[Vector2(119,1820),Vector2(165,1820),Vector2(166,1821),Vector2(166,1830),Vector2(165,1831),Vector2(119,1831),Vector2(118,1830),Vector2(118,1821)],
	],
	"map": [[Vector2(295,1793),Vector2(312,1789),Vector2(318,1789),Vector2(338,1793),Vector2(355,1789),Vector2(357,1790),Vector2(357,1829),Vector2(340,1832),Vector2(326,1832),Vector2(315,1830),Vector2(296,1832),Vector2(295,1831)]],
	"guide": [[Vector2(478,1795),Vector2(482,1794),Vector2(483,1792),Vector2(491,1789),Vector2(503,1789),Vector2(510,1793),Vector2(516,1790),Vector2(531,1790),Vector2(539,1792),Vector2(540,1796),Vector2(543,1797),Vector2(544,1832),Vector2(530,1831),Vector2(515,1832),Vector2(511,1833),Vector2(505,1832),Vector2(487,1831),Vector2(479,1833)]],
	"sound_on": [
		[Vector2(666,1802),Vector2(677,1802),Vector2(694,1789),Vector2(696,1790),Vector2(697,1832),Vector2(694,1832),Vector2(678,1821),Vector2(666,1821)],
		[Vector2(699,1802),Vector2(702,1803),Vector2(705,1807),Vector2(706,1812),Vector2(705,1816),Vector2(702,1820),Vector2(699,1819),Vector2(701,1815),Vector2(702,1811),Vector2(701,1807)],
		[Vector2(707,1796),Vector2(710,1797),Vector2(714,1803),Vector2(715,1810),Vector2(715,1816),Vector2(712,1822),Vector2(709,1825),Vector2(706,1824),Vector2(709,1818),Vector2(710,1813),Vector2(710,1808),Vector2(708,1802),Vector2(706,1798)],
		[Vector2(713,1791),Vector2(716,1791),Vector2(720,1797),Vector2(723,1803),Vector2(725,1811),Vector2(724,1818),Vector2(721,1825),Vector2(717,1831),Vector2(713,1833),Vector2(712,1830),Vector2(715,1825),Vector2(718,1818),Vector2(719,1811),Vector2(718,1804),Vector2(716,1799),Vector2(712,1794)],
	],
}
# Measured visible bounds (alpha > 1/255). The generator left isolated alpha=1
# pixels across the cells; including those would shrink the actual symbols.
const REGIONS := {
	"health": Rect2(85, 114, 238, 213),
	"energy": Rect2(470, 91, 158, 247),
	"spark": Rect2(763, 81, 272, 270),
	"shield": Rect2(1148, 100, 204, 226),
	"focus": Rect2(70, 464, 267, 176),
	"remove": Rect2(448, 768, 206, 208),
	"rotate": Rect2(804, 774, 231, 209),
	"attack": Rect2(1133, 726, 249, 284),
}
static var _cropped: Dictionary = {}
static var _board: Dictionary = {}
static var _navigation_materials: Dictionary = {}

static func _has_approved_icon(name: String) -> bool:
	return NAVIGATION_REGIONS.has(name) or RESOURCE_REGIONS.has(name)

static func _approved_region(name: String) -> Rect2:
	return NAVIGATION_REGIONS[name] if NAVIGATION_REGIONS.has(name) else RESOURCE_REGIONS[name]

static func _approved_contours(name: String) -> Array:
	return NAVIGATION_CONTOURS[name] if NAVIGATION_CONTOURS.has(name) else RESOURCE_CONTOURS[name]

static func _region(name: String) -> Rect2:
	# Import size limits can downsample the GPU texture without changing the
	# source sheet. Apply the same ratio to every sampled coordinate.
	var scale: Vector2 = ATLAS.get_size() / SOURCE_SIZE
	var original: Rect2 = REGIONS[name]
	return Rect2(original.position * scale, original.size * scale)

static func texture(name: String) -> Texture2D:
	if _has_approved_icon(name):
		if not _cropped.has(name):
			var result := AtlasTexture.new()
			var scale: Vector2 = NAVIGATION_ATLAS.get_size() / NAVIGATION_SOURCE_SIZE
			var source: Rect2 = _approved_region(name)
			result.atlas = NAVIGATION_ATLAS
			result.region = Rect2(source.position * scale, source.size * scale)
			result.filter_clip = true
			_cropped[name] = result
		return _cropped[name]
	if not REGIONS.has(name):
		return null
	if not _cropped.has(name):
		var result := AtlasTexture.new()
		result.atlas = ATLAS
		result.region = _region(name)
		result.filter_clip = true
		_cropped[name] = result
	return _cropped[name]

static func material(name: String) -> Material:
	if not _has_approved_icon(name):
		return null
	if not _navigation_materials.has(name):
		var vertices := PackedVector2Array()
		var ends := PackedInt32Array([0, 0, 0, 0])
		var contours: Array = _approved_contours(name)
		for index in contours.size():
			vertices.append_array(PackedVector2Array(contours[index]))
			ends[index] = vertices.size()
		vertices.resize(96)
		var result := ShaderMaterial.new()
		result.shader = NAVIGATION_MASK
		result.set_shader_parameter("vertices", vertices)
		result.set_shader_parameter("contour_ends", Vector4i(ends[0], ends[1], ends[2], ends[3]))
		_navigation_materials[name] = result
	return _navigation_materials[name]

static func navigation_geometry(name: String) -> Dictionary:
	if not NAVIGATION_REGIONS.has(name): return {}
	return source_geometry(name)

static func source_geometry(name: String) -> Dictionary:
	if not _has_approved_icon(name): return {}
	return {"reference_rect": _approved_region(name), "contours": _approved_contours(name).duplicate(true), "atlas": NAVIGATION_ATLAS.resource_path}

static func board_texture(name: String) -> Texture2D:
	if not name in ["spark", "shield"]:
		return null
	if not _board.has(name):
		# Keep the canonical glyph's visible fraction of its 128-unit canvas.
		# AtlasTexture margins are virtual transparency, not resampled artwork.
		var region := _region(name)
		var visible_fraction := 0.75 if name == "spark" else 0.68
		var canvas := Vector2.ONE * (maxf(region.size.x, region.size.y) / visible_fraction)
		var padding := canvas - region.size
		var result := AtlasTexture.new()
		result.atlas = ATLAS
		result.region = region
		result.margin = Rect2(padding * 0.5, padding)
		result.filter_clip = true
		_board[name] = result
	return _board[name]
