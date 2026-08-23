/// App ki saari user-facing text yahan se aati hai.
///
/// Default **English** hai. Hindi sirf tab dikhti hai jab user
/// Settings -> Language mein hi select kare.
enum AppLang {
  en('English', 'en'),
  hi('हिंदी', 'hi');

  const AppLang(this.label, this.code);

  final String label;
  final String code;

  static AppLang fromCode(String? code) =>
      AppLang.values.firstWhere((l) => l.code == code, orElse: () => AppLang.en);
}

class AppStrings {
  const AppStrings(this.lang);

  final AppLang lang;

  /// English pehle, Hindi doosra.
  String _p(String en, String hi) => lang == AppLang.hi ? hi : en;

  // ---------------- Common ----------------
  String get appName => 'QuickKart';
  String get retry => _p('Try again', 'फिर कोशिश करें');
  String get logout => _p('Log out', 'लॉग आउट');
  String get settings => _p('Settings', 'सेटिंग्स');
  String get cancel => _p('Cancel', 'रद्द करें');

  // ---------------- Login ----------------
  String get fullName => _p('Full name', 'पूरा नाम');
  String get email => _p('Email', 'ईमेल');
  String get password => _p('Password', 'पासवर्ड');
  String get enterName => _p('Please enter your name', 'कृपया नाम डालें');
  String get invalidEmail => _p('Enter a valid email', 'सही ईमेल डालें');
  String get passwordTooShort => _p('At least 6 characters', 'कम से कम 6 अक्षर');
  String get createAccount => _p('Create account', 'अकाउंट बनाएं');
  String get login => _p('Log in', 'लॉग इन करें');
  String get alreadyHaveAccount =>
      _p('Already have an account? Log in', 'पहले से अकाउंट है? लॉग इन करें');
  String get createNewAccount => _p('Create a new account', 'नया अकाउंट बनाएं');
  String get accountCreated =>
      _p('Account created! Please log in.', 'अकाउंट बन गया! अब लॉग इन करें।');
  String get confirmEmailSent => _p(
        'Account created. Check your inbox and confirm your email, then log in.',
        'अकाउंट बन गया। ईमेल में आए लिंक से कन्फर्म करें, phir लॉग इन करें।',
      );

  // ---------------- Auth errors ----------------
  // Supabase raw exception (AuthApiException(...)) kabhi user ko nahi dikhani —
  // uske jagah yeh saaf messages dikhte hain.
  String get errEmailNotConfirmed => _p(
        'Please confirm your email first — check your inbox for the confirmation link.',
        'पहले अपना ईमेल कन्फर्म करें — इनबॉक्स में कन्फर्मेशन लिंक देखें।',
      );
  String get errInvalidCredentials =>
      _p('Email or password is incorrect', 'ईमेल या पासवर्ड गलत है');
  String get errEmailExists => _p(
        'An account with this email already exists — try logging in.',
        'इस ईमेल से अकाउंट पहले से है — लॉग इन करके देखें।',
      );
  String get errWeakPassword => _p(
        'Password is too weak — use at least 6 characters.',
        'पासवर्ड बहुत कमज़ोर है — कम से कम 6 अक्षर रखें।',
      );
  String get errTooManyRequests => _p(
        'Too many attempts. Please wait a minute and try again.',
        'बहुत ज़्यादा कोशिशें। एक मिनट रुककर दोबारा try करें।',
      );
  String get errNetwork => _p(
        'Could not reach the server — check your internet connection.',
        'सर्वर तक नहीं पहुँच पाए — अपना इंटरनेट कनेक्शन जाँचें।',
      );
  String get errGeneric =>
      _p('Something went wrong. Please try again.', 'कुछ गड़बड़ हो गई। दोबारा try करें।');

  // ---------------- Home ----------------
  String get searchHint => _p(
        'Search groceries, electronics, fashion…',
        'ग्रोसरी, इलेक्ट्रॉनिक्स, फैशन... कुछ भी खोजें',
      );
  String get all => _p('All', 'सभी');
  String productsAvailable(int count) => _p(
        '${_grouped(count)} products available',
        '${_grouped(count)} प्रोडक्ट उपलब्ध',
      );
  String get loadingMore => _p('Loading more…', 'और लोड हो रहा है…');
  String get endOfCatalog => _p('That\'s everything', 'बस इतना ही');

