### Balance App — README

#### Overview
Balance App is an iOS SwiftUI application that helps users understand their focus cues based on a combination of:
- Apple HealthKit data: heart rate, sleep, steps, active energy, and workouts
- User inputs: activity type, duration, self-reported stress and focus
- An LLM-based analysis service that interprets signals and generates insights, a focus score, and actionable recommendations

The app ships with a full mock-data mode for development and a HealthKit-backed mode for production. It includes validation and guardrails for unlikely data (e.g., 24+ hours of activity), and a history view to revisit past analyses.

#### Key Features
- HealthKit integration (real data) with a robust mock data mode for development and testing
- Activity logging with self-assessed stress/focus sliders
- LLM-powered analysis that returns a Focus Score (0–100), summary, and recommendations
- Input and metric validation with user-facing error messages for unrealistic values
- History of analyses persisted locally
- Configurable LLM provider, API URL, and model via a `Secrets.plist` or environment variables

---

### Architecture

#### App Entry
- BalanceAppApp.swift
  - SwiftUI App entry point. Initializes a SwiftData ModelContainer (with `Item` model) and loads `ContentView`.

#### UI Layer (SwiftUI Views)
- ContentView.swift
  - Landing screen. Handles:
    - Mock/testing mode vs. real HealthKit mode.
    - HealthKit authorization flow.
    - Navigation to Activity logging and History.
  - Shows error messages from authorization.

- ActivityInputView.swift
  - Form to capture:
    - Activity type (e.g., Studying, Working, Exercising)
    - Duration (0.5–12 hours slider; warnings > 8h and hard error if > 16h)
    - Self-reported stress and focus (1–10 sliders)
  - In mock mode, includes a “Health Data Scenario” picker to simulate different profiles:
    - Well Rested, Stressed, Very Active, Sedentary, Optimal
  - On Analyze:
    - Validates user input
    - Fetches health data (mock or HealthKit)
    - Validates health data
    - Calls LLM service to analyze combined signals
    - Saves analysis to history and presents results

- AnalysisView.swift
  - Displays:
    - Focus Score visualization (circular gauge)
    - Summary text from the LLM
    - Recommendations list (3–5 items)
    - Timestamp of analysis
  - Color-coded score rings (red/orange/green)

- HistoryView.swift
  - Lists past analyses with date and focus score indicator
  - Tap any item to view the full AnalysisView
  - Implements `Identifiable` for `FocusAnalysis` to support sheets

#### Data & Services
- HealthKitManager.swift
  - Requests HealthKit authorization
  - Fetches:
    - Heart rate (latest 10 samples, bpm)
    - Sleep samples (last N days)
    - Step count (last N days)
  - Returns raw values for downstream processing

- MockHealthKitManager.swift
  - Simulates authorization
  - Generates realistic random data for:
    - Heart rate array
    - Average sleep hours
    - Step count
    - Active minutes
  - Provides preset scenarios for deterministic testing
  - Used when `Config.useMockData == true`

- LLMService.swift
  - Reads configuration from `Config`
  - Validates inputs and health data before calling the LLM
  - Constructs a structured prompt combining:
    - Average and recent heart rates
    - Average sleep hours (last 7 days)
    - Today’s steps
    - Active minutes
    - Current activity, duration, stress, focus
  - Calls the configured chat-completions endpoint
  - Parses response into `FocusAnalysis`:
    - Extracts Focus Score using regex on content
    - Extracts recommendations from numbered/bulleted list lines
    - Provides fallbacks if extraction fails

- DataManager.swift
  - Persists analysis history to `UserDefaults`
  - Stores up to the last 30 analyses
  - Provides load and clear operations

- HealthData.swift
  - Model representing health signals:
    - heartRate [Double], sleepHours Double, stepCount Double, activeMinutes Double, timestamp Date
  - `validate()` enforces reasonable bounds:
    - Heart rate sanity check
    - Sleep hours 0–24
    - Active minutes <= 1440
    - Non-negative steps
  - Returns `ValidationResult` with `isValid` and error messages

- UserInput.swift
  - Model for user-submitted context:
    - activity String, duration Double, stressLevel Int, focusLevel Int, timestamp Date
  - `validate()` enforces reasonable bounds:
    - Duration 0–24
    - Stress/focus levels 1–10

