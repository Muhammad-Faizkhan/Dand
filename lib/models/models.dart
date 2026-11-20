import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

enum ListingType { sale, trade, auction }

enum Rarity { common, rare, ultraRare, legendary }

extension RarityX on Rarity {
  String get label => switch (this) {
    Rarity.common => 'Common',
    Rarity.rare => 'Rare',
    Rarity.ultraRare => 'Ultra Rare',
    Rarity.legendary => 'Legendary',
  };
}

extension ListingTypeX on ListingType {
  String get label => switch (this) {
    ListingType.sale => 'Sale',
    ListingType.trade => 'Trade',
    ListingType.auction => 'Auction',
  };
}

/// A collectible chip listing. [imageUrl] is a network URL that takes priority
/// over the local [image] asset path when non-null.
class ChipItem {
  const ChipItem({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    this.imageUrl,
    this.owner = 'HD Collection',
    this.type = ListingType.sale,
    this.rarity = Rarity.ultraRare,
    this.year = '2019',
    this.condition = 'Mint',
    this.distance = '125 mi',
    this.location = 'Sturgis, SD',
    this.description =
        'Authentic Yankee Harley-Davidson Bristol CT casino chip. Teal edition, excellent condition, '
        'from a private Sturgis collection. Comes with certificate of authenticity.',
    this.bids = 0,
    this.seller = const Seller.tom(),
    this.listingId,
    this.itemId,
    this.sellerId,
    this.auctionId,
    this.bidIncrement = 5,
  });

  factory ChipItem.fromApiListing(Map<String, dynamic> json) {
    final item = json['item'] as Map<String, dynamic>? ?? {};
    final images = item['images'] as List<dynamic>? ?? [];
    final seller = json['seller'] as Map<String, dynamic>? ?? {};
    final auction = json['auction'] as Map<String, dynamic>?;
    final priceCents = json['priceCents'] as int? ?? 0;
    final startPriceCents =
        auction?['currentPriceCents'] as int? ?? auction?['startPriceCents'] as int? ?? priceCents;
    final bidCount = (auction?['bids'] as List<dynamic>?)?.length ?? 0;
    return ChipItem(
      id: '${json['id']}',
      listingId: json['id'] as int?,
      auctionId: auction?['id'] as int?,
      bidIncrement: ((auction?['bidIncrementCents'] as int? ?? 500) / 100).toDouble(),
      itemId: item['id'] as int?,
      sellerId: json['sellerId'] as int?,
      name: item['title'] as String? ?? 'Unknown',
      image: 'assets/images/chip_buckeye_big.jpg',
      imageUrl: images.isNotEmpty ? images[0]['url'] as String? : null,
      price: (startPriceCents / 100).toDouble(),
      owner: seller['username'] as String? ?? 'Unknown',
      type: _parseType(json['listingType'] as String?),
      condition: item['condition'] as String? ?? 'Unknown',
      year: '${item['year'] as int? ?? 2024}',
      bids: bidCount,
      description: item['description'] as String? ?? '',
      seller: Seller(
        name: seller['fullName'] as String? ?? seller['username'] as String? ?? 'Unknown',
        initials: _initials(seller['username'] as String? ?? 'U'),
        rating: 4.9,
        trades: 0,
      ),
    );
  }

  /// An item from `/api/items` or a nested `item` object (not a marketplace listing).
  factory ChipItem.fromApiItem(Map<String, dynamic> json, {String? owner}) {
    final images = json['images'] as List<dynamic>? ?? const [];
    final listing = json['listing'] as Map<String, dynamic>?;
    final ownerJson = json['owner'] as Map<String, dynamic>?;
    final cents = listing?['priceCents'] as int? ?? json['estimatedValueCents'] as int? ?? 0;
    final ownerName = owner ?? ownerJson?['username'] as String? ?? '';
    return ChipItem(
      id: 'item-${json['id']}',
      itemId: json['id'] as int?,
      listingId: listing?['id'] as int?,
      sellerId: json['ownerId'] as int?,
      name: json['title'] as String? ?? 'Untitled',
      image: 'assets/images/chip_buckeye_big.jpg',
      imageUrl: images.isNotEmpty ? (images.first as Map<String, dynamic>)['url'] as String? : null,
      price: cents / 100,
      owner: ownerName,
      type: listing == null
          ? (json['status'] == 'FOR_TRADE' ? ListingType.trade : ListingType.sale)
          : _parseType(listing['listingType'] as String?),
      rarity: _parseRarity(json['rarity'] as String?),
      condition: json['condition'] as String? ?? '',
      year: json['year'] == null ? '' : '${json['year']}',
      description: json['description'] as String? ?? '',
      distance: '',
      location: json['brand'] as String? ?? '',
      seller: Seller(name: ownerName, initials: _initials(ownerName.isEmpty ? '?' : ownerName), rating: 0, trades: 0),
    );
  }

