import '../models/pet_breed.dart';

const List<PetBreed> defaultTopDogBreeds = [
  PetBreed(
    name: 'Aspin',
    animalType: 'Dog',
    breedGroup: 'Native / Mixed Breed',
    size: 'Medium (varies)',
    lifeSpan: '13-15 years',
    description:
        'Aspin (Asong Pinoy) are loyal, intelligent, and adaptable dogs. They thrive with active families who provide exercise, consistent routines, and plenty of affection.',
    characteristics: {
      'Friendliness': 85,
      'Trainability': 75,
      'Energy Level': 80,
      'Shedding': 60,
    },
    careGuide: {
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
  PetBreed(
    name: 'Shih Tzu',
    animalType: 'Dog',
    breedGroup: 'Toy',
    size: 'Small',
    lifeSpan: '10-16 years',
    description:
        'Shih Tzus are affectionate lap dogs with charming personalities. They prefer indoor living, gentle play, and consistent routines—perfect for cozy homes and apartments.',
    characteristics: {
      'Friendliness': 90,
      'Trainability': 70,
      'Energy Level': 60,
      'Shedding': 40,
    },
    careGuide: {
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
  PetBreed(
    name: 'Labrador Retriever',
    animalType: 'Dog',
    breedGroup: 'Sporting',
    size: 'Medium-Large',
    lifeSpan: '10-12 years',
    description:
        'Labrador Retrievers are energetic family dogs known for friendliness and eagerness to please. They excel in active households that offer training, water play, and purposeful tasks.',
    characteristics: {
      'Friendliness': 95,
      'Trainability': 90,
      'Energy Level': 85,
      'Shedding': 70,
    },
    careGuide: {
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
];

const List<PetBreed> defaultTopCatBreeds = [
  PetBreed(
    name: 'British Shorthair',
    animalType: 'Cat',
    breedGroup: 'Shorthair',
    size: 'Medium-Large',
    lifeSpan: '12-20 years',
    description:
        'British Shorthairs are calm, plush-coated companions known for their round faces and gentle nature. They love relaxed households and regular affection.',
    characteristics: {
      'Friendliness': 80,
      'Trainability': 70,
      'Energy Level': 55,
      'Shedding': 65,
    },
    careGuide: {
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
  PetBreed(
    name: 'Puspin (Philippine Shorthair)',
    animalType: 'Cat',
    breedGroup: 'Mixed / Domestic',
    size: 'Medium',
    lifeSpan: '13-16 years',
    description:
        'Puspin cats are resilient Philippine natives recognized for playful, people-loving personalities. They adapt well to lively homes and regular playtime.',
    characteristics: {
      'Friendliness': 85,
      'Trainability': 75,
      'Energy Level': 75,
      'Shedding': 50,
    },
    careGuide: {
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
  PetBreed(
    name: 'Persian',
    animalType: 'Cat',
    breedGroup: 'Longhair',
    size: 'Medium',
    lifeSpan: '12-17 years',
    description:
        'Persian cats are affectionate and serene, thriving in calm environments. Their luxurious coat needs regular care, and they value gentle companionship.',
    characteristics: {
      'Friendliness': 85,
      'Trainability': 60,
      'Energy Level': 45,
      'Shedding': 80,
    },
    careGuide: {
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
];

const Map<String, String> _dogCanonicalNames = {
  'aspin': 'Aspin',
  'asong pinoy': 'Aspin',
  'native dog': 'Aspin',
  'shih tzu': 'Shih Tzu',
  'shih-tzu': 'Shih Tzu',
  'shitzu': 'Shih Tzu',
  'shihtzu': 'Shih Tzu',
  'labrador retriever': 'Labrador Retriever',
  'labrador': 'Labrador Retriever',
  'lab retriever': 'Labrador Retriever',
};

const Map<String, String> _catCanonicalNames = {
  'british shorthair': 'British Shorthair',
  'british short hair': 'British Shorthair',
  'puspin': 'Puspin (Philippine Shorthair)',
  'philippine shorthair': 'Puspin (Philippine Shorthair)',
  'philippine short hair': 'Puspin (Philippine Shorthair)',
  'persian': 'Persian',
  'persian cat': 'Persian',
  'persian cats': 'Persian',
};

final Set<String> topDogBreedNamesLower = _dogCanonicalNames.values
    .map((name) => name.toLowerCase())
    .toSet();

final Set<String> topCatBreedNamesLower = _catCanonicalNames.values
    .map((name) => name.toLowerCase())
    .toSet();

String? resolveTopDogCanonicalName(String breedName) {
  final lower = breedName.toLowerCase().trim();
  return _dogCanonicalNames[lower] ??
      (topDogBreedNamesLower.contains(lower) ? capitalizeBreed(lower) : null);
}

String? resolveTopCatCanonicalName(String breedName) {
  final lower = breedName.toLowerCase().trim();
  return _catCanonicalNames[lower] ??
      (topCatBreedNamesLower.contains(lower) ? capitalizeBreed(lower) : null);
}

bool isTopDogBreedName(String breedName) =>
    resolveTopDogCanonicalName(breedName) != null;

bool isTopCatBreedName(String breedName) =>
    resolveTopCatCanonicalName(breedName) != null;

String capitalizeBreed(String value) {
  if (value.isEmpty) return value;
  return value
      .split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1);
      })
      .join(' ');
}

PetBreed? findDefaultDogBreedByName(String canonicalName) {
  final lower = canonicalName.toLowerCase();
  try {
    return defaultTopDogBreeds.firstWhere(
      (breed) => breed.name.toLowerCase() == lower,
    );
  } catch (_) {
    return null;
  }
}

PetBreed? findDefaultCatBreedByName(String canonicalName) {
  final lower = canonicalName.toLowerCase();
  try {
    return defaultTopCatBreeds.firstWhere(
      (breed) => breed.name.toLowerCase() == lower,
    );
  } catch (_) {
    return null;
  }
}