- APIDebugHelper.swift
  - Simple connectivity test that:
    - Verifies API key presence and format (OpenRouter example)
    - Attempts a minimal chat-completions call
    - Returns success/error status and useful messages

- Config.swift
  - Central configuration:
    - API provider enum: openai, abacus, anthropic, openrouter
    - API key via `Secrets.plist` or `LLM_API_KEY` environment variable
    - API URL and default model selection per provider
      - OpenRouter example default: `amazon/nova-lite-v1`
    - `useMockData` toggle for switching between mock and real HealthKit

- Item.swift
  - Example SwiftData model (timestamp only). Not central to core features, but shows SwiftData setup.

- Tests
  - BalanceAppTests.swift: scaffold with `Testing` framework
  - BalanceAppUITests.swift and BalanceAppUITestsLaunchTests.swift: default Xcode-generated UI test scaffolding

---

### Getting Started

#### Requirements
- Xcode 15+
- iOS 17+ target recommended
- A valid LLM API key for your chosen provider
- A device (or simulator) with HealthKit available for real data mode

#### Setup
1. Clone the project and open the `.xcodeproj` or `.xcworkspace` in Xcode.

2. Configure the LLM credentials:
   - Create a `Secrets.plist` in the app bundle with keys:
     - `LLM_API_KEY` = your key
     - `API_PROVIDER` = one of: `openai`, `abacus`, `anthropic`, `openrouter`
   - Alternatively, set environment variable `LLM_API_KEY` for your scheme.
   - The API endpoint and model are automatically chosen by `Config`. You can customize by editing `Config.llmAPIURL` and `Config.llmModel`.

3. HealthKit entitlements (for real data mode):
   - In Xcode target capabilities, enable HealthKit.
   - Add needed read permissions:
     - Heart Rate, Resting Heart Rate, HRV (SDNN)
     - Step Count
     - Active Energy Burned
     - Sleep Analysis
     - Workouts
   - Update `Info.plist` with NSHealthShareUsageDescription describing why you need data.

4. Choose data mode:
   - Development/testing: leave `Config.useMockData = true`
   - Production/real data: set `Config.useMockData = false`

5. Build and run:
   - In mock mode, tap “Start Testing” to proceed without HealthKit.
   - In real mode, tap “Authorize HealthKit” and grant permissions.

---

### Using the App

1. From the Home screen, authorize HealthKit (real mode) or start testing (mock mode).
2. Tap “Log New Activity.”
3. Choose:
   - Activity: Studying, Working, Exercising, Relaxing, Meeting, Creative Work
   - Duration (0.5–12 hours; warnings appear > 8 hours)
   - Stress Level (1–10)
   - Focus Level (1–10)
   - In mock mode, you can select a predefined testing scenario.
4. Tap “Analyze Focus Cues.”
   - The app validates all inputs.
   - Health data is fetched (mock or real).
   - LLM generates an analysis with a Focus Score, summary, and recommendations.
   - The result is saved to History and shown in a detail sheet.
5. To revisit, go to “View History” and tap any entry.

---

### Data Validation and Guardrails

- UserInput:
  - Duration must be 0–24 hours; UI warns > 8 hours and disallows > 16 hours in the view
  - Stress and focus must be 1–10

- HealthData:
  - Ensures values are realistic (HR, sleep, active minutes, steps)
  - Returns clear error messages if invalid

- The UI displays validation feedback before sending to the LLM.

---

### Project Files Map

- App lifecycle
  - BalanceAppApp.swift

- Config/Helpers
  - Config.swift
  - APIDebugHelper.swift
  - DataManager.swift

- Health data
  - HealthKitManager.swift
  - MockHealthKitManager.swift
  - HealthData.swift
  - UserInput.swift

- LLM
  - LLMService.swift

- UI
  - ContentView.swift
  - ActivityInputView.swift
  - AnalysisView.swift
  - HistoryView.swift

- Models (SwiftData example)
  - Item.swift

- Tests
  - BalanceAppTests.swift
  - BalanceAppUITests.swift
  - BalanceAppUITestsLaunchTests.swift

### License
Add your project’s license here (e.g., MIT).
