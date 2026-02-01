import SwiftUI

/// Enum representing each step in the signup flow
enum SignUpStep: Int, CaseIterable {
    case phone = 0
    case verification = 1
    case welcome = 2
    case country = 3
    case name = 4
    case birthday = 5
    case reviewTerms = 6
    
    var progress: CGFloat {
        CGFloat(rawValue + 1) / CGFloat(SignUpStep.allCases.count)
    }
}

/// Container view that manages the signup flow with slide transitions
struct SignUpFlowView: View {
    @ObservedObject private var themeService = ThemeService.shared
    @Binding var isComplete: Bool
    var startStep: SignUpStep = .phone
    
    @StateObject private var signUpData = SignUpData()
    @State private var currentStep: SignUpStep
    @State private var previousStep: SignUpStep
    
    init(isComplete: Binding<Bool>, startStep: SignUpStep = .phone) {
        self._isComplete = isComplete
        self.startStep = startStep
        // Initialize state with startStep to avoid flashing phone screen
        self._currentStep = State(initialValue: startStep)
        self._previousStep = State(initialValue: startStep)
    }
    @Environment(\.dismiss) private var dismiss
    @State private var hasInitialized = false
    
    // Name validation state
    @State private var isValidatingName = false
    @State private var nameValidationError: String?
    @State private var shouldTriggerNameValidation = false
    
    // Debug stage picker
    @State private var showStagePicker = false
    
    // Determine if we're moving forward (right) or backward (left)
    private var isMovingForward: Bool {
        currentStep.rawValue > previousStep.rawValue
    }
    