  static Rarity _parseRarity(String? r) => switch (r) {
    'COMMON' => Rarity.common,
    'RARE' => Rarity.rare,
    'LEGENDARY' => Rarity.legendary,
    _ => Rarity.ultraRare,
  };

  static ListingType _parseType(String? t) => switch (t) {
    'TRADE' => ListingType.trade,
    'AUCTION' => ListingType.auction,
    _ => ListingType.sale,
  };

  static String _initials(String s) {
    // ignore: deprecated_member_use
    final parts = s.split(RegExp(r'[_\s]+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return s.isNotEmpty ? s[0].toUpperCase() : '?';
  }

  final String id;
  final String name;
  final String image;
  final String? imageUrl;
  final double price;
  final String owner;
  final ListingType type;
  final Rarity rarity;
  final String year;
  final String condition;
  final String distance;
  final String location;
  final String description;
  final int bids;
  final Seller seller;
  final int? listingId;
  final int? itemId;
  final int? sellerId;

  /// Set only for auctions loaded from the API; mock auctions bid locally.
  final int? auctionId;
  final double bidIncrement;

  String get priceLabel => '\$${price.toStringAsFixed(0)}';
  bool get isAuction => type == ListingType.auction;
}

/// `GET /api/subscriptions/me`: which plan the user is on and how much of it
/// they've used. A null limit means unlimited.
class PlanStatus {
  const PlanStatus({
    required this.planName,
    required this.isTrial,
    this.bidLimit,
    this.bidCount = 0,
    this.itemLimit,
    this.itemCount = 0,
    this.trialEndsAt,
  });

  factory PlanStatus.fromJson(Map<String, dynamic> json) {
    final plan = json['plan'] as Map<String, dynamic>? ?? const {};
    return PlanStatus(
      planName: plan['name'] as String? ?? 'Free Trial',
      isTrial: plan['billingPeriod'] == 'trial_15d',
      bidLimit: plan['bidLimit'] as int?,
      bidCount: json['bidCount'] as int? ?? 0,
      itemLimit: plan['itemLimit'] as int?,
      itemCount: json['itemCount'] as int? ?? 0,
      trialEndsAt: DateTime.tryParse(json['trialEndsAt'] as String? ?? ''),
    );
  }

  final String planName;
  final bool isTrial;
  final int? bidLimit;
  final int bidCount;
  final int? itemLimit;
  final int itemCount;
  final DateTime? trialEndsAt;

  bool get trialEnded => isTrial && trialEndsAt != null && trialEndsAt!.isBefore(DateTime.now());

  int? get bidsLeft => bidLimit == null ? null : (bidLimit! - bidCount).clamp(0, bidLimit!);
}

/// What `POST /api/items/scan` read off the chip photo. Suggestions only.
class ChipScanResult {
  const ChipScanResult({
    required this.isChip,
    required this.title,
    required this.description,
    required this.confidence,
    this.dealership,
    this.city,
    this.state,
    this.year,
    this.denomination,
    this.condition,
    this.unreadable,
  });

  factory ChipScanResult.fromJson(Map<String, dynamic> json) => ChipScanResult(
    isChip: json['isChip'] as bool? ?? true,
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    confidence: json['confidence'] as String? ?? 'low',
    dealership: json['dealership'] as String?,
    city: json['city'] as String?,
    state: json['state'] as String?,
    year: json['year'] as int?,
    denomination: json['denomination'] as String?,
    condition: json['condition'] as String?,
    unreadable: json['unreadable'] as String?,
  );

  final bool isChip;
  final String title;
  final String description;
  final String confidence;
  final String? dealership;
  final String? city;
  final String? state;
  final int? year;
  final String? denomination;
  final String? condition;
  final String? unreadable;

  /// "Ellington CT · $5" style line under the detected name.
  String get summary => [
    [city, state].whereType<String>().join(' '),
    ?denomination,
  ].where((s) => s.isNotEmpty).join(' · ');
}

class Seller {
  const Seller({
    required this.name,
    required this.initials,
    required this.rating,
    required this.trades,
  });

  const Seller.tom() : name = 'Tom', initials = 'HD', rating = 4.9, trades = 156;

  final String name;
  final String initials;
  final double rating;
  final int trades;
}

class TradeMatch {
  const TradeMatch({
    required this.user,
    required this.initials,
    required this.rating,
    required this.trades,
    required this.match,
    required this.give,
    required this.get,
    this.userId,
    this.giveChip,
    this.getChip,
  });

  /// `GET /api/trades/matches` row. `give` is null when none of yours fits their wants.
  factory TradeMatch.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? const {};
    final name = user['fullName'] as String? ?? user['username'] as String? ?? 'Collector';
    final get = json['get'] as Map<String, dynamic>?;
    final give = json['give'] as Map<String, dynamic>?;
    final getChip = get == null ? null : ChipItem.fromApiItem({...get, 'ownerId': user['id']}, owner: name);
    final giveChip = give == null ? null : ChipItem.fromApiItem(give);
    return TradeMatch(
      user: name,
      initials: ChipItem._initials(name),
      rating: 0,
      trades: json['userTrades'] as int? ?? 0,
      match: json['match'] as int? ?? 0,
      give: giveChip?.image ?? '',
      get: getChip?.image ?? '',
      userId: user['id'] as int?,
      giveChip: giveChip,
      getChip: getChip,
    );
  }

  final String user;
  final String initials;
  final double rating;
  final int trades;
  final int match;
  final String give;
  final String get;
  final int? userId;

  /// Set for API matches, which carry real items (and photos) instead of asset paths.
  final ChipItem? giveChip;
  final ChipItem? getChip;
}

class ActivityEntry {
  const ActivityEntry({
    required this.initials,
    required this.user,
    required this.detail,
    required this.time,
  });

