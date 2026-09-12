enum Disease {
  healthy,
  earlyBlight,
  lateBlight,
  bacterialSpot,
  leafMold,
  septoria,
  spiderMites,
  targetSpot,
  yellowLeafCurl,
  mosaicVirus,
  unknown,
}

extension DiseaseText on Disease {
  String get label => switch (this) {
        Disease.healthy => 'Healthy',
        Disease.earlyBlight => 'Early blight',
        Disease.lateBlight => 'Late blight',
        Disease.bacterialSpot => 'Bacterial spot',
        Disease.leafMold => 'Leaf mold',
        Disease.septoria => 'Septoria leaf spot',
        Disease.spiderMites => 'Spider mites',
        Disease.targetSpot => 'Target spot',
        Disease.yellowLeafCurl => 'Yellow leaf curl virus',
        Disease.mosaicVirus => 'Mosaic virus',
        Disease.unknown => 'Unknown anomaly',
      };

  String get tamil => switch (this) {
        Disease.healthy => 'ஆரோக்கியமான இலை',
        Disease.earlyBlight => 'முன் கருகல் நோய்',
        Disease.lateBlight => 'பின் கருகல் நோய்',
        Disease.bacterialSpot => 'பாக்டீரியா புள்ளி நோய்',
        Disease.leafMold => 'இலை பூஞ்சை',
        Disease.septoria => 'செப்டோரியா இலைப்புள்ளி',
        Disease.spiderMites => 'சிலந்திப் பேன்',
        Disease.targetSpot => 'வட்டப் புள்ளி நோய்',
        Disease.yellowLeafCurl => 'மஞ்சள் இலை சுருள் வைரஸ்',
        Disease.mosaicVirus => 'மொசைக் வைரஸ்',
        Disease.unknown => 'அறியப்படாத அசாதாரண நிலை',
      };
}

class Weather {
  final double humidity; // percent
  final double tempC;
  final double rainMm;
  const Weather({required this.humidity, required this.tempC, required this.rainMm});
}