    // Asymmetric transition based on direction
    private var stepTransition: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .opacity.combined(with: .offset(x: isMovingForward ? 50 : -50)),
            removal: .opacity.combined(with: .offset(x: isMovingForward ? -50 : 50))
        )
    }
    
    // Button configuration for each step
    private var buttonSubtitle: String? {
        currentStep == .welcome ? "Most people finish within 8 minutes" : nil
    }
    
    private var canContinue: Bool {
        switch currentStep {
        case .phone:
            return signUpData.phoneNumber.filter { $0.isNumber }.count >= 6
        case .verification:
            return signUpData.verificationCode.count == 6
        case .welcome:
            return true
        case .country:
            return !signUpData.country.isEmpty
        case .name:
            return !signUpData.firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
                   !signUpData.lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
                   !isValidatingName
        case .birthday:
            return signUpData.isBirthdayValid
        case .reviewTerms:
            return signUpData.useESignature
        }
    }
    
    private var buttonDisplayTitle: String {
        if currentStep == .name && isValidatingName {
            return "Checking..."
        }
        if currentStep == .reviewTerms {
            return "I agree"
        }
        return "Next"
    }
    
    private func handleNextAction() {
        switch currentStep {
        case .phone:
            goToStep(.verification)
        case .verification:
            goToStep(.welcome)
        case .welcome:
            goToStep(.country)
        case .country:
            goToStep(.name)
        case .name:
            // Trigger validation - the content view will handle the actual validation
            shouldTriggerNameValidation = true
        case .birthday:
            goToStep(.reviewTerms)
        case .reviewTerms:
            signUpData.hasAcceptedTerms = true
            AnalyticsService.shared.track("signup_completed")
            isComplete = true
        }
    }
    
    var body: some View {
        ZStack {
            themeService.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Static header - doesn't animate
                SignUpStepHeader(
                    progress: currentStep.progress,
                    onBack: {
                        if currentStep == .phone {
                            dismiss()
                        } else {
                            goBack()
                        }
                    },
                    onSkip: {
                        // Skip sign-up for development
                        AnalyticsService.shared.track("signup_skipped", properties: ["method": "header_button"])
                        isComplete = true
                    },
                    onLongPress: {
                        // Show stage picker
                        withAnimation(.easeOut(duration: 0.25)) {
                            showStagePicker = true
                        }
                    },
                    onProgressTap: {
                        // Show stage picker when progress bar is tapped
                        withAnimation(.easeOut(duration: 0.25)) {
                            showStagePicker = true
                        }
                    }
                )
                
                // Animated content area
                ZStack {
                    switch currentStep {
                    case .phone:
                        SignUpPhoneContent(signUpData: signUpData)
                            .transition(stepTransition)
                        
                    case .verification:
                        SignUpVerificationContent(signUpData: signUpData)
                            .transition(stepTransition)
                        
                    case .welcome:
                        SignUpWelcomeContent()
                            .transition(stepTransition)
                        
                    case .country:
                        SignUpCountryContent(signUpData: signUpData, onCountrySelected: {
                            goToStep(.name)
                        })
                            .transition(stepTransition)
                        
                    case .name:
                        SignUpNameContent(
                            signUpData: signUpData,
                            validationTrigger: $shouldTriggerNameValidation,
                            onValidationStateChanged: { isValidating, error in
                                isValidatingName = isValidating
                                nameValidationError = error
                            },
                            onValidatedContinue: {
                                goToStep(.birthday)
                            }
                        )
                        .transition(stepTransition)
                        
                    case .birthday:
                        SignUpBirthdayContent(signUpData: signUpData)
                            .transition(stepTransition)
                    
                    case .reviewTerms:
                        SignUpReviewTermsContent(signUpData: signUpData)
                            .transition(stepTransition)
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: currentStep)
            }
            
            // Static bottom button - doesn't animate with content (hidden on country step)
            if currentStep != .country {
                VStack {
                    Spacer()
                    SignUpBottomButton(
                        title: buttonDisplayTitle,
                        isEnabled: canContinue,
                        action: handleNextAction,
                        subtitle: buttonSubtitle
                    )
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // State is now initialized in init(), no need to set here
            hasInitialized = true
        }
        .overlay {
            if showStagePicker {
                SignUpStagePicker(
                    currentStep: currentStep,
                    onSelectStep: { step in
                        // Navigate to new screen - picker handles its own fade-out and dismissal
                        goToStep(step)
                    },
                    onDismiss: {
                        showStagePicker = false
                    },
                    onSkipToHome: {
                        showStagePicker = false
                        isComplete = true
                    }
                )
            }
        }
    }
    
    private func goBack() {
        let steps = SignUpStep.allCases
        if let currentIndex = steps.firstIndex(of: currentStep), currentIndex > 0 {
            previousStep = currentStep
            currentStep = steps[currentIndex - 1]
        }
    }
    
    private func goToStep(_ step: SignUpStep) {
        // Track step transition
        AnalyticsService.shared.trackSignUpStep(String(describing: currentStep), completed: true)
        AnalyticsService.shared.trackSignUpStep(String(describing: step))
        
        previousStep = currentStep
        currentStep = step
    }
}

// MARK: - Content Views (without headers - for animated transitions)

/// Phone entry content
struct SignUpPhoneContent: View {
    @ObservedObject var signUpData: SignUpData
    var disableAutoFocus: Bool = false
    
    @State private var showCountryPicker = false
    @FocusState private var isPhoneFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What's your phone number?")
                        .h2Style()
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("We'll send you a code to verify your number.")
                        .bodyTextStyle()
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
                
                PhoneInputField(
                    countryCode: signUpData.countryCode,
                    countryFlag: signUpData.countryFlag,
                    phoneNumber: $signUpData.phoneNumber,
                    isFocused: $isPhoneFocused,
                    onCountryTap: { showCountryPicker = true }
                )
                .padding(.horizontal, 16)
                
                // Bottom padding for button
                Spacer().frame(height: 150)
            }
        }
        .sheet(isPresented: $showCountryPicker) {
            SignUpCountryPickerSheet(
                signUpData: signUpData,
                isPresented: $showCountryPicker
            )
        }
        .onAppear {
            if !disableAutoFocus {
                isPhoneFocused = true
            }
        }
    }
}

/// Verification code content
struct SignUpVerificationContent: View {
    @ObservedObject private var themeService = ThemeService.shared
    @ObservedObject var signUpData: SignUpData
    var disableAutoFocus: Bool = false
    
    @FocusState private var isCodeFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter verification code")
                        .h2Style()
                        .fixedSize(horizontal: false, vertical: true)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("We sent your code to \(signUpData.formattedPhoneNumber) via SMS.")
                            .bodyTextStyle()
                        