  final String initials;
  final String user;
  final String detail;
  final String time;
}

class Dealer {
  const Dealer({
    required this.name,
    required this.lat,
    required this.lng,
    this.address = 'Harley-Davidson Dealership',
    this.distance = '12 mi',
    this.chips = 24,
    this.phone,
    this.id,
    this.nextCheckInAt,
  });

  factory Dealer.fromJson(Map<String, dynamic> json) {
    final km = (json['distanceKm'] as num?)?.toDouble();
    final miles = km == null ? null : km * 0.621371;
    return Dealer(
      name: json['name'] as String? ?? 'Dealer',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      address: json['address'] as String? ?? '',
      distance: miles == null ? '' : '${miles < 10 ? miles.toStringAsFixed(1) : miles.round()} mi',
      chips: 0,
      phone: json['phone'] as String?,
      id: json['id'] as int?,
      nextCheckInAt: DateTime.tryParse(json['nextCheckInAt'] as String? ?? '')?.toLocal(),
    );
  }

  final String name;
  final double lat;
  final double lng;
  final String address;
  final String distance;
  final int chips;
  final String? phone;
  final int? id;

  /// When this user may check in here again; null if they never have.
  final DateTime? nextCheckInAt;

  bool get checkInOpen => nextCheckInAt == null || nextCheckInAt!.isBefore(DateTime.now());
}

class ChatThread {
  const ChatThread({
    required this.name,
    required this.initials,
    required this.preview,
    required this.time,
    this.unread = 0,
    this.online = false,
    this.conversationId,
    this.userId,
    this.avatarUrl,
  });

  final String name;
  final String initials;
  final String preview;
  final String time;
  final int unread;
  final bool online;

  /// Set for API threads. A thread with only [userId] is a chat not started yet.
  final int? conversationId;
  final int? userId;
  final String? avatarUrl;
}

class ChatMessage {
  const ChatMessage({required this.text, required this.mine, required this.time, this.image});

