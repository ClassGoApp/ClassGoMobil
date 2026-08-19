import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'ClassGo'**
  String get appName;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get selectLanguage;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcome;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @findTutors.
  ///
  /// In en, this message translates to:
  /// **'Find tutors\nfor your subjects'**
  String get findTutors;

  /// No description provided for @searchSubjectHint.
  ///
  /// In en, this message translates to:
  /// **'What subject do you need help with?'**
  String get searchSubjectHint;

  /// No description provided for @instantTutor.
  ///
  /// In en, this message translates to:
  /// **'Instant Tutor'**
  String get instantTutor;

  /// No description provided for @scheduleTutoring.
  ///
  /// In en, this message translates to:
  /// **'Schedule\nTutoring'**
  String get scheduleTutoring;

  /// No description provided for @exploreTutors.
  ///
  /// In en, this message translates to:
  /// **'Explore\nTutors'**
  String get exploreTutors;

  /// No description provided for @weAreWithYou.
  ///
  /// In en, this message translates to:
  /// **'We\'re with you!'**
  String get weAreWithYou;

  /// No description provided for @findIdealTutor.
  ///
  /// In en, this message translates to:
  /// **'Find the ideal tutor for you and reach your goals today.'**
  String get findIdealTutor;

  /// No description provided for @ourAlliances.
  ///
  /// In en, this message translates to:
  /// **'Our\nAlliances'**
  String get ourAlliances;

  /// No description provided for @institutions.
  ///
  /// In en, this message translates to:
  /// **'Institutions'**
  String get institutions;

  /// No description provided for @needHelp.
  ///
  /// In en, this message translates to:
  /// **'Need\nHelp?'**
  String get needHelp;

  /// No description provided for @support247.
  ///
  /// In en, this message translates to:
  /// **'24/7 Support'**
  String get support247;

  /// No description provided for @exploreSubjects.
  ///
  /// In en, this message translates to:
  /// **'Explore Subjects'**
  String get exploreSubjects;

  /// No description provided for @instantTutorDrawer.
  ///
  /// In en, this message translates to:
  /// **'Instant Tutor'**
  String get instantTutorDrawer;

  /// No description provided for @searchTutorsDrawer.
  ///
  /// In en, this message translates to:
  /// **'Search Tutors'**
  String get searchTutorsDrawer;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @questions.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get questions;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logIn;

  /// No description provided for @accessToInstantTutorTitle.
  ///
  /// In en, this message translates to:
  /// **'Instant Tutor Access'**
  String get accessToInstantTutorTitle;

  /// No description provided for @accessToInstantTutorMessage.
  ///
  /// In en, this message translates to:
  /// **'To access instant tutoring, you need to log in to your account.'**
  String get accessToInstantTutorMessage;

  /// No description provided for @scheduleTutoringTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule Tutoring'**
  String get scheduleTutoringTitle;

  /// No description provided for @scheduleTutoringMessage.
  ///
  /// In en, this message translates to:
  /// **'To schedule a class with a tutor, you need to log in.'**
  String get scheduleTutoringMessage;

  /// No description provided for @categoryAccounting.
  ///
  /// In en, this message translates to:
  /// **'Accounting'**
  String get categoryAccounting;

  /// No description provided for @categoryChemistry.
  ///
  /// In en, this message translates to:
  /// **'Chemistry'**
  String get categoryChemistry;

  /// No description provided for @categoryProgramming.
  ///
  /// In en, this message translates to:
  /// **'Programming'**
  String get categoryProgramming;

  /// No description provided for @categoryEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get categoryEnglish;

  /// No description provided for @categoryExactSciences.
  ///
  /// In en, this message translates to:
  /// **'Exact Sciences'**
  String get categoryExactSciences;

  /// No description provided for @categoryMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get categoryMusic;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'My Calendar'**
  String get calendarTitle;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Tutoring History'**
  String get historyTitle;

  /// No description provided for @addSubject.
  ///
  /// In en, this message translates to:
  /// **'ADD SUBJECT'**
  String get addSubject;

  /// No description provided for @subjectLabel.
  ///
  /// In en, this message translates to:
  /// **'SUBJECT'**
  String get subjectLabel;

  /// No description provided for @addSubjectHint.
  ///
  /// In en, this message translates to:
  /// **'Add your next subject...'**
  String get addSubjectHint;

  /// No description provided for @noTutoringsDay.
  ///
  /// In en, this message translates to:
  /// **'No tutoring sessions for this day'**
  String get noTutoringsDay;

  /// No description provided for @noTutoringsDisplay.
  ///
  /// In en, this message translates to:
  /// **'No tutoring sessions to display'**
  String get noTutoringsDisplay;

  /// No description provided for @tutoringLabel.
  ///
  /// In en, this message translates to:
  /// **'Tutoring'**
  String get tutoringLabel;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status:'**
  String get statusLabel;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'From {start} to {end}'**
  String dateRange(String start, String end);

  /// No description provided for @tutoringsOnDate.
  ///
  /// In en, this message translates to:
  /// **'Tutoring on {date}'**
  String tutoringsOnDate(String date);

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @searchTutors.
  ///
  /// In en, this message translates to:
  /// **'Search Tutors'**
  String get searchTutors;

  /// No description provided for @findExperts.
  ///
  /// In en, this message translates to:
  /// **'Find experts'**
  String get findExperts;

  /// No description provided for @myBookings.
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get myBookings;

  /// No description provided for @viewSessions.
  ///
  /// In en, this message translates to:
  /// **'View sessions'**
  String get viewSessions;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @favoriteTutors.
  ///
  /// In en, this message translates to:
  /// **'Favorite Tutors'**
  String get favoriteTutors;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile settings'**
  String get profileSettings;

  /// No description provided for @noRecentBookings.
  ///
  /// In en, this message translates to:
  /// **'You have no recent bookings'**
  String get noRecentBookings;

  /// No description provided for @recentBookings.
  ///
  /// In en, this message translates to:
  /// **'Recent Bookings'**
  String get recentBookings;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @student.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get student;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'EDIT'**
  String get editProfile;

  /// No description provided for @editProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Modify personal information'**
  String get editProfileSubtitle;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @pricePerTutoring.
  ///
  /// In en, this message translates to:
  /// **'PRICE PER TUTORING'**
  String get pricePerTutoring;

  /// No description provided for @pricePerTutoringDetails.
  ///
  /// In en, this message translates to:
  /// **'{_price} Bs / 20min.'**
  String pricePerTutoringDetails(String _price);

  /// No description provided for @definePrice.
  ///
  /// In en, this message translates to:
  /// **'Define Price'**
  String get definePrice;

  /// No description provided for @enterTutoringAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter the amount you will charge for 20 minutes of tutoring.'**
  String get enterTutoringAmount;

  /// No description provided for @priceSuffix.
  ///
  /// In en, this message translates to:
  /// **'Bs / 20min'**
  String get priceSuffix;

  /// No description provided for @savePrice.
  ///
  /// In en, this message translates to:
  /// **'SAVE PRICE'**
  String get savePrice;

  /// No description provided for @rateUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Rate updated successfully'**
  String get rateUpdatedSuccessfully;

  /// No description provided for @updateYourData.
  ///
  /// In en, this message translates to:
  /// **'Update your data'**
  String get updateYourData;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get firstName;

  /// No description provided for @yourFirstName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourFirstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @yourLastName.
  ///
  /// In en, this message translates to:
  /// **'Your last name'**
  String get yourLastName;

  /// No description provided for @cellphone.
  ///
  /// In en, this message translates to:
  /// **'Cellphone'**
  String get cellphone;

  /// No description provided for @enterYourCellphone.
  ///
  /// In en, this message translates to:
  /// **'Enter your cellphone number'**
  String get enterYourCellphone;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @tellUsAboutYou.
  ///
  /// In en, this message translates to:
  /// **'Tell us something about yourself...'**
  String get tellUsAboutYou;

  /// No description provided for @verifiedTutor.
  ///
  /// In en, this message translates to:
  /// **'Verified Tutor'**
  String get verifiedTutor;

  /// No description provided for @pendingVerification.
  ///
  /// In en, this message translates to:
  /// **'Pending Verification'**
  String get pendingVerification;

  /// No description provided for @presentationVideoOptional.
  ///
  /// In en, this message translates to:
  /// **'Presentation Video (Optional)'**
  String get presentationVideoOptional;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get uploading;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'Updating...'**
  String get updating;

  /// No description provided for @changeVideo.
  ///
  /// In en, this message translates to:
  /// **'Change Video'**
  String get changeVideo;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @accountSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change password and settings'**
  String get accountSettingsSubtitle;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @helpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help center and support'**
  String get helpSubtitle;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @logoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of the app'**
  String get logoutSubtitle;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @logoutError.
  ///
  /// In en, this message translates to:
  /// **'Error logging out'**
  String get logoutError;

  /// No description provided for @loginToAccessProfile.
  ///
  /// In en, this message translates to:
  /// **'Log in to access your profile'**
  String get loginToAccessProfile;

  /// No description provided for @loginToAccessProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'Review your history, statistics, payments and personal settings.'**
  String get loginToAccessProfileDesc;

  /// No description provided for @noSort.
  ///
  /// In en, this message translates to:
  /// **'No sort'**
  String get noSort;

  /// No description provided for @nameAZ.
  ///
  /// In en, this message translates to:
  /// **'Name (A-Z)'**
  String get nameAZ;

  /// No description provided for @nameZA.
  ///
  /// In en, this message translates to:
  /// **'Name (Z-A)'**
  String get nameZA;

  /// No description provided for @subjectAZ.
  ///
  /// In en, this message translates to:
  /// **'Subject (A-Z)'**
  String get subjectAZ;

  /// No description provided for @subjectZA.
  ///
  /// In en, this message translates to:
  /// **'Subject (Z-A)'**
  String get subjectZA;

  /// No description provided for @tutorsFor.
  ///
  /// In en, this message translates to:
  /// **'tutors for'**
  String get tutorsFor;

  /// No description provided for @tutorsFound.
  ///
  /// In en, this message translates to:
  /// **'{total} tutors found'**
  String tutorsFound(int total);

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @tutor.
  ///
  /// In en, this message translates to:
  /// **'Tutor'**
  String get tutor;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @noTutorsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No tutors available'**
  String get noTutorsAvailable;

  /// No description provided for @tutorRemovedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Tutor removed from favorites'**
  String get tutorRemovedFromFavorites;

  /// No description provided for @tutorAddedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Tutor added to favorites'**
  String get tutorAddedToFavorites;

  /// No description provided for @favoriteError.
  ///
  /// In en, this message translates to:
  /// **'Could not add/remove from favorites'**
  String get favoriteError;

  /// No description provided for @loginRequired.
  ///
  /// In en, this message translates to:
  /// **'Login required!'**
  String get loginRequired;

  /// No description provided for @loginRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'You need to be logged in to enter'**
  String get loginRequiredMessage;

  /// No description provided for @goToLogin.
  ///
  /// In en, this message translates to:
  /// **'Go to Login'**
  String get goToLogin;

  /// No description provided for @noFavoriteTutors.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have favorite tutors yet'**
  String get noFavoriteTutors;

  /// No description provided for @noFavoriteTutorsDesc.
  ///
  /// In en, this message translates to:
  /// **'Save tutors you like to find them quickly.'**
  String get noFavoriteTutorsDesc;

  /// No description provided for @noDescriptionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No description available.'**
  String get noDescriptionAvailable;

  /// No description provided for @teachingPhilosophy.
  ///
  /// In en, this message translates to:
  /// **'Teaching Philosophy'**
  String get teachingPhilosophy;

  /// No description provided for @qrPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'QR Payment Method'**
  String get qrPaymentMethod;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'terms and conditions'**
  String get termsAndConditions;

  /// No description provided for @pendingTermsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Pending terms and conditions'**
  String get pendingTermsAndConditions;

  /// No description provided for @noNameAvailable.
  ///
  /// In en, this message translates to:
  /// **'No name available'**
  String get noNameAvailable;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @classes20Min.
  ///
  /// In en, this message translates to:
  /// **'20-minute classes'**
  String get classes20Min;

  /// No description provided for @noName.
  ///
  /// In en, this message translates to:
  /// **'No name'**
  String get noName;

  /// No description provided for @reservations.
  ///
  /// In en, this message translates to:
  /// **'Reservations'**
  String get reservations;

  /// No description provided for @newReservation.
  ///
  /// In en, this message translates to:
  /// **'New reservation'**
  String get newReservation;

  /// No description provided for @createNewReservation.
  ///
  /// In en, this message translates to:
  /// **'Create new reservation for'**
  String get createNewReservation;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @noReservationsForDate.
  ///
  /// In en, this message translates to:
  /// **'No reservations for this date'**
  String get noReservationsForDate;

  /// No description provided for @reservation.
  ///
  /// In en, this message translates to:
  /// **'Reservation'**
  String get reservation;

  /// No description provided for @passwordSettings.
  ///
  /// In en, this message translates to:
  /// **'Password Settings'**
  String get passwordSettings;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'The password field is required.'**
  String get passwordRequired;

  /// No description provided for @passwordLengthError.
  ///
  /// In en, this message translates to:
  /// **'The password field must be at least 8 characters.'**
  String get passwordLengthError;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'The confirm field is required.'**
  String get confirmPasswordRequired;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'The confirm field must match password.'**
  String get passwordMismatch;

  /// No description provided for @passwordUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Password not updated, please try again: {error}'**
  String passwordUpdateError(Object error);

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @tugoHelpMessage.
  ///
  /// In en, this message translates to:
  /// **'Hi! I\'m Tuggo. I\'m here to answer all your questions about ClassGo. How can I help you?'**
  String get tugoHelpMessage;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @students.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get students;

  /// No description provided for @tutors.
  ///
  /// In en, this message translates to:
  /// **'Tutors'**
  String get tutors;

  /// No description provided for @directContact.
  ///
  /// In en, this message translates to:
  /// **'Direct Contact'**
  String get directContact;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @faqStudentQ1.
  ///
  /// In en, this message translates to:
  /// **'How to find a tutor?'**
  String get faqStudentQ1;

  /// No description provided for @faqStudentA1.
  ///
  /// In en, this message translates to:
  /// **'Use the search bar to find available tutors based on the subject or topic you need.'**
  String get faqStudentA1;

  /// No description provided for @faqStudentQ2.
  ///
  /// In en, this message translates to:
  /// **'How do I book a session?'**
  String get faqStudentQ2;

  /// No description provided for @faqStudentA2.
  ///
  /// In en, this message translates to:
  /// **'Once you find a tutor, check their profile and select an available time slot that suits you. Click \"Book\" and follow the instructions to confirm your session.'**
  String get faqStudentA2;

  /// No description provided for @faqStudentQ3.
  ///
  /// In en, this message translates to:
  /// **'What if I need to cancel or reschedule?'**
  String get faqStudentQ3;

  /// No description provided for @faqStudentA3.
  ///
  /// In en, this message translates to:
  /// **'Tutoring sessions cannot be canceled once booked. If any inconvenience occurred, contact us and we will gladly help you.'**
  String get faqStudentA3;

  /// No description provided for @faqStudentQ4.
  ///
  /// In en, this message translates to:
  /// **'How do I pay for sessions?'**
  String get faqStudentQ4;

  /// No description provided for @faqStudentA4.
  ///
  /// In en, this message translates to:
  /// **'Payments are made through the QR provided in your reservation or by bank transfer with the data shown on the screen.'**
  String get faqStudentA4;

  /// No description provided for @faqStudentQ5.
  ///
  /// In en, this message translates to:
  /// **'What should I do if my tutor doesn\'t show up?'**
  String get faqStudentQ5;

  /// No description provided for @faqStudentA5.
  ///
  /// In en, this message translates to:
  /// **'If your tutor does not show up for a scheduled session, contact support immediately for assistance and to schedule a reschedule or refund.'**
  String get faqStudentA5;

  /// No description provided for @faqStudentQ6.
  ///
  /// In en, this message translates to:
  /// **'How can I leave feedback?'**
  String get faqStudentQ6;

  /// No description provided for @faqStudentA6.
  ///
  /// In en, this message translates to:
  /// **'Go to the tutor\'s profile, scroll down to the reviews section, where you can see student ratings and comments.'**
  String get faqStudentA6;

  /// No description provided for @faqTutorQ1.
  ///
  /// In en, this message translates to:
  /// **'How can I become a tutor?'**
  String get faqTutorQ1;

  /// No description provided for @faqTutorA1.
  ///
  /// In en, this message translates to:
  /// **'Create an account, fill out the form, and at the end select \"Tutor\". Create your profile and send the necessary documentation for approval.'**
  String get faqTutorA1;

  /// No description provided for @faqTutorQ2.
  ///
  /// In en, this message translates to:
  /// **'What qualifications do I need to be a tutor?'**
  String get faqTutorQ2;

  /// No description provided for @faqTutorA2.
  ///
  /// In en, this message translates to:
  /// **'Academic qualification is not a requirement. If you want to teach \"something\" you can do it.'**
  String get faqTutorA2;

  /// No description provided for @faqTutorQ3.
  ///
  /// In en, this message translates to:
  /// **'How do I set my availability?'**
  String get faqTutorQ3;

  /// No description provided for @faqTutorA3.
  ///
  /// In en, this message translates to:
  /// **'Log in to your account, go to the “Manage available time” section, and update your calendar with your available time slots.'**
  String get faqTutorA3;

  /// No description provided for @faqTutorQ4.
  ///
  /// In en, this message translates to:
  /// **'What should I do if a student cancels?'**
  String get faqTutorQ4;

  /// No description provided for @faqTutorA4.
  ///
  /// In en, this message translates to:
  /// **'Students do not have the option to cancel a session after booking. If the student informs you of a problem, recommend them to write to our contact for help.'**
  String get faqTutorA4;

  /// No description provided for @professionNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Profession not available'**
  String get professionNotAvailable;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @bookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookings;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @tutorsFoundForTutor.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No tutors found for {tutorName}} one{{count} tutor found for {tutorName}} other{{count} tutors found for {tutorName}}}'**
  String tutorsFoundForTutor(int count, String tutorName);

  /// No description provided for @tutorsFoundForKeyword.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No tutors found for {keyword}} one{{count} tutor found for {keyword}} other{{count} tutors found for {keyword}}}'**
  String tutorsFoundForKeyword(int count, String keyword);

  /// No description provided for @studentReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Student Reviews'**
  String get studentReviewsTitle;

  /// No description provided for @resultsFound.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No results found} one{{count} result found} other{{count} results found}}'**
  String resultsFound(int count);

  /// No description provided for @noReviewsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No reviews available'**
  String get noReviewsAvailable;

  /// No description provided for @defaultStudentName.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get defaultStudentName;

  /// No description provided for @defaultGuestEmail.
  ///
  /// In en, this message translates to:
  /// **'email@example.com'**
  String get defaultGuestEmail;

  /// No description provided for @emailCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Email cannot be empty'**
  String get emailCannotBeEmpty;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @passwordCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Password cannot be empty'**
  String get passwordCannotBeEmpty;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @loginSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Login successful'**
  String get loginSuccessful;

  /// No description provided for @emailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Your email is not verified. Check your inbox and confirm your account.'**
  String get emailNotVerified;

  /// No description provided for @serverNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Server is not available. Please try again later.'**
  String get serverNotAvailable;

  /// No description provided for @serverDownTitle.
  ///
  /// In en, this message translates to:
  /// **'Server temporarily out of service'**
  String get serverDownTitle;

  /// No description provided for @serverDownMessage.
  ///
  /// In en, this message translates to:
  /// **'The server is not available at this moment. Please try again later.'**
  String get serverDownMessage;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please check your details and try again.'**
  String get loginFailed;

  /// No description provided for @resendEmailSuccess.
  ///
  /// In en, this message translates to:
  /// **'We have resent the email. Check your inbox to verify your account.'**
  String get resendEmailSuccess;

  /// No description provided for @resendEmailFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not resend email. Please try again later.'**
  String get resendEmailFailed;

  /// No description provided for @noActiveSession.
  ///
  /// In en, this message translates to:
  /// **'Error: No active session'**
  String get noActiveSession;

  /// No description provided for @emailVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Email Verification'**
  String get emailVerificationTitle;

  /// No description provided for @resendEmailButton.
  ///
  /// In en, this message translates to:
  /// **'Resend Email'**
  String get resendEmailButton;

  /// No description provided for @googleTokenError.
  ///
  /// In en, this message translates to:
  /// **'Could not get Google token'**
  String get googleTokenError;

  /// No description provided for @googleLoginError.
  ///
  /// In en, this message translates to:
  /// **'Error logging in with Google'**
  String get googleLoginError;

  /// No description provided for @homeButton.
  ///
  /// In en, this message translates to:
  /// **'HOME'**
  String get homeButton;

  /// No description provided for @loginScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to your account'**
  String get loginScreenTitle;

  /// No description provided for @loginScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Access courses, manage your schedule,\nand stay connected.'**
  String get loginScreenSubtitle;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailHint;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordHint;

  /// No description provided for @rememberAccount.
  ///
  /// In en, this message translates to:
  /// **'Remember account on device'**
  String get rememberAccount;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginButton;

  /// No description provided for @loginWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Log in with Google'**
  String get loginWithGoogle;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotPassword;

  /// No description provided for @noAccountRegister.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?, Register'**
  String get noAccountRegister;

  /// No description provided for @defaultTutorName.
  ///
  /// In en, this message translates to:
  /// **'Tutor'**
  String get defaultTutorName;

  /// No description provided for @defaultSubjectName.
  ///
  /// In en, this message translates to:
  /// **'Tutoring'**
  String get defaultSubjectName;

  /// No description provided for @defaultPendingStatus.
  ///
  /// In en, this message translates to:
  /// **'pending'**
  String get defaultPendingStatus;

  /// No description provided for @onboardingBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'You are one step away from teaching!'**
  String get onboardingBannerTitle;

  /// No description provided for @onboardingBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your profile is incomplete. Set it up now to start receiving students.'**
  String get onboardingBannerSubtitle;

  /// No description provided for @onboardingBannerButton.
  ///
  /// In en, this message translates to:
  /// **'Complete my profile now'**
  String get onboardingBannerButton;

  /// No description provided for @quickAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get quickAccessTitle;

  /// No description provided for @mySchedule.
  ///
  /// In en, this message translates to:
  /// **'My Schedule'**
  String get mySchedule;

  /// No description provided for @mySubjects.
  ///
  /// In en, this message translates to:
  /// **'My Subjects'**
  String get mySubjects;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @todaysClasses.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Classes'**
  String get todaysClasses;

  /// No description provided for @viewSchedule.
  ///
  /// In en, this message translates to:
  /// **'View Schedule'**
  String get viewSchedule;

  /// No description provided for @noDate.
  ///
  /// In en, this message translates to:
  /// **'NO DATE'**
  String get noDate;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusInProgress;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @meetLinkNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Meet link is not yet available.'**
  String get meetLinkNotAvailable;

  /// No description provided for @meetingLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Meeting link'**
  String get meetingLinkLabel;

  /// No description provided for @meetButton.
  ///
  /// In en, this message translates to:
  /// **'Meet'**
  String get meetButton;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get linkCopied;

  /// No description provided for @meetingStartedWaitingLink.
  ///
  /// In en, this message translates to:
  /// **'Meeting started, waiting for link...'**
  String get meetingStartedWaitingLink;

  /// No description provided for @enterSession.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get enterSession;

  /// No description provided for @startSession.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startSession;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @allClear.
  ///
  /// In en, this message translates to:
  /// **'All clear!'**
  String get allClear;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline mode'**
  String get offlineMode;

  /// No description provided for @noClassesToday.
  ///
  /// In en, this message translates to:
  /// **'You have no classes scheduled for today.'**
  String get noClassesToday;

  /// No description provided for @noUpcomingClasses.
  ///
  /// In en, this message translates to:
  /// **'You have no upcoming classes right now.'**
  String get noUpcomingClasses;

  /// No description provided for @activateAvailability.
  ///
  /// In en, this message translates to:
  /// **'Activate your availability for students to see you.'**
  String get activateAvailability;

  /// No description provided for @termsAcceptedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Terms accepted successfully!'**
  String get termsAcceptedSuccessfully;

  /// No description provided for @errorAcceptingTerms.
  ///
  /// In en, this message translates to:
  /// **'Error accepting terms. Please try again.'**
  String get errorAcceptingTerms;

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link'**
  String get couldNotOpenLink;

  /// No description provided for @tutoriaReady.
  ///
  /// In en, this message translates to:
  /// **'TUTORING READY!'**
  String get tutoriaReady;

  /// No description provided for @tutoriaReadySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Payment was confirmed. Enter the class now!'**
  String get tutoriaReadySubtitle;

  /// No description provided for @fuisteElegido.
  ///
  /// In en, this message translates to:
  /// **'YOU WERE CHOSEN!'**
  String get fuisteElegido;

  /// No description provided for @fuisteElegidoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The student is paying. Tap to see details.'**
  String get fuisteElegidoSubtitle;

  /// No description provided for @solicitudTomada.
  ///
  /// In en, this message translates to:
  /// **'REQUEST ALREADY TAKEN'**
  String get solicitudTomada;

  /// No description provided for @solicitudTomadaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This tutoring has already been assigned to another teacher'**
  String get solicitudTomadaSubtitle;

  /// No description provided for @solicitudExpirada.
  ///
  /// In en, this message translates to:
  /// **'REQUEST EXPIRED'**
  String get solicitudExpirada;

  /// No description provided for @solicitudExpiradaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This invitation is no longer available'**
  String get solicitudExpiradaSubtitle;

  /// No description provided for @nuevaSolicitud.
  ///
  /// In en, this message translates to:
  /// **'NEW REQUEST!'**
  String get nuevaSolicitud;

  /// No description provided for @nuevaSolicitudSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A student needs your help now'**
  String get nuevaSolicitudSubtitle;

  /// No description provided for @unirseAlasClase.
  ///
  /// In en, this message translates to:
  /// **'Enter the Class'**
  String get unirseAlasClase;

  /// No description provided for @verEstadoPago.
  ///
  /// In en, this message translates to:
  /// **'Check Payment Status'**
  String get verEstadoPago;

  /// No description provided for @revisarSolicitud.
  ///
  /// In en, this message translates to:
  /// **'Review Request'**
  String get revisarSolicitud;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String greeting(String name);

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'VERIFIED'**
  String get verified;

  /// No description provided for @unverified.
  ///
  /// In en, this message translates to:
  /// **'UNVERIFIED'**
  String get unverified;

  /// No description provided for @agendaTitle.
  ///
  /// In en, this message translates to:
  /// **'SCHEDULE'**
  String get agendaTitle;

  /// No description provided for @myClasses.
  ///
  /// In en, this message translates to:
  /// **'MY CLASSES'**
  String get myClasses;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'AVAILABILITY'**
  String get availability;

  /// No description provided for @myNextClasses.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Bookings'**
  String get myNextClasses;

  /// No description provided for @configureSchedule.
  ///
  /// In en, this message translates to:
  /// **'CONFIGURE SCHEDULES'**
  String get configureSchedule;

  /// No description provided for @selectedDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} day selected} other{{count} days selected}}'**
  String selectedDays(int count);

  /// No description provided for @scheduleAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Schedule added successfully'**
  String get scheduleAddedSuccessfully;

  /// No description provided for @errorSavingSchedule.
  ///
  /// In en, this message translates to:
  /// **'Error saving schedule'**
  String get errorSavingSchedule;

  /// No description provided for @freeDay.
  ///
  /// In en, this message translates to:
  /// **'FREE DAY'**
  String get freeDay;

  /// No description provided for @noClassesTodayMessage.
  ///
  /// In en, this message translates to:
  /// **'You have no classes scheduled today.\nTake a break!'**
  String get noClassesTodayMessage;

  /// No description provided for @daysSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day selected} other{{count} days selected}}'**
  String daysSelected(num count);

  /// No description provided for @subjectsTitle.
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get subjectsTitle;

  /// No description provided for @subjectsManagement.
  ///
  /// In en, this message translates to:
  /// **'SUBJECTS MANAGEMENT'**
  String get subjectsManagement;

  /// No description provided for @youHaveSubjects.
  ///
  /// In en, this message translates to:
  /// **'You have {count, plural, =1{{count} subject} other{{count} subjects}}'**
  String youHaveSubjects(int count);

  /// No description provided for @noSubjectsYet.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added any subjects yet.'**
  String get noSubjectsYet;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No results found.'**
  String get noSearchResults;

  /// No description provided for @subjectAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'You already have this subject'**
  String get subjectAlreadyAdded;

  /// No description provided for @subjectAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'The subject \"{name}\" was added successfully.'**
  String subjectAddedSuccess(String name);

  /// No description provided for @subjectAddedError.
  ///
  /// In en, this message translates to:
  /// **'Could not add \"{name}\". Try again.'**
  String subjectAddedError(String name);

  /// No description provided for @subjectDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Subject \"{name}\" deleted successfully.'**
  String subjectDeletedSuccess(String name);

  /// No description provided for @subjectDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting \"{name}\". Try again.'**
  String subjectDeleteError(String name);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'MY PROFILE'**
  String get profileTitle;

  /// No description provided for @videoProfile.
  ///
  /// In en, this message translates to:
  /// **'VIDEO'**
  String get videoProfile;

  /// No description provided for @legalSection.
  ///
  /// In en, this message translates to:
  /// **'LEGAL'**
  String get legalSection;

  /// No description provided for @mustAcceptTerms.
  ///
  /// In en, this message translates to:
  /// **'You must accept the terms and conditions'**
  String get mustAcceptTerms;

  /// No description provided for @youMustAcceptTerms.
  ///
  /// In en, this message translates to:
  /// **'You must accept the terms and conditions to continue'**
  String get youMustAcceptTerms;

  /// No description provided for @logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'LOGOUT'**
  String get logoutTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of your Tutor account?'**
  String get logoutConfirmMessage;

  /// No description provided for @logoutButton.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get logoutButton;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @logoutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Session closed successfully.'**
  String get logoutSuccess;

  /// No description provided for @configureQR.
  ///
  /// In en, this message translates to:
  /// **'Configure QR Code'**
  String get configureQR;

  /// No description provided for @speedUpPayments.
  ///
  /// In en, this message translates to:
  /// **'Speed up your payments'**
  String get speedUpPayments;

  /// No description provided for @qrDescription.
  ///
  /// In en, this message translates to:
  /// **'Upload your banking QR code to receive your payments quickly and securely.'**
  String get qrDescription;

  /// No description provided for @noQRCode.
  ///
  /// In en, this message translates to:
  /// **'No QR Code'**
  String get noQRCode;

  /// No description provided for @changeQRCode.
  ///
  /// In en, this message translates to:
  /// **'Change QR Code'**
  String get changeQRCode;

  /// No description provided for @deleteQRCode.
  ///
  /// In en, this message translates to:
  /// **'Delete QR Code'**
  String get deleteQRCode;

  /// No description provided for @uploadQRCode.
  ///
  /// In en, this message translates to:
  /// **'Upload QR Code'**
  String get uploadQRCode;

  /// No description provided for @deleteQRConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete QR?'**
  String get deleteQRConfirmTitle;

  /// No description provided for @deleteQRConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'If you delete your QR, students won\'t be able to make direct payments until you upload a new one.'**
  String get deleteQRConfirmMessage;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @qrUploadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'QR uploaded successfully!'**
  String get qrUploadedSuccessfully;

  /// No description provided for @qrDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'QR deleted successfully'**
  String get qrDeletedSuccessfully;

  /// No description provided for @errorUploadingQR.
  ///
  /// In en, this message translates to:
  /// **'Error uploading image'**
  String get errorUploadingQR;

  /// No description provided for @errorSelectingImage.
  ///
  /// In en, this message translates to:
  /// **'Error selecting image'**
  String get errorSelectingImage;

  /// No description provided for @errorLoadingQR.
  ///
  /// In en, this message translates to:
  /// **'Error loading'**
  String get errorLoadingQR;

  /// No description provided for @closeQRViewer.
  ///
  /// In en, this message translates to:
  /// **'Close QR'**
  String get closeQRViewer;

  /// No description provided for @searchByTutorHint.
  ///
  /// In en, this message translates to:
  /// **'Search by tutor...'**
  String get searchByTutorHint;

  /// No description provided for @searchBySubjectHint.
  ///
  /// In en, this message translates to:
  /// **'Search by subject...'**
  String get searchBySubjectHint;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @topRated.
  ///
  /// In en, this message translates to:
  /// **'Top Rated'**
  String get topRated;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @reviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =0{0 reviews} =1{1 review} other{{count} reviews}}'**
  String reviewsCount(int count);

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @pressBackAgainToExit.
  ///
  /// In en, this message translates to:
  /// **'Press back button again to exit'**
  String get pressBackAgainToExit;

  /// No description provided for @subjectsTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get subjectsTabTitle;

  /// No description provided for @subjectsTabSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Here you will see all the subjects you are studying'**
  String get subjectsTabSubtitle;

  /// No description provided for @homeNavigation.
  ///
  /// In en, this message translates to:
  /// **'HOME'**
  String get homeNavigation;

  /// No description provided for @scheduleNavigation.
  ///
  /// In en, this message translates to:
  /// **'SCHEDULE'**
  String get scheduleNavigation;

  /// No description provided for @subjectsNavigation.
  ///
  /// In en, this message translates to:
  /// **'SUBJECTS'**
  String get subjectsNavigation;

  /// No description provided for @profileNavigation.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get profileNavigation;

  /// No description provided for @dayLabel.
  ///
  /// In en, this message translates to:
  /// **'DAY'**
  String get dayLabel;

  /// No description provided for @monthLabel.
  ///
  /// In en, this message translates to:
  /// **'MONTH'**
  String get monthLabel;

  /// No description provided for @withoutScheduleToday.
  ///
  /// In en, this message translates to:
  /// **'NO SCHEDULES TODAY'**
  String get withoutScheduleToday;

  /// No description provided for @withoutScheduleThisMonth.
  ///
  /// In en, this message translates to:
  /// **'NO SCHEDULES THIS MONTH'**
  String get withoutScheduleThisMonth;

  /// No description provided for @workingHours.
  ///
  /// In en, this message translates to:
  /// **'Working Hours'**
  String get workingHours;

  /// No description provided for @defineRangeSelectedDays.
  ///
  /// In en, this message translates to:
  /// **'Define the range for the selected days'**
  String get defineRangeSelectedDays;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'STARTS'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'ENDS'**
  String get endTime;

  /// No description provided for @confirmSchedule.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM SCHEDULE'**
  String get confirmSchedule;

  /// No description provided for @scheduleConfiguredSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Working schedule configured successfully'**
  String get scheduleConfiguredSuccessfully;

  /// No description provided for @couldNotSaveSchedule.
  ///
  /// In en, this message translates to:
  /// **'Could not save schedule. Try again.'**
  String get couldNotSaveSchedule;

  /// No description provided for @scheduleDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Schedule deleted successfully'**
  String get scheduleDeletedSuccessfully;

  /// No description provided for @errorDeletingSchedule.
  ///
  /// In en, this message translates to:
  /// **'Error deleting schedule. Check your connection.'**
  String get errorDeletingSchedule;

  /// No description provided for @endTimeGreaterThanStart.
  ///
  /// In en, this message translates to:
  /// **'End time must be greater than start time'**
  String get endTimeGreaterThanStart;

  /// No description provided for @addSchedule.
  ///
  /// In en, this message translates to:
  /// **'ADD'**
  String get addSchedule;

  /// No description provided for @hourlySchedule.
  ///
  /// In en, this message translates to:
  /// **'SCHEDULE'**
  String get hourlySchedule;

  /// No description provided for @calendarLabel.
  ///
  /// In en, this message translates to:
  /// **'CALENDAR'**
  String get calendarLabel;

  /// No description provided for @rangeMode.
  ///
  /// In en, this message translates to:
  /// **'RANGE MODE'**
  String get rangeMode;

  /// No description provided for @rangeActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE RANGE'**
  String get rangeActive;

  /// No description provided for @multipleSelection.
  ///
  /// In en, this message translates to:
  /// **'MULTIPLE SELECTION'**
  String get multipleSelection;

  /// No description provided for @dayActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE DAY'**
  String get dayActive;

  /// No description provided for @acceptButton.
  ///
  /// In en, this message translates to:
  /// **'ACCEPT'**
  String get acceptButton;

  /// No description provided for @configureSchedulesButton.
  ///
  /// In en, this message translates to:
  /// **'CONFIGURE SCHEDULES'**
  String get configureSchedulesButton;

  /// No description provided for @cancelModal.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancelModal;

  /// No description provided for @selectRange.
  ///
  /// In en, this message translates to:
  /// **'SELECT A RANGE'**
  String get selectRange;

  /// No description provided for @selectedDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'SELECTED DAYS'**
  String get selectedDaysLabel;

  /// No description provided for @dayBlocksLabel.
  ///
  /// In en, this message translates to:
  /// **'DAY BLOCKS'**
  String get dayBlocksLabel;

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'CLEAR'**
  String get clearSelection;

  /// No description provided for @noBlocksRegistered.
  ///
  /// In en, this message translates to:
  /// **'NO BLOCKS REGISTERED'**
  String get noBlocksRegistered;

  /// No description provided for @readyToConfigureSchedules.
  ///
  /// In en, this message translates to:
  /// **'READY TO CONFIGURE SCHEDULES'**
  String get readyToConfigureSchedules;

  /// No description provided for @deleteScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete schedule'**
  String get deleteScheduleTitle;

  /// No description provided for @deleteScheduleConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this schedule?'**
  String get deleteScheduleConfirm;

  /// No description provided for @cancelDialogButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelDialogButton;

  /// No description provided for @deleteButton2.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton2;

  /// No description provided for @scheduleDeletedSuccessfully2.
  ///
  /// In en, this message translates to:
  /// **'Schedule deleted successfully'**
  String get scheduleDeletedSuccessfully2;

  /// No description provided for @errorDeletingScheduleMsg.
  ///
  /// In en, this message translates to:
  /// **'Error deleting schedule'**
  String get errorDeletingScheduleMsg;

  /// No description provided for @sessionDuration.
  ///
  /// In en, this message translates to:
  /// **'20 MIN SESSION'**
  String get sessionDuration;

  /// No description provided for @configureSchedulesCount.
  ///
  /// In en, this message translates to:
  /// **'CONFIGURE SCHEDULES'**
  String get configureSchedulesCount;

  /// No description provided for @previousDay.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get previousDay;

  /// No description provided for @nextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get nextDay;

  /// No description provided for @instantTutoring.
  ///
  /// In en, this message translates to:
  /// **'Instant tutoring,'**
  String get instantTutoring;

  /// No description provided for @multiplyYourClasses.
  ///
  /// In en, this message translates to:
  /// **'multiply your classes'**
  String get multiplyYourClasses;

  /// No description provided for @receiveTutoringRequests.
  ///
  /// In en, this message translates to:
  /// **'Receive tutoring requests from students in real-time. Accept the regulatory terms to enable your push alerts and start teaching instantly.'**
  String get receiveTutoringRequests;

  /// No description provided for @iHaveReadAndAccept.
  ///
  /// In en, this message translates to:
  /// **'I have read and accept the '**
  String get iHaveReadAndAccept;

  /// No description provided for @acceptAndContinue.
  ///
  /// In en, this message translates to:
  /// **'ACCEPT AND CONTINUE'**
  String get acceptAndContinue;

  /// No description provided for @withStudent.
  ///
  /// In en, this message translates to:
  /// **'with'**
  String get withStudent;

  /// No description provided for @deleteSubject.
  ///
  /// In en, this message translates to:
  /// **'Delete subject'**
  String get deleteSubject;

  /// No description provided for @deleteSubjectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this subject?'**
  String get deleteSubjectConfirm;

  /// No description provided for @subjectDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Subject deleted successfully'**
  String get subjectDeletedSuccessfully;

  /// No description provided for @errorDeletingSubject.
  ///
  /// In en, this message translates to:
  /// **'Error deleting the subject'**
  String get errorDeletingSubject;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get invalidEmail;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPassword;

  /// No description provided for @enterEmailToReset.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to reset your account password.'**
  String get enterEmailToReset;

  /// No description provided for @verifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify your email!'**
  String get verifyEmail;

  /// No description provided for @verificationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'We sent you a verification email to:'**
  String get verificationEmailSent;

  /// No description provided for @resendVerificationEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend verification email'**
  String get resendVerificationEmail;

  /// No description provided for @checkInboxAndClick.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox and click the link to activate your account.'**
  String get checkInboxAndClick;

  /// No description provided for @backToRegistration.
  ///
  /// In en, this message translates to:
  /// **'Back to registration'**
  String get backToRegistration;

  /// No description provided for @enterFirstName.
  ///
  /// In en, this message translates to:
  /// **'Enter your first name'**
  String get enterFirstName;

  /// No description provided for @enterLastName.
  ///
  /// In en, this message translates to:
  /// **'Enter your last name'**
  String get enterLastName;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterPhoneNumber;

  /// No description provided for @invalidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get invalidPhoneNumber;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter a password'**
  String get enterPassword;

  /// No description provided for @passwordMinChars.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters'**
  String get passwordMinChars;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords must match'**
  String get passwordsDontMatch;

  /// No description provided for @acceptTermsAndPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Accept terms and privacy to continue'**
  String get acceptTermsAndPrivacy;

  /// No description provided for @successfulRegistration.
  ///
  /// In en, this message translates to:
  /// **'Successful registration, verify your email'**
  String get successfulRegistration;

  /// No description provided for @failedToRegister.
  ///
  /// In en, this message translates to:
  /// **'Could not register'**
  String get failedToRegister;

  /// No description provided for @secureConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Secure connection error. Check your internet connection.'**
  String get secureConnectionError;

  /// No description provided for @serverConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to server. Check your internet connection.'**
  String get serverConnectionError;

  /// No description provided for @home_nav.
  ///
  /// In en, this message translates to:
  /// **'HOME'**
  String get home_nav;

  /// No description provided for @schedule_nav.
  ///
  /// In en, this message translates to:
  /// **'SCHEDULE'**
  String get schedule_nav;

  /// No description provided for @favorites_nav.
  ///
  /// In en, this message translates to:
  /// **'FAVORITES'**
  String get favorites_nav;

  /// No description provided for @profile_nav.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get profile_nav;

  /// No description provided for @loadingVideo.
  ///
  /// In en, this message translates to:
  /// **'Loading video...'**
  String get loadingVideo;

  /// No description provided for @thisMayTakeFewSeconds.
  ///
  /// In en, this message translates to:
  /// **'This may take a few seconds'**
  String get thisMayTakeFewSeconds;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCache;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @errorUpdatingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error updating profile'**
  String get errorUpdatingProfile;

  /// No description provided for @invoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoices;

  /// No description provided for @noInvoices.
  ///
  /// In en, this message translates to:
  /// **'No invoices'**
  String get noInvoices;

  /// No description provided for @couldNotGetUserToken.
  ///
  /// In en, this message translates to:
  /// **'Could not get user token.'**
  String get couldNotGetUserToken;

  /// No description provided for @errorResendingEmail.
  ///
  /// In en, this message translates to:
  /// **'Error resending email'**
  String get errorResendingEmail;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @viewFullDetails.
  ///
  /// In en, this message translates to:
  /// **'View full details'**
  String get viewFullDetails;

  /// No description provided for @joinSession.
  ///
  /// In en, this message translates to:
  /// **'Join session'**
  String get joinSession;

  /// No description provided for @confirmPasswordPrompt.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordPrompt;

  /// No description provided for @registerWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Register with Google'**
  String get registerWithGoogle;

  /// No description provided for @createYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createYourAccount;

  /// No description provided for @registerAsStudentOrTutor.
  ///
  /// In en, this message translates to:
  /// **'Register as a student or tutor and start your educational journey with us.'**
  String get registerAsStudentOrTutor;

  /// No description provided for @signUpWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign up with Google'**
  String get signUpWithGoogle;

  /// No description provided for @authGoogleSelectRole.
  ///
  /// In en, this message translates to:
  /// **'Select how you want to register on ClassGo'**
  String get authGoogleSelectRole;

  /// No description provided for @iHaveReadAndAgreeToAll.
  ///
  /// In en, this message translates to:
  /// **'I have read and agree to all '**
  String get iHaveReadAndAgreeToAll;

  /// No description provided for @andWord.
  ///
  /// In en, this message translates to:
  /// **'and '**
  String get andWord;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @alreadyHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAnAccount;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @successfulUserRegistration.
  ///
  /// In en, this message translates to:
  /// **'Successful user registration'**
  String get successfulUserRegistration;

  /// No description provided for @couldNotObtainGoogleToken.
  ///
  /// In en, this message translates to:
  /// **'Could not obtain Google token'**
  String get couldNotObtainGoogleToken;

  /// No description provided for @errorRegisteringWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Error registering with Google'**
  String get errorRegisteringWithGoogle;

  /// No description provided for @registrationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration successful, verify your email'**
  String get registrationSuccess;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @nombres.
  ///
  /// In en, this message translates to:
  /// **'First names'**
  String get nombres;

  /// No description provided for @apellidos.
  ///
  /// In en, this message translates to:
  /// **'Last names'**
  String get apellidos;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'CALENDAR'**
  String get calendar;

  /// No description provided for @filterSubjects.
  ///
  /// In en, this message translates to:
  /// **'Filter subjects...'**
  String get filterSubjects;

  /// No description provided for @selectInstitutionType.
  ///
  /// In en, this message translates to:
  /// **'Select institution type'**
  String get selectInstitutionType;

  /// No description provided for @selectSubject.
  ///
  /// In en, this message translates to:
  /// **'Select a subject'**
  String get selectSubject;

  /// No description provided for @selectedDate.
  ///
  /// In en, this message translates to:
  /// **'Selected Date: {date}'**
  String selectedDate(String date);

  /// No description provided for @noSubjects.
  ///
  /// In en, this message translates to:
  /// **'No subjects'**
  String get noSubjects;

  /// No description provided for @createNewReservationModal.
  ///
  /// In en, this message translates to:
  /// **'Create new reservation'**
  String get createNewReservationModal;

  /// No description provided for @selectInstitutionTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Select institution type'**
  String get selectInstitutionTypeHint;

  /// No description provided for @selectMatterHint.
  ///
  /// In en, this message translates to:
  /// **'Select a subject'**
  String get selectMatterHint;

  /// No description provided for @withoutTime.
  ///
  /// In en, this message translates to:
  /// **'Without time'**
  String get withoutTime;

  /// No description provided for @reservationDetails.
  ///
  /// In en, this message translates to:
  /// **'Reservation Details'**
  String get reservationDetails;

  /// No description provided for @id.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get id;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @meet.
  ///
  /// In en, this message translates to:
  /// **'Meet'**
  String get meet;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @loadingReservations.
  ///
  /// In en, this message translates to:
  /// **'Loading reservations...'**
  String get loadingReservations;

  /// No description provided for @reservationCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 reservation} other{{count} reservations}}'**
  String reservationCount(int count);

  /// No description provided for @noReservationsForThisDay.
  ///
  /// In en, this message translates to:
  /// **'No reservations for this day'**
  String get noReservationsForThisDay;

  /// No description provided for @whatSubjectNeedHelp.
  ///
  /// In en, this message translates to:
  /// **'What subject do\nyou need help with today?'**
  String get whatSubjectNeedHelp;

  /// No description provided for @searchSubjectPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'E.g. Mathematics, English...'**
  String get searchSubjectPlaceholder;

  /// No description provided for @exploreCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore Categories'**
  String get exploreCategoriesTitle;

  /// No description provided for @confirmSearch.
  ///
  /// In en, this message translates to:
  /// **'Confirm Search'**
  String get confirmSearch;

  /// No description provided for @confirmSearchMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to search for an available tutor right now for {subject}?'**
  String confirmSearchMessage(String subject);

  /// No description provided for @yesSearchTutor.
  ///
  /// In en, this message translates to:
  /// **'Yes, Search Tutor'**
  String get yesSearchTutor;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Results ({count})'**
  String searchResults(int count);

  /// No description provided for @noSubjectsFound.
  ///
  /// In en, this message translates to:
  /// **'No subjects found.'**
  String get noSubjectsFound;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error.'**
  String get connectionError;

  /// No description provided for @activeTutoring.
  ///
  /// In en, this message translates to:
  /// **'Active Tutoring'**
  String get activeTutoring;

  /// No description provided for @primary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get primary;

  /// No description provided for @secondary.
  ///
  /// In en, this message translates to:
  /// **'Secondary'**
  String get secondary;

  /// No description provided for @exactSciences.
  ///
  /// In en, this message translates to:
  /// **'Exact Sciences'**
  String get exactSciences;

  /// No description provided for @advancedEngineering.
  ///
  /// In en, this message translates to:
  /// **'Advanced Engineering'**
  String get advancedEngineering;

  /// No description provided for @socialAndEconomicSciences.
  ///
  /// In en, this message translates to:
  /// **'Social and Economic Sciences'**
  String get socialAndEconomicSciences;

  /// No description provided for @languages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languages;

  /// No description provided for @marketingAndDigitalCommunication.
  ///
  /// In en, this message translates to:
  /// **'Marketing and Digital Communication'**
  String get marketingAndDigitalCommunication;

  /// No description provided for @artAndDesign.
  ///
  /// In en, this message translates to:
  /// **'Art and Design'**
  String get artAndDesign;

  /// No description provided for @gastronomyAndPastry.
  ///
  /// In en, this message translates to:
  /// **'Gastronomy and Pastry'**
  String get gastronomyAndPastry;

  /// No description provided for @engineeringAndTechnology.
  ///
  /// In en, this message translates to:
  /// **'Engineering and Technology'**
  String get engineeringAndTechnology;

  /// No description provided for @psychologyAndPersonalDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Psychology and Personal Development'**
  String get psychologyAndPersonalDevelopment;

  /// No description provided for @sportsAndWellness.
  ///
  /// In en, this message translates to:
  /// **'Sports and Wellness'**
  String get sportsAndWellness;

  /// No description provided for @searchingForTutors.
  ///
  /// In en, this message translates to:
  /// **'Searching for tutors...'**
  String get searchingForTutors;

  /// No description provided for @timeoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Time\'s up. No tutors available.'**
  String get timeoutMessage;

  /// No description provided for @resumingActiveTutoring.
  ///
  /// In en, this message translates to:
  /// **'Resuming your active tutoring'**
  String get resumingActiveTutoring;

  /// No description provided for @tutorsReady.
  ///
  /// In en, this message translates to:
  /// **'Ready Tutors'**
  String get tutorsReady;

  /// No description provided for @tutorsResponded.
  ///
  /// In en, this message translates to:
  /// **'They have responded to your request for {subject}.'**
  String tutorsResponded(String subject);

  /// No description provided for @confirmingTutor.
  ///
  /// In en, this message translates to:
  /// **'Confirming tutor...'**
  String get confirmingTutor;

  /// No description provided for @newRequest.
  ///
  /// In en, this message translates to:
  /// **'New Request'**
  String get newRequest;

  /// No description provided for @myVideo.
  ///
  /// In en, this message translates to:
  /// **'My Video'**
  String get myVideo;

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// No description provided for @videoLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load video'**
  String get videoLoadError;

  /// No description provided for @agendaSegment.
  ///
  /// In en, this message translates to:
  /// **'Agenda'**
  String get agendaSegment;

  /// No description provided for @materialSupport.
  ///
  /// In en, this message translates to:
  /// **'Material de apoyo'**
  String get materialSupport;

  /// No description provided for @attachMaterial.
  ///
  /// In en, this message translates to:
  /// **'Attach material'**
  String get attachMaterial;

  /// No description provided for @downloadOrShare.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadOrShare;

  /// No description provided for @deleteMaterial.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteMaterial;

  /// No description provided for @editMaterial.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editMaterial;

  /// No description provided for @noAttachedMaterial.
  ///
  /// In en, this message translates to:
  /// **'No material attached.'**
  String get noAttachedMaterial;

  /// No description provided for @noTutoringMaterial.
  ///
  /// In en, this message translates to:
  /// **'Select a tutoring session to see its materials.'**
  String get noTutoringMaterial;

  /// No description provided for @attachFile.
  ///
  /// In en, this message translates to:
  /// **'Attach file'**
  String get attachFile;

  /// No description provided for @selectFile.
  ///
  /// In en, this message translates to:
  /// **'Select file'**
  String get selectFile;

  /// No description provided for @materialDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'What is this material about?'**
  String get materialDescriptionLabel;

  /// No description provided for @materialDescriptionPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Example: practice exercises I have trouble solving...'**
  String get materialDescriptionPlaceholder;

  /// No description provided for @attachmentsForSession.
  ///
  /// In en, this message translates to:
  /// **'Files attached for this session'**
  String get attachmentsForSession;

  /// No description provided for @tutoringDetails.
  ///
  /// In en, this message translates to:
  /// **'Tutoring details'**
  String get tutoringDetails;

  /// No description provided for @timeConnector.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get timeConnector;

  /// No description provided for @materialOptionalNote.
  ///
  /// In en, this message translates to:
  /// **'Attaching support material is optional.'**
  String get materialOptionalNote;

  /// No description provided for @savedStatus.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedStatus;

  /// No description provided for @statusNotCompleted.
  ///
  /// In en, this message translates to:
  /// **'Not completed'**
  String get statusNotCompleted;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @noMaterialsAttached.
  ///
  /// In en, this message translates to:
  /// **'No materials attached'**
  String get noMaterialsAttached;

  /// No description provided for @materialsAttached.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} material attached} other{{count} materials attached}}'**
  String materialsAttached(int count);

  /// No description provided for @tapCardToSeeDetails.
  ///
  /// In en, this message translates to:
  /// **'Tap the card to see details or attach files.'**
  String get tapCardToSeeDetails;

  /// No description provided for @tutorLabel.
  ///
  /// In en, this message translates to:
  /// **'Tutor: '**
  String get tutorLabel;

  /// No description provided for @studentLabel.
  ///
  /// In en, this message translates to:
  /// **'Student: '**
  String get studentLabel;

  /// No description provided for @maxSize5Mb.
  ///
  /// In en, this message translates to:
  /// **'PDF, DOCX, XLSX, JPG, PNG (Max 5 MB)'**
  String get maxSize5Mb;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @fileNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This file type is not allowed.'**
  String get fileNotAllowed;

  /// No description provided for @fileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The file exceeds the 5 MB limit.'**
  String get fileTooLarge;

  /// No description provided for @descriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Please write a short description.'**
  String get descriptionRequired;

  /// No description provided for @descriptionMinLength.
  ///
  /// In en, this message translates to:
  /// **'The description must be at least 2 characters.'**
  String get descriptionMinLength;

  /// No description provided for @descriptionMaxLength.
  ///
  /// In en, this message translates to:
  /// **'The description must not exceed 500 characters.'**
  String get descriptionMaxLength;

  /// No description provided for @deleteMaterialConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this material?'**
  String get deleteMaterialConfirm;

  /// No description provided for @deleteMaterialDescription.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteMaterialDescription;

  /// No description provided for @editMaterialDescription.
  ///
  /// In en, this message translates to:
  /// **'Update the description or replace the file.'**
  String get editMaterialDescription;

  /// No description provided for @materialDeleted.
  ///
  /// In en, this message translates to:
  /// **'Material deleted.'**
  String get materialDeleted;

  /// No description provided for @materialSaved.
  ///
  /// In en, this message translates to:
  /// **'Material saved.'**
  String get materialSaved;

  /// No description provided for @loadingMaterials.
  ///
  /// In en, this message translates to:
  /// **'Loading materials...'**
  String get loadingMaterials;

  /// No description provided for @sharingFile.
  ///
  /// In en, this message translates to:
  /// **'Downloading file...'**
  String get sharingFile;

  /// No description provided for @downloadedFile.
  ///
  /// In en, this message translates to:
  /// **'File downloaded'**
  String get downloadedFile;

  /// No description provided for @alreadyDownloaded.
  ///
  /// In en, this message translates to:
  /// **'File already downloaded'**
  String get alreadyDownloaded;

  /// No description provided for @downloadingFile.
  ///
  /// In en, this message translates to:
  /// **'Downloading file...'**
  String get downloadingFile;

  /// No description provided for @noAppToOpenFile.
  ///
  /// In en, this message translates to:
  /// **'There is no app to open this file'**
  String get noAppToOpenFile;

  /// No description provided for @noMaterialSelected.
  ///
  /// In en, this message translates to:
  /// **'Drag a file or click here to select it'**
  String get noMaterialSelected;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
