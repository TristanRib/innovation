const { initializeApp } = require('firebase/app');
const { getFirestore, collection, doc, setDoc } = require('firebase/firestore');
const { getAuth, createUserWithEmailAndPassword, signInWithEmailAndPassword } = require('firebase/auth');
const { v4: uuidv4 } = require('uuid');

const firebaseConfig = {
  apiKey: 'AIzaSyBaw-3DAatPFwNoLNXlreyKlDJ4OKX9m10',
  authDomain: 'innovation-dda6d.firebaseapp.com',
  projectId: 'innovation-dda6d',
  storageBucket: 'innovation-dda6d.firebasestorage.app',
  messagingSenderId: '360416043038',
  appId: '1:360416043038:web:8cd253b947ae2cced10e0f',
};

const SEED_EMAIL = 'seed@remedia.app';
const SEED_PASS  = 'SeedRemedia2026!';
const SEED_NAME  = 'Équipe Remedia';

const remedies = [
  {
    title: 'Grog au miel et citron contre le rhume',
    description: 'Le remède classique de grand-mère pour soulager rapidement les symptômes du rhume et adoucir la gorge.',
    ingredients: ['1 citron bio', '2 cuillères à soupe de miel', '1 verre d\'eau chaude', '1 pincée de cannelle'],
    method: 'Pressez le citron. Versez le jus dans un grand verre d\'eau bien chaude (pas bouillante). Ajoutez le miel et la cannelle. Mélangez et buvez lentement avant de dormir.',
    tags: ['Rhume', 'Gorge'],
    averageRating: 4.7, ratingCount: 34, commentCount: 12,
  },
  {
    title: 'Tisane de gingembre et curcuma anti-inflammatoire',
    description: 'Puissante tisane anti-inflammatoire naturelle, idéale pour les douleurs articulaires et le renforcement immunitaire.',
    ingredients: ['2 cm de gingembre frais râpé', '1 c.à.c de curcuma', '1 c.à.c de miel', '1 pincée de poivre noir', '400 ml d\'eau'],
    method: 'Portez l\'eau à ébullition. Ajoutez le gingembre râpé et laissez infuser 10 minutes. Filtrez, ajoutez le curcuma, une pincée de poivre et le miel. Buvez chaud, 1 à 2 fois par jour.',
    tags: ['Articulations', 'Immunité', 'Stress'],
    averageRating: 4.5, ratingCount: 28, commentCount: 8,
  },
  {
    title: 'Cataplasme d\'argile verte pour les contusions',
    description: 'L\'argile verte absorbe les toxines et réduit l\'inflammation lors de coups, entorses ou douleurs musculaires.',
    ingredients: ['4 cuillères à soupe d\'argile verte en poudre', 'Eau froide', '2 gouttes d\'huile essentielle de lavande (optionnel)'],
    method: 'Mélangez l\'argile avec de l\'eau froide pour obtenir une pâte épaisse. Appliquez une couche généreuse sur la zone douloureuse. Couvrez d\'un linge humide. Laissez poser 20-30 minutes puis rincez à l\'eau froide.',
    tags: ['Articulations', 'Peau'],
    averageRating: 4.2, ratingCount: 15, commentCount: 5,
  },
  {
    title: 'Infusion de camomille pour le sommeil',
    description: 'La camomille est reconnue pour ses propriétés sédatives douces. Parfaite pour retrouver un sommeil naturel sans médicaments.',
    ingredients: ['2 cuillères à café de fleurs de camomille séchées', '200 ml d\'eau bouillante', '1 c.à.c de miel (optionnel)'],
    method: 'Versez l\'eau bouillante sur les fleurs de camomille. Couvrez et laissez infuser 5 à 10 minutes. Filtrez et ajoutez le miel si désiré. Boire 30 minutes avant d\'aller dormir.',
    tags: ['Sommeil', 'Stress'],
    averageRating: 4.6, ratingCount: 42, commentCount: 18,
  },
  {
    title: 'Sirop d\'oignon pour la toux',
    description: 'Remède de grand-mère très efficace contre la toux grasse et sèche. L\'oignon a des propriétés antibactériennes naturelles.',
    ingredients: ['2 gros oignons', '4 cuillères à soupe de miel', '1 citron', '1 verre d\'eau'],
    method: 'Coupez les oignons en rondelles. Faites-les cuire à feu doux avec l\'eau pendant 20 minutes. Filtrez le jus, ajoutez le miel et le jus de citron. Prenez 3 cuillères à soupe par jour.',
    tags: ['Rhume', 'Gorge'],
    averageRating: 4.1, ratingCount: 21, commentCount: 9,
  },
  {
    title: 'Masque au miel et cannelle anti-acné',
    description: 'Le miel et la cannelle ont des propriétés antibactériennes et anti-inflammatoires efficaces contre les imperfections cutanées.',
    ingredients: ['2 cuillères à soupe de miel bio', '1 cuillère à café de cannelle en poudre'],
    method: 'Mélangez le miel et la cannelle en pâte homogène. Appliquez sur le visage propre en évitant les yeux. Laissez poser 10-15 minutes. Rincez à l\'eau tiède. À utiliser 2 fois par semaine.',
    tags: ['Peau'],
    averageRating: 4.3, ratingCount: 37, commentCount: 14,
  },
  {
    title: 'Infusion de verveine citronnelle contre le stress',
    description: 'La verveine citronnelle est une plante adaptogène reconnue pour calmer le système nerveux et réduire l\'anxiété.',
    ingredients: ['2 c.à.c de verveine citronnelle séchée', '200 ml d\'eau bouillante', 'Miel ou citron selon goût'],
    method: 'Faites bouillir l\'eau. Versez sur la verveine et laissez infuser 7 minutes couvert. Filtrez et dégustez chaud. Boire 2 fois par jour en période de stress.',
    tags: ['Stress', 'Sommeil'],
    averageRating: 4.4, ratingCount: 19, commentCount: 6,
  },
  {
    title: 'Eau de riz contre la diarrhée',
    description: 'L\'amidon du riz aide à solidifier les selles et à réhydrater l\'organisme lors de diarrhées légères à modérées.',
    ingredients: ['100 g de riz blanc', '1 litre d\'eau', '1 pincée de sel'],
    method: 'Faites cuire le riz dans l\'eau sans couvercle 20 minutes. Filtrez en gardant l\'eau de cuisson. Ajoutez une pincée de sel. Buvez tiède par petites gorgées toute la journée.',
    tags: ['Digestion'],
    averageRating: 4.0, ratingCount: 12, commentCount: 3,
  },
  {
    title: 'Cataplasme de chou blanc contre les douleurs',
    description: 'Les feuilles de chou blanc ont des vertus anti-inflammatoires et décongestionnantes reconnues depuis des siècles.',
    ingredients: ['4 grandes feuilles de chou blanc', 'Rouleau à pâtisserie'],
    method: 'Retirez la nervure centrale des feuilles. Aplatissez-les au rouleau pour libérer le jus. Chauffez légèrement les feuilles. Appliquez directement sur la zone douloureuse. Maintenez avec un bandage pendant 1 heure.',
    tags: ['Articulations'],
    averageRating: 3.8, ratingCount: 9, commentCount: 2,
  },
  {
    title: 'Gargarisme au sel et bicarbonate',
    description: 'Remède express pour soulager les maux de gorge et désinfecter naturellement la cavité buccale.',
    ingredients: ['1 verre d\'eau tiède', '1 c.à.c de sel fin', '1/2 c.à.c de bicarbonate de soude'],
    method: 'Dissolvez le sel et le bicarbonate dans l\'eau tiède. Gargarisez-vous pendant 30 secondes, crachez. Répétez 3 à 4 fois par jour jusqu\'à amélioration.',
    tags: ['Gorge', 'Rhume'],
    averageRating: 4.5, ratingCount: 48, commentCount: 22,
  },
  {
    title: 'Huile de coco pour hydrater la peau sèche',
    description: 'L\'huile de coco vierge est un excellent hydratant naturel, riche en acides gras qui renforcent la barrière cutanée.',
    ingredients: ['Huile de coco vierge extra (quantité selon besoin)', '2 gouttes d\'huile essentielle de rose (optionnel)'],
    method: 'Réchauffez une petite quantité d\'huile de coco entre vos paumes. Appliquez sur la peau propre en massages circulaires. Idéal après la douche sur peau légèrement humide.',
    tags: ['Peau'],
    averageRating: 4.6, ratingCount: 56, commentCount: 24,
  },
  {
    title: 'Tisane de menthe poivrée contre les maux de tête',
    description: 'La menthe poivrée contient du menthol, un analgésique naturel qui soulage les céphalées de tension.',
    ingredients: ['1 poignée de feuilles de menthe fraîche (ou 2 c.à.c séchée)', '250 ml d\'eau bouillante', 'Miel'],
    method: 'Versez l\'eau bouillante sur la menthe. Couvrez et laissez infuser 5 minutes. Filtrez et ajoutez le miel. Vous pouvez aussi appliquer une huile essentielle de menthe diluée sur les tempes.',
    tags: ['Maux de tête'],
    averageRating: 4.2, ratingCount: 31, commentCount: 10,
  },
  {
    title: 'Lait chaud au curcuma (Golden Milk)',
    description: 'Le "lait d\'or" est une boisson ayurvédique anti-inflammatoire qui favorise le sommeil et renforce l\'immunité.',
    ingredients: ['250 ml de lait végétal (amande ou coco)', '1 c.à.c de curcuma', '1/2 c.à.c de cannelle', '1/4 c.à.c de gingembre', '1 c.à.c de miel', '1 pincée de poivre'],
    method: 'Chauffez le lait à feu doux. Ajoutez les épices et le miel. Mélangez au fouet jusqu\'à homogénéité. Versez dans un mug et savourez le soir avant de dormir.',
    tags: ['Sommeil', 'Immunité', 'Articulations'],
    averageRating: 4.8, ratingCount: 63, commentCount: 28,
  },
  {
    title: 'Bain de pieds au bicarbonate et huile essentielle',
    description: 'Ce bain de pieds soulage la fatigue, élimine les odeurs et hydrate la peau des talons secs.',
    ingredients: ['3 litres d\'eau chaude', '3 c.à.s de bicarbonate de soude', '5 gouttes d\'HE de tea tree', '5 gouttes d\'HE de lavande', '1 c.à.s de gros sel'],
    method: 'Remplissez une bassine d\'eau chaude supportable. Ajoutez tous les ingrédients et mélangez. Trempez vos pieds 15-20 minutes. Frottez les zones sèches avec une pierre ponce. Séchez bien entre les orteils.',
    tags: ['Peau', 'Stress'],
    averageRating: 4.1, ratingCount: 17, commentCount: 4,
  },
  {
    title: 'Vinaigre de cidre pour la digestion',
    description: 'Le vinaigre de cidre stimule la production d\'acides gastriques et favorise une bonne digestion après les repas.',
    ingredients: ['1 c.à.s de vinaigre de cidre bio (avec la mère)', '200 ml d\'eau tiède', '1 c.à.c de miel'],
    method: 'Diluez le vinaigre dans l\'eau tiède. Ajoutez le miel et mélangez. Buvez 10 à 15 minutes avant le repas principal. Commencez par de petites doses si vous n\'avez jamais essayé.',
    tags: ['Digestion'],
    averageRating: 4.0, ratingCount: 25, commentCount: 7,
  },
  {
    title: 'Compresse de thé vert pour les yeux gonflés',
    description: 'La caféine et les antioxydants du thé vert réduisent les poches sous les yeux et les rougeurs.',
    ingredients: ['2 sachets de thé vert usagés', 'Eau froide'],
    method: 'Après infusion, laissez refroidir les sachets de thé au réfrigérateur 20 minutes. Allongez-vous et posez un sachet sur chaque œil fermé pendant 15 minutes.',
    tags: ['Peau'],
    averageRating: 4.3, ratingCount: 22, commentCount: 8,
  },
  {
    title: 'Soupe miso pour booster l\'énergie',
    description: 'Riche en probiotiques et minéraux, la soupe miso redonne de l\'énergie rapidement et soutient la flore intestinale.',
    ingredients: ['1 c.à.s de pâte miso', '300 ml d\'eau chaude', '1 feuille d\'algue nori', '50 g de tofu soyeux', '1 oignon vert'],
    method: 'Chauffez l\'eau sans faire bouillir. Délayez la pâte miso dans un peu d\'eau froide puis ajoutez au reste. Incorporez le tofu coupé en dés, l\'algue et l\'oignon vert émincé. Servez immédiatement.',
    tags: ['Énergie', 'Digestion'],
    averageRating: 4.4, ratingCount: 14, commentCount: 5,
  },
  {
    title: 'Rinçage nasal au sel contre les allergies',
    description: 'Le neti pot ou rinçage nasal salin élimine les allergènes et mucus des voies nasales, soulageant durablement les rhinites allergiques.',
    ingredients: ['1 c.à.c de sel non iodé', '1 c.à.c de bicarbonate', '500 ml d\'eau tiède (bouillie puis refroidie)'],
    method: 'Dissolvez sel et bicarbonate dans l\'eau. Utilisez un neti pot ou une seringue. Penchez la tête à 45°. Versez délicatement dans une narine, ressort par l\'autre. Mouchez-vous doucement après.',
    tags: ['Allergie', 'Rhume'],
    averageRating: 4.2, ratingCount: 18, commentCount: 6,
  },
  {
    title: 'Masque à l\'avocat pour cheveux secs',
    description: 'L\'avocat est riche en acides gras et vitamines E et B qui nourrissent et réparent les cheveux abîmés et secs.',
    ingredients: ['1 avocat mûr', '2 c.à.s d\'huile d\'olive', '1 c.à.s de miel', '1 jaune d\'œuf'],
    method: 'Écrasez l\'avocat en purée lisse. Ajoutez l\'huile, le miel et le jaune d\'œuf. Mélangez bien. Appliquez sur cheveux propres et humides. Couvrez d\'une charlotte. Laissez agir 30 minutes puis rincez abondamment.',
    tags: ['Peau'],
    averageRating: 4.5, ratingCount: 29, commentCount: 11,
  },
  {
    title: 'Tisane de thym contre la bronchite',
    description: 'Le thym est un antiseptique naturel des voies respiratoires, reconnu pour fluidifier les sécrétions bronchiques.',
    ingredients: ['1 branche de thym frais (ou 2 c.à.c séché)', '250 ml d\'eau bouillante', 'Miel de thym', '1/2 citron'],
    method: 'Faites infuser le thym 10 minutes dans l\'eau bouillante couverte. Filtrez. Ajoutez le jus de citron et le miel. Boire 3 tasses par jour. Efficace en cure de 5 à 7 jours.',
    tags: ['Rhume', 'Gorge'],
    averageRating: 4.6, ratingCount: 33, commentCount: 13,
  },
  {
    title: 'Bain d\'avoine contre les démangeaisons',
    description: 'L\'avoine colloïdale apaise les démangeaisons cutanées dues à l\'eczéma, l\'urticaire ou les coups de soleil.',
    ingredients: ['200 g de flocons d\'avoine', 'Mixeur', 'Bain tiède'],
    method: 'Mixez les flocons en poudre fine. Versez dans un bain tiède (pas chaud) en brassant pour bien dissoudre. Restez immergé 15-20 minutes sans frotter. Séchez délicatement en tapotant.',
    tags: ['Peau', 'Allergie'],
    averageRating: 4.3, ratingCount: 16, commentCount: 4,
  },
  {
    title: 'Smoothie énergie banane-spiruline',
    description: 'Ce smoothie fournit un boost d\'énergie durable grâce aux glucides complexes de la banane et aux protéines de la spiruline.',
    ingredients: ['2 bananes mûres', '1 c.à.c de spiruline en poudre', '200 ml de lait végétal', '1 c.à.s de beurre d\'amande', '1 c.à.c de miel'],
    method: 'Mixez tous les ingrédients jusqu\'à obtenir un smoothie lisse. Servez immédiatement. Idéal le matin avant l\'effort physique ou en cas de fatigue passagère.',
    tags: ['Énergie'],
    averageRating: 4.4, ratingCount: 38, commentCount: 16,
  },
  {
    title: 'Cataplasme de moutarde contre la toux',
    description: 'Le cataplasme sinapisant dilate les bronches et stimule la circulation locale, soulageant la congestion thoracique.',
    ingredients: ['2 c.à.s de farine de moutarde', '4 c.à.s de farine de lin', 'Eau tiède'],
    method: 'Mélangez les farines avec de l\'eau tiède pour former une pâte. Étalez sur un linge propre. Appliquez sur le torse (jamais directement sur la peau). Gardez 10-15 minutes max. Arrêtez si sensation de brûlure.',
    tags: ['Rhume'],
    averageRating: 3.7, ratingCount: 8, commentCount: 2,
  },
  {
    title: 'Eau citronnée le matin pour la digestion',
    description: 'Boire de l\'eau citronnée à jeun stimule le système digestif, alcalinise le corps et aide l\'élimination des toxines.',
    ingredients: ['1 citron bio', '250 ml d\'eau tiède (pas chaude)', 'Optionnel : 1 c.à.c de miel'],
    method: 'Pressez le citron dans l\'eau tiède. Ajoutez le miel si désiré. Boire à jeun, au moins 20 minutes avant le petit-déjeuner. À pratiquer en cure de 21 jours minimum pour voir les effets.',
    tags: ['Digestion', 'Énergie'],
    averageRating: 4.3, ratingCount: 71, commentCount: 31,
  },
  {
    title: 'Huile de ricin pour faire pousser les sourcils',
    description: 'L\'huile de ricin est riche en acide ricinoléique qui stimule la circulation et favorise la repousse des poils et cheveux.',
    ingredients: ['Huile de ricin (quelques gouttes)', 'Coton-tige'],
    method: 'Avec un coton-tige, appliquez une fine couche d\'huile de ricin sur les sourcils le soir avant de dormir. Rincez le matin. Pratiquer quotidiennement pendant 4 à 6 semaines.',
    tags: ['Peau'],
    averageRating: 3.9, ratingCount: 20, commentCount: 7,
  },
  {
    title: 'Décoction de sauge contre les sueurs nocturnes',
    description: 'La sauge officinale est reconnue pour réduire la transpiration excessive, notamment lors de la ménopause.',
    ingredients: ['2 c.à.c de sauge séchée', '250 ml d\'eau', 'Miel (optionnel)'],
    method: 'Portez l\'eau à ébullition avec la sauge. Réduisez le feu et laissez frémir 3 minutes. Retirez du feu, couvrez et infusez 10 minutes. Filtrez et boire 2 tasses par jour, une le matin, une le soir.',
    tags: ['Stress', 'Sommeil'],
    averageRating: 4.0, ratingCount: 11, commentCount: 3,
  },
  {
    title: 'Gommage au café contre la cellulite',
    description: 'La caféine est un actif anti-cellulite reconnu qui stimule la lipolyse. Le gommage améliore la microcirculation locale.',
    ingredients: ['1/2 tasse de marc de café', '3 c.à.s d\'huile de coco', '3 c.à.s de sucre brun'],
    method: 'Mélangez tous les ingrédients. Sous la douche, massez les zones à traiter (cuisses, fesses) en mouvements circulaires 3-5 minutes. Rincez. Utilisez 2 à 3 fois par semaine.',
    tags: ['Peau', 'Énergie'],
    averageRating: 4.2, ratingCount: 45, commentCount: 19,
  },
  {
    title: 'Infusion de passiflore contre l\'anxiété',
    description: 'La passiflore agit sur les récepteurs GABA du cerveau, produisant un effet anxiolytique doux et naturel.',
    ingredients: ['1 c.à.s de feuilles de passiflore séchée', '200 ml d\'eau bouillante', 'Miel'],
    method: 'Versez l\'eau bouillante sur la passiflore. Couvrez et infusez 10 minutes. Filtrez soigneusement. Ajoutez le miel. Boire 1 à 2 tasses par jour, notamment en soirée.',
    tags: ['Stress', 'Sommeil'],
    averageRating: 4.5, ratingCount: 24, commentCount: 9,
  },
  {
    title: 'Compression froide au plantain pour les piqûres',
    description: 'La feuille de plantain a des propriétés anti-prurigineuses et cicatrisantes efficaces contre les piqûres d\'insectes.',
    ingredients: ['Quelques feuilles de plantain lancéolé frais', 'Eau froide'],
    method: 'Rincez et froissez les feuilles de plantain pour libérer leur sève. Appliquez directement sur la piqûre ou placez dans un linge froid. Maintenez 10-15 minutes. Répétez si nécessaire.',
    tags: ['Peau', 'Allergie'],
    averageRating: 4.1, ratingCount: 13, commentCount: 3,
  },
  {
    title: 'Bouillon de poulet maison contre la grippe',
    description: 'Le bouillon de poulet contient des composés anti-inflammatoires qui soulagent la congestion nasale et renforcent l\'immunité.',
    ingredients: ['1 carcasse de poulet', '2 carottes', '1 poireau', '1 branche de céleri', '3 gousses d\'ail', 'Thym, laurier, persil', '2 litres d\'eau', 'Sel, poivre'],
    method: 'Mettez la carcasse dans une cocotte avec tous les légumes et aromates. Couvrez d\'eau froide. Portez à ébullition et écumez. Laissez mijoter 2h à feu doux. Filtrez et assaisonnez. Boire chaud tout au long de la journée.',
    tags: ['Rhume', 'Immunité', 'Énergie'],
    averageRating: 4.8, ratingCount: 52, commentCount: 25,
  },
  {
    title: 'Huile de nigelle pour booster l\'immunité',
    description: 'La nigelle (cumin noir) est surnommée "remède universel" dans la médecine traditionnelle. Études cliniques confirmant des effets immunostimulants.',
    ingredients: ['1 c.à.c d\'huile de nigelle (thymoquinone)', 'Miel (pour masquer l\'amertume)'],
    method: 'Mélangez l\'huile de nigelle avec le miel. Prenez 1 cuillère à café le matin à jeun. Peut aussi être ajoutée dans une tisane ou un yaourt. En cure de 40 jours.',
    tags: ['Immunité', 'Énergie'],
    averageRating: 4.6, ratingCount: 30, commentCount: 12,
  },
];

