import 'package:flutter/material.dart';
import '../constants/app_assets.dart';
import '../constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../../models/models.dart';

/// Static seed content transcribed from the Figma frames.
class AppData {
  AppData._();

  static const yankeeBristol = ChipItem(
    id: 'yankee-bristol',
    name: 'Yankee Bristol',
    image: AppAssets.chipBuckeyeBig,
    price: 45,
    owner: 'HD Collection',
    type: ListingType.trade,
    rarity: Rarity.ultraRare,
  );

  static const oldSchoolHd = ChipItem(
    id: 'old-school-hd',
    name: 'Old School HD',
    image: AppAssets.chipOldSchoolHd,
    price: 120,
    owner: 'RetroRide',
    type: ListingType.sale,
    distance: '50 mi',
    rarity: Rarity.rare,
    description:
        'Old School Harley-Davidson Ellington chip in outstanding condition. A staple of any '
        'serious collection, kept in a climate controlled display case since purchase.',
  );

  static const bourbonStreet = ChipItem(
    id: 'bourbon-street',
    name: 'Bourbon Street',
    image: AppAssets.chipBourbon,
    price: 110,
    owner: 'NolaRider',
    type: ListingType.auction,
    bids: 12,
    distance: '75 mi',
    rarity: Rarity.ultraRare,
    description:
        'Bourbon Street Harley-Davidson commemorative chip from New Orleans. Rare colourway, '
        'sharp edges and vivid inlay. Ships insured and tracked.',
  );

  static const skyline = ChipItem(
    id: 'skyline',
    name: 'Skyline HD',
    image: AppAssets.chipSkyline,
    price: 95,
    owner: 'ChipKing92',
    type: ListingType.auction,
    bids: 8,
    rarity: Rarity.rare,
  );

  static const southside = ChipItem(
    id: 'southside',
    name: 'Indianapolis Southside',
    image: AppAssets.chipSouthside,
    price: 110,
    owner: 'IndyCollector',
    type: ListingType.auction,
    bids: 12,
    distance: '38 mi',
    rarity: Rarity.legendary,
  );

  static const paradise = ChipItem(
    id: 'paradise',
    name: 'Paradise HD',
    image: AppAssets.chipParadise,
    price: 75,
    owner: 'IslandRides',
    type: ListingType.sale,
    distance: '210 mi',
    rarity: Rarity.rare,
  );

  static const asheville = ChipItem(
    id: 'asheville',
    name: 'Asheville HD',
    image: AppAssets.chipAsheville,
    price: 65,
    owner: 'BlueRidgeHD',
    type: ListingType.trade,
    distance: '95 mi',
    rarity: Rarity.rare,
  );

  static const almostHeaven = ChipItem(
    id: 'almost-heaven',
    name: 'Almost Heaven',
    image: AppAssets.chipAlmostHeaven,
    price: 80,
    owner: 'WVCollector',
    type: ListingType.trade,
    distance: '145 mi',
    rarity: Rarity.ultraRare,
  );

  static const bristolWide = ChipItem(
    id: 'bristol-wide',
    name: 'Yankee Bristol',
    image: AppAssets.chipBristolWide,
    price: 45,
    owner: 'HD Collection',
    type: ListingType.sale,
    rarity: Rarity.ultraRare,
  );

  static const grizzly = ChipItem(
    id: 'grizzly',
    name: 'Grizzly HD',
    image: AppAssets.chipGrizzly,
    price: 45,
    owner: 'Tom',
    type: ListingType.auction,
    bids: 12,
    rarity: Rarity.ultraRare,
  );

  static const classicReading = ChipItem(
    id: 'classic-reading',
    name: 'Classic Reading PA',
    image: AppAssets.chipClassicReading,
    price: 120,
    owner: 'RetroRide',
    type: ListingType.sale,
    distance: '50 mi',
    rarity: Rarity.rare,
  );

  /// Home — "Trending near you".
  static const trending = <ChipItem>[
    ChipItem(
      id: 'trend-yankee',
      name: 'Yankee Bristol',
      image: AppAssets.chipYankeeBristol,
      price: 45,
      type: ListingType.sale,
    ),
    ChipItem(
      id: 'trend-bourbon',
      name: 'Bourbon Street',
      image: AppAssets.chipBourbonStreet,
      price: 110,
      bids: 12,
      type: ListingType.auction,
    ),
  ];

