import 'dart:typed_data';
import 'package:flutter/material.dart';

const _mint = Color(0xFF6F994A);
const _screenBg = Color(0xFFF6F8FB);

class BreedDetailScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final String breed;
  final String breedGroup;
  final String size;
  final String lifeSpan;
  final String description;
  final Map<String, int> characteristics;
  final Map<String, dynamic> careGuide;

  const BreedDetailScreen({
    super.key,
    required this.imageBytes,
    required this.breed,
    required this.breedGroup,
    required this.size,
    required this.lifeSpan,
    required this.description,
    required this.characteristics,
    required this.careGuide,
  });

  @override
  State<BreedDetailScreen> createState() => _BreedDetailScreenState();
}

class _BreedDetailScreenState extends State<BreedDetailScreen> {
  String _activeCareGuideTab = 'Nutrition';

  // Top 3 breeds for detailed content
  static const List<String> _top3Dogs = [
    'aspin',
    'shih tzu',
    'labrador retriever',
    'labrador',
  ];
  static const List<String> _top3Cats = [
    'british shorthair',
    'puspin',
    'philippine shorthair',
    'persian cats',
    'persian',
  ];

  bool get _isTop3Breed {
    final breedLower = widget.breed.toLowerCase().trim();
    // Check exact matches and partial matches
    for (final topBreed in _top3Dogs) {
      if (breedLower == topBreed ||
          breedLower.contains(topBreed) ||
          topBreed.contains(breedLower)) {
        return true;
      }
    }
    for (final topBreed in _top3Cats) {
      if (breedLower == topBreed ||
          breedLower.contains(topBreed) ||
          topBreed.contains(breedLower)) {
        return true;
      }
    }
    return false;
  }

  String? get _animalType {
    final breedLower = widget.breed.toLowerCase().trim();
    // Check for dog breeds
    for (final topBreed in _top3Dogs) {
      if (breedLower == topBreed ||
          breedLower.contains(topBreed) ||
          topBreed.contains(breedLower)) {
        return 'dog';
      }
    }
    // Check for cat breeds
    for (final topBreed in _top3Cats) {
      if (breedLower == topBreed ||
          breedLower.contains(topBreed) ||
          topBreed.contains(breedLower)) {
        return 'cat';
      }
    }
    return null;
  }

