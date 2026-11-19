import 'dart:io';

import 'package:flutter/material.dart';
import '../core/api/api_client.dart';
import '../core/api/auctions_api.dart';
import '../core/api/marketplace_api.dart';
import '../core/api/messages_api.dart';
import '../core/api/trades_api.dart';
import '../core/constants/app_assets.dart';
import '../core/utils/app_data.dart';
import '../core/utils/format.dart';
import '../models/models.dart';

/// The signed-in user's own profile. Held here rather than in a screen's state
/// so that changing the avatar on Edit Profile shows up everywhere it is drawn
/// — the profile screen, the side menu — without either screen knowing about
/// the other.
class ProfileController extends ChangeNotifier {
  ProfileController({this.client});

  final ApiClient? client;

  /// A file the user picked, or null while the seeded design asset is in use.
  String? avatarPath;

  /// Uploads [path] and saves it as the account's avatar. The local file is
  /// shown straight away; returns false if the server copy didn't save.
  Future<bool> uploadAvatar(String path) async {
    setAvatar(path);
    final client = this.client;
    if (client == null) return true;
    try {
      final urls = await client.upload([path]);
      await client.patch('/api/users/me', body: {'avatarUrl': urls.first});
      return true;
    } on ApiException {
      return false;
    }
  }

  bool get hasCustomAvatar => avatarPath != null;

  /// Whatever should be drawn as the avatar right now.
  ImageProvider get avatar =>
      avatarPath == null ? const AssetImage(AppAssets.avatarMike) : FileImage(File(avatarPath!));

  /// Pass null (or an empty path, which is what "Remove photo" returns) to go
  /// back to the seeded asset.
  void setAvatar(String? path) {
    final next = (path == null || path.isEmpty) ? null : path;
    if (next == avatarPath) return;
    avatarPath = next;
    // A re-picked file can reuse a path, so drop the decoded copy too.
    if (next != null) FileImage(File(next)).evict();
    notifyListeners();
  }
}

/// Bottom-navigation + global shell state.
class NavController extends ChangeNotifier {
  int _index = 0;
  int get index => _index;

  void setIndex(int i) {
    if (_index == i) return;
    _index = i;
    notifyListeners();
  }
}

/// Marketplace browsing: category filter, search and the filter sheet.
class MarketplaceController extends ChangeNotifier {
  MarketplaceController({this.client});

  final ApiClient? client;

  static const filters = ['All', 'For Sale', 'For Trade', 'Near Me', 'Auctions'];

  int _filter = 0;
  int get filter => _filter;

  String _query = '';
  String get query => _query;

  RangeValues priceRange = const RangeValues(0, 500);
  double distance = 125;
  final Set<String> conditions = {'Mint'};
  final Set<String> rarities = {};

  List<ChipItem> _apiItems = [];
  bool _loaded = false;
  bool _loading = false;
  String? _error;
  int _total = 0;

  bool get loading => _loading;
  String? get error => _error;
  int get total => _total;
  bool get hasApiData => _loaded;

  Future<void> load() async {
    final c = client;
    if (c == null || _loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await MarketplaceApi(c).getListings(
        listingType: _apiListingType(),
        search: _query.isNotEmpty ? _query : null,
        pageSize: 40,
      );
      _apiItems = result.items;
      _total = result.total;
      _loaded = true;
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> reload() async {
    _loaded = false;
    _apiItems = [];
    await load();
  }

  String? _apiListingType() => switch (filters[_filter]) {
    'For Sale' => 'SALE',
    'For Trade' => 'TRADE',
    'Auctions' => 'AUCTION',
    _ => null,
  };

  List<ChipItem> get items {
    if (_loaded) {
      var out = _apiItems;
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        out = out.where((e) => e.name.toLowerCase().contains(q)).toList();
      }
      return out;
    }
    // Fallback to mock data while not loaded.
    var list = AppData.marketplace;
    final f = filters[_filter];
    var out = switch (f) {
      'For Sale' => list.where((e) => e.type == ListingType.sale).toList(),
      'For Trade' => list.where((e) => e.type == ListingType.trade).toList(),
      'Auctions' => list.where((e) => e.type == ListingType.auction).toList(),
      _ => list.toList(),
    };
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      out = out.where((e) => e.name.toLowerCase().contains(q)).toList();
    }
    return out;
  }