  final String text;
  final bool mine;
  final String time;
  final String? image;
}

class AppNotification {
  const AppNotification({
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    this.color,
    this.unread = false,
    this.route,
    this.arguments,
  });

  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color? color;
  final bool unread;

  /// Where tapping the notification takes you, if anywhere.
  final String? route;
  final Object? arguments;
}

class OrderModel {
  const OrderModel({
    required this.id,
    required this.item,
    required this.status,
    required this.date,
    this.isTrade = false,
  });

  final String id;
  final ChipItem item;
  final String status;
  final String date;
  final bool isTrade;
}

class PaymentCard {
  const PaymentCard({
    required this.brand,
    required this.last4,
    required this.expiry,
    this.isDefault = false,
  });

  final String brand;
  final String last4;
  final String expiry;
  final bool isDefault;
}

class PlanModel {
  const PlanModel({
    required this.name,
    required this.tier,
    required this.price,
    required this.period,
    required this.items,
    required this.accent,
    this.badge,
    this.isCurrent = false,
    this.buttonLabel,
    this.highlighted = false,
    this.id,
  });

  /// A row from `GET /api/plans`, styled to match the design's tier of the same code.
  factory PlanModel.fromJson(Map<String, dynamic> json, {required bool current, required int index}) {
    final code = json['code'] as String? ?? '';
    final cents = json['priceCents'] as int? ?? 0;
    final trial = json['billingPeriod'] == 'trial_15d';
    final limit = json['itemLimit'] as int?;
    final short = (json['name'] as String? ?? code).replaceAll(' Package', '');
    final gold = code == 'GOLD' || json['recommended'] == true;
    return PlanModel(
      id: json['id'] as int?,
      name: short,
      tier: trial ? 'Tier ${index + 1} · 30 days' : 'Tier ${index + 1}',
      price: cents == 0 ? 'Free' : '\$${(cents / 100).toStringAsFixed(2)}',
      period: trial ? 'for 30 days' : '/${json['billingPeriod'] == 'month' ? 'month' : 'year'}',
      items: limit == null ? 'unlimited items' : '$limit items',
      accent: switch (code) {
        'FREE' => AppColors.planBlue,
        'SILVER' => AppColors.planSilver,
        'GOLD' => AppColors.planGold,
        _ => AppColors.planPurple,
      },
      badge: gold ? 'MOST POPULAR' : null,
      highlighted: gold,
      isCurrent: current,
      buttonLabel: current || trial ? null : 'Upgrade to $short',
    );
  }

  /// The API plan id; null for the seeded tiers.
  final int? id;

  final String name;
  final String tier;
  final String price;
  final String period;
  final String items;
  final Color accent;
  final String? badge;
  final bool isCurrent;
  final String? buttonLabel;
  final bool highlighted;
}

class CollectionEvent {
  const CollectionEvent({
    required this.title,
    required this.date,
    required this.location,
    required this.image,
    this.attendees = 0,
  });

  final String title;
  final String date;
  final String location;
  final String image;
  final int attendees;
}

/// Signed-in user data from GET /api/users/me.
class ApiUser {
  const ApiUser({
    required this.id,
    required this.email,
    required this.username,
    this.fullName,
    this.avatarUrl,
    this.bio,
    this.phone,
    this.address,
    this.planCode = 'FREE',
    this.planName = 'Free Trial',
    this.itemCount = 0,
    this.tradeCount = 0,
    this.listingCount = 0,
    this.collectionCount = 0,
    this.wishlistCount = 0,
    this.createdAt,
  });