  Map<String, String> _getDetailedCareGuide() {
    final breedLower = widget.breed.toLowerCase().trim();
    final animalType = _animalType;

    // Detailed content for top 3 breeds
    if (animalType == 'dog') {
      // Check for Aspin
      if (breedLower.contains('aspin')) {
        return {
          'nutrition':
              '''**Puppy (2-12 months):** Puppies require 22-25% daily protein (minimum 25g per 100g dry food) and calories ranging from 300-400 kcal for small dogs, 800-1200 kcal for medium dogs, to 1200-1800 kcal for large dogs. Feed high-quality puppy kibble with real meat (chicken, fish, beef) as the first ingredient, and include cooked rice, sweet potato, and vegetables in meals. Feed 3-4 times daily in smaller portions.

**Adult (1-7 years):** Adults need 18-25% daily protein (minimum 20g per 100g dry food) and calories ranging from 400-600 kcal for small, 1200-1600 kcal for medium, to 1600-2200 kcal for large dogs. Provide high-quality adult dog food with meat protein and include omega-3 rich foods like fish and flaxseed. Feed twice daily.

**Senior (7+ years):** Senior dogs need 18-22% daily protein (easier to digest) and calories reduced by 10-20% from adult requirements. Use senior formula dog food with joint support (glucosamine, chondroitin) and add fiber-rich foods like pumpkin and green beans. Feed 2-3 times daily in smaller portions.

**Foods to Include:** Lean meats such as chicken, turkey, and fish; brown rice, oats, and sweet potatoes; fresh vegetables including carrots, green beans, and pumpkin; and fruits like apple, banana, and blueberries in moderation.

**Foods to Avoid:** Never feed chocolate, caffeine, grapes, raisins, onions, garlic, chives, avocado, macadamia nuts, high-fat foods, excessive salt, or raw meat due to bacteria risk.''',
          'grooming':
              '''**Brushing:** Brush 2-3 times per week with a slicker brush or rubber curry brush, more frequently during shedding seasons. This removes dead hair and distributes natural oils throughout the coat.

**Bathing:** Bathe every 4-6 weeks or when visibly dirty using a mild, pH-balanced dog shampoo. Rinse thoroughly to prevent skin irritation and dry completely to avoid skin infections.

**Ear Cleaning:** Check ears weekly for dirt, odor, or redness. Clean every 1-2 weeks with a vet-approved ear cleaner and cotton ball, gently wiping the outer ear canal without inserting deep.

**Dental Care:** Brush teeth 2-3 times per week with dog toothpaste and use dental chews daily for plaque removal. Schedule annual professional dental cleaning if needed and regularly check for tartar buildup and gum disease.

**Nail and Paw Care:** Trim nails every 3-4 weeks or when you hear clicking on the floor using guillotine or scissor-style clippers, being careful to avoid cutting the quick (pink area). Inspect paw pads regularly for cuts, cracks, or foreign objects and moisturize if they appear dry.''',
          'training':
              '''**Physical Exercises:** Provide daily walks of 30-60 minutes, 2-3 times per day. Active Aspins can also benefit from 20-30 minutes of running or jogging. Include fetch and retrieving games, swimming if accessible for low-impact exercise, and agility exercises like jumping and running through obstacles.

**Interactive Play:** Engage them with puzzle toys containing treats for mental stimulation, hide and seek games, tug-of-war with proper toys (never hands), interactive squeaky toys and balls, and social play with other dogs at dog parks.

**Obedience Training:** Teach basic commands including sit, stay, come, down, and heel using positive reinforcement with treats and praise. Conduct training sessions of 10-15 minutes, 2-3 times daily. Consistency is key for Aspin's quick learning, and starting training from puppyhood yields best results.

**Mental Stimulation:** Provide scent work games where you hide treats for them to track, food puzzle toys like Kong and snuffle mats, regular training of new tricks, interactive feeding toys instead of bowls, and rotate toys weekly to maintain interest.''',
          'health':
              '''**Common Health Issues:** Aspins, especially larger ones, are prone to hip dysplasia requiring regular vet checks. Watch for skin allergies indicated by excessive scratching or rashes, ear infections that require keeping ears clean and dry, parasites including ticks, fleas, and heartworms requiring monthly preventatives, and obesity which needs consistent weight and diet monitoring.

**Preventive Care:** Schedule annual vet checkups (semi-annual for seniors), maintain core vaccinations (DHPP, rabies) with boosters, provide monthly heartworm prevention, use monthly flea and tick prevention, and conduct regular deworming every 3-6 months.

**Health Monitoring:** Watch for signs of limping or joint stiffness, monitor appetite and water intake, check for unusual lumps or bumps, observe behavior changes like lethargy or aggression, and maintain healthy weight where the waist is visible and ribs can be felt but not seen.

**Special Considerations:** Provide comfortable bedding for joint support, keep them active to prevent obesity-related issues, protect from extreme heat especially in the Philippines climate, and ensure access to fresh water at all times.''',
        };
      }
      // Check for Shih Tzu (must contain both words or exact match)
      else if ((breedLower.contains('shih') && breedLower.contains('tzu')) ||
          breedLower == 'shih tzu' ||
          breedLower.contains('shih tzu')) {
        return {
          'nutrition':
              '''**Puppy (2-12 months):** Puppies need 25-28% daily protein (minimum 27g per 100g dry food) and 200-350 kcal per day. Feed a small breed puppy formula with high-quality protein using tiny kibble size appropriate for small mouths. Include DHA for brain development and feed 3-4 times daily.

**Adult (1-9 years):** Adults require 20-25% daily protein (minimum 22g per 100g dry food) and 300-450 kcal per day, adjusting based on activity. Use high-quality small breed adult formula and watch for food allergies, as chicken and grains are common allergens. Feed twice daily.

**Senior (9+ years):** Seniors need 18-22% daily protein (easier to digest) and calories reduced by 15-20% from adult requirements. Use senior small breed formula with joint support and add omega-3 fatty acids for skin and coat health. Feed 2-3 times daily in smaller portions.

**Foods to Include:** High-quality small breed kibble, lean proteins like lamb, fish, or duck if chicken-sensitive, easily digestible carbohydrates, and small amounts of fresh vegetables.

**Foods to Avoid:** Never feed large kibble size due to choking hazard, common allergens like chicken, wheat, or corn if sensitive, high-fat foods that can cause pancreatitis, human foods with spices or additives, or toxic foods like grapes, chocolate, onions, and garlic.''',
          'grooming':
              '''**Brushing:** Daily brushing is required for their long, flowing coat. Use a pin brush or slicker brush, starting from the skin and brushing outward. Pay special attention to the undercoat and prevent matting with regular care.

**Bathing:** Bathe every 3-4 weeks using a gentle, hypoallergenic dog shampoo. Conditioner is recommended for coat softness. Dry thoroughly with a blow dryer on low heat and keep the face clean and dry.

**Ear Cleaning:** Clean weekly as floppy ears are prone to infections. Use a vet-approved ear cleaner and gently wipe the outer ear canal. Check for excessive wax or foul odor and keep ear hair trimmed.

**Dental Care:** Brush teeth daily as small breeds are prone to dental issues. Use a small dog toothbrush and dog toothpaste, provide dental chews designed for small dogs, schedule annual professional dental cleaning, and watch for tartar buildup and gum disease.

**Nail and Paw Care:** Trim nails every 2-3 weeks, as very small nails require careful trimming. Inspect paw pads regularly, keep hair between paw pads trimmed, and moisturize if pads appear dry.''',
          'training':
              '''**Physical Exercises:** Provide daily walks of 15-30 minutes, twice per day. Include short play sessions indoors appropriate for apartment living, gentle play with small toys, stair climbing for light exercise, and short fetch games in safe, enclosed areas.

**Interactive Play:** Engage them with puzzle toys sized for small dogs, hide and seek games indoors, interactive squeaky toys, treat-dispensing toys like Kong and puzzle feeders, and social interaction with family members.

**Obedience Training:** Teach basic commands including sit, stay, come, and down. House training requires patience and consistency. Use positive reinforcement with small treats in training sessions of 5-10 minutes, multiple times daily. Start early to prevent stubborn behaviors.

**Mental Stimulation:** Provide food puzzle toys and slow feeders, encourage learning new tricks and commands, engage in social play with gentle interaction, rotate toys to maintain interest, and use training games that engage their intelligence.''',
          'health':
              '''**Common Health Issues:** Shih Tzus are prone to brachycephalic airway issues causing breathing problems, so avoid overexertion in heat. Eye problems including proptosis, cataracts, and dry eye require regular eye checks. Monitor for hip dysplasia indicated by limping, patellar luxation shown by skipping or lameness, dental disease requiring daily dental care, and skin allergies indicated by excessive scratching.

**Preventive Care:** Schedule annual vet checkups (semi-annual for seniors), maintain core vaccinations with boosters, provide monthly heartworm prevention, use monthly flea and tick prevention, conduct regular grooming to prevent skin issues, and schedule regular ophthalmologic exams for eye care.

**Health Monitoring:** Watch breathing especially in hot weather, monitor for eye discharge or redness, check for dental issues and bad breath, observe for signs of pain or discomfort, and maintain healthy weight as obesity worsens breathing issues.

**Special Considerations:** Avoid excessive exercise in hot weather, protect eyes from debris and injury, keep facial folds clean and dry, provide a comfortable and well-ventilated sleeping area, and regular professional grooming is recommended.''',
        };
      }
      // Check for Labrador Retriever
      else if (breedLower.contains('labrador')) {
        return {
          'nutrition':
              '''**Puppy (2-12 months):** Puppies need 25-28% daily protein (minimum 27g per 100g dry food) and calories ranging from 800-1200 kcal for medium dogs to 1200-1800 kcal for large dogs. Use large breed puppy formula to support controlled growth, include DHA for brain and vision development, and provide high-quality protein sources like chicken, fish, or lamb. Feed 3-4 times daily.

**Adult (1-7 years):** Adults require 21-25% daily protein (minimum 23g per 100g dry food) and calories ranging from 1200-1600 kcal for medium to 1600-2200 kcal for large dogs, adjusting for activity level. Use high-quality adult formula for active breeds and watch calories closely as Labradors are prone to obesity. Include omega-3 fatty acids for joint health and feed twice daily, measuring portions carefully.

**Senior (7+ years):** Seniors need 18-22% daily protein (easier to digest) and calories reduced by 15-20% from adult requirements. Use senior formula with glucosamine and chondroitin, lower calorie density to prevent weight gain, increase fiber for digestive health, and feed twice daily in controlled portions.

**Foods to Include:** High-quality large breed formulas, lean proteins including chicken, turkey, and fish, complex carbohydrates like brown rice and sweet potato, fresh vegetables and fruits in moderation, and foods rich in omega-3 such as fish oil and flaxseed.

**Foods to Avoid:** Never feed excessive treats and table scraps to prevent obesity, high-fat foods that can cause pancreatitis, toxic foods like chocolate, grapes, raisins, onions, and garlic, allow rapid eating (use slow feeder bowls), or give human foods with spices or additives.''',
          'grooming':
              '''**Brushing:** Brush 2-3 times per week, more frequently during shedding seasons. Use a slicker brush or deshedding tool like Furminator as the double coat requires regular attention. Remove dead undercoat to reduce shedding and distribute natural oils through brushing.

**Bathing:** Bathe every 4-6 weeks or when dirty using gentle, moisturizing dog shampoo. Conditioner helps with coat health. Dry thoroughly, especially the undercoat, and bathe more frequently if swimming regularly.

**Ear Cleaning:** Clean weekly as floppy ears are prone to infections. Check after swimming or water activities, use vet-approved ear cleaner, and gently wipe the outer ear canal. Watch for signs of infection including odor, redness, or discharge.

**Dental Care:** Brush teeth 3-4 times per week using large dog toothbrush and dog toothpaste. Provide dental chews daily and schedule annual professional dental cleaning. Monitor for tartar buildup regularly.

**Nail and Paw Care:** Trim nails every 3-4 weeks, though active Labs may need less frequent trims. Check paw pads after outdoor activities, remove debris from between paw pads, and inspect for cuts or foreign objects.''',
          'training':
              '''**Physical Exercises:** Provide daily exercise totaling 60-90 minutes. Include long walks of 30-45 minutes twice per day, 20-30 minutes of running or jogging, fetch and retrieving games which are natural instincts, swimming for excellent low-impact exercise, and hiking and outdoor adventures.

**Interactive Play:** Engage them with fetch using tennis balls or frisbees, tug-of-war with appropriate toys, puzzle toys with treats, interactive squeaky toys, and social play with other dogs.

**Obedience Training:** Teach basic commands including sit, stay, come, down, heel, and leave it, plus advanced commands like wait, drop it, and fetch. Use positive reinforcement with treats and praise in training sessions of 15-20 minutes, 2-3 times daily. Labradors are highly trainable and excel in obedience.

**Agility Training:** Include jumping through hoops, weaving through poles, tunnel runs, balance beam exercises, and obstacle courses to keep them physically and mentally engaged.

**Mental Stimulation:** Provide scent work and nose games, food puzzle toys and treat dispensers, regular learning of new tricks, hide and seek games, rotate toys to maintain interest, and consider training classes for ongoing engagement.''',
          'health':
              '''**Common Health Issues:** Labradors are prone to hip and elbow dysplasia requiring genetic screening, Progressive Retinal Atrophy (PRA) needing regular eye exams, exercise-induced collapse (EIC) requiring avoiding overexertion, obesity which is very common and needs strict diet management, ear infections requiring regular cleaning, and bloat (Gastric Dilatation-Volvulus) requiring feeding multiple small meals.

**Preventive Care:** Schedule annual vet checkups (semi-annual for seniors), maintain core vaccinations (DHPP, rabies) with boosters, provide monthly heartworm prevention, use monthly flea and tick prevention, conduct regular deworming, and perform hip and elbow X-rays for breeding dogs.

**Health Monitoring:** Maintain healthy weight where waist is visible and ribs can be felt, watch for limping or joint stiffness, monitor for signs of bloat including restlessness and drooling, schedule regular eye examinations, and check ears for infections regularly.

**Special Considerations:** Ensure controlled growth in puppies to prevent joint issues, avoid excessive exercise in puppies to protect joints, provide joint supplements like glucosamine as preventive measures, monitor food intake carefully as they are prone to overeating, and provide regular exercise essential for both physical and mental health.''',
        };
      }
    } else if (animalType == 'cat') {
      // Check for British Shorthair
      if (breedLower.contains('british') && breedLower.contains('shorthair')) {
        return {
          'nutrition':
              '''**Kitten (2-12 months):** Kittens need 30-35% daily protein (minimum 32g per 100g dry food) and 200-300 kcal per day. Feed high-quality kitten formula with DHA for brain development, 3-4 times daily in small portions, and include wet food for hydration.

**Adult (1-7 years):** Adults require 26-30% daily protein (minimum 28g per 100g dry food) and 250-350 kcal per day, adjusting for activity and spay/neuter status. Use high-quality adult cat food with real meat as the first ingredient, include both dry and wet food, and feed twice daily while measuring portions.

**Senior (7+ years):** Seniors need 26-30% daily protein to maintain muscle mass and calories reduced by 10-15% from adult requirements if less active. Use senior formula with joint support and easier to digest proteins, feeding 2-3 times daily in smaller portions.

**Foods to Include:** High-quality commercial cat food in both wet and dry forms, real meat proteins including chicken, turkey, and fish, taurine-rich foods which are essential for cats, limited carbohydrates, and ensure fresh water is always available.

**Foods to Avoid:** Never feed dog food which lacks taurine, raw fish that can cause thiamine deficiency, onions, garlic, chives, chocolate, caffeine, excessive carbohydrates, or human foods with spices or additives.''',
          'grooming':
              '''**Brushing:** Brush 2-3 times per week as the dense, plush coat requires regular attention. Use a slicker brush or metal comb, more frequently during shedding seasons, to remove dead hair and prevent matting. Use gentle brushing from head to tail.

**Bathing:** Bathe every 4-6 weeks or when dirty using cat-specific shampoo that is pH balanced. Rinse thoroughly to prevent skin irritation and dry completely with a towel and low-heat dryer if needed. Keep them calm during bath time.

**Ear Cleaning:** Check ears weekly and clean monthly or when dirty using vet-approved ear cleaner and cotton ball. Gently wipe the outer ear without inserting deep and watch for excessive wax or foul odor.

**Dental Care:** Brush teeth 2-3 times per week with cat toothpaste using a finger brush or small cat toothbrush. Provide dental treats or chews and schedule annual professional dental cleaning if needed. Watch for signs of dental disease including bad breath and drooling.

**Nail and Paw Care:** Trim nails every 2-3 weeks using cat nail clippers, being careful to avoid cutting the quick (pink area). Provide scratching posts and inspect paw pads regularly for cuts or issues.''',
          'training':
              '''**Physical Exercises:** Provide daily play sessions of 15-20 minutes, 2-3 times per day. Use interactive wand toys like feather wands and laser pointers, engage in chasing games and pouncing activities, encourage climbing on cat trees and scratching posts, and include running and jumping exercises.

**Interactive Play:** Engage them with feather wand toys to satisfy natural hunting instincts, puzzle toys with treats, interactive automated toys like moving mice and balls, hide and seek games with treats, and social interaction with family members.

**Obedience Training:** Teach basic commands including come and sit, requiring patience. Litter box training is usually natural. Use positive reinforcement with treats in training sessions of 5-10 minutes. Clicker training can be effective for these cats.

**Mental Stimulation:** Provide food puzzle toys and treat dispensers, window perches for bird watching, rotate toys regularly to maintain interest, train new tricks and behaviors, and use interactive feeding methods instead of bowls.''',
          'health':
              '''**Common Health Issues:** British Shorthairs are prone to Hypertrophic Cardiomyopathy (HCM), a genetic heart condition requiring regular screening. Polycystic Kidney Disease (PKD) has genetic screening available. Monitor weight closely as they are prone to weight gain and obesity. Dental disease requires regular dental care, and urinary tract issues can be prevented by ensuring plenty of fresh water.

**Preventive Care:** Schedule annual vet checkups (semi-annual for seniors), maintain core vaccinations (FVRCP, rabies) with boosters, provide monthly flea and tick prevention, conduct regular deworming, schedule heart disease screening (echocardiogram) if breeding, and implement weight monitoring and management.

**Health Monitoring:** Watch for signs of heart disease including breathing difficulty and lethargy, monitor weight as obesity is common, check for dental issues and bad breath, observe litter box habits for UTI signs, and watch for signs of kidney disease including increased thirst and urination.

**Special Considerations:** Provide regular exercise to prevent obesity, offer multiple fresh water sources, ensure a comfortable and quiet environment, conduct regular grooming to prevent hairballs, and monitor for breathing issues as some lines have flat-faced traits.''',
        };
      }
      // Check for Puspin/Philippine Shorthair
      else if (breedLower.contains('puspin') ||
          (breedLower.contains('philippine') &&
              breedLower.contains('shorthair'))) {
        return {
          'nutrition':
              '''**Kitten (2-12 months):** Kittens need 30-35% daily protein (minimum 32g per 100g dry food) and 180-280 kcal per day. Feed high-quality kitten formula with DHA, 3-4 times daily, and include wet food for hydration.

**Adult (1-7 years):** Adults require 26-30% daily protein (minimum 28g per 100g dry food) and 200-300 kcal per day, adjusting for activity and spay/neuter status. Use high-quality adult cat food with real meat, a mix of wet and dry food is recommended, and feed twice daily while measuring portions.

**Senior (7+ years):** Seniors need 26-30% daily protein to maintain muscle mass and calories reduced by 10-15% if less active. Use senior formula with joint support and easier to digest proteins, feeding 2-3 times daily.

**Foods to Include:** High-quality commercial cat food in both wet and dry forms, real meat proteins including chicken, fish, and turkey, taurine-rich foods which are essential nutrients, ensure fresh water is always available, and offer occasional treats in moderation.

**Foods to Avoid:** Never feed dog food which lacks essential taurine, raw fish that poses thiamine deficiency risk, onions, garlic, chives, chocolate, caffeine, alcohol, excessive carbohydrates, or human foods with spices.''',
          'grooming':
              '''**Brushing:** Brush 1-2 times per week as the short coat is low maintenance. Use a rubber curry brush or soft bristle brush, more frequently during shedding seasons, to remove loose hair. This is a quick and easy grooming routine.

**Bathing:** Bathe every 6-8 weeks or when dirty using mild, cat-specific shampoo. Rinse thoroughly and dry completely. Minimal bathing is needed for the short coat.

**Ear Cleaning:** Check ears monthly and clean when dirty or if you notice buildup using vet-approved ear cleaner. Gently wipe the outer ear and watch for signs of infection.

**Dental Care:** Brush teeth 2-3 times per week using cat toothbrush and toothpaste. Provide dental treats and schedule annual dental cleaning if needed. Monitor for dental issues regularly.

**Nail and Paw Care:** Trim nails every 2-3 weeks using cat nail clippers, being careful to avoid cutting the quick. Provide scratching posts and inspect paw pads regularly.''',
          'training':
              '''**Physical Exercises:** Provide daily play of 15-20 minutes, 2-3 times per day. Use interactive wand toys, engage in chasing and pouncing games, encourage climbing on cat trees, and include running and jumping activities.

**Interactive Play:** Engage them with feather wand toys, laser pointers used carefully, puzzle toys with treats, interactive automated toys, and hide and seek games.

**Obedience Training:** Teach basic commands including come and sit. Litter box training is usually natural. Use positive reinforcement with treats in short training sessions of 5-10 minutes. Consistency in training is important.

**Mental Stimulation:** Provide food puzzle toys, window perches for bird watching, rotate toys regularly to maintain interest, train new tricks, and use interactive feeding methods instead of bowls.''',
          'health':
              '''**Common Health Issues:** Puspin are generally healthy breeds as mixed genetics provide hybrid vigor. Watch for common cat issues including dental disease and obesity. Urinary tract issues can be prevented by ensuring adequate water intake. Parasites like fleas, ticks, and worms are common in tropical climates, and respiratory infections should be monitored.

**Preventive Care:** Schedule annual vet checkups, maintain core vaccinations (FVRCP, rabies), provide monthly flea and tick prevention especially in the Philippines, conduct regular deworming, and implement weight monitoring.

**Health Monitoring:** Monitor weight to prevent obesity, watch for dental issues, check litter box habits regularly, observe appetite and water intake, and watch for signs of parasites.

**Special Considerations:** These cats are adaptable to the Philippines climate. Provide regular exercise to prevent obesity, offer multiple fresh water sources, ensure a comfortable living environment, and conduct regular grooming despite the short coat.''',
        };
      }
      // Check for Persian
      else if (breedLower.contains('persian')) {
        return {
          'nutrition':
              '''**Kitten (2-12 months):** Kittens need 30-35% daily protein (minimum 32g per 100g dry food) and 200-300 kcal per day. Feed high-quality kitten formula with DHA, 3-4 times daily, and include wet food for hydration.

**Adult (1-7 years):** Adults require 26-30% daily protein (minimum 28g per 100g dry food) and 250-350 kcal per day, adjusting for activity and spay/neuter status. Use high-quality adult cat food with real meat, a mix of wet and dry food is recommended, and feed twice daily while measuring portions carefully.

**Senior (7+ years):** Seniors need 26-30% daily protein to maintain muscle mass and calories reduced by 10-15% if less active. Use senior formula with joint support and easier to digest proteins, feeding 2-3 times daily.

**Foods to Include:** High-quality commercial cat food in both wet and dry forms, real meat proteins including chicken, turkey, and fish, taurine-rich foods which are essential for cats, ensure fresh water is always available, and offer occasional treats in moderation.

**Foods to Avoid:** Never feed dog food which lacks taurine, raw fish that causes thiamine deficiency, onions, garlic, chives, chocolate, caffeine, excessive carbohydrates, or human foods with spices.''',
          'grooming':
              '''**Brushing:** Brush daily as the long, luxurious coat requires extensive care. Use a wide-tooth comb followed by a slicker brush to prevent matting with regular, thorough brushing. Pay attention to the undercoat and professional grooming may be needed.

**Bathing:** Bathe every 3-4 weeks using gentle, cat-specific shampoo and conditioner. Thorough rinsing is essential. Dry completely with a blow dryer on low heat and keep them calm during grooming.

**Ear Cleaning:** Clean weekly as long hair can trap debris. Use vet-approved ear cleaner, gently wipe the outer ear, check for excessive wax, and watch for signs of infection.

**Dental Care:** Brush teeth 2-3 times per week using cat toothbrush and toothpaste. Provide dental treats and schedule annual professional dental cleaning. Monitor for dental disease regularly.

**Nail and Paw Care:** Trim nails every 2-3 weeks using cat nail clippers, being careful to avoid cutting the quick. Inspect paw pads regularly and keep hair between paw pads trimmed.''',
          'training':
              '''**Physical Exercises:** Provide daily play of 15-20 minutes, 2-3 times per day. Engage in gentle interactive play as this is a less active breed. Use wand toys and feather toys, encourage climbing on cat trees for lower energy activities, and include moderate chasing games.

**Interactive Play:** Engage them with feather wand toys, puzzle toys with treats, interactive automated toys used gently, hide and seek games, and social interaction with family members.

**Obedience Training:** Teach basic commands including come and sit. Litter box training is usually natural. Use positive reinforcement with treats in short training sessions of 5-10 minutes. Patience is required as they can be stubborn.

**Mental Stimulation:** Provide food puzzle toys, window perches for bird watching, rotate toys regularly to maintain interest, train new tricks, and use interactive feeding methods instead of bowls.''',
          'health':
              '''**Common Health Issues:** Persians are prone to Brachycephalic Airway Syndrome causing breathing difficulties due to their flat face. Polycystic Kidney Disease (PKD) requires genetic screening. Hypertrophic Cardiomyopathy (HCM) is a heart condition needing regular screening. Eye problems including excessive tearing and entropion require daily eye cleaning. Dental disease requires regular dental care, and heat sensitivity means avoiding overheating.

**Preventive Care:** Schedule annual vet checkups (semi-annual for seniors), maintain core vaccinations (FVRCP, rabies), provide monthly flea and tick prevention, conduct regular deworming, schedule kidney screening (ultrasound) if breeding, and perform heart screening (echocardiogram) which is recommended.

**Health Monitoring:** Watch breathing especially in heat, perform daily eye cleaning and monitoring, monitor for signs of kidney disease, check for dental issues regularly, and watch weight as obesity worsens breathing problems.

**Special Considerations:** Daily grooming is essential due to the long coat. Keep them in cool, well-ventilated areas, daily eye cleaning is required, monitor breathing and activity levels, and regular professional grooming is recommended.''',
        };
      }
    }

    return {};
  }