  void setFilter(int i) {
    _filter = i;
    if (client != null) reload();
    notifyListeners();
  }

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  void toggleCondition(String c) {
    conditions.contains(c) ? conditions.remove(c) : conditions.add(c);
    notifyListeners();
  }

  void toggleRarity(String r) {
    rarities.contains(r) ? rarities.remove(r) : rarities.add(r);
    notifyListeners();
  }

  void setPriceRange(RangeValues v) {
    priceRange = v;
    notifyListeners();
  }

  void setDistance(double v) {
    distance = v;
    notifyListeners();
  }

  void resetFilters() {
    priceRange = const RangeValues(0, 500);
    distance = 125;
    conditions
      ..clear()
      ..add('Mint');
    rarities.clear();
    if (client != null) reload();
    notifyListeners();
  }
}

/// Saved / wishlisted chips.
class WishlistController extends ChangeNotifier {
  WishlistController({this.client});

  final ApiClient? client;

  final List<ChipItem> _items = [
    AppData.oldSchoolHd,
    AppData.bourbonStreet,
    AppData.paradise,
    AppData.bristolWide,
  ];

  /// API wishlist entries: what the user is looking for, plus the item it matched.
  List<({int id, String query, ChipItem chip})> _entries = [];

  List<ChipItem> get items => client == null ? _items : [for (final e in _entries) e.chip];

  Future<void> load() async {
    final c = client;
    if (c == null) return;
    try {
      final data = await c.get('/api/wishlist') as List<dynamic>;
      _entries = [for (final e in data.cast<Map<String, dynamic>>()) _entryFrom(e)];
      notifyListeners();
    } on ApiException {
      // Keep the previous list.
    }
  }

  static ({int id, String query, ChipItem chip}) _entryFrom(Map<String, dynamic> e) {
    final query = e['query'] as String? ?? '';
    final matched = e['matchedItem'] as Map<String, dynamic>?;
    return (
      id: e['id'] as int,
      query: query,
      chip: matched != null
          ? ChipItem.fromApiItem(matched)
          : ChipItem(
              id: 'wish-${e['id']}',
              name: query,
              image: 'assets/images/chip_buckeye_big.jpg',
              price: 0,
              owner: 'Looking for',
              distance: '',
              description: '',
            ),
    );
  }

  bool _matches(({int id, String query, ChipItem chip}) e, ChipItem c) =>
      (c.itemId != null && e.chip.itemId == c.itemId) || e.query.toLowerCase() == c.name.toLowerCase() || e.chip.id == c.id;

  bool contains(ChipItem c) => client == null ? _items.any((e) => e.id == c.id) : _entries.any((e) => _matches(e, c));

  Future<void> toggle(ChipItem c) async {
    final api = client;
    if (api == null) {
      contains(c) ? _items.removeWhere((e) => e.id == c.id) : _items.add(c);
      notifyListeners();
      return;
    }
    try {
      final existing = _entries.where((e) => _matches(e, c)).toList();
      if (existing.isNotEmpty) {
        _entries.removeWhere((e) => _matches(e, c));
        notifyListeners();
        for (final e in existing) {
          await api.delete('/api/wishlist/${e.id}');
        }
      } else {
        final created = await api.post('/api/wishlist', body: {'query': c.name}) as Map<String, dynamic>;
        _entries = [..._entries, (id: created['id'] as int, query: c.name, chip: c)];
        notifyListeners();
      }
    } on ApiException {
      await load();
    }
  }
}

/// Trade proposal builder: what you give vs. what you get.
class TradeController extends ChangeNotifier {
  TradeController({this.client});

  final ApiClient? client;

  final List<ChipItem> _offered = [];
  List<ChipItem> get offered => _offered;