                        HStack(spacing: 0) {
                            Text("Didn't receive a code? ")
                                .font(.custom("Inter-Regular", size: 16))
                                .foregroundColor(themeService.textSecondaryColor)
                            
                            Button(action: { /* Resend */ }) {
                                Text("Request again.")
                                    .font(.custom("Inter-Medium", size: 16))
                                    .foregroundColor(Color(hex: "FF5113"))
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
                
                VerificationCodeInput(code: $signUpData.verificationCode, length: 6, isFocused: $isCodeFocused)
                    .padding(.horizontal, 16)
                
                Spacer().frame(height: 150)
            }
        }
        .onAppear {
            if !disableAutoFocus {
                isCodeFocused = true
            }
        }
    }
}

/// Welcome content
struct SignUpWelcomeContent: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome to Sling, let's get you set up")
                        .h2Style()
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("Signing up should take no more than a few minutes. We need this info to verify your identity and keep your money safe.")
                        .bodyTextStyle()
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
                
                VStack(spacing: 16) {
                    SignUpStepCard(
                        icon: "IconSparkle",
                        title: "About you",
                        duration: "~1m",
                        description: "Answer some questions to help us tailor your experience.",
                        isAssetIcon: true
                    )
                    SignUpStepCard(
                        icon: "IconVerified",
                        title: "Get verified",
                        duration: "~6m",
                        description: "Take a selfie and send a photo of your ID to finish creating your unique account identity.",
                        isAssetIcon: true
                    )
                    SignUpStepCard(
                        icon: "IconWallet",
                        title: "Set up your account",
                        duration: "~1m",
                        description: "Customize your app settings and preferences to suit you.",
                        isAssetIcon: true
                    )
                }
                .padding(.horizontal, 16)
                
                Spacer().frame(height: 170)
            }
        }
    }
}

/// Country selection content
struct SignUpCountryContent: View {
    @ObservedObject var signUpData: SignUpData
    var onCountrySelected: (() -> Void)? = nil
    
    @State private var searchText = ""
    
    private var suggestedCountry: Country? {
        Country.all.first { $0.dialCode == signUpData.countryCode }
    }
    
    private var otherCountries: [Country] {
        let filtered = searchText.isEmpty
            ? Country.all
            : Country.all.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        return filtered.filter { $0.dialCode != signUpData.countryCode }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What country do you live in?")
                    .h2Style()
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("We need this to show you the right features for your location.")
                    .bodyTextStyle()
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
            
            SearchField(text: $searchText, placeholder: "Search countries")
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    if let suggested = suggestedCountry,
                       searchText.isEmpty || suggested.name.localizedCaseInsensitiveContains(searchText) {
                        CountryRow(country: suggested, isSelected: signUpData.country == suggested.name) {
                            selectCountry(suggested)
                        }
                        
                        Divider()
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    
                    ForEach(otherCountries) { country in
                        CountryRow(country: country, isSelected: signUpData.country == country.name) {
                            selectCountry(country)
                        }
                    }
                    
                    Spacer().frame(height: 50)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 16)
            }
        }
    }
    
    private func selectCountry(_ country: Country) {
        signUpData.country = country.name
        signUpData.countryCode = country.dialCode
        signUpData.countryFlag = country.flagAsset
        onCountrySelected?()
    }
}

/// Name entry content
struct SignUpNameContent: View {
    @ObservedObject var signUpData: SignUpData
    @Binding var validationTrigger: Bool
    var onValidationStateChanged: ((Bool, String?) -> Void)? = nil
    var onValidatedContinue: (() -> Void)? = nil
    var disableAutoFocus: Bool = false
    
    @StateObject private var nameValidationService = NameValidationService()
    @FocusState private var focusedField: NameField?
    
    @State private var validationError: String?
    @State private var isValidating = false
    
    enum NameField {
        case firstName, lastName, preferredName
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What's your legal name?")
                        .h2Style()
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("This must match the name on your ID. You can add a preferred name if you like.")
                        .bodyTextStyle()
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
                