  factory ApiUser.fromJson(Map<String, dynamic> json) {
    final plan = json['plan'] as Map<String, dynamic>? ?? {};
    final stats = json['stats'] as Map<String, dynamic>? ?? const {};
    return ApiUser(
      itemCount: stats['items'] as int? ?? 0,
      tradeCount: stats['trades'] as int? ?? 0,
      listingCount: stats['listings'] as int? ?? 0,
      collectionCount: stats['collections'] as int? ?? 0,
      wishlistCount: stats['wishlist'] as int? ?? 0,
      createdAt: json['createdAt'] as String?,
      id: json['id'] as int,
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      fullName: json['fullName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      planCode: plan['code'] as String? ?? 'FREE',
      planName: plan['name'] as String? ?? 'Free Trial',
    );
  }

  final int id;
  final String email;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final String? bio;
  final String? phone;
  final String? address;
  final String planCode;
  final String planName;
  final int itemCount;
  final int tradeCount;
  final int listingCount;
  final int collectionCount;
  final int wishlistCount;
  final String? createdAt;

  String get displayName => fullName?.isNotEmpty == true ? fullName! : username;
}

/// A user's collection from GET /api/collections.
class ApiCollection {
  const ApiCollection({
    required this.id,
    required this.name,
    this.description,
    this.coverImageUrl,
    this.eventDate,
    this.itemCount = 0,
    this.kind,
    this.children = const [],
  });