const authors = ['Marie D.', 'Paul M.', 'Sophie L.', 'Jean-Pierre B.', 'Isabelle R.', 'Thomas V.'];

async function main() {
  const app = initializeApp(firebaseConfig);
  const auth = getAuth(app);
  const db = getFirestore(app);

  // Connexion ou création du compte seed
  let user;
  try {
    const cred = await signInWithEmailAndPassword(auth, SEED_EMAIL, SEED_PASS);
    user = cred.user;
    console.log('Connecté avec le compte seed existant.');
  } catch {
    try {
      const cred = await createUserWithEmailAndPassword(auth, SEED_EMAIL, SEED_PASS);
      user = cred.user;
      console.log('Compte seed créé.');
    } catch (e) {
      console.error('Impossible de créer/connecter le compte seed :', e.message);
      process.exit(1);
    }
  }

  // Créer le profil utilisateur seed dans Firestore
  await setDoc(doc(db, 'users', user.uid), {
    email: SEED_EMAIL,
    pseudo: SEED_NAME,
    favoriteRemedyIds: [],
    createdRemediesCount: remedies.length,
    createdAt: new Date(),
  });

  // Insérer les remèdes
  let count = 0;
  for (const r of remedies) {
    const id = uuidv4();
    const authorName = authors[count % authors.length];
    await setDoc(doc(db, 'remedies', id), {
      title: r.title,
      description: r.description,
      ingredients: r.ingredients,
      method: r.method,
      tags: r.tags,
      authorId: user.uid,
      authorName,
      createdAt: new Date(Date.now() - count * 3600_000 * 12), // espacés dans le temps
      averageRating: r.averageRating,
      ratingCount: r.ratingCount,
      commentCount: r.commentCount,
      imageUrl: null,
      isReported: false,
    });
    count++;
    console.log(`[${count}/${remedies.length}] ${r.title}`);
  }

  console.log(`\n✓ ${count} remèdes insérés avec succès !`);
  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