                VStack(spacing: 16) {
                    TextFormInput(
                        label: "First name",
                        text: $signUpData.firstName
                    )
                    .focused($focusedField, equals: .firstName)
                    
                    TextFormInput(
                        label: "Last name",
                        text: $signUpData.lastName
                    )
                    .focused($focusedField, equals: .lastName)
                    
                    TextFormInput(
                        label: "Preferred name (optional)",
                        text: $signUpData.preferredName
                    )
                    .focused($focusedField, equals: .preferredName)
                    .onChange(of: signUpData.preferredName) { _, _ in
                        // Clear validation error when user edits preferred name
                        validationError = nil
                        onValidationStateChanged?(false, nil)
                    }
                    
                    // Validation error message
                    if let error = validationError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 14))
                            Text(error)
                                .font(.custom("Inter-Regular", size: 14))
                        }
                        .foregroundColor(Color(hex: "E53935"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer().frame(height: 150)
            }
        }
        .onAppear {
            if !disableAutoFocus {
                focusedField = .firstName
            }
        }
        .onChange(of: isValidating) { _, newValue in
            onValidationStateChanged?(newValue, validationError)
        }
        .onChange(of: validationTrigger) { _, shouldValidate in
            if shouldValidate {
                Task {
                    await validateAndContinue()
                }
            }
        }
    }
    
    /// Validates the preferred name against the legal name using AI
    private func validateAndContinue() async {
        // Reset the trigger immediately
        await MainActor.run {
            validationTrigger = false
        }
        
        // If no preferred name, skip validation and proceed
        let trimmedPreferred = signUpData.preferredName.trimmingCharacters(in: .whitespaces)
        if trimmedPreferred.isEmpty {
            await MainActor.run {
                onValidatedContinue?()
            }
            return
        }
        
        // Start validation
        await MainActor.run {
            isValidating = true
            validationError = nil
            onValidationStateChanged?(true, nil)
        }
        
        // Call validation service
        let result = await nameValidationService.validatePreferredName(
            legalFirstName: signUpData.firstName,
            legalLastName: signUpData.lastName,
            preferredName: signUpData.preferredName
        )
        
        await MainActor.run {
            isValidating = false
            
            switch result {
            case .success(let validation):
                if validation.approved {
                    // Validation passed, proceed to next step
                    onValidationStateChanged?(false, nil)
                    onValidatedContinue?()
                } else {
                    // Validation failed, show error
                    validationError = validation.reason
                    onValidationStateChanged?(false, validation.reason)
                }
                
            case .failure(let error):
                // Network or API error - show generic message
                validationError = "Unable to verify name. Please try again."
                onValidationStateChanged?(false, "Unable to verify name. Please try again.")
                print("Name validation error: \(error.localizedDescription)")
            }
        }
    }
}

/// Birthday entry content
struct SignUpBirthdayContent: View {
    @ObservedObject var signUpData: SignUpData
    var disableAutoFocus: Bool = false
    
    @State private var showMonthPicker = false
    @State private var selectedMonthName = ""
    @FocusState private var focusedField: BirthdayField?
    
    enum BirthdayField {
        case day, year
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("When's your birthday?")
                        .h2Style()
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("We need this to verify your identity.")
                        .bodyTextStyle()
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
                
                HStack(spacing: 12) {
                    DateFieldInput(
                        label: "Day",
                        text: $signUpData.birthDay,
                        placeholder: "DD",
                        keyboardType: .numberPad,
                        maxLength: 2
                    )
                    .focused($focusedField, equals: .day)
                    .frame(width: 80)
                    
                    MonthFieldInput(
                        label: "Month",
                        selectedMonth: selectedMonthName,
                        onTap: { showMonthPicker = true }
                    )
                    
                    DateFieldInput(
                        label: "Year",
                        text: $signUpData.birthYear,
                        placeholder: "YYYY",
                        keyboardType: .numberPad,
                        maxLength: 4
                    )
                    .focused($focusedField, equals: .year)
                    .frame(width: 100)
                }
                .padding(.horizontal, 16)
                