  ChipItem? target;
  String note = '';

  /// Set when the last propose or accept hit the plan's trade limit.
  bool upgradeRequired = false;

  /// The offer [sendProposal] last created, for the "offer sent" screen.
  ApiTradeRequest? lastSent;

  // API-loaded trade requests.
  List<ApiTradeRequest> _trades = [];
  bool _tradesLoading = false;
  String? _tradesError;

  List<ApiTradeRequest> get trades => _trades;
  bool get tradesLoading => _tradesLoading;
  String? get tradesError => _tradesError;

  List<TradeMatch> _matches = [];
  bool matchesLoading = false;

  /// Suggested trades: real ones when signed in, the seeded pair otherwise.
  List<TradeMatch> get matches => client == null ? AppData.matches : _matches;

  Future<void> loadMatches() async {
    final c = client;
    if (c == null) return;
    matchesLoading = true;
    notifyListeners();
    try {
      final data = await c.get('/api/trades/matches') as List<dynamic>;
      _matches = [for (final m in data.cast<Map<String, dynamic>>()) TradeMatch.fromJson(m)];
    } on ApiException {
      // Keep the previous suggestions.
    } finally {
      matchesLoading = false;
      notifyListeners();
    }
  }

  List<ChipItem> _myItems = [];
  bool myItemsLoading = false;

  /// What you can offer: your own items when signed in, the seeded collection otherwise.
  List<ChipItem> get myCollection => client == null ? AppData.myCollection : _myItems;

  Future<void> loadMyItems(int myId) async {
    final c = client;
    if (c == null || myId <= 0) return;
    myItemsLoading = true;
    notifyListeners();
    try {
      final data = await c.get('/api/items', query: {'ownerId': myId, 'pageSize': 100}) as Map<String, dynamic>;
      _myItems = [for (final i in data['items'] as List<dynamic>? ?? const []) ChipItem.fromApiItem(i as Map<String, dynamic>)];
    } on ApiException {
      // Keep the previous list.
    } finally {
      myItemsLoading = false;
      notifyListeners();
    }
  }

  /// Sends the proposal built on Propose Trade / Add to Trade. Returns an error message, or null on success.
  Future<String?> sendProposal() async {
    final c = client;
    final get = target;
    upgradeRequired = false;
    if (c == null) return null;
    if (get?.itemId == null || get?.sellerId == null) return "This chip can't be traded yet.";
    if (_offered.isEmpty) return 'Add at least one of your chips to offer.';
    try {
      final created = await c.post('/api/trades', body: {
        'recipientId': get!.sellerId,
        if (note.trim().isNotEmpty) 'message': note.trim(),
        'offerItems': [
          for (final o in _offered)
            if (o.itemId != null) {'itemId': o.itemId, 'side': 'GIVE'},
          {'itemId': get.itemId, 'side': 'GET'},
        ],
      }) as Map<String, dynamic>?;
      lastSent = ApiTradeRequest(
        id: created?['id'] as int? ?? 0,
        status: 'PENDING',
        otherUsername: get.owner.isEmpty ? get.seller.name : get.owner,
        otherId: get.sellerId,
        chip: get,
        giveItems: [for (final o in _offered) o.name],
        getItems: [get.name],
      );
      return null;
    } on ApiException catch (e) {
      upgradeRequired = e.upgradeRequired;
      return e.message;
    }
  }

  Future<void> loadTrades(int myId) async {
    final c = client;
    if (c == null || _tradesLoading) return;
    _tradesLoading = true;
    _tradesError = null;
    notifyListeners();
    try {
      _trades = await TradesApi(c).getTrades(myId);
    } on ApiException catch (e) {
      _tradesError = e.message;
    } finally {
      _tradesLoading = false;
      notifyListeners();
    }
  }