  String _getFormattedContent(String tabName) {
    if (!_isTop3Breed) {
      // For non-top breeds, use AI-generated content with simple formatting
      String content = '';
      switch (tabName) {
        case 'Nutrition':
          content =
              widget.careGuide['nutrition'] ?? 'No information available.';
          break;
        case 'Grooming':
          content = widget.careGuide['grooming'] ?? 'No information available.';
          break;
        case 'Training':
          content =
              widget.careGuide['exercise'] ??
              widget.careGuide['training'] ??
              'No information available.';
          break;
        case 'Health':
          content = widget.careGuide['health'] ?? 'No information available.';
          break;
      }
      return content;
    }

    // For top breeds, use detailed content
    final detailedGuide = _getDetailedCareGuide();
    final content =
        detailedGuide[tabName.toLowerCase()] ??
        widget.careGuide[tabName.toLowerCase()] ??
        'No information available.';

    return content;
  }

  Widget _buildFormattedContent(String content) {
    // Parse content with bold markers (paragraph format)
    final lines = content.split('\n');
    final List<Widget> widgets = [];

    for (final line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 12));
        continue;
      }

      // Regular line with possible bold text
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 6),
          child: _buildTextWithBold(line.trim()),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildTextWithBold(String text) {
    final List<TextSpan> spans = [];
    final RegExp boldRegex = RegExp(r'\*\*(.*?)\*\*');

    int lastMatchEnd = 0;
    for (final match in boldRegex.allMatches(text)) {
      // Add text before bold
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        );
      }
      // Add bold text
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      lastMatchEnd = match.end;
    }
    // Add remaining text
    if (lastMatchEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastMatchEnd),
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      );
    }

    if (spans.isEmpty) {
      return Text(
        text,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBg,
      appBar: AppBar(
        backgroundColor: _mint,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Breed Information',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Return the breed to the previous screen
              Navigator.of(context).pop(widget.breed);
            },
            child: const Text(
              'Use This Breed',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breed Image and Name Section
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1, // Makes it square (1:1 ratio)
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: MemoryImage(widget.imageBytes),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5],
                      ),
                    ),
                    child: Text(
                      widget.breed,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Breed Info Row
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _BreedInfoColumn(
                    title: 'Breed Group',
                    value: widget.breedGroup,
                  ),
                  const SizedBox(width: 24),
                  _BreedInfoColumn(title: 'Size', value: widget.size),
                  const SizedBox(width: 24),
                  _BreedInfoColumn(title: 'Life Span', value: widget.lifeSpan),
                ],
              ),
            ),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                widget.description,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 20),

            // Characteristics
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Characteristics',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...widget.characteristics.entries.map(
                    (entry) => _buildCharacteristicRow(entry.key, entry.value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Care Guide Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Care Guide',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCareGuideTab('Nutrition'),
                      _buildCareGuideTab('Grooming'),
                      _buildCareGuideTab('Training'),
                      _buildCareGuideTab('Health'),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildCareGuideContent(),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacteristicRow(String characteristic, int percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                characteristic,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[300],
            color: _mint,
            minHeight: 8,
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      ),
    );
  }

  Widget _buildCareGuideTab(String tabName) {
    final bool isActive = _activeCareGuideTab == tabName;
    return GestureDetector(
      onTap: () => setState(() => _activeCareGuideTab = tabName),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _mint : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? _mint : Colors.grey.shade300),
        ),
        child: Text(
          tabName,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black87,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCareGuideContent() {
    String content = '';
    IconData icon = Icons.info;

    switch (_activeCareGuideTab) {
      case 'Nutrition':
        content = _getFormattedContent('Nutrition');
        icon = Icons.fastfood;
        break;
      case 'Grooming':
        content = _getFormattedContent('Grooming');
        icon = Icons.brush;
        break;
      case 'Training':
        content = _getFormattedContent('Training');
        icon = Icons.school;
        break;
      case 'Health':
        content = _getFormattedContent('Health');
        icon = Icons.local_hospital;
        break;
    }

    return _buildInfoCard(
      icon: icon,
      title: _activeCareGuideTab,
      content: content,
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFC5E7A6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF61972E), size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                _isTop3Breed
                    ? _buildFormattedContent(content)
                    : Text(
                        content,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BreedInfoColumn extends StatelessWidget {
  final String title;
  final String value;

  const _BreedInfoColumn({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
