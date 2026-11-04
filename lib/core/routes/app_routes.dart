/// Every named destination in the app. Mirrors the Figma prototype flow.
class AppRoutes {
  AppRoutes._();

  // Onboarding
  static const splash = '/';
  static const onboarding = '/onboarding';

  // Auth
  static const login = '/login';
  static const createAccount = '/create-account';
  static const verifyEmail = '/verify-email';
  static const enterCode = '/enter-code';
  static const forgotPassword = '/forgot-password';
  static const enterOtp = '/enter-otp';
  static const createNewPassword = '/create-new-password';

  // Setup
  static const congratulations = '/congratulations';
  static const choosePlan = '/choose-plan';
  static const planPayment = '/plan-payment';
  static const subscribed = '/subscribed';
  static const whatYouCollect = '/what-you-collect';
  static const profileCompleted = '/profile-completed';

  // Shell + core
  static const main = '/main';
  static const filters = '/filters';
  static const mapDealers = '/map-dealers';
  static const wishlist = '/wishlist';
  static const search = '/search';
  static const notifications = '/notifications';

  // Trading
  static const tradeMatches = '/trade-matches';
  static const proposeTrade = '/propose-trade';
  static const addToTrade = '/add-to-trade';
  static const reviewConfirm = '/review-confirm';
  static const tradeSent = '/trade-sent';
  static const tradeCompleted = '/trade-completed';
  static const tradeConfirmed = '/trade-confirmed';
  static const tradeRejected = '/trade-rejected';

  // Item + buy flow
  static const itemDetail = '/item-detail';
  static const shipping = '/shipping';
  static const checkout = '/checkout';
  static const orderPlaced = '/order-placed';
  static const trackOrder = '/track-order';

  // Auctions
  static const auctionDetail = '/auction-detail';
  static const placeBid = '/place-bid';
  static const bidPlaced = '/bid-placed';
  static const auctionWinner = '/auction-winner';
  static const auctionLost = '/auction-lost';

  // Messaging
  static const messages = '/messages';
  static const chat = '/chat';

  // Profile
  static const myProfile = '/my-profile';
  static const editProfile = '/edit-profile';
  static const sellerProfile = '/seller-profile';
  static const collections = '/collections';
  static const eventDetail = '/event-detail';
  static const myActivity = '/my-activity';

  // Sell
  static const addItem = '/add-item';
  static const itemForm = '/item-form';
  static const createCategory = '/create-category';
  static const addToCollection = '/add-to-collection';

  // Settings
  static const settings = '/settings';
  static const changePassword = '/change-password';
  static const thankYouPassword = '/thank-you-password';
  static const tradePreferences = '/trade-preferences';
  static const editCollect = '/edit-collect';
  static const pushNotifications = '/push-notifications';
  static const paymentMethods = '/payment-methods';
  static const addCard = '/add-card';
  static const cardAdded = '/card-added';
  static const manageCard = '/manage-card';
  static const privacyPolicy = '/privacy-policy';
  static const terms = '/terms';
  static const helpFeedback = '/help-feedback';
  static const thankYouFeedback = '/thank-you-feedback';

  // Orders
  static const orderRequests = '/order-requests';
  static const confirmRequest = '/confirm-request';
  static const requestSent = '/request-sent';
  static const orderRejected = '/order-rejected';
  static const ordersPurchase = '/orders-purchase';
  static const ordersTrade = '/orders-trade';

  // Points, rankings and the official chip store
  static const wallet = '/wallet';
  static const walletHistory = '/wallet-history';
  static const leaderboard = '/leaderboard';
  static const dealerRanking = '/dealer-ranking';
  static const chipStore = '/chip-store';
}