  factory ApiCollection.fromJson(Map<String, dynamic> json) {
    final count = json['_count'] as Map<String, dynamic>?;
    return ApiCollection(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      eventDate: json['eventDate'] as String?,
      itemCount: count?['items'] as int? ?? 0,
      kind: json['kind'] as String?,
      children: [
        for (final c in (json['children'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>()) ApiCollection.fromJson(c),
      ],
    );
  }

  final int id;
  final String name;
  final String? description;
  final String? coverImageUrl;
  final String? eventDate;
  final int itemCount;

  /// Set on the default ("primary") collections every user starts with, e.g.
  /// "dealer-plates"; null for the ones the user made.
  final String? kind;

  /// Sub-folders, e.g. Shirts / Hats / Cups inside Merchandise. Chips go into
  /// those, and [itemCount] already includes theirs.
  final List<ApiCollection> children;

  bool get hasSubfolders => children.isNotEmpty;

  /// Default collections can't be renamed, re-covered or deleted.
  bool get isDefault => kind != null;

  /// What to show when it has nothing in it: "No dealer plates in this
  /// collection yet." for a default one, the collection's own name otherwise.
  String get emptyText => isDefault
      ? 'No ${name.toLowerCase()} in this collection yet. Tap + to add one.'
      : 'Nothing in $name yet. Tap + to add a chip.';

  ApiCollection copyWith({String? name, String? description, String? coverImageUrl, int? itemCount}) => ApiCollection(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    coverImageUrl: coverImageUrl ?? this.coverImageUrl,
    eventDate: eventDate,
    itemCount: itemCount ?? this.itemCount,
    kind: kind,
    children: children,
  );
}

/// A conversation from GET /api/messages/conversations.
class ApiConversation {
  const ApiConversation({
    required this.id,
    required this.participantName,
    required this.participantUsername,
    this.participantId,
    this.participantAvatarUrl,
    this.lastMessage,
    this.lastMessageTime,
    this.unread = 0,
  });

  factory ApiConversation.fromJson(Map<String, dynamic> json, int myId) {
    final participants = json['participants'] as List<dynamic>? ?? [];
    final other = participants.firstWhere(
      (p) => (p['userId'] as int?) != myId,
      orElse: () => participants.isNotEmpty ? participants[0] : <String, dynamic>{},
    );
    final user = other['user'] as Map<String, dynamic>? ?? {};
    final messages = json['messages'] as List<dynamic>? ?? [];
    final last = messages.isNotEmpty ? messages[0] as Map<String, dynamic>? : null;
    final mine = participants.cast<Map<String, dynamic>?>().firstWhere(
      (p) => p?['userId'] == myId,
      orElse: () => null,
    );
    final lastReadAt = DateTime.tryParse(mine?['lastReadAt'] as String? ?? '');
    final lastAt = DateTime.tryParse(last?['createdAt'] as String? ?? '');
    final unread = last != null &&
        last['senderId'] != myId &&
        (lastReadAt == null || (lastAt != null && lastAt.isAfter(lastReadAt)));
    return ApiConversation(
      id: json['id'] as int,
      participantName: user['fullName'] as String? ?? user['username'] as String? ?? 'Unknown',
      participantUsername: user['username'] as String? ?? '',
      participantId: other['userId'] as int?,
      participantAvatarUrl: user['avatarUrl'] as String?,
      lastMessage: last?['body'] as String? ?? (last?['attachmentUrl'] != null ? 'Photo' : null),
      lastMessageTime: last?['createdAt'] as String?,
      unread: unread ? 1 : 0,
    );
  }

  final int id;
  final String participantName;
  final String participantUsername;
  final int? participantId;
  final String? participantAvatarUrl;
  final String? lastMessage;
  final String? lastMessageTime;
  final int unread;
}

/// A trade request from GET /api/trades.
class ApiTradeRequest {
  const ApiTradeRequest({
    required this.id,
    required this.status,
    required this.otherUsername,
    this.otherId,
    this.incoming = false,
    this.chip,
    this.message,
    this.giveItems = const [],
    this.getItems = const [],
  });

  factory ApiTradeRequest.fromJson(Map<String, dynamic> json, int myId) {
    final initiator = json['initiator'] as Map<String, dynamic>? ?? {};
    final recipient = json['recipient'] as Map<String, dynamic>? ?? {};
    final isMine = (initiator['id'] as int?) == myId;
    final other = isMine ? recipient : initiator;
    final offerItems = json['offerItems'] as List<dynamic>? ?? [];
    final getSide = offerItems.cast<Map<String, dynamic>>().where((i) => i['side'] == (isMine ? 'GET' : 'GIVE'));
    final getItem = getSide.isEmpty ? null : getSide.first['item'] as Map<String, dynamic>?;
    return ApiTradeRequest(
      id: json['id'] as int,
      incoming: !isMine,
      chip: getItem == null ? null : ChipItem.fromApiItem(getItem),
      status: json['status'] as String? ?? 'PENDING',
      otherUsername: other['username'] as String? ?? 'Unknown',
      otherId: other['id'] as int?,
      message: json['message'] as String?,
      giveItems: offerItems
          .where((i) => (i['side'] as String?) == (isMine ? 'GIVE' : 'GET'))
          .map((i) => (i['item'] as Map<String, dynamic>?)?['title'] as String? ?? '')
          .toList(),
      getItems: offerItems
          .where((i) => (i['side'] as String?) == (isMine ? 'GET' : 'GIVE'))
          .map((i) => (i['item'] as Map<String, dynamic>?)?['title'] as String? ?? '')
          .toList(),
    );
  }

  final int id;
  final String status;
  final String otherUsername;
  final int? otherId;

  /// True when someone sent this to you (only you can accept or reject it).
  final bool incoming;

  /// The chip you'd receive, for the row thumbnail.
  final ChipItem? chip;
  final String? message;
  final List<String> giveItems;
  final List<String> getItems;

  bool get isPending => status == 'PENDING';
}

/// A notification from GET /api/notifications.
class ApiNotification {
  const ApiNotification({
    required this.id,
    required this.type,
    required this.body,
    required this.createdAt,
    this.title = '',
    this.read = false,
    this.data = const {},
    this.route,
    this.routeArguments,
  });

  factory ApiNotification.fromJson(Map<String, dynamic> json) => ApiNotification(
    id: json['id'] as int,
    type: json['type'] as String? ?? '',
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? _bodyFor(json),
    createdAt: json['createdAt'] as String? ?? '',
    // The API marks reads with a timestamp, not a flag.
    read: json['readAt'] != null,
    data: json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : const {},
  );

  ApiNotification copyWith({bool? read}) => ApiNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    createdAt: createdAt,
    read: read ?? this.read,
    data: data,
  );

  final String title;
  final Map<String, dynamic> data;

  static String _bodyFor(Map<String, dynamic> json) {
    return switch (json['type'] as String?) {
      'trade_request' => 'You have a new trade request',
      'trade_accepted' => 'Your trade was accepted',
      'trade_rejected' => 'Your trade was declined',
      'bid_outbid' => 'You were outbid on an auction',
      'auction_won' => 'You won an auction',
      'order_placed' => 'Your order has been placed',
      'order_status' => 'Your order status changed',
      'new_message' => 'You have a new message',
      _ => json['body'] as String? ?? 'New notification',
    };
  }

  final int id;
  final String type;
  final String body;
  final String createdAt;
  final bool read;
  final String? route;
  final Object? routeArguments;
}
