extends RefCounted

const AXIAL_TILT := 23.44


static func sample(latitude: float, december: bool, axial_tilt := AXIAL_TILT) -> Vector3:
	var declination := -axial_tilt if december else axial_tilt
	var altitude := 90.0 - absf(latitude - declination)
	var hour_angle := acos(clampf(-tan(deg_to_rad(latitude)) * tan(deg_to_rad(declination)), -1.0, 1.0))
	var daylight := rad_to_deg(hour_angle) * (2.0 / 15.0)
	var noon_energy := maxf(0.0, sin(deg_to_rad(altitude)))
	return Vector3(altitude, daylight, noon_energy)
