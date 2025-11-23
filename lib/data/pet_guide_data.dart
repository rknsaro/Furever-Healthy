import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/pet_breed.dart';

const List<PetBreed> defaultTopDogBreeds = [
  PetBreed(
    name: 'Aspin',
    animalType: 'Dog',
    breedGroup: 'Native / Mixed Breed',
    size: 'Medium (varies)',
    lifeSpan: '13-15 years',
    description:
        'Aspin (Asong Pinoy) are loyal, intelligent, and adaptable dogs native to the Philippines. They are known for their resilience, strong survival instincts, and deep bond with families. These mixed-breed dogs often display hybrid vigor, making them generally healthy and robust. They thrive with active families who provide exercise, consistent routines, and plenty of affection. Aspins are highly alert and make excellent watchdogs while remaining friendly to familiar faces.',
    characteristics: {
      'Friendliness': 85,
      'Trainability': 75,
      'Energy Level': 80,
      'Shedding': 60,
      'Independence': 70,
      'Protectiveness': 75,
      'Playfulness': 85,
      'Adaptability': 90,
    },
    careGuide: {
      'nutrition':
          'Feed high-quality balanced meals with lean protein (chicken, fish, or beef) making up 25-30% of diet, complex carbohydrates (rice, sweet potato) at 40-50%, and vegetables (carrots, squash, leafy greens) at 20-25%. Portion 1 to 1.5 cups per meal for medium Aspins (20-30 lbs) twice daily. Adjust portions based on activity level and body condition. Supplement with omega-3 fatty acids (fish oil) for coat health and joint support. Avoid overfeeding to prevent obesity. Provide fresh water at all times. Consider age-appropriate formulas: puppies need higher protein (28-32%), seniors may benefit from lower-calorie options with joint supplements.',
      'grooming':
          'Brush 2-3 times per week with a slicker brush or rubber curry comb to remove loose fur and distribute natural oils. During shedding seasons (typically spring and fall), increase to daily brushing. Bathe every 4-6 weeks using a gentle, pH-balanced dog shampoo. Over-bathing can strip natural oils. Check and clean ears weekly with a vet-approved ear cleaner to prevent infections, especially if ears are floppy. Trim nails monthly or when you hear clicking on floors. Brush teeth 3-4 times per week with dog-specific toothpaste to prevent periodontal disease. Check for ticks and fleas regularly, especially after outdoor activities.',
      'exercise':
          'Provide 45-60 minutes of daily physical activity including brisk walks, jogging, or active play sessions. Aspins enjoy fetch, tug-of-war, and scent games that engage their natural instincts. Mental stimulation is crucial: use puzzle feeders, snuffle mats, and interactive toys. Training sessions (10-15 minutes) serve as both mental and physical exercise. Socialization is important—expose them to different people, dogs, and environments. Off-leash play in secure areas allows them to run and explore. Swimming is excellent low-impact exercise if your Aspin enjoys water.',
      'health':
          'Schedule annual veterinary exams including vaccinations (DHPP, rabies), heartworm testing, and fecal exams. Maintain monthly parasite prevention (heartworm, fleas, ticks). Common health concerns include skin allergies (watch for excessive scratching), hip dysplasia (especially in larger individuals), and dental issues. Monitor weight regularly—obesity leads to joint problems and diabetes. Keep vaccinations current and discuss spay/neuter timing with your vet (typically 6-12 months). Watch for signs of heatstroke in hot weather. Maintain a first-aid kit and know your emergency vet contact. Regular dental cleanings may be needed if home care is insufficient.',
      'wellness':
          'Aspins thrive on routine and consistency. Establish regular feeding, walking, and sleep schedules. Provide a comfortable, quiet space for rest. Mental enrichment prevents boredom and destructive behaviors—rotate toys, teach new tricks, and provide chew toys. Social interaction is vital; they bond deeply with family members. Early socialization (8-16 weeks) helps develop confidence. Positive reinforcement training works best; they respond well to treats and praise. Monitor stress indicators: excessive panting, hiding, or changes in appetite. Create a safe space during thunderstorms or fireworks. Regular health monitoring includes checking eyes, ears, skin, and weight.',
    },
  ),
  PetBreed(
    name: 'Shih Tzu',
    animalType: 'Dog',
    breedGroup: 'Toy',
    size: 'Small',
    lifeSpan: '10-16 years',
    description:
        'Shih Tzus are affectionate, regal lap dogs with charming personalities and a rich history as companion dogs. They are known for their friendly disposition, playful nature, and strong attachment to their families. Despite their small size, they have big personalities and are confident, outgoing dogs. They prefer indoor living, gentle play, and consistent routines—perfect for cozy homes and apartments. Shih Tzus are excellent with children and other pets when properly socialized, and they make wonderful therapy dogs due to their calm, loving nature.',
    characteristics: {
      'Friendliness': 90,
      'Trainability': 70,
      'Energy Level': 60,
      'Shedding': 40,
      'Independence': 50,
      'Protectiveness': 40,
      'Playfulness': 75,
      'Adaptability': 85,
    },
    careGuide: {
      'nutrition':
          'Offer high-quality small-breed kibble (kibble size designed for small mouths) or balanced home-cooked meals two to three times daily. Small breeds have faster metabolisms, so frequent small meals help maintain blood sugar. Portion size: 1/2 to 1 cup total daily for adults (9-16 lbs), divided into 2-3 meals. Watch calories closely to prevent weight gain—obesity is common and leads to joint problems. Protein should be 22-26% from quality sources (chicken, turkey, fish). Include omega-3 fatty acids (fish oil) for skin and coat health. Avoid foods with artificial preservatives. Puppies need 3-4 meals daily until 6 months. Seniors may need lower-calorie, higher-fiber diets. Always provide fresh water.',
      'grooming':
          'Brush daily with a pin brush and metal comb to prevent matting—their long, double coat requires consistent care. Start with a slicker brush to remove tangles, then use a comb to reach the skin. Pay special attention to areas behind ears, under legs, and around the tail. Schedule professional grooms every 4-6 weeks for trimming and styling. Clean facial folds daily with a damp cloth and dry thoroughly to prevent bacterial infections. Clean around eyes gently to remove tear stains using a vet-approved eye cleaner. Trim hair around eyes monthly to prevent irritation. Bathe every 3-4 weeks using gentle shampoo and conditioner. Brush teeth daily or at least 4-5 times per week—small breeds are prone to dental disease. Trim nails every 2-3 weeks. Check and clean ears weekly.',
      'exercise':
          'Plan for two short walks (15-20 minutes each) daily. Shih Tzus are not high-energy dogs but need regular activity to maintain health and prevent obesity. Gentle indoor games like fetch with soft toys work well. Rotate plush toys and incorporate training games for mental enrichment. They enjoy puzzle toys and treat-dispensing games. Avoid overexertion, especially in hot weather due to their brachycephalic (flat-faced) structure. Swimming is not recommended due to their body structure. Indoor play and short walks are ideal. Training sessions (5-10 minutes) provide mental stimulation. Socialization with other dogs and people is important for confidence.',
      'health':
          'Monitor breathing closely—Shih Tzus are brachycephalic and can have respiratory issues, especially in heat or humidity. Watch for excessive panting, snoring, or difficulty breathing. Eye health is critical: they are prone to proptosis (eye popping out), corneal ulcers, and dry eye. Regular eye exams are essential. Dental hygiene is crucial—small breeds have crowded teeth and are prone to periodontal disease. Professional cleanings may be needed annually. Keep up with annual veterinary exams, vaccinations (DHPP, rabies), and monthly parasite preventives. Common issues include hip dysplasia, patellar luxation, and allergies. Monitor weight to prevent obesity. Watch for signs of heatstroke. Maintain a first-aid kit. Discuss spay/neuter timing with your vet (typically 6-12 months).',
      'wellness':
          'Shih Tzus thrive on companionship and should not be left alone for extended periods. They bond deeply with family members and can develop separation anxiety. Provide a comfortable, quiet space for rest with soft bedding. They enjoy being close to their humans and make excellent lap dogs. Mental enrichment prevents boredom—teach tricks, use puzzle toys, and provide variety in activities. Early socialization (8-16 weeks) helps develop confidence and prevents fearfulness. Positive reinforcement training works best; they can be stubborn but respond well to treats and praise. Maintain consistent routines for feeding, walking, and sleep. Monitor stress indicators: excessive licking, hiding, or changes in behavior. They are sensitive to temperature extremes—keep them cool in summer and warm in winter. Regular health monitoring includes checking eyes, breathing, skin, and weight.',
    },
  ),
  PetBreed(
    name: 'Labrador Retriever',
    animalType: 'Dog',
    breedGroup: 'Sporting',
    size: 'Medium-Large',
    lifeSpan: '10-12 years',
    description:
        'Labrador Retrievers are energetic, friendly family dogs known for their intelligence, eagerness to please, and gentle nature. They are one of the most popular breeds worldwide due to their versatility as family companions, working dogs, and service animals. Labs are highly social, patient with children, and generally get along well with other pets. They excel in active households that offer training, water play, and purposeful tasks. Their retrieving instincts make them natural swimmers and excellent companions for outdoor activities. Labs are known for their "soft mouth" and love of carrying objects.',
    characteristics: {
      'Friendliness': 95,
      'Trainability': 90,
      'Energy Level': 85,
      'Shedding': 70,
      'Independence': 40,
      'Protectiveness': 50,
      'Playfulness': 95,
      'Adaptability': 85,
    },
    careGuide: {
      'nutrition':
          'Choose high-quality large-breed formulas with 22-26% protein from quality sources (chicken, fish, lamb) and joint-support nutrients (glucosamine, chondroitin). Large breeds need controlled growth to prevent joint issues—avoid overfeeding puppies. Feed adults twice daily: 2.5-3 cups for females (55-70 lbs), 3-3.5 cups for males (65-80 lbs), adjusted for activity level. Monitor weight closely—Labs are prone to obesity which exacerbates joint problems. Include omega-3 fatty acids (fish oil) for joint health, skin, and coat. Avoid free-feeding. Puppies need large-breed puppy formulas until 12-18 months. Seniors may benefit from lower-calorie, higher-fiber diets with joint supplements. Provide fresh water at all times, especially after exercise. Be cautious with treats—Labs are food-motivated and can easily gain weight.',
      'grooming':
          'Brush 2-3 times weekly with a slicker brush or undercoat rake (daily during heavy shedding seasons in spring and fall). Their double coat sheds year-round. Regular brushing removes loose fur, distributes oils, and reduces shedding in the home. Bathe every 4-6 weeks or after swimming using a gentle, pH-balanced shampoo. After swimming, rinse thoroughly and dry ears completely to prevent infections. Check and clean ears weekly, especially after water activities—floppy ears trap moisture. Trim nails monthly or when you hear clicking. Brush teeth 3-4 times per week with dog-specific toothpaste—large breeds are still prone to dental disease. Check for ticks and fleas regularly, especially after outdoor activities. Their water-resistant coat helps protect them, but regular grooming maintains skin health.',
      'exercise':
          'Provide 60-90 minutes of daily physical activity including brisk walks, jogging, swimming, or fetch. Labs are high-energy dogs that need substantial exercise to prevent boredom and destructive behaviors. Swimming is excellent exercise and most Labs love water—it\'s low-impact and great for joints. Combine physical activity with mental stimulation: obedience drills, agility training, puzzle toys, and scent work. Fetch and retrieving games engage their natural instincts. Off-leash play in secure areas allows them to run and explore. Training sessions (15-20 minutes) serve as both mental and physical exercise. Socialization is important—expose them to different people, dogs, and environments. Without adequate exercise, Labs can become hyperactive or develop behavioral issues. Adjust exercise for weather conditions—avoid overexertion in extreme heat.',
      'health':
          'Stay current with annual veterinary exams including vaccinations (DHPP, rabies), heartworm testing, and fecal exams. Maintain monthly parasite prevention (heartworm, fleas, ticks). Labs are prone to hip and elbow dysplasia—consider screening (OFA or PennHIP) if breeding or for early detection. Weight management is critical—obesity leads to joint problems, diabetes, and heart disease. Monitor for signs of joint stiffness, limping, or difficulty rising. Common health concerns include exercise-induced collapse (EIC), progressive retinal atrophy (PRA), and allergies (food and environmental). Watch for signs of bloat (GDV) especially in deep-chested individuals—feed smaller meals and avoid exercise immediately after eating. Keep vaccinations current. Discuss spay/neuter timing with your vet (typically 12-18 months for large breeds to allow proper growth). Regular dental cleanings may be needed. Maintain a first-aid kit and know your emergency vet contact.',
      'wellness':
          'Labs thrive on activity, companionship, and purpose. They are highly social and should not be left alone for extended periods—they can develop separation anxiety. Provide a comfortable space for rest with supportive bedding (important for joint health). Mental enrichment is crucial—rotate toys, teach new tricks, provide puzzle feeders, and engage in training. They excel at obedience, agility, therapy work, and service tasks. Early socialization (8-16 weeks) helps develop confidence and prevents fearfulness. Positive reinforcement training works exceptionally well—they are eager to please and food-motivated. Maintain consistent routines for feeding, exercise, and sleep. Monitor stress indicators: excessive licking, destructive behavior, or changes in appetite. They are generally adaptable but need structure and boundaries. Regular health monitoring includes checking joints, weight, eyes, ears, and skin. Labs are known for their love of food—use this for training but monitor intake carefully.',
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
        'British Shorthairs are calm, dignified, plush-coated companions known for their round faces, stocky build, and gentle, easygoing nature. They are one of the oldest English cat breeds, dating back to Roman times. These cats are known for their teddy bear-like appearance with dense, plush coats and large, round eyes. They love relaxed households and regular affection but are not overly demanding. British Shorthairs are independent yet affectionate, making them ideal for families, singles, and seniors. They are generally quiet, well-mannered cats that adapt well to indoor living and get along with children and other pets when properly introduced.',
    characteristics: {
      'Friendliness': 80,
      'Trainability': 70,
      'Energy Level': 55,
      'Shedding': 65,
      'Independence': 75,
      'Vocalization': 40,
      'Playfulness': 60,
      'Adaptability': 85,
    },
    careGuide: {
      'nutrition':
          'Serve high-quality wet and dry food rich in animal protein (30-40% protein from meat sources like chicken, turkey, or fish) to maintain muscle mass and support their stocky build. British Shorthairs are prone to obesity, so portion control is essential. Feed adults 2-3 times daily: approximately 1/4 to 1/3 cup dry food or 5-6 oz wet food total daily for adults (9-17 lbs), adjusted for activity level and body condition. Avoid free-feeding. Include omega-3 fatty acids for skin and coat health. Provide fresh water at all times—consider a water fountain to encourage drinking. Kittens need 3-4 meals daily until 6 months. Seniors may need lower-calorie, higher-fiber diets. Monitor weight regularly—obesity leads to diabetes, joint problems, and heart disease. Be cautious with treats.',
      'grooming':
          'Brush weekly with a rubber grooming glove or soft-bristle brush to remove loose fur and distribute natural oils. Their dense, plush coat benefits from regular brushing, especially during shedding seasons (spring and fall) when daily brushing may be needed. The dense undercoat can mat if neglected. Bathe only when necessary (every few months or if they get dirty) using a gentle cat shampoo. Clean ears monthly with a vet-approved ear cleaner and cotton ball—check for wax buildup or signs of infection. Wipe around eyes gently with a damp cloth if needed. Trim nails every 2-3 weeks using cat-specific nail clippers. Brush teeth 2-3 times per week with cat-specific toothpaste to prevent periodontal disease—dental issues are common. Check for fleas and ticks regularly, especially if they have outdoor access.',
      'exercise':
          'Encourage daily play sessions (15-20 minutes) with feather wands, interactive toys, laser pointers (use cautiously), and food puzzles. British Shorthairs are not highly active but need regular exercise to prevent obesity and maintain muscle tone. Provide climbing shelves, cat trees, and perches to encourage natural climbing behaviors. Rotate toys to maintain interest. Puzzle feeders and treat-dispensing toys provide mental stimulation. They enjoy gentle play and may not be as acrobatic as other breeds. Interactive play strengthens the bond with owners. Ensure they have vertical spaces to observe their environment—they enjoy being up high. Without adequate exercise, they can become overweight and develop health issues.',
      'health':
          'Schedule yearly veterinary exams including vaccinations (FVRCP, rabies), dental checkups, and blood work (especially for seniors). British Shorthairs are generally healthy but prone to certain conditions. Monitor for dental disease—regular cleanings may be needed. They are predisposed to hypertrophic cardiomyopathy (HCM), a heart condition—discuss screening with your vet. Obesity is a major concern—monitor weight and body condition score regularly. Watch for signs of diabetes (increased thirst, urination, weight loss). Keep vaccines and parasite preventives (fleas, ticks, heartworm) updated. Common issues include polycystic kidney disease (PKD) in some lines, though less common than in Persians. Monitor for signs of arthritis in seniors. Maintain a first-aid kit. Discuss spay/neuter timing with your vet (typically 4-6 months). Regular dental cleanings may be needed if home care is insufficient.',
      'wellness':
          'British Shorthairs thrive in calm, stable environments with consistent routines. They are independent but enjoy companionship and should not be left alone for extended periods. Provide comfortable resting spots with soft bedding—they enjoy quiet corners and elevated perches. Mental enrichment prevents boredom—rotate toys, provide puzzle feeders, and create vertical spaces. They are generally low-maintenance emotionally but appreciate attention and gentle petting. Early socialization (8-16 weeks) helps develop confidence. They adapt well to indoor living and are less likely to want to go outside than some breeds. Maintain consistent routines for feeding, play, and sleep. Monitor stress indicators: hiding, changes in appetite, excessive grooming, or litter box issues. They are generally calm and handle changes well but appreciate predictability. Regular health monitoring includes checking weight, eyes, ears, teeth, and skin. They are known for their easygoing nature and make excellent companions for relaxed households.',
    },
  ),
  PetBreed(
    name: 'Puspin (Philippine Shorthair)',
    animalType: 'Cat',
    breedGroup: 'Mixed / Domestic',
    size: 'Medium',
    lifeSpan: '13-16 years',
    description:
        'Puspin (Pusang Pinoy) cats are resilient Philippine native cats recognized for their playful, people-loving personalities, intelligence, and adaptability. These mixed-breed domestic shorthairs often display hybrid vigor, making them generally healthy and robust. They are known for their strong survival instincts, social nature, and ability to thrive in various environments. Puspins adapt well to lively homes and regular playtime, making them excellent family companions. They are typically friendly, curious, and form strong bonds with their human families. Their diverse genetic background contributes to their hardiness and generally good health.',
    characteristics: {
      'Friendliness': 85,
      'Trainability': 75,
      'Energy Level': 75,
      'Shedding': 50,
      'Independence': 70,
      'Vocalization': 60,
      'Playfulness': 85,
      'Adaptability': 90,
    },
    careGuide: {
      'nutrition':
          'Provide high-quality balanced wet and dry meals with animal protein above 30% from quality sources (chicken, fish, turkey). Mixed-breed cats benefit from varied, nutrient-dense diets. Offer 2-3 smaller feedings daily: approximately 1/4 cup dry food or 4-5 oz wet food total daily for adults (8-12 lbs), adjusted for activity level. Avoid free-feeding to prevent obesity. Include omega-3 fatty acids for skin and coat health. Provide fresh water at all times—consider a water fountain to encourage hydration, especially important in warm climates. Kittens need 3-4 meals daily until 6 months. Seniors may need lower-calorie options with joint support. Monitor weight regularly. Be cautious with treats and human food.',
      'grooming':
          'Brush weekly with a slicker brush or rubber grooming glove to remove loose fur and distribute natural oils. During shedding seasons, increase to 2-3 times per week. Their short coat is relatively low-maintenance but benefits from regular brushing. Bathe only when necessary (every few months or if they get dirty) using a gentle cat shampoo. Clean ears monthly with a vet-approved ear cleaner—check for wax buildup, especially if they have outdoor access. Wipe around eyes gently if needed. Trim nails every 2-3 weeks using cat-specific nail clippers. Brush teeth 2-3 times per week with cat-specific toothpaste to prevent periodontal disease. Check for fleas, ticks, and skin issues regularly, especially for outdoor or indoor-outdoor cats. Regular grooming sessions also provide bonding time.',
      'exercise':
          'Rotate toys regularly to maintain interest—feather wands, interactive toys, laser pointers (use cautiously), and puzzle feeders. Introduce climbing trees, cat shelves, and vertical spaces to encourage natural behaviors. Aim for 20-30 minutes of interactive play daily. Puspins are typically active and enjoy playtime—they may be more energetic than purebred cats. Use treat puzzles and food-dispensing toys to channel their curiosity and provide mental stimulation. They enjoy chasing, pouncing, and climbing activities. Provide scratching posts and pads to satisfy natural scratching instincts. Without adequate exercise and mental stimulation, they can become bored and develop behavioral issues. Outdoor access (if safe and supervised) can provide additional exercise, but indoor play is safer.',
      'health':
          'Keep vaccinations current (FVRCP, rabies) and schedule annual veterinary exams. Maintain consistent deworming (every 3-6 months) and flea/tick prevention, especially for outdoor or indoor-outdoor cats. Puspins are generally healthy due to genetic diversity, but monitor for common issues. Watch for respiratory infections (sneezing, nasal discharge, eye discharge) and seek prompt veterinary care. Monitor for skin irritations, especially in outdoor explorers—check for wounds, parasites, or allergies. Dental health is important—regular cleanings may be needed if home care is insufficient. Monitor weight to prevent obesity. Watch for signs of parasites (fleas, ticks, worms) and treat promptly. Keep a first-aid kit for minor injuries. Discuss spay/neuter timing with your vet (typically 4-6 months). Regular health monitoring includes checking eyes, ears, teeth, skin, and weight. Outdoor cats need more frequent health checks.',
      'wellness':
          'Puspins thrive on social interaction and should not be left alone for extended periods—they can develop loneliness or behavioral issues. Provide comfortable resting spots with soft bedding and quiet areas for retreat. Mental enrichment is crucial—rotate toys, provide puzzle feeders, create vertical spaces, and engage in interactive play. They form strong bonds with family members and enjoy being part of household activities. Early socialization (8-16 weeks) helps develop confidence and prevents fearfulness. They are generally adaptable to various living situations but appreciate consistency and routine. Monitor stress indicators: hiding, changes in appetite, excessive grooming, or litter box issues. Provide a safe, stimulating environment. If kept indoors, ensure they have enough space and enrichment. Regular health monitoring includes checking weight, behavior, and overall condition. They are known for their resilience and generally good temperament, making them excellent companions for active families.',
    },
  ),
  PetBreed(
    name: 'Persian',
    animalType: 'Cat',
    breedGroup: 'Longhair',
    size: 'Medium',
    lifeSpan: '12-17 years',
    description:
        'Persian cats are affectionate, serene, and elegant companions known for their luxurious long coats, flat faces, and gentle, calm personalities. They are one of the oldest and most recognizable cat breeds, valued for their beauty and sweet disposition. Persians thrive in calm, quiet environments and prefer predictable routines. They are not highly active cats and enjoy lounging and being pampered. Their luxurious coat is their defining feature but requires significant grooming commitment. Persians value gentle companionship and form strong bonds with their families. They are generally quiet, well-mannered cats that adapt well to indoor living and are excellent companions for those who appreciate a more laid-back feline friend.',
    characteristics: {
      'Friendliness': 85,
      'Trainability': 60,
      'Energy Level': 45,
      'Shedding': 80,
      'Independence': 65,
      'Vocalization': 35,
      'Playfulness': 50,
      'Adaptability': 70,
    },
    careGuide: {
      'nutrition':
          'Use high-quality longhair-specific diets with omega-3 and omega-6 fatty acids for coat health, or hairball control formulas to help manage ingested fur. Persians are prone to hairballs due to their long coats and grooming habits. Offer small, frequent meals (2-3 times daily) to support digestion and prevent overeating. Portion approximately 1/4 to 1/3 cup dry food or 4-6 oz wet food total daily for adults (7-12 lbs), adjusted for activity level. Avoid free-feeding. Include hairball prevention supplements or treats if needed. Provide fresh water at all times—consider a water fountain. Their flat faces may make eating from certain bowls difficult—use shallow, wide bowls. Kittens need 3-4 meals daily until 6 months. Seniors may need lower-calorie, higher-fiber diets. Monitor weight regularly—obesity is a concern.',
      'grooming':
          'Brush daily with a wide-toothed comb and slicker brush to prevent mats and tangles—their long, dense coat requires consistent, thorough care. Start with a comb to work through tangles, then use a slicker brush. Pay special attention to areas prone to matting: behind ears, under legs, belly, and around the tail. Daily grooming prevents painful mats that can pull on skin. Bathe every 4-6 weeks using a gentle cat shampoo and conditioner—regular bathing helps maintain coat health and reduces shedding. After bathing, dry thoroughly with a towel and low-heat blow dryer if tolerated. Clean eyes twice daily with a damp cloth or vet-approved eye wipes to manage tear staining—their flat faces cause tears to overflow. Trim hair around eyes monthly to prevent irritation. Keep nails trimmed every 2-3 weeks. Brush teeth 2-3 times per week with cat-specific toothpaste—dental issues are common. Check ears weekly for wax buildup.',
      'exercise':
          'Schedule gentle play sessions (10-15 minutes) with teaser toys, feather wands, and interactive toys. Persians are not highly active but need some exercise to maintain health and prevent obesity. Encourage light climbing with cat trees and provide comfortable perches at various heights. They enjoy observing from elevated positions. Provide scratching posts and pads to satisfy natural scratching instincts. Puzzle feeders provide mental stimulation. Avoid overexertion, especially in heat—their flat faces can make breathing difficult during intense activity. They prefer calm, gentle play over high-energy activities. Without any exercise, they can become overweight and develop health issues. Interactive play also strengthens the bond with owners.',
      'health':
          'Plan regular veterinary visits (at least annually, more for seniors) including vaccinations (FVRCP, rabies), dental checkups, and comprehensive exams. Persians are prone to several breed-specific health issues. Monitor breathing closely—their brachycephalic (flat-faced) structure can cause respiratory problems, especially in heat or stress. Watch for signs of difficulty breathing, excessive panting, or open-mouth breathing. Eye health is critical: they are prone to eye infections, tear duct issues, and corneal ulcers due to their facial structure. Regular eye cleaning is essential. Dental disease is common—regular cleanings may be needed. They are predisposed to polycystic kidney disease (PKD)—discuss screening with your vet. Watch for signs of heart disease (hypertrophic cardiomyopathy). Maintain parasite prevention (fleas, ticks, heartworm). Monitor for skin issues under mats. Keep them in cool, well-ventilated areas, especially in warm climates. Discuss spay/neuter timing with your vet (typically 4-6 months).',
      'wellness':
          'Persians thrive in calm, stable, quiet environments with minimal stress and consistent routines. They are sensitive to changes and loud noises. Provide comfortable, quiet resting spots with soft bedding—they enjoy peaceful corners and elevated perches away from high-traffic areas. Mental enrichment is important despite their low activity level—provide puzzle feeders, rotate toys, and create vertical spaces. They form strong bonds with family members and enjoy gentle attention and petting. Early socialization (8-16 weeks) helps develop confidence, though they are naturally more reserved than some breeds. They adapt well to indoor living and are less likely to want to go outside. Maintain consistent routines for feeding, grooming, play, and sleep. Monitor stress indicators: hiding, changes in appetite, excessive grooming, or litter box issues. They are sensitive to temperature extremes—keep them cool in summer and provide warm spots in winter. Regular health monitoring includes checking breathing, eyes, weight, and overall condition. Their luxurious appearance and calm nature make them excellent companions for those who can commit to their grooming needs and appreciate a serene feline friend.',
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

// ====== External dataset (optional, loaded from assets) ======
bool _datasetsLoaded = false;

final Map<String, String> _extraDogCanonicalNames = <String, String>{};
final Map<String, String> _extraCatCanonicalNames = <String, String>{};

final List<PetBreed> _extraDogBreeds = <PetBreed>[];
final List<PetBreed> _extraCatBreeds = <PetBreed>[];

/// Loads optional external breed datasets from assets if present.
///
/// Expected files (optional):
/// - assets/breeds/dog_breeds.json
/// - assets/breeds/cat_breeds.json
///
/// File schema:
/// [
///   {
///     "name": "Beagle",
///     "synonyms": ["beagle"],
///     "animalType": "Dog",
///     "breedGroup": "Hound",
///     "size": "Medium",
///     "lifeSpan": "12-15 years",
///     "description": "...",
///     "characteristics": { "Friendliness": 90, "Trainability": 70 },
///     "careGuide": { "nutrition": "...", "grooming": "...", "exercise": "...", "health": "..." }
///   }
/// ]
Future<void> loadBreedDatasets() async {
  if (_datasetsLoaded) return;
  _datasetsLoaded = true;

  Future<void> loadFile({required String path, required bool isDog}) async {
    try {
      final raw = await rootBundle.loadString(path);
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        final breed = PetBreed.fromMap(item);
        final synonyms =
            (item['synonyms'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .where((e) => e.trim().isNotEmpty)
                .toList() ??
            <String>[];

        if (isDog) {
          _extraDogBreeds.add(breed);
          for (final s in synonyms) {
            _extraDogCanonicalNames[s.toLowerCase().trim()] = breed.name;
          }
          _extraDogCanonicalNames[breed.name.toLowerCase().trim()] = breed.name;
        } else {
          _extraCatBreeds.add(breed);
          for (final s in synonyms) {
            _extraCatCanonicalNames[s.toLowerCase().trim()] = breed.name;
          }
          _extraCatCanonicalNames[breed.name.toLowerCase().trim()] = breed.name;
        }
      }
    } catch (_) {
      // Silently ignore if file doesn't exist or malformed; keep defaults
    }
  }

  await Future.wait([
    loadFile(path: 'assets/breeds/dog_breeds.json', isDog: true),
    loadFile(path: 'assets/breeds/cat_breeds.json', isDog: false),
  ]);
}

String? resolveTopDogCanonicalName(String breedName) {
  final lower = breedName.toLowerCase().trim();
  // Prefer extras if loaded
  if (_extraDogCanonicalNames.isNotEmpty) {
    final viaExtra = _extraDogCanonicalNames[lower];
    if (viaExtra != null && viaExtra.isNotEmpty) return viaExtra;
  }
  return _dogCanonicalNames[lower] ??
      (topDogBreedNamesLower.contains(lower) ? capitalizeBreed(lower) : null);
}

String? resolveTopCatCanonicalName(String breedName) {
  final lower = breedName.toLowerCase().trim();
  if (_extraCatCanonicalNames.isNotEmpty) {
    final viaExtra = _extraCatCanonicalNames[lower];
    if (viaExtra != null && viaExtra.isNotEmpty) return viaExtra;
  }
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
  // Prefer external
  try {
    return _extraDogBreeds.firstWhere(
      (breed) => breed.name.toLowerCase() == lower,
    );
  } catch (_) {}
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
    return _extraCatBreeds.firstWhere(
      (breed) => breed.name.toLowerCase() == lower,
    );
  } catch (_) {}
  try {
    return defaultTopCatBreeds.firstWhere(
      (breed) => breed.name.toLowerCase() == lower,
    );
  } catch (_) {
    return null;
  }
}
