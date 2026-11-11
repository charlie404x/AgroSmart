/// Rutas de los recursos visuales de la identidad AgroSMART Perú.
///
/// Recortados de la lámina `01_identidad_visual_agrosmart_peru.png`
/// (ver "Guía de imágenes y recursos visuales").
class AppAssets {
  AppAssets._();

  // Marca
  static const String appIcon = 'assets/branding/app_icon.png';
  static const String logo = 'assets/branding/logo.png';

  // Ilustraciones / banners
  static const String bannerCampo = 'assets/illustrations/banner_campo.jpg';
  static const String agricultorCampo = 'assets/illustrations/agricultor_campo.jpg';
  static const String paisajeAndino = 'assets/illustrations/paisaje_andino.jpg';
  static const String agriculturaInteligente = 'assets/illustrations/agricultura_inteligente.jpg';
  static const String appPromo = 'assets/illustrations/app_promo.jpg';

  // Iconos de módulos (PNG con transparencia)
  static String module(String name) => 'assets/icons/modules/$name.png';
  static final String inicio = module('inicio');
  static final String historial = module('historial');
  static final String clima = module('clima');
  static final String recomendaciones = module('recomendaciones');
  static final String cultivos = module('cultivos');
  static final String mapa = module('mapa');
  static final String estadisticas = module('estadisticas');
  static final String agua = module('agua');
  static final String suelo = module('suelo');

  /// Cultivos con fotografía individual en `assets/crops/{clave}.jpg`.
  /// Si una clave no está aquí, se usa su ilustración SVG de assets/icons/crops/.
  /// Al agregar una foto nueva, añade su clave a este conjunto.
  static const Set<String> cropPhotos = {
    'papa',
    'maiz',
    'quinua',
    'kiwicha',
    'oca',
    'cebada',
    'trigo',
    'avena',
    'haba',
    'arveja',
    'lenteja',
    'olluco',
    'mashua',
    'tarwi',
    'canihua',
    'maca',
  };

  static String? cropPhoto(String key) => cropPhotos.contains(key) ? 'assets/crops/$key.jpg' : null;
}