  /// Marketplace grid.
  static const marketplace = <ChipItem>[
    ChipItem(
      id: 'mk-yankee',
      name: 'Yankee Bristol',
      image: AppAssets.chipYankeeBristol,
      price: 45,
      owner: 'HD Collection',
      type: ListingType.trade,
      distance: '125 mi',
    ),
    ChipItem(
      id: 'mk-oldschool',
      name: 'Old School HD',
      image: AppAssets.chipOldSchoolHd,
      price: 120,
      owner: 'RetroRide',
      type: ListingType.sale,
      distance: '50 mi',
    ),
    ChipItem(
      id: 'mk-skyline',
      name: 'Skyline HD',
      image: AppAssets.chipSkyline,
      price: 95,
      owner: 'ChipKing92',
      type: ListingType.auction,
      distance: '125 mi',
      bids: 8,
    ),
    ChipItem(
      id: 'mk-classic',
      name: 'Classic Reading',
      image: AppAssets.chipClassicReading,
      price: 110,
      owner: 'NolaRider',
      type: ListingType.auction,
      distance: '75 mi',
      bids: 12,
    ),
    ChipItem(
      id: 'mk-buckeye',
      name: 'Buckeye HD',
      image: AppAssets.chipBuckeye,
      price: 60,
      owner: 'OhioRides',
      type: ListingType.sale,
      distance: '30 mi',
    ),
    ChipItem(
      id: 'mk-southside',
      name: 'Southside Indy',
      image: AppAssets.chipSouthside,
      price: 110,
      owner: 'IndyCollector',
      type: ListingType.auction,
      distance: '38 mi',
      bids: 12,
    ),
  ];

  /// The signed-in collector's own items (used by the trade builder).
  static const myCollection = <ChipItem>[
    ChipItem(
      id: 'my-ellington',
      name: 'Old School Ellington',
      image: AppAssets.chipYankeeBristol,
      price: 120,
      owner: 'You',
    ),
    ChipItem(
      id: 'my-bourbon-special',
      name: 'Bourbon Special',
      image: AppAssets.chipClassicReading,
      price: 110,
      owner: 'You',
    ),
    ChipItem(
      id: 'my-museum',
      name: 'Museum Collection',
      image: AppAssets.chipYankeeBristol,
      price: 150,
      owner: 'You',
    ),
    ChipItem(
      id: 'my-yankee',
      name: 'Yankee Bristol',
      image: AppAssets.chipClassicReading,
      price: 45,
      owner: 'You',
    ),
  ];

  static const bourbonSpecial = ChipItem(
    id: 'bourbon-special',
    name: 'Bourbon Street Special',
    image: AppAssets.chipHighStakesBig,
    price: 110,
    owner: 'ChipKing92',
    type: ListingType.auction,
    bids: 12,
    distance: '75 mi',
    rarity: Rarity.legendary,
    description:
        'Legendary edition Bourbon Street Harley-Davidson chip. Florence Y\'all tower artwork, '
        'sharp inlay and mint edge spots. Shipped insured within two days of auction close.',
  );

  static const bidHistory = <MapEntry<String, int>>[
    MapEntry('ChipKing92', 110),
    MapEntry('VintageHD', 100),
    MapEntry('HDMaster', 95),
  ];

  static const bristolWideGive = ChipItem(
    id: 'give-bristol-wide',
    name: 'Bristol Wide',
    image: AppAssets.chipSkylineSq,
    price: 65,
    owner: 'You',
  );

  static const activity = <ActivityEntry>[
    ActivityEntry(
      initials: 'VH',
      user: 'VintageHD',
      detail: 'Old School Ellington',
      time: '1h ago',
    ),
    ActivityEntry(
      initials: 'HM',
      user: 'HDMaster',
      detail: 'Bourbon Street Special',
      time: '3h ago',
    ),
    ActivityEntry(
      initials: 'CK',
      user: 'ChipKing92',
      detail: 'Skyline Harley-Davidson',
      time: '5h ago',
    ),
  ];

  static const matches = <TradeMatch>[
    TradeMatch(
      user: 'VintageCollector',
      initials: 'VC',
      rating: 4.8,
      trades: 89,
      match: 95,
      give: AppAssets.chipAlmostHeavenSq,
      get: AppAssets.chipSkylineSq,
    ),
    TradeMatch(
      user: 'ChipMaster99',
      initials: 'CM',
      rating: 4.9,
      trades: 156,
      match: 88,
      give: AppAssets.chipHighStakes,
      get: AppAssets.chipAshevilleSq,
    ),
  ];

  static const dealers = <Dealer>[
    Dealer(name: 'Harley Davidson 1', lat: 40.6639, lng: -74.2107, distance: '8 mi', chips: 32),
    Dealer(name: 'Harley Davidson 2', lat: 40.7362, lng: -74.3040, distance: '12 mi', chips: 24),
    Dealer(name: 'Harley Davidson 3', lat: 40.6795, lng: -74.2900, distance: '15 mi', chips: 18),
    Dealer(name: 'Harley Davidson 4', lat: 40.6420, lng: -74.3120, distance: '21 mi', chips: 11),
  ];

  /// Shops listed in the map bottom sheet.
  static const shops = <(String, double, int, String)>[
    ('Sturgis Chip Exchange', 4.9, 5, '2.1 mi'),
    ('Rally Road Collectibles', 4.7, 3, '5.4 mi'),
    ('Black Hills HD Shop', 4.8, 8, '8.9 mi'),
    ('Badlands Trading Post', 4.6, 2, '12.3 mi'),
  ];