                Spacer().frame(height: 150)
            }
        }
        .onAppear {
            if !disableAutoFocus {
                focusedField = .day
            }
        }
        .sheet(isPresented: $showMonthPicker) {
            MonthPickerSheet(selectedMonth: $selectedMonthName, isPresented: $showMonthPicker)
        }
        .onChange(of: selectedMonthName) { _, newValue in
            if let month = Month.all.first(where: { $0.name == newValue }) {
                signUpData.birthMonth = String(month.id)
            }
        }
    }
}

// MARK: - Shared Components

/// Fixed bottom button container for consistent positioning
struct SignUpBottomButton: View {
    @ObservedObject private var themeService = ThemeService.shared
    let title: String
    let isEnabled: Bool
    let action: () -> Void
    var subtitle: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Gradient fade
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.white.opacity(0), location: 0),
                    .init(color: Color.white, location: 0.3)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 40)
            .allowsHitTesting(false)
            
            VStack(spacing: 0) {
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.custom("Inter-Regular", size: 14))
                        .foregroundColor(themeService.textSecondaryColor)
                        .padding(.bottom, 16)
                }
                
                SecondaryButton(title: title, isEnabled: isEnabled, action: action)
                    .padding(.horizontal, 16)
            }
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity)
            .background(Color.white)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

/// Header with progress bar and back button for signup steps
struct SignUpStepHeader: View {
    @ObservedObject private var themeService = ThemeService.shared
    let progress: CGFloat
    let onBack: () -> Void
    var onSkip: (() -> Void)? = nil
    var onLongPress: (() -> Void)? = nil
    var onProgressTap: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            // Centered progress bar - tappable to open stage picker
            ProgressBarView(progress: progress)
                .contentShape(Rectangle())
                .onTapGesture {
                    if let onProgressTap = onProgressTap {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        onProgressTap()
                    }
                }
            
            // Back button on left, skip button on right
            HStack {
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    onBack()
                }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(themeService.textPrimaryColor)
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
                
                // Skip button (for development)
                // Tap to skip, long press to open stage picker
                if onSkip != nil || onLongPress != nil {
                    Text("•••")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(themeService.textPrimaryColor)
                        .frame(width: 44, height: 44)
                        .background(Color(hex: "F7F7F7"))
                        .cornerRadius(12)
                        .onTapGesture {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            onSkip?()
                        }
                        .onLongPressGesture(minimumDuration: 0.5) {
                            let generator = UIImpactFeedbackGenerator(style: .heavy)
                            generator.impactOccurred()
                            onLongPress?()
                        }
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 64)
    }
}

// MARK: - Stage Picker (App Switcher Style)

/// Represents all screens available in the stage picker (including welcome)
enum StagePickerScreen: Int, CaseIterable, Identifiable {
    case welcome = -1
    case phone = 0
    case verification = 1
    case welcomeInfo = 2
    case country = 3
    case name = 4
    case birthday = 5
    case reviewTerms = 6
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .welcome: return "Welcome"
        case .phone: return "Phone"
        case .verification: return "Verify"
        case .welcomeInfo: return "Get Started"
        case .country: return "Country"
        case .name: return "Name"
        case .birthday: return "Birthday"
        case .reviewTerms: return "Terms"
        }
    }
    
    var signUpStep: SignUpStep? {
        switch self {
        case .welcome: return nil
        case .phone: return .phone
        case .verification: return .verification
        case .welcomeInfo: return .welcome
        case .country: return .country
        case .name: return .name
        case .birthday: return .birthday
        case .reviewTerms: return .reviewTerms
        }
    }
}

/// App switcher style view for quickly navigating between sign-up stages
struct SignUpStagePicker: View {
    let currentStep: SignUpStep
    let onSelectStep: (SignUpStep) -> Void
    let onDismiss: () -> Void
    var onSkipToHome: (() -> Void)? = nil
    var isFromWelcome: Bool = false
    
    // Animation progress values (0 to 1)
    @State private var introProgress: CGFloat = 0        // 0 = full screen, 1 = card size
    @State private var cardsVisible: CGFloat = 0         // 0 = hidden, 1 = visible
    @State private var selectionProgress: CGFloat = 0    // 0 = card size, 1 = full screen
    @State private var selectedScreen: StagePickerScreen? = nil
    @State private var isReady: Bool = false             // Prevents jolt on first frame
    