  /// 30020 -> "30,020" (Indian grouping ke bajaye simple thousands grouping,
  /// dono languages mein same padha jaata hai).
  static String _grouped(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
  String get noProductsFound => _p('No products found', 'कोई प्रोडक्ट नहीं मिला');
  String loadFailed(Object error) => _p(
        'Could not load data from Supabase:\n$error',
        'Supabase से डेटा नहीं आ पाया:\n$error',
      );
  String get heroTitle => _p(
        'Everything you need, delivered to your door',
        'सब कुछ मिलेगा, तुरंत घर तक',
      );
  String get heroSubtitle =>
      _p('From groceries to electronics', 'ग्रोसरी से लेकर इलेक्ट्रॉनिक्स तक');
  String get deliveryBadge => _p('🚀 12 min', '🚀 12 मिनट');
  String cartSummary(int items, String total) =>
      _p('$items items · ₹$total', '$items आइटम · ₹$total');

  // ---------------- Location ----------------
  String deliveryInMinutes(int minutes) =>
      _p('Delivery in $minutes minutes', '$minutes मिनट में डिलीवरी');
  String get selectLocation =>
      _p('Select delivery location', 'डिलीवरी लोकेशन चुनें');
  String get changeLocation => _p('Change location', 'लोकेशन बदलें');
  String get savedAddresses => _p('Saved locations', 'सेव की लोकेशन');
  String get noLocationMatch =>
      _p('No matching location found', 'कोई मैचिंग लोकेशन नहीं मिली');
  String get removeAddress => _p('Remove', 'हटाएं');
  String get deliveringTo => _p('Delivering to', 'यहाँ डिलीवरी');

  // Cascade: State -> District -> Pincode
  String get selectState => _p('Select state', 'राज्य चुनें');
  String get selectDistrict => _p('Select district', 'ज़िला चुनें');
  String get selectPincode => _p('Select pincode', 'पिनकोड चुनें');
  String get searchState => _p('Search state', 'राज्य खोजें');
  String get searchDistrict => _p('Search district', 'ज़िला खोजें');
  String get searchPincode => _p('Search pincode', 'पिनकोड खोजें');
  String get state => _p('State', 'राज्य');
  String get district => _p('District', 'ज़िला');
  String get pincode => _p('Pincode', 'पिनकोड');
  String get change => _p('Change', 'बदलें');
  String get loadingLocations => _p('Loading…', 'लोड हो रहा है…');
  String get locationLoadFailed =>
      _p('Could not load locations', 'लोकेशन लोड नहीं हो paayi');

  // ---------------- Cart ----------------
  String get yourCart => _p('Your cart', 'आपका कार्ट');
  String get cartEmpty => _p('Your cart is empty 🛒', 'कार्ट खाली है 🛒');
  String get itemTotal => _p('Item total', 'आइटम कुल');
  String get deliveryFee => _p('Delivery fee', 'डिलीवरी शुल्क');
  String get free => _p('FREE', 'मुफ़्त');
  String get totalPayable => _p('Total payable', 'कुल भुगतान');
  String get checkout => _p('Checkout', 'चेकआउट करें');

  // ---------------- Checkout ----------------
  String get deliveryDetails => _p('Delivery details', 'डिलीवरी जानकारी');
  String get nameHint => _p('e.g. Rahul Sharma', 'जैसे: Rahul Sharma');
  String get phone => _p('Mobile number', 'मोबाइल नंबर');
  String get phoneHint => _p('10-digit number', '10 अंकों का नंबर');
  String get invalidPhone =>
      _p('Enter a valid 10-digit number', 'सही 10 अंकों का नंबर डालें');
  String get emailHint => 'name@example.com';
  String get deliveryAddress => _p('Delivery address', 'डिलीवरी पता');
  String get addressHint => _p(
        'House no, street, city, PIN code',
        'घर नंबर, गली, शहर, पिनकोड',
      );
  String get invalidAddress =>
      _p('Please enter your full address', 'कृपया पूरा पता डालें');
  String get payWithCashfree => _p('Pay with Cashfree', 'Cashfree से भुगतान करें');
  String get paymentSuccess => _p(
        'Payment successful! Your order is confirmed.',
        'भुगतान सफल! ऑर्डर कन्फर्म हो गया।',
      );
  String checkoutFailed(Object error) => _p(
        'Something went wrong: $error',
        'गड़बड़ी हो गई: $error',
      );
  String get payment => _p('Payment', 'भुगतान');

  // ---------------- Admin ----------------
  String get adminAllOrders => _p('Admin — All orders', 'एडमिन — सभी ऑर्डर');
  String get noOrdersYet => _p('No orders yet', 'अभी कोई ऑर्डर नहीं है');
  String get paid => _p('PAID', 'भुगतान हुआ');
  String get pending => _p('PENDING', 'बाकी है');

  // ---------------- Settings ----------------
  String get appearance => _p('Appearance', 'दिखावट');
  String get theme => _p('Theme', 'थीम');
  String get themeLight => _p('Light', 'लाइट');
  String get themeDark => _p('Dark', 'डार्क');
  String get themeSystem => _p('System default', 'सिस्टम डिफ़ॉल्ट');
  String get notifications => _p('Notifications', 'नोटिफिकेशन');
  String get orderUpdates => _p('Order updates', 'ऑर्डर अपडेट');
  String get orderUpdatesDesc => _p(
        'Show in-app alerts when an order is placed or its status changes',
        'ऑर्डर होने या स्टेटस बदलने पर ऐप के अंदर अलर्ट दिखाएं',
      );
  String get notificationsOn => _p('On', 'चालू');
  String get notificationsOff => _p('Off', 'बंद');
  String get language => _p('Language', 'भाषा');
  String get languageDesc => _p(
        'Applies to the whole app, including product names',
        'पूरे ऐप पर लागू होगा, प्रोडक्ट नामों समेत',
      );
  String get account => _p('Account', 'अकाउंट');
  String get signedInAs => _p('Signed in as', 'लॉग इन:');
  String get notSignedIn => _p('Not signed in', 'लॉग इन नहीं');
}