  static const threads = <ChatThread>[
    ChatThread(
      name: 'ChipKing92',
      initials: 'CK',
      preview: "Sounds good! Let's trade.",
      time: '5m',
      unread: 2,
      online: true,
    ),
    ChatThread(
      name: 'VintageHD',
      initials: 'VH',
      preview: 'Is the Old School Ellington still available?',
      time: '1h',
      unread: 1,
      online: true,
    ),
    ChatThread(
      name: 'HDMaster',
      initials: 'HM',
      preview: 'Thanks for the trade! Great doing business.',
      time: '3h',
    ),
    ChatThread(
      name: 'RallyBecca',
      initials: 'RB',
      preview: 'Check out my new Bristol chip!',
      time: '1d',
    ),
  ];

  static const conversation = <ChatMessage>[
    ChatMessage(
      text: "Hey! I'm interested in your Yankee Bristol chip",
      mine: false,
      time: '9:32 AM',
    ),
    ChatMessage(
      text: "Hi! Yeah it's available. What are you looking to trade?",
      mine: true,
      time: '9:34 AM',
    ),
    ChatMessage(text: 'I have a rare Old School Ellington chip', mine: false, time: '9:36 AM'),
    ChatMessage(text: "Wow, that's amazing! Let's do it 🔥", mine: true, time: '9:38 AM'),
  ];

  static const notifications = <AppNotification>[
    AppNotification(
      title: 'HDCollector',
      body: 'accepted your trade',
      time: '10 min ago',
      icon: Icons.swap_vert_rounded,
      color: AppColors.redSolid,
      unread: true,
      route: AppRoutes.tradeConfirmed,
    ),
    AppNotification(
      title: 'Bourbon Street',
      body: 'You were outbid on',
      time: '42 min ago',
      icon: Icons.access_time_rounded,
      color: AppColors.green,
      route: AppRoutes.auctionLost,
    ),
    AppNotification(
      title: '3 new wishlist matches found',
      body: '',
      time: 'Yesterday',
      icon: Icons.auto_awesome,
      color: AppColors.amber,
      route: AppRoutes.wishlist,
    ),
    AppNotification(
      title: 'ChipKing92',
      body: 'sent you a message',
      time: '2 days ago',
      icon: Icons.chat_bubble_outline_rounded,
      color: AppColors.textSecondary,
      route: AppRoutes.chat,
      arguments: 'ChipKing92',
    ),
  ];

  static const plans = <PlanModel>[
    PlanModel(
      name: 'Free Trial',
      tier: 'Tier 1 · 30 days',
      price: 'Free',
      period: 'for 30 days',
      items: '100 items',
      accent: AppColors.planBlue,
      isCurrent: true,
    ),
    PlanModel(
      name: 'Silver',
      tier: 'Tier 2',
      price: '\$4.99',
      period: '/year',
      items: '200 items',
      accent: AppColors.planSilver,
      buttonLabel: 'Upgrade to Silver',
    ),
    PlanModel(
      name: 'Gold',
      tier: 'Tier 3',
      price: '\$9.99',
      period: '/year',
      items: '450 items',
      accent: AppColors.planGold,
      badge: 'MOST POPULAR',
      buttonLabel: 'Upgrade to Gold',
      highlighted: true,
    ),
    PlanModel(
      name: 'Platinum',
      tier: 'Tier 4',
      price: '\$19.99',
      period: '/year',
      items: '1000 items',
      accent: AppColors.planPurple,
      buttonLabel: 'Upgrade to Platinum',
    ),
  ];

  /// "What do you collect?" chips.
  static const categories = <String>[
    'Harley-Davidson',
    'Poker chips',
    'Casino chips',
    'Coins',
    'Patches',
    'Rally memorabilia',
    'Pins',
    'Trading cards',
    'Vintage signs',
  ];

  static const events = <CollectionEvent>[
    CollectionEvent(
      title: 'Sturgis Rally Meetup',
      date: 'Aug 4 - Aug 10',
      location: 'Sturgis, SD',
      image: AppAssets.chipSouthside,
      attendees: 248,
    ),
    CollectionEvent(
      title: 'Daytona Bike Week',
      date: 'Mar 1 - Mar 10',
      location: 'Daytona Beach, FL',
      image: AppAssets.chipParadise,
      attendees: 176,
    ),
    CollectionEvent(
      title: 'Laconia Chip Swap',
      date: 'Jun 14 - Jun 22',
      location: 'Laconia, NH',
      image: AppAssets.chipAlmostHeaven,
      attendees: 92,
    ),
  ];

  static const cards = <PaymentCard>[
    PaymentCard(brand: 'Visa', last4: '4242', expiry: '08/27', isDefault: true),
    PaymentCard(brand: 'Mastercard', last4: '8891', expiry: '11/26'),
  ];
}