    // Fixed card dimensions - never change during animation
    private let cardWidth: CGFloat = 300
    private let cardHeight: CGFloat = 300 * (852 / 393)
    
    // Current screen for animation origin
    private var currentScreen: StagePickerScreen {
        if isFromWelcome {
            return .welcome
        }
        return StagePickerScreen.allCases.first { $0.signUpStep == currentStep } ?? .phone
    }
    
    // Spring animation for smooth motion - tuned to match iOS app switcher feel
    private let smoothSpring = Animation.spring(response: 0.45, dampingFraction: 0.82)
    private let quickSpring = Animation.spring(response: 0.35, dampingFraction: 0.78)
    
    var body: some View {
        GeometryReader { geometry in
            let fullScale = geometry.size.width / cardWidth
            
            // Intro: scale from fullScale down to 1
            let introScale = 1 + (fullScale - 1) * (1 - introProgress)
            // Selection: scale from 1 up to fullScale
            let selectionScale = 1 + (fullScale - 1) * selectionProgress
            
            // Corner radius interpolation - 47pt matches iPhone device corners
            let introCornerRadius = 47 * introProgress
            let selectionCornerRadius = 47 * (1 - selectionProgress)
            
            
            ZStack {
                // Blur background - fades with intro, fades out faster during selection
                Rectangle()
                    .fill(.regularMaterial)
                    .environment(\.colorScheme, .dark)
                    .ignoresSafeArea()
                    .opacity(introProgress * max(0, 1 - selectionProgress * 2.5))
                    .onTapGesture {
                        dismissWithAnimation()
                    }
                
                // Main content layer
                ZStack {
                    // During selection: card grows to full screen
                    // During intro: morphing preview card
                    if let selected = selectedScreen {
                        // Growing preview card - scales from card size to full screen
                        VStack(spacing: 10) {
                            // App icon and name - fades out as card grows
                            appHeader(for: selected)
                                .opacity(max(0.0, 1.0 - selectionProgress * 3.0))
                            
                            StageCardPreview(screen: selected)
                                .frame(width: cardWidth, height: cardHeight)
                                .clipShape(RoundedRectangle(cornerRadius: selectionCornerRadius, style: .continuous))
                                .overlay(cardOverlay(cornerRadius: selectionCornerRadius))
                                .scaleEffect(selectionScale)
                                .shadow(color: .black.opacity(0.4 * (1 - selectionProgress)), radius: 30, x: 0, y: 15)
                        }
                        // Fade out preview as it reaches full size to reveal actual screen
                        .opacity(1 - selectionProgress)
                    } else {
                        // Morphing card (only during intro, not selection)
                        let morphScreen = currentScreen
                        let morphCornerRadius = introCornerRadius
                        // Morph card fades out as scroll cards fade in
                        let morphCardOpacity: CGFloat = 1 - cardsVisible
                        
                        VStack(spacing: 10) {
                            // App icon and name
                            appHeader(for: morphScreen)
                                .opacity(introProgress * (1 - cardsVisible))
                            
                            StageCardPreview(screen: morphScreen)
                                .frame(width: cardWidth, height: cardHeight)
                                .clipShape(RoundedRectangle(cornerRadius: morphCornerRadius, style: .continuous))
                                .overlay(cardOverlay(cornerRadius: morphCornerRadius))
                                .scaleEffect(introScale)
                                .shadow(color: .black.opacity(0.5), radius: 40, x: 0, y: 20)
                        }
                        .opacity(morphCardOpacity)
                    }
                    
                    // Scrollable cards view
                    VStack(spacing: 0) {
                        Spacer()
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            ScrollViewReader { proxy in
                                HStack(spacing: 24) {
                                    ForEach(StagePickerScreen.allCases) { screen in
                                        // All cards fade in together
                                        let cardOpacity = cardsVisible
                                        
                                        // Use GeometryReader to get position-based scaling
                                        GeometryReader { cardGeometry in
                                            let screenWidth = geometry.size.width
                                            let cardCenterX = cardGeometry.frame(in: .global).midX
                                            let screenCenterX = screenWidth / 2
                                            let distanceFromCenter: CGFloat = abs(cardCenterX - screenCenterX)
                                            let maxDistance = screenWidth / 2
                                            let normalizedDistance = min(distanceFromCenter / maxDistance, 1.0)
                                            // Scale: 1.0 at center, 0.85 at edges
                                            let positionScale = 1.0 - (normalizedDistance * 0.15)
                                            
                                            VStack(spacing: 10) {
                                                appHeader(for: screen)
                                                    .opacity(positionScale) // Fade header slightly at edges
                                                
                                                StageCardPreview(screen: screen)
                                                    .frame(width: cardWidth, height: cardHeight)
                                                    .clipShape(RoundedRectangle(cornerRadius: 47, style: .continuous))
                                                    .overlay(cardOverlay(cornerRadius: 47))
                                                    .shadow(color: .black.opacity(0.5 * positionScale), radius: 40, x: 0, y: 20)
                                                    .onTapGesture {
                                                        selectScreen(screen)
                                                    }
                                            }
                                            .scaleEffect(positionScale * (0.8 + 0.2 * cardsVisible))
                                            .opacity(cardOpacity)
                                            .frame(width: cardWidth, height: cardHeight + 50) // Account for header
                                        }
                                        .frame(width: cardWidth, height: cardHeight + 50)
                                        .id(screen.rawValue)
                                        .scrollTransition { content, phase in
                                            content
                                                .opacity(phase.isIdentity ? 1 : 0.8)
                                        }
                                    }
                                }
                                .scrollTargetLayout()
                                .padding(.horizontal, (geometry.size.width - cardWidth) / 2)
                                .padding(.top, 20)
                                .padding(.bottom, 80)
                                .onAppear {
                                    proxy.scrollTo(currentScreen.rawValue, anchor: .center)
                                }
                            }
                        }
                        .scrollTargetBehavior(.viewAligned)
                        
                        Spacer()
                    }
                    .opacity(selectedScreen == nil ? 1 : 0)
                }
            }
            .opacity(isReady ? 1 : 0)
            .animation(.easeOut(duration: 0.15), value: isReady)
            .onAppear {
                // Fade in and start animation together
                withAnimation(.easeOut(duration: 0.15)) {
                    isReady = true
                }
                startIntroAnimation()
            }
        }
    }
    
    // MARK: - Subviews
    
    private func appHeader(for screen: StagePickerScreen) -> some View {
        HStack(spacing: 8) {
            Image("SlingLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .background(Color.white)
                .cornerRadius(6)
            
            Text(screen.displayName)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    private func cardOverlay(cornerRadius: CGFloat) -> some View {
        ZStack {
            // Subtle gradient overlay
            LinearGradient(
                colors: [
                    Color.black.opacity(0.15),
                    Color.clear,
                    Color.clear,
                    Color.clear,
                    Color.black.opacity(0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Border highlight
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
    
    // MARK: - Animations
    
    private func startIntroAnimation() {
        // Single coordinated animation for intro
        withAnimation(smoothSpring) {
            introProgress = 1
        }
        
        // Cards appear slightly after morph begins
        withAnimation(smoothSpring.delay(0.15)) {
            cardsVisible = 1
        }
    }
    
    private func selectScreen(_ screen: StagePickerScreen) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        selectedScreen = screen
        
        // Navigate IMMEDIATELY - actual screen appears behind picker
        if let step = screen.signUpStep {
            onSelectStep(step)
        } else {
            onSkipToHome?()
        }
        
        // Animate picker chrome out while revealing actual screen
        withAnimation(quickSpring) {
            cardsVisible = 0
            selectionProgress = 1
        }
        
        // Dismiss after animation settles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.onDismiss()
        }
    }
    
    private func dismissWithAnimation() {
        withAnimation(smoothSpring) {
            cardsVisible = 0
            introProgress = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            onDismiss()
        }
    }
}

/// Preview card showing actual screen content
struct StageCardPreview: View {
    @ObservedObject private var themeService = ThemeService.shared
    let screen: StagePickerScreen
    
    @StateObject private var previewData = SignUpData()
    
    // Fixed dimensions - parent handles scaling via scaleEffect
    private let cardWidth: CGFloat = 300
    private let cardHeight: CGFloat = 300 * (852 / 393)
    private let deviceWidth: CGFloat = 393
    private let deviceHeight: CGFloat = 852
    
    private var scaleFactor: CGFloat {
        cardWidth / deviceWidth
    }
    
    var body: some View {
        ZStack {
            Color.white
            
            // Render at full device size, then scale down to card size
            screenContent
                .frame(width: deviceWidth, height: deviceHeight)
                .scaleEffect(scaleFactor, anchor: .top)
                .frame(width: cardWidth, height: cardHeight, alignment: .top)
                .allowsHitTesting(false)
        }
        .clipped()
    }
    
    @ViewBuilder
    private var screenContent: some View {
        switch screen {
        case .welcome:
            // Login/Welcome screen preview
            LoginPreviewContent()
        case .phone:
            VStack(spacing: 0) {
                headerPreview(progress: SignUpStep.phone.progress)
                SignUpPhoneContent(signUpData: previewData, disableAutoFocus: true)
            }
        case .verification:
            VStack(spacing: 0) {
                headerPreview(progress: SignUpStep.verification.progress)
                SignUpVerificationContent(signUpData: previewData, disableAutoFocus: true)
            }
        case .welcomeInfo:
            VStack(spacing: 0) {
                headerPreview(progress: SignUpStep.welcome.progress)
                SignUpWelcomeContent()
            }
        case .country:
            VStack(spacing: 0) {
                headerPreview(progress: SignUpStep.country.progress)
                SignUpCountryContent(signUpData: previewData)
            }
        case .name:
            VStack(spacing: 0) {
                headerPreview(progress: SignUpStep.name.progress)
                SignUpNameContent(signUpData: previewData, validationTrigger: .constant(false), disableAutoFocus: true)
            }
        case .birthday:
            VStack(spacing: 0) {
                headerPreview(progress: SignUpStep.birthday.progress)
                SignUpBirthdayContent(signUpData: previewData, disableAutoFocus: true)
            }
        case .reviewTerms:
            VStack(spacing: 0) {
                headerPreview(progress: SignUpStep.reviewTerms.progress)
                SignUpReviewTermsContent(signUpData: previewData)
            }
        }
    }
    
    private func headerPreview(progress: CGFloat) -> some View {
        ZStack {
            ProgressBarView(progress: progress)
            
            HStack {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(themeService.textPrimaryColor)
                    .frame(width: 44, height: 44)
                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 64)
        .padding(.top, 50)
    }
}

/// Preview content for the login/welcome screen
struct LoginPreviewContent: View {
    @ObservedObject private var themeService = ThemeService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 100)
            
            Text("The global account for global people")
                .font(.custom("Inter-Bold", size: 32))
                .foregroundColor(themeService.textPrimaryColor)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            
            VStack(spacing: 24) {
                FeatureRowPreview(icon: "bolt.fill", title: "Send money in seconds")
                FeatureRowPreview(icon: "chart.line.uptrend.xyaxis", title: "Trade stocks 24/7")
                FeatureRowPreview(icon: "dollarsign.circle.fill", title: "Earn savings on your USD")
                FeatureRowPreview(icon: "building.columns.fill", title: "EUR and USD accounts")
                FeatureRowPreview(icon: "clock.fill", title: "Sign up in minutes")
            }
            .padding(.horizontal, 16)
            
            Spacer()
            
            // Bottom buttons preview
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "EDEDED"))
                    .frame(width: 56, height: 56)
                
                RoundedRectangle(cornerRadius: 20)
                    .fill(themeService.textPrimaryColor)
                    .frame(height: 56)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 50)
        }
    }
}

struct FeatureRowPreview: View {
    @ObservedObject private var themeService = ThemeService.shared
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "FF5113").opacity(0.05))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: "FF5113"))
            }
            
            Text(title)
                .font(.custom("Inter-Bold", size: 18))
                .foregroundColor(themeService.textPrimaryColor)
            
            Spacer()
        }
    }
}

#Preview {
    SignUpFlowView(isComplete: .constant(false))
}
