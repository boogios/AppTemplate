//
//  OnboardingView.swift
//  AppTemplate
//

import SwiftUI

struct OnboardingView: View {

    enum Mode: Equatable {
        case initial
        case replay
    }

    private enum Step: Int, CaseIterable {
        case introOne
        case introTwo
        case nickname
        case notifications
        case advertising

        var isIntro: Bool {
            self == .introOne || self == .introTwo
        }
    }

    let mode: Mode
    let onComplete: (String) -> Void
    let onReplayDismiss: () -> Void

    @State private var step: Step = .introOne
    @State private var nickname = ""
    @State private var showsNicknameError = false

    private var visibleSteps: [Step] {
        mode == .initial ? Step.allCases : [.introOne, .introTwo]
    }

    private var currentIndex: Int {
        visibleSteps.firstIndex(of: step) ?? 0
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text("\(currentIndex + 1)/\(visibleSteps.count)")
                    .font(.pretendardMedium(size: 13))
                    .foregroundStyle(Color.boogiosGray6)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)

            Spacer(minLength: 16)

            content
                .padding(.horizontal, 28)

            Spacer(minLength: 20)

            Button(action: advance) {
                Text(buttonTitle)
                    .font(.pretendardSemiBold(size: 15))
                    .foregroundStyle(Color.boogiosWhite)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.boogiosMain)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(step == .nickname && !OnboardingStore.isValidNickname(nickname))
            .opacity(step == .nickname && !OnboardingStore.isValidNickname(nickname) ? 0.45 : 1)
            .accessibilityIdentifier(buttonIdentifier)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.boogiosGray1.ignoresSafeArea())
        .onAppear {
            if mode == .replay {
                step = .introOne
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .introOne:
            page(
                title: OnboardingL10n.introOneTitle,
                description: OnboardingL10n.introOneDescription,
                symbol: "sparkles"
            )
        case .introTwo:
            page(
                title: OnboardingL10n.introTwoTitle,
                description: OnboardingL10n.introTwoDescription,
                symbol: "slider.horizontal.3"
            )
        case .nickname:
            nicknamePage
        case .notifications:
            page(
                title: OnboardingL10n.notificationsTitle,
                description: OnboardingL10n.notificationsDescription,
                symbol: "bell.badge"
            )
        case .advertising:
            page(
                title: OnboardingL10n.advertisingTitle,
                description: OnboardingL10n.advertisingDescription,
                symbol: "hand.raised"
            )
        }
    }

    private var nicknamePage: some View {
        VStack(alignment: .leading, spacing: 22) {
            onboardingShape(symbol: "person.crop.circle")

            VStack(alignment: .leading, spacing: 10) {
                Text(OnboardingL10n.nicknameTitle)
                    .font(.headline1)
                    .foregroundStyle(Color.boogiosGray9)

                Text(OnboardingL10n.nicknameDescription)
                    .font(.body1)
                    .foregroundStyle(Color.boogiosGray7)
                    .fixedSize(horizontal: false, vertical: true)
            }

            TextField(OnboardingL10n.nicknamePlaceholder, text: $nickname)
                .font(.body1)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.boogiosWhite)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(showsNicknameError ? Color.red : Color.boogiosGray3, lineWidth: 1)
                }
                .accessibilityIdentifier("onboarding.nickname")
                .onChange(of: nickname) { _, newValue in
                    nickname = String(newValue.prefix(20))
                    showsNicknameError = false
                }

            if showsNicknameError {
                Text(OnboardingL10n.nicknameValidation)
                    .font(.caption1)
                    .foregroundStyle(Color.red)
            }
        }
    }

    private func page(title: String, description: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            onboardingShape(symbol: symbol)

            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.headline1)
                    .foregroundStyle(Color.boogiosGray9)

                Text(description)
                    .font(.body1)
                    .foregroundStyle(Color.boogiosGray7)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func onboardingShape(symbol: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34)
                .fill(Color.boogiosMainSoft)
                .frame(width: 156, height: 156)
                .rotationEffect(.degrees(-7))

            Circle()
                .fill(Color.boogiosMainSofter)
                .frame(width: 112, height: 112)
                .offset(x: 20, y: 18)

            Image(systemName: symbol)
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(Color.boogiosMain)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 190)
    }

    private var buttonTitle: String {
        if mode == .replay {
            return currentIndex == visibleSteps.count - 1 ? OnboardingL10n.start : OnboardingL10n.next
        }

        switch step {
        case .notifications:
            return OnboardingL10n.allowNotifications
        case .advertising:
            return OnboardingL10n.start
        default:
            return OnboardingL10n.next
        }
    }

    private var buttonIdentifier: String {
        if mode == .replay && currentIndex == visibleSteps.count - 1 {
            return "onboarding.start"
        }
        return step == .advertising ? "onboarding.start" : "onboarding.next"
    }

    private func advance() {
        guard let currentStepIndex = visibleSteps.firstIndex(of: step) else { return }

        if step == .nickname && !OnboardingStore.isValidNickname(nickname) {
            showsNicknameError = true
            return
        }

        if mode == .replay {
            if currentStepIndex == visibleSteps.count - 1 {
                onReplayDismiss()
            } else {
                step = visibleSteps[currentStepIndex + 1]
            }
            return
        }

        switch step {
        case .notifications:
            if ProcessInfo.processInfo.arguments.contains("-ui-test-skip-permissions") {
                moveToNextStep(after: currentStepIndex)
                return
            }
            Task {
                await NotificationAuthorizationManager.shared.requestIfNeeded()
                await MainActor.run {
                    moveToNextStep(after: currentStepIndex)
                }
            }
        case .advertising:
            Task {
                await AdMobManager.shared.requestConsentForOnboarding()
                await TrackingAuthorizationManager.shared.requestIfNeeded()
                await MainActor.run {
                    onComplete(nickname)
                }
            }
        default:
            moveToNextStep(after: currentStepIndex)
        }
    }

    private func moveToNextStep(after index: Int) {
        guard index + 1 < visibleSteps.count else {
            onComplete(nickname)
            return
        }
        step = visibleSteps[index + 1]
    }
}

#Preview {
    OnboardingView(mode: .initial, onComplete: { _ in }, onReplayDismiss: {})
}
