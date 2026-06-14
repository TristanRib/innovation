const { initializeApp } = require('firebase/app');
const { getFirestore, collection, addDoc, Timestamp } = require('firebase/firestore');
const { getAuth, signInWithEmailAndPassword } = require('firebase/auth');

const firebaseConfig = {
  apiKey: 'AIzaSyBaw-3DAatPFwNoLNXlreyKlDJ4OKX9m10',
  authDomain: 'innovation-dda6d.firebaseapp.com',
  projectId: 'innovation-dda6d',
  storageBucket: 'innovation-dda6d.firebasestorage.app',
  messagingSenderId: '360416043038',
  appId: '1:360416043038:web:8cd253b947ae2cced10e0f',
};

const publications = [
  {
    title: 'Les antioxydants : protéger ses cellules au naturel',
    summary: 'Découvrez pourquoi les antioxydants sont essentiels à votre santé et comment les intégrer facilement dans votre alimentation quotidienne.',
    tags: ['Nutrition', 'Immunité', 'Antioxydants'],
    authorName: 'Équipe Remedia',
    readingTimeMinutes: 5,
    publishedAt: Timestamp.fromDate(new Date('2024-11-10')),
    sections: [
      {
        type: 'paragraph',
        content: 'Les antioxydants sont des molécules capables de neutraliser les radicaux libres, ces substances instables qui endommagent les cellules et accélèrent le vieillissement. Notre corps en produit naturellement, mais notre alimentation doit compléter cette défense.'
      },
      {
        type: 'heading',
        content: 'Comment agissent les antioxydants ?'
      },
      {
        type: 'paragraph',
        content: 'Les radicaux libres sont produits lors de la respiration cellulaire, du stress, de la pollution ou d\'une alimentation déséquilibrée. En excès, ils provoquent un phénomène appelé stress oxydatif, associé à de nombreuses maladies chroniques (cardiovasculaires, cancers, Alzheimer). Les antioxydants "piègent" ces radicaux avant qu\'ils n\'attaquent les cellules.'
      },
      {
        type: 'heading',
        content: 'Les principales sources alimentaires'
      },
      {
        type: 'bullets',
        items: [
          'Fruits rouges (myrtilles, framboises, cassis) : très riches en anthocyanes',
          'Légumes verts à feuilles (épinards, brocoli) : vitamine C et bêta-carotène',
          'Noix et graines (noix du Brésil, graines de tournesol) : vitamine E et sélénium',
          'Chocolat noir à 70 %+ : flavonoïdes puissants',
          'Thé vert : catéchines documentées par de nombreuses études',
          'Épices (curcuma, cannelle, clou de girofle) : concentration exceptionnelle en polyphénols',
        ]
      },
      {
        type: 'tip',
        content: 'Astuce pratique : la règle des 5 couleurs. Pour maximiser la diversité en antioxydants, essayez chaque jour de manger des fruits et légumes de 5 couleurs différentes. Chaque pigment correspond à une famille d\'antioxydants différente.'
      },
      {
        type: 'heading',
        content: 'Quelle est la dose recommandée ?'
      },
      {
        type: 'paragraph',
        content: 'Il n\'existe pas de dose universelle définie, car les antioxydants agissent en synergie. Les suppléments isolés (vitamine E ou C à haute dose) ont montré des résultats décevants voire négatifs dans certaines études. L\'approche la plus efficace reste l\'alimentation variée et colorée, riche en végétaux.'
      },
      {
        type: 'warning',
        content: 'Attention aux suppléments à haute dose. La prise isolée de bêta-carotène en complément alimentaire a été associée à un risque accru de cancer du poumon chez les fumeurs (étude ATBC, 1994). Préférez toujours les sources alimentaires naturelles.'
      },
      {
        type: 'quote',
        content: '« Que ton alimentation soit ta première médecine. » — Hippocrate'
      },
    ]
  },
  {
    title: 'Le miel : bien plus qu\'un simple sucre naturel',
    summary: 'Antibactérien, cicatrisant, apaisant pour la gorge — le miel possède des propriétés thérapeutiques documentées bien au-delà de son goût.',
    tags: ['Miel', 'Antibactérien', 'Gorge'],
    authorName: 'Équipe Remedia',
    readingTimeMinutes: 4,
    publishedAt: Timestamp.fromDate(new Date('2024-12-01')),
    sections: [
      {
        type: 'paragraph',
        content: 'Utilisé comme médicament depuis l\'Antiquité, le miel fait l\'objet de nombreuses recherches modernes qui confirment en partie ses propriétés. Sa composition complexe (sucres, peroxyde d\'hydrogène, polyphénols, enzymes) lui confère des effets multiples.'
      },
      {
        type: 'heading',
        content: 'Propriétés antibactériennes'
      },
      {
        type: 'paragraph',
        content: 'Le miel crée un environnement inhospitalier pour les bactéries grâce à son pH acide (3,5–4,5), sa faible teneur en eau et sa production de peroxyde d\'hydrogène. Le miel de Manuka (Nouvelle-Zélande) contient en plus du méthylglyoxal (MGO), un composé particulièrement actif contre des bactéries résistantes comme Staphylococcus aureus.'
      },
      {
        type: 'heading',
        content: 'Ce que les études disent sur la toux'
      },
      {
        type: 'paragraph',
        content: 'Une méta-analyse publiée dans BMJ Evidence-Based Medicine (2020) portant sur 1 345 patients a conclu que le miel réduisait la fréquence et la sévérité de la toux plus efficacement que les antitussifs classiques chez l\'enfant de plus d\'un an, avec un profil de sécurité nettement supérieur.'
      },
      {
        type: 'bullets',
        items: [
          'Miel toutes fleurs : bon rapport qualité/prix, utilisé pour la gorge',
          'Miel de thym : traditionnellement utilisé pour ses propriétés antiseptiques',
          'Miel de manuka UMF 10+ : pour les infections bactériennes cutanées',
          'Miel de châtaignier : riche en polyphénols, saveur intense',
        ]
      },
      {
        type: 'tip',
        content: 'Pour la gorge : dissolvez 1 cuillère à soupe de miel dans de l\'eau chaude (pas bouillante — au-dessus de 40 °C, les enzymes sont détruites) avec du jus de citron. À prendre le soir avant de dormir.'
      },
      {
        type: 'warning',
        content: 'Ne jamais donner de miel aux enfants de moins d\'un an. Le miel peut contenir des spores de Clostridium botulinum qui ne présentent aucun risque pour les adultes mais peuvent provoquer le botulisme infantile, une urgence médicale grave.'
      },
    ]
  },
  {
    title: 'Vitamine D : le nutriment que 80 % des Français manquent',
    summary: 'Immunité, humeur, os, muscles — la vitamine D joue un rôle central dans l\'organisme. Comment savoir si vous êtes carencé et comment y remédier ?',
    tags: ['Vitamines', 'Immunité', 'Nutrition'],
    authorName: 'Équipe Remedia',
    readingTimeMinutes: 5,
    publishedAt: Timestamp.fromDate(new Date('2025-01-15')),
    sections: [
      {
        type: 'paragraph',
        content: 'La vitamine D est synthétisée par la peau sous l\'action des rayons UVB du soleil. En France, entre octobre et mars, l\'angle du soleil est trop faible pour déclencher cette synthèse — la quasi-totalité de la population accumule un déficit pendant cette période, qui ne se rattrape pas toujours en été.'
      },
      {
        type: 'heading',
        content: 'Rôles dans l\'organisme'
      },
      {
        type: 'bullets',
        items: [
          'Absorption du calcium et du phosphore : indispensable à la solidité osseuse',
          'Régulation du système immunitaire : réduit le risque d\'infections respiratoires',
          'Santé musculaire : prévient les chutes chez les personnes âgées',
          'Équilibre de l\'humeur : études associant déficit et dépression saisonnière',
          'Réduction de l\'inflammation chronique',
        ]
      },
      {
        type: 'heading',
        content: 'Sources alimentaires (souvent insuffisantes seules)'
      },
      {
        type: 'bullets',
        items: [
          'Poissons gras (saumon, maquereau, hareng, sardine) : meilleures sources alimentaires',
          'Jaune d\'œuf : petites quantités mais facilement accessible',
          'Champignons exposés aux UV (shiitake, girolles)',
          'Foie de veau',
          'Produits laitiers enrichis',
        ]
      },
      {
        type: 'tip',
        content: '15 à 20 minutes de soleil sur les bras et le visage entre 11h et 14h en été suffisent à produire 10 000 à 20 000 UI de vitamine D. Inutile de "bronzer" — une exposition courte sans crème solaire est bien plus efficace.'
      },
      {
        type: 'heading',
        content: 'Supplémentation'
      },
      {
        type: 'paragraph',
        content: 'La supplémentation est recommandée par l\'ANSM pour les groupes à risque (nourrissons, personnes âgées, personnes à peau foncée, faible exposition solaire). Des doses de 800 à 2 000 UI/jour sont généralement sans risque pour les adultes. Une prise de sang (dosage 25-OH-D) permet de confirmer un déficit avant de supplémenter.'
      },
      {
        type: 'warning',
        content: 'Un excès de vitamine D (toxicité rare mais possible) peut provoquer une hypercalcémie avec nausées, fatigue et calcifications rénales. Ne dépassez pas 4 000 UI/jour sans avis médical, et ne cumulez pas plusieurs suppléments contenant de la vitamine D.'
      },
    ]
  },
];

async function main() {
  const app = initializeApp(firebaseConfig);
  const auth = getAuth(app);
  const db = getFirestore(app);

  await signInWithEmailAndPassword(auth, 'seed@remedia.app', 'SeedRemedia2026!');
  console.log('Connecté.\n');

  const col = collection(db, 'publications');
  console.log('Ajout des publications...\n');
  for (const pub of publications) {
    const docRef = await addDoc(col, pub);
    console.log(`✓ "${pub.title}" → ${docRef.id}`);
  }
  console.log(`\n✓ ${publications.length} publications ajoutées avec succès !`);
  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
