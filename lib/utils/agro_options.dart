/// Opciones del formulario. Deben coincidir con los valores que valida el backend
/// (ver backend/app/catalog.py y GET /catalog).
class AgroOptions {
  AgroOptions._();

  static const List<String> departments = [
    'Apurímac',
    'Ayacucho',
    'Cajamarca',
    'Cusco',
    'Huancavelica',
    'Junín',
    'Pasco',
    'Puno',
  ];

  static const List<SoilOption> soils = [
    SoilOption('Andosol', 'Suelo de origen volcánico, oscuro, suelto y con buena retención de humedad.'),
    SoilOption('Cambisol', 'Suelo joven de desarrollo moderado, frecuente en laderas y valles interandinos.'),
    SoilOption('Fluvisol', 'Suelo formado por sedimentos de ríos; típico de fondos de valle y riberas.'),
    SoilOption('Leptosol', 'Suelo delgado y pedregoso sobre roca; común en pendientes y zonas altas.'),
    SoilOption('Phaeozem', 'Suelo oscuro y rico en materia orgánica, generalmente fértil.'),
    SoilOption('Regosol', 'Suelo suelto y poco desarrollado, sobre material no consolidado.'),
  ];

  static const List<WaterOption> waterLevels = [
    WaterOption('Baja', 'Dependo sólo de las lluvias o tengo agua muy limitada.'),
    WaterOption('Media', 'Tengo riego ocasional o por turnos durante la campaña.'),
    WaterOption('Alta', 'Tengo riego permanente o fuente de agua segura todo el año.'),
  ];

  /// Bandas de altitud usadas por el motor de recomendación.
  static const List<AltitudeBand> altitudeBands = [
    AltitudeBand('Baja', 'Menos de 2 500 m', 0, 2499.999),
    AltitudeBand('Media', '2 500 – 3 500 m', 2500, 3500),
    AltitudeBand('Alta', 'Más de 3 500 m', 3500.001, 5000),
  ];

  static String bandFor(double altitude) {
    if (altitude < 2500) return 'Baja';
    if (altitude <= 3500) return 'Media';
    return 'Alta';
  }

  /// Claves de cultivos con ilustración en assets/icons/crops/.
  static const Set<String> cropKeys = {
    'papa',
    'maiz',
    'quinua',
    'cebada',
    'trigo',
    'avena',
    'haba',
    'arveja',
    'lenteja',
    'olluco',
    'oca',
    'mashua',
    'tarwi',
    'canihua',
    'kiwicha',
    'maca',
  };

  static String? cropAsset(String key) => cropKeys.contains(key) ? 'assets/icons/crops/$key.svg' : null;
}

class SoilOption {
  const SoilOption(this.name, this.description);
  final String name;
  final String description;
}

class WaterOption {
  const WaterOption(this.level, this.description);
  final String level;
  final String description;
}

class AltitudeBand {
  const AltitudeBand(this.name, this.label, this.min, this.max);
  final String name;
  final String label;
  final double min;
  final double max;
}
