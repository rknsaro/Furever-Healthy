import 'models/breed_profile.dart';

class TopBreedsData {
  TopBreedsData._();

  static const List<String> dogOrder = [
    'aspin',
    'shih_tzu',
    'labrador_retriever',
  ];

  static const List<String> catOrder = [
    'british_shorthair',
    'puspin',
    'persian',
  ];

  static final Map<String, List<String>> _dogSynonyms = {
    'aspin': ['aspin', 'asong pinoy', 'native dog'],
    'shih_tzu': ['shih tzu', 'shihtzu', 'shi tzu', 'shitzu'],
    'labrador_retriever': ['labrador retriever', 'labrador', 'lab'],
  };

  static final Map<String, List<String>> _catSynonyms = {
    'british_shorthair': ['british shorthair', 'british short hair'],
    'puspin': ['puspin', 'philippine shorthair', 'philippine short hair'],
    'persian': ['persian', 'persian cat', 'persian cats'],
  };

  static String? canonicalDogBreed(String name) {
    return _matchCanonical(name, _dogSynonyms);
  }

  static String? canonicalCatBreed(String name) {
    return _matchCanonical(name, _catSynonyms);
  }

  static String? _matchCanonical(
    String name,
    Map<String, List<String>> synonymMap,
  ) {
    final normalized = _normalize(name);
    if (normalized.isEmpty) return null;

    for (final entry in synonymMap.entries) {
      for (final synonym in entry.value) {
        final candidate = _normalize(synonym);
        if (candidate == normalized ||
            candidate.contains(normalized) ||
            normalized.contains(candidate)) {
          return entry.key;
        }
      }
    }
    return null;
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static Map<String, PetBreed> defaultDogBreeds() {
    return {
      'aspin': PetBreed(
        name: 'Aspin',
        animalType: 'Dog',
        breedGroup: 'Native / Mixed Breed',
        size: 'Medium (varies)',
        lifeSpan: '13-15 years',
        description:
            'Aspin (Asong Pinoy) are loyal, intelligent, and adaptable dogs. They thrive with active families who provide exercise, consistent routines, and plenty of affection.',
        characteristics: const {
          'Friendliness': 85,
          'Trainability': 75,
          'Energy Level': 80,
          'Shedding': 60,
        },
        careGuide: const {
          'nutrition':
              'Feed balanced meals with lean protein, complex carbohydrates, and vegetables. Portion 1 to 1.5 cups per meal for medium Aspins twice daily. Supplement with omega-3 oils for coat health and tailor calories to activity level.',
          'grooming':
              'Brush twice a week to manage shedding, bathe every 4-6 weeks, and check ears for debris. Trim nails monthly and brush teeth multiple times per week to prevent tartar.',
          'exercise':
              'Provide 45-60 minutes of walks plus active play like fetch or scent games. Puzzle feeders and snuffle mats keep them mentally sharp.',
          'health':
              'Schedule annual vet visits, vaccinations, and monthly parasite prevention. Monitor for skin irritations, hip dysplasia signs, and weight changes.',
        },
      ),
      'shih_tzu': PetBreed(
        name: 'Shih Tzu',
        animalType: 'Dog',
        breedGroup: 'Toy',
        size: 'Small',
        lifeSpan: '10-16 years',
        description:
            'Shih Tzus are affectionate lap dogs with charming personalities. They prefer indoor living, gentle play, and consistent routines—perfect for cozy homes and apartments.',
        characteristics: const {
          'Friendliness': 90,
          'Trainability': 70,
          'Energy Level': 60,
          'Shedding': 40,
        },
        careGuide: const {
          'nutrition':
              'Offer small-breed kibble or balanced home-cooked meals two to three times daily. Watch calories to prevent weight gain and use fish oil supplements for skin and coat.',
          'grooming':
              'Brush daily to prevent matting, schedule professional grooms every 4-6 weeks, clean facial folds and eyes, and maintain dental care.',
          'exercise':
              'Plan for two short walks (15-20 minutes) and gentle indoor games. Rotate plush toys and incorporate training games for mental enrichment.',
          'health':
              'Monitor breathing, eye health, and dental hygiene. Keep up with annual veterinary exams, vaccinations, and monthly parasite preventives.',
        },
      ),
      'labrador_retriever': PetBreed(
        name: 'Labrador Retriever',
        animalType: 'Dog',
        breedGroup: 'Sporting',
        size: 'Medium-Large',
        lifeSpan: '10-12 years',
        description:
            'Labrador Retrievers are energetic family dogs known for friendliness and eagerness to please. They excel in active households that offer training, water play, and purposeful tasks.',
        characteristics: const {
          'Friendliness': 95,
          'Trainability': 90,
          'Energy Level': 85,
          'Shedding': 70,
        },
        careGuide: const {
          'nutrition':
              'Choose large-breed formulas with 22-26% protein and joint-support nutrients. Feed twice daily, monitor weight, and add glucosamine or fish oil for joint health.',
          'grooming':
              'Brush 2-3 times weekly (daily when shedding). Bathe every 4-6 weeks or after swimming and keep ears dry to prevent infections.',
          'exercise':
              'Provide 60-90 minutes of activity—brisk walks, jogging, swimming, or fetch. Combine obedience drills and puzzle toys for mental stimulation.',
          'health':
              'Stay current with annual exams, hip/elbow screenings, and weight management. Maintain parasite prevention and watch for allergies or joint stiffness.',
        },
      ),
    };
  }

  static Map<String, PetBreed> defaultCatBreeds() {
    return {
      'british_shorthair': PetBreed(
        name: 'British Shorthair',
        animalType: 'Cat',
        breedGroup: 'Shorthair',
        size: 'Medium-Large',
        lifeSpan: '12-20 years',
        description:
            'British Shorthairs are calm, plush-coated companions known for their round faces and gentle nature. They love relaxed households and regular affection.',
        characteristics: const {
          'Friendliness': 80,
          'Trainability': 70,
          'Energy Level': 55,
          'Shedding': 65,
        },
        careGuide: const {
          'nutrition':
              'Serve high-quality wet and dry food rich in protein to maintain muscle mass. Portion meals twice daily and monitor weight to avoid obesity.',
          'grooming':
              'Brush weekly with a rubber grooming glove, clean ears and eyes gently, trim nails regularly, and brush teeth to prevent tartar.',
          'exercise':
              'Encourage daily play with feather wands, interactive toys, and food puzzles. Provide climbing shelves to keep them active.',
          'health':
              'Schedule yearly vet visits and monitor for dental disease, heart conditions, and obesity. Keep vaccines and parasite preventives updated.',
        },
      ),
      'puspin': PetBreed(
        name: 'Puspin (Philippine Shorthair)',
        animalType: 'Cat',
        breedGroup: 'Mixed / Domestic',
        size: 'Medium',
        lifeSpan: '13-16 years',
        description:
            'Puspin cats are resilient Philippine natives recognized for playful, people-loving personalities. They adapt well to lively homes and regular playtime.',
        characteristics: const {
          'Friendliness': 85,
          'Trainability': 75,
          'Energy Level': 75,
          'Shedding': 50,
        },
        careGuide: const {
          'nutrition':
              'Provide balanced wet and dry meals with protein above 30%. Offer 2-3 smaller feedings and ensure constant access to fresh water.',
          'grooming':
              'Brush weekly to remove loose fur, bathe only when needed, trim nails routinely, and schedule dental cleanings if tartar builds up.',
          'exercise':
              'Rotate toys, introduce climbing trees, and use treat puzzles to channel their curiosity. Aim for 20-30 minutes of interactive play daily.',
          'health':
              'Keep vaccinations, deworming, and flea prevention consistent. Watch for respiratory infections or skin irritations, especially in outdoor explorers.',
        },
      ),
      'persian': PetBreed(
        name: 'Persian',
        animalType: 'Cat',
        breedGroup: 'Longhair',
        size: 'Medium',
        lifeSpan: '12-17 years',
        description:
            'Persian cats are affectionate and serene, thriving in calm environments. Their luxurious coat needs regular care, and they value gentle companionship.',
        characteristics: const {
          'Friendliness': 85,
          'Trainability': 60,
          'Energy Level': 45,
          'Shedding': 80,
        },
        careGuide: const {
          'nutrition':
              'Use longhair-specific diets with omega fatty acids or hairball control formulas. Offer small, frequent meals to support digestion.',
          'grooming':
              'Brush daily to prevent mats, bathe every 4-6 weeks, and clean eyes twice a day to manage tear staining. Keep nails trimmed and brush teeth often.',
          'exercise':
              'Schedule gentle play with teaser toys, encourage light climbing, and provide comfortable perches and scratching posts.',
          'health':
              'Plan regular vet visits and monitor for breathing issues, eye infections, and dental disease. Maintain parasite prevention and cool resting areas.',
        },
      ),
    };
  }
}