  Future<bool> respondToTrade(int id, {required bool accept, required int myId}) async {
    final c = client;
    upgradeRequired = false;
    if (c == null) return false;
    try {
      await TradesApi(c).respondToTrade(id, accept: accept);
      await loadTrades(myId);
      return true;
    } on ApiException catch (e) {
      upgradeRequired = e.upgradeRequired;
      _tradesError = e.message;
      notifyListeners();
      return false;
    }
  }

  void setTarget(ChipItem c) {
    target = c;
    notifyListeners();
  }

  bool isOffered(ChipItem c) => _offered.any((e) => e.id == c.id);

  void toggleOffer(ChipItem c) {
    isOffered(c) ? _offered.removeWhere((e) => e.id == c.id) : _offered.add(c);
    notifyListeners();
  }

  void setNote(String v) {
    note = v;
    notifyListeners();
  }

  void reset() {
    _offered.clear();
    note = '';
    notifyListeners();
  }
}

/// Checkout: shipping address + payment selection.
class CheckoutController extends ChangeNotifier {
  final nameCtrl = TextEditingController(text: 'Daniel Dermaree');
  final addressCtrl = TextEditingController(text: '1420 Lazelle St');
  final cityCtrl = TextEditingController(text: 'Sturgis');
  final stateCtrl = TextEditingController(text: 'SD');
  final zipCtrl = TextEditingController(text: '57785');
  final phoneCtrl = TextEditingController(text: '(605) 555-0142');

  int shippingMethod = 0;
  int cardIndex = 0;
  ChipItem? item;

  double get shippingCost => shippingMethod == 0 ? 6 : 14;
  static const double buyerProtection = 2;
  double get subtotal => item?.price ?? 45;
  double get total => subtotal + shippingCost + buyerProtection;

  void setItem(ChipItem c) {
    item = c;
    notifyListeners();
  }

  void setShipping(int i) {
    shippingMethod = i;
    notifyListeners();
  }

  void setCard(int i) {
    cardIndex = i;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final c in [nameCtrl, addressCtrl, cityCtrl, stateCtrl, zipCtrl, phoneCtrl]) {
      c.dispose();
    }
    super.dispose();
  }
}

/// Live auction bidding.
enum BidStatus { placed, upgradeRequired, failed }

typedef BidResult = ({BidStatus status, String? message});

class AuctionController extends ChangeNotifier {
  AuctionController({this.client});

  final ApiClient? client;

  double currentBid = 110;
  int bids = 12;
  double bidStep = 5;
  double _myBid = 110;
  double get myBid => _myBid;

  /// The API auction the bid screen is showing, null for the mock one.
  int? openedAuctionId;

  PlanStatus? plan;
  bool placing = false;

  double get minBid => currentBid + bidStep;

  /// Bidder name -> whole dollars, highest first. Seeded until a real auction is opened.
  List<MapEntry<String, int>> history = AppData.bidHistory;
  DateTime? endsAt;

  /// "1h 20m" style countdown; the design's value for the seeded auction.
  String get endsIn {
    final end = endsAt;
    if (end == null) return '1h 20m';
    final left = end.difference(DateTime.now());
    if (left.isNegative) return 'Ended';
    if (left.inDays > 0) return '${left.inDays}d ${left.inHours % 24}h';
    if (left.inHours > 0) return '${left.inHours}h ${left.inMinutes % 60}m';
    return '${left.inMinutes}m';
  }

  /// Points the bid screens at a real auction. Mock items leave the seeded values alone.
  void open(ChipItem item) {
    final id = item.auctionId;
    if (id == null) return;
    if (openedAuctionId != id) {
      openedAuctionId = id;
      currentBid = item.price;
      bids = item.bids;
      bidStep = item.bidIncrement;
      _myBid = minBid;
      history = const [];
      endsAt = null;
      notifyListeners();
    }
    _loadAuction(id);
    loadPlan();
  }

  Future<void> _loadAuction(int id) async {
    final c = client;
    if (c == null) return;
    try {
      final a = await c.get('/api/auctions/$id', auth: false) as Map<String, dynamic>;
      final rows = (a['bids'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
      history = [
        for (final b in rows)
          MapEntry((b['bidder'] as Map<String, dynamic>?)?['username'] as String? ?? 'Bidder', ((b['amountCents'] as int? ?? 0) / 100).round()),
      ];
      currentBid = ((a['currentPriceCents'] as int? ?? (currentBid * 100).round()) / 100).toDouble();
      bidStep = ((a['bidIncrementCents'] as int? ?? (bidStep * 100).round()) / 100).toDouble();
      bids = rows.length;
      endsAt = DateTime.tryParse(a['endsAt'] as String? ?? '')?.toLocal();
      if (_myBid < minBid) _myBid = minBid;
      notifyListeners();
    } on ApiException {
      // Keeps the listing's own numbers.
    }
  }

  Future<void> loadPlan() async {
    final c = client;
    if (c == null) return;
    try {
      plan = await AuctionsApi(c).myPlan();
      notifyListeners();
    } on ApiException {
      // The counter is a hint; the server still enforces the limit.
    }
  }

  void setBid(double v) {
    _myBid = v;
    notifyListeners();
  }

  void increment(double by) {
    _myBid += by;
    notifyListeners();
  }

  Future<BidResult> placeBid(ChipItem item) async {
    final c = client;
    final auctionId = item.auctionId;
    if (c == null || auctionId == null) {
      currentBid = _myBid;
      bids += 1;
      notifyListeners();
      return (status: BidStatus.placed, message: null);
    }

    placing = true;
    notifyListeners();
    try {
      await AuctionsApi(c).placeBid(auctionId, (_myBid * 100).round());
      currentBid = _myBid;
      bids += 1;
      _myBid = minBid;
      await Future.wait([loadPlan(), _loadAuction(auctionId)]);
      return (status: BidStatus.placed, message: null);
    } on ApiException catch (e) {
      if (e.upgradeRequired) await loadPlan();
      return (status: e.upgradeRequired ? BidStatus.upgradeRequired : BidStatus.failed, message: e.message);
    } finally {
      placing = false;
      notifyListeners();
    }
  }
}

/// In-app messaging.
class ChatController extends ChangeNotifier {
  ChatController({this.client});

  final ApiClient? client;

  int _myId = 0;
  List<ApiConversation> _conversations = [];
  bool _convsLoaded = false;
  bool loading = false;

  List<ApiConversation> get conversations => _conversations;
  bool get hasConversations => _convsLoaded;
  bool get live => client != null;

  // conversationId -> messages, oldest first.
  final Map<int, List<Map<String, dynamic>>> _apiMessages = {};

  // Mock threads keyed by name, used when there is no API.
  final Map<String, List<ChatMessage>> _threads = {};

  /// The Messages list: real conversations when signed in, the seeded ones otherwise.
  List<ChatThread> get threads => !live
      ? AppData.threads
      : [
          for (final c in _conversations)
            ChatThread(
              name: c.participantName,
              initials: initialsOf(c.participantName),
              preview: c.lastMessage ?? '',
              time: timeAgo(c.lastMessageTime),
              unread: c.unread,
              conversationId: c.id,
              userId: c.participantId,
              avatarUrl: c.participantAvatarUrl,
            ),
        ];

  Future<void> loadConversations([int? myId]) async {
    final c = client;
    if (c == null) return;
    if (myId != null && myId > 0) _myId = myId;
    loading = true;
    notifyListeners();
    try {
      _conversations = await MessagesApi(c).getConversations(_myId);
      _convsLoaded = true;
    } on ApiException {
      // Keep the previous list.
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Fetches a thread and marks it read. Always refetches: new replies arrive between visits.
  Future<void> openThread(ChatThread thread) async {
    final c = client;
    final id = thread.conversationId;
    if (c == null || id == null) return;
    try {
      _apiMessages[id] = await MessagesApi(c).getMessages(id);
      notifyListeners();
      await MessagesApi(c).markRead(id);
    } on ApiException {
      // Shows whatever is cached.
    }
  }

  List<ChatMessage> messagesIn(ChatThread thread) {
    final id = thread.conversationId;
    if (id == null) return const [];
    return [
      for (final m in _apiMessages[id] ?? const <Map<String, dynamic>>[])
        ChatMessage(
          text: m['body'] as String? ?? '',
          mine: m['senderId'] == _myId,
          time: timeAgo(m['createdAt'] as String?),
          image: m['attachmentUrl'] as String?,
        ),
    ];
  }

  /// Sends [text]; a thread with no conversation yet is started with this first message.
  /// Returns the thread to keep showing (it gains a conversationId on first send).
  Future<ChatThread?> sendTo(ChatThread thread, String text) async {
    final c = client;
    final body = text.trim();
    if (c == null || body.isEmpty) return null;
    try {
      var id = thread.conversationId;
      if (id == null) {
        final userId = thread.userId;
        if (userId == null) return null;
        final res = await MessagesApi(c).startConversation(userId, body);
        id = res['conversationId'] as int;
        _apiMessages[id] = [res['message'] as Map<String, dynamic>];
      } else {
        final msg = await MessagesApi(c).sendMessage(id, body);
        _apiMessages.putIfAbsent(id, () => []).add(msg);
      }
      notifyListeners();
      loadConversations();
      return ChatThread(
        name: thread.name,
        initials: thread.initials,
        preview: body,
        time: 'now',
        conversationId: id,
        userId: thread.userId,
        avatarUrl: thread.avatarUrl,
      );
    } on ApiException {
      return null;
    }
  }

  /// The existing conversation with [userId], or a new one to start on first send.
  ChatThread threadWith(int userId, String name, String? avatarUrl) {
    for (final c in _conversations) {
      if (c.participantId == userId) {
        return ChatThread(
          name: c.participantName,
          initials: initialsOf(c.participantName),
          preview: c.lastMessage ?? '',
          time: timeAgo(c.lastMessageTime),
          conversationId: c.id,
          userId: userId,
          avatarUrl: c.participantAvatarUrl,
        );
      }
    }
    return ChatThread(name: name, initials: initialsOf(name), preview: '', time: '', userId: userId, avatarUrl: avatarUrl);
  }

  // Mock-only threads.
  List<ChatMessage> messagesFor(String user) =>
      _threads.putIfAbsent(user, () => [...AppData.conversation]);

  void send(String user, String text) {
    if (text.trim().isEmpty) return;
    messagesFor(user).add(ChatMessage(text: text.trim(), mine: true, time: 'now'));
    notifyListeners();
  }
}

/// Push and trade preferences. Saved to `/api/users/me/preferences` when signed in.
class SettingsController extends ChangeNotifier {
  SettingsController({this.client});

  final ApiClient? client;

  bool pushTrades = false;
  bool pushAuctions = false;
  bool pushMessages = true;
  bool pushMarketing = false;
  bool localTradesOnly = false;

  /// Not stored on the server yet, so it only lasts for this session.
  bool shipNationwide = true;
  final Set<String> tradeInterests = {'Harley-Davidson', 'Casino Chips'};

  bool _loaded = false;

  Future<void> load() async {
    final c = client;
    if (c == null || _loaded) return;
    try {
      _apply(await c.get('/api/users/me/preferences') as Map<String, dynamic>);
      _loaded = true;
      notifyListeners();
    } on ApiException {
      // Shows the defaults; the next toggle saves over them.
    }
  }

  void _apply(Map<String, dynamic> prefs) {
    final push = prefs['push'] as Map<String, dynamic>? ?? const {};
    final trade = prefs['trade'] as Map<String, dynamic>? ?? const {};
    pushTrades = push['wishlistMatches'] as bool? ?? pushTrades;
    pushAuctions = push['auctionAlerts'] as bool? ?? pushAuctions;
    pushMessages = push['weeklyDigest'] as bool? ?? pushMessages;
    pushMarketing = push['nearbyTopTrades'] as bool? ?? pushMarketing;
    localTradesOnly = trade['autoAcceptFairTrades'] as bool? ?? localTradesOnly;
    if (trade['willingToTradeFor'] case final List<dynamic> list) {
      tradeInterests
        ..clear()
        ..addAll(list.cast<String>());
    }
  }

  Future<void> _save(Map<String, dynamic> patch) async {
    final c = client;
    if (c == null) return;
    try {
      _apply(await c.patch('/api/users/me/preferences', body: patch) as Map<String, dynamic>);
    } on ApiException {
      _loaded = false;
      await load();
    }
    notifyListeners();
  }

  void toggle(String key) {
    switch (key) {
      case 'trades':
        pushTrades = !pushTrades;
      case 'auctions':
        pushAuctions = !pushAuctions;
      case 'messages':
        pushMessages = !pushMessages;
      case 'marketing':
        pushMarketing = !pushMarketing;
      case 'local':
        localTradesOnly = !localTradesOnly;
      case 'nationwide':
        shipNationwide = !shipNationwide;
    }
    notifyListeners();
    final patch = switch (key) {
      'trades' => {'push': {'wishlistMatches': pushTrades}},
      'auctions' => {'push': {'auctionAlerts': pushAuctions}},
      'messages' => {'push': {'weeklyDigest': pushMessages}},
      'marketing' => {'push': {'nearbyTopTrades': pushMarketing}},
      'local' => {'trade': {'autoAcceptFairTrades': localTradesOnly}},
      _ => null,
    };
    if (patch != null) _save(patch);
  }

  void toggleInterest(String c) {
    tradeInterests.contains(c) ? tradeInterests.remove(c) : tradeInterests.add(c);
    notifyListeners();
    _save({'trade': {'willingToTradeFor': tradeInterests.toList()}});
  }
}

/// Add-item flow (camera capture + listing form).
enum SaveStatus { saved, upgradeRequired, failed }

typedef SaveResult = ({SaveStatus status, String? message});

/// Add Item: photo -> upload -> Claude reads the chip -> the user checks and
/// corrects every field -> only then is the item saved.
class SellController extends ChangeNotifier {
  SellController({this.client}) {
    // Confirm & Save is disabled while the title is empty.
    titleCtrl.addListener(notifyListeners);
  }

  final ApiClient? client;

  String? photoPath;
  int listingType = 0; // 0 trade, 1 sale, 2 auction
  final titleCtrl = TextEditingController(text: 'Old School Ellington');
  final dealerCtrl = TextEditingController();
  final priceCtrl = TextEditingController(text: '110');
  final yearCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  String condition = 'Mint';
  String rarity = 'Rare';
  String category = 'Harley-Davidson';

  static const conditions = ['Mint', 'Near Mint', 'Good', 'Fair'];
  static const rarities = ['Common', 'Rare', 'Ultra Rare', 'Legendary'];

  String? _uploadedUrl;
  bool scanning = false;
  bool saving = false;

  /// Set when the chip is being added from inside a collection.
  int? collectionId;

  /// The dealership the chip comes from, picked from the dealer list (or
  /// matched from the scan). [dealerCtrl] keeps the name as typed or read.
  Dealer? dealer;

  /// Set once the scan finishes; null until then and for mock (offline) runs.
  ChipScanResult? scan;
  String? scanError;

  bool get canSave => !scanning && !saving && titleCtrl.text.trim().isNotEmpty;

  void setPhoto(String? path) {
    photoPath = path;
    notifyListeners();
  }

  /// Starts a fresh item from [path]. Without a client the seeded form is kept.
  Future<void> scanPhoto(String path) async {
    photoPath = path;
    _uploadedUrl = null;
    scan = null;
    scanError = null;
    dealer = null;
    final c = client;
    if (c == null) {
      notifyListeners();
      return;
    }
    scanning = true;
    notifyListeners();
    try {
      _uploadedUrl = (await c.upload([path])).first;
      final data = await c.post('/api/items/scan', body: {'imageUrl': _uploadedUrl}) as Map<String, dynamic>;
      scan = ChipScanResult.fromJson(data['suggestion'] as Map<String, dynamic>);
      _fillFrom(scan!);
      await _suggestDealer(scan!);
    } on ApiException catch (e) {
      // The photo may still be uploaded; the user can type the details in.
      scanError = e.message;
      _clearForm();
    } finally {
      scanning = false;
      notifyListeners();
    }
  }

  void _fillFrom(ChipScanResult s) {
    titleCtrl.text = s.title;
    dealerCtrl.text = s.dealership ?? '';
    yearCtrl.text = s.year?.toString() ?? '';
    descCtrl.text = s.description;
    condition = switch (s.condition) {
      'Excellent' => 'Near Mint',
      'Good' => 'Good',
      'Fair' || 'Poor' => 'Fair',
      _ => 'Mint',
    };
  }

  /// Dealers whose name or address has every word of [query], for the picker.
  Future<List<Dealer>> searchDealers(String query) async {
    final c = client;
    if (c == null) return const [];
    final data = await c.get('/api/dealers', auth: false, query: {'search': query.trim(), 'limit': 30});
    if (data is! List) throw ApiException(0, 'Unexpected answer from the server.');
    return [for (final d in data.cast<Map<String, dynamic>>()) Dealer.fromJson(d)];
  }

  /// Picks the dealer for the user when the name on the chip matches exactly
  /// one; otherwise they choose it. A failed lookup never blocks the scan.
  Future<void> _suggestDealer(ChipScanResult s) async {
    final name = s.dealership;
    if (name == null || name.trim().isEmpty) return;
    try {
      var found = await searchDealers(name);
      // A dealer with exactly the name on the chip wins over others in the same town.
      final exact = found.where((d) => d.name.toLowerCase() == name.trim().toLowerCase()).toList();
      if (exact.length == 1) found = exact;
      // Otherwise the city narrows a long list.
      if (found.length > 1 && s.city != null) found = await searchDealers('$name ${s.city}');
      if (found.length == 1) dealer = found.single;
    } on ApiException {
      // Leave it for the user to pick.
    }
  }

  void setDealer(Dealer? d) {
    dealer = d;
    if (d != null) dealerCtrl.text = d.name;
    notifyListeners();
  }

  void _clearForm() {
    dealer = null;
    titleCtrl.clear();
    dealerCtrl.clear();
    yearCtrl.clear();
    descCtrl.clear();
  }

  Future<SaveResult> save() async {
    final c = client;
    if (c == null) return (status: SaveStatus.saved, message: null);
    saving = true;
    notifyListeners();
    try {
      // A failed scan can leave the photo un-uploaded; retry before saving.
      final path = photoPath;
      if (_uploadedUrl == null && path != null) _uploadedUrl = (await c.upload([path])).first;
      final year = int.tryParse(yearCtrl.text.trim());
      await c.post('/api/items', body: {
        'title': titleCtrl.text.trim(),
        if (descCtrl.text.trim().isNotEmpty) 'description': descCtrl.text.trim(),
        if (dealerCtrl.text.trim().isNotEmpty) 'brand': dealerCtrl.text.trim(),
        'dealerId': ?dealer?.id,
        'year': ?year,
        'condition': condition,
        'rarity': rarity.toUpperCase().replaceAll(' ', '_'),
        'status': listingType == 0 ? 'FOR_TRADE' : 'HAVE',
        'collectionId': ?collectionId,
        if (_uploadedUrl != null) 'imageUrls': [_uploadedUrl],
      });
      collectionId = null;
      return (status: SaveStatus.saved, message: null);
    } on ApiException catch (e) {
      return (status: e.upgradeRequired ? SaveStatus.upgradeRequired : SaveStatus.failed, message: e.message);
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  void setRarity(String r) {
    rarity = r;
    notifyListeners();
  }

  void setListingType(int i) {
    listingType = i;
    notifyListeners();
  }

  void setCondition(String c) {
    condition = c;
    notifyListeners();
  }

  void setCategory(String c) {
    category = c;
    notifyListeners();
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    dealerCtrl.dispose();
    priceCtrl.dispose();
    yearCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }
}
