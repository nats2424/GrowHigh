import SwiftUI

struct LevelUpModalView: View {
    @Binding var isPresented: Bool
    let statistics: LevelUpStatistics
    let onActionSelected: (LevelUpAction) -> Void
    
    @State private var showContent = false
    @State private var animateProgress = false
    @State private var showActions = false
    @State private var confettiTrigger = false
    
    private let messageService = LevelUpMessageService.shared
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissModal()
                }
            
            // Modal content
            VStack(spacing: 0) {
                modalContent
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 20)
            )
            .padding(.horizontal, 32)
            .scaleEffect(showContent ? 1.0 : 0.7)
            .opacity(showContent ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showContent)
            
            // Confetti overlay
            if confettiTrigger {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            setupAnimations()
        }
    }
    
    // MARK: - Modal Content
    
    private var modalContent: some View {
        let messageContent = messageService.generateLevelUpMessage(for: statistics)
        
        return VStack(spacing: 20) {
            // Header with icon and level
            headerSection(iconEmoji: messageContent.iconEmoji)
            
            // Title and message
            messageSection(
                title: messageContent.title,
                message: messageContent.message,
                backgroundColor: messageContent.backgroundColor
            )
            
            // Progress visualization
            progressSection
            
            // Next action prompt
            actionPromptSection(messageContent.nextActionPrompt)
            
            // Action buttons
            actionButtonsSection
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
    }
    
    // MARK: - UI Components
    
    private func headerSection(iconEmoji: String) -> some View {
        VStack(spacing: 12) {
            // New Avatar Display
            ZStack {
                // Glow effect
                Circle()
                    .fill(RadialGradient(
                        gradient: Gradient(colors: [Color.cyan.opacity(0.3), Color.clear]),
                        center: .center,
                        startRadius: 40,
                        endRadius: 80
                    ))
                    .frame(width: 100, height: 100)
                
                // Avatar image with border
                Image(statistics.currentAvatarImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [.cyan, .blue]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    )
                    .scaleEffect(showContent ? 1.0 : 0.5)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1), value: showContent)
            }
            
            // Job Title
            Text(statistics.jobTitle)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.6).delay(0.2), value: showContent)
            
            Text("LEVEL \(statistics.currentLevel)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.6).delay(0.3), value: showContent)
        }
    }
    
    private func messageSection(title: String, message: String, backgroundColor: String) -> some View {
        VStack(spacing: 16) {
            // Title
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.6).delay(0.4), value: showContent)
            
            // Message
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.6).delay(0.5), value: showContent)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemGray6))
                .opacity(0.5)
        )
    }
    
    private var progressSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("継続日数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(statistics.consecutiveDays)日")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("完了タスク")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(statistics.totalTasksCompleted)個")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
            
            // Progress bar for improvement
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("成長度")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(statistics.improvementMetric)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .fontWeight(.medium)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(
                                width: animateProgress ? geometry.size.width * 0.8 : 0,
                                height: 8
                            )
                            .animation(.easeInOut(duration: 1.0).delay(0.8), value: animateProgress)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(.horizontal)
        .opacity(showContent ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.6).delay(0.6), value: showContent)
    }
    
    private func actionPromptSection(_ prompt: String) -> some View {
        Text(prompt)
            .font(.subheadline)
            .foregroundColor(.primary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .opacity(showActions ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.5).delay(1.2), value: showActions)
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ActionButton(
                    action: .setGoal,
                    isVisible: showActions
                ) { action in
                    handleActionSelection(action)
                }
                
                ActionButton(
                    action: .continueJourney,
                    isVisible: showActions,
                    isPrimary: true
                ) { action in
                    handleActionSelection(action)
                }
            }
            
            HStack(spacing: 12) {
                ActionButton(
                    action: .saveRecord,
                    isVisible: showActions
                ) { action in
                    handleActionSelection(action)
                }
                
                ActionButton(
                    action: .shareAchievement,
                    isVisible: showActions
                ) { action in
                    handleActionSelection(action)
                }
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Animation Setup
    
    private func setupAnimations() {
        // Trigger haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // Sequential animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showContent = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            confettiTrigger = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            animateProgress = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            showActions = true
        }
    }
    
    // MARK: - Actions
    
    private func handleActionSelection(_ action: LevelUpAction) {
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
        
        onActionSelected(action)
        dismissModal()
    }
    
    private func dismissModal() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showContent = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

// MARK: - Action Button Component

private struct ActionButton: View {
    let action: LevelUpAction
    let isVisible: Bool
    let isPrimary: Bool
    let onTap: (LevelUpAction) -> Void
    
    init(action: LevelUpAction, isVisible: Bool, isPrimary: Bool = false, onTap: @escaping (LevelUpAction) -> Void) {
        self.action = action
        self.isVisible = isVisible
        self.isPrimary = isPrimary
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: { onTap(action) }) {
            HStack(spacing: 8) {
                Image(systemName: action.icon)
                    .font(.footnote)
                
                Text(action.displayText)
                    .font(.footnote)
                    .fontWeight(.medium)
            }
            .foregroundColor(isPrimary ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isPrimary ? Color.blue : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double.random(in: 0...0.2)), value: isVisible)
    }
}

// MARK: - Confetti Animation View

private struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<50, id: \.self) { _ in
                ConfettiPiece()
            }
        }
        .onAppear {
            animate = true
        }
    }
}

private struct ConfettiPiece: View {
    @State private var offsetY: CGFloat = -100
    @State private var offsetX: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1
    
    private let colors = [Color.red, Color.blue, Color.green, Color.yellow, Color.purple, Color.orange]
    private let color = Color.random(from: [.red, .blue, .green, .yellow, .purple, .orange])
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 8, height: 8)
            .rotationEffect(.degrees(rotation))
            .offset(x: offsetX, y: offsetY)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 2.0)) {
                    offsetY = UIScreen.main.bounds.height + 100
                    offsetX = CGFloat.random(in: -100...100)
                    rotation = Double.random(in: 0...360)
                    opacity = 0
                }
            }
    }
}

// MARK: - Extensions

private extension Color {
    static func random(from colors: [Color]) -> Color {
        return colors.randomElement() ?? .blue
    }
}

// MARK: - Preview

struct LevelUpModalView_Previews: PreviewProvider {
    static var previews: some View {
        LevelUpModalView(
            isPresented: .constant(true),
            statistics: LevelUpStatistics(
                daysSinceFirstTask: 25,
                mostCompletedTaskType: .strength,
                currentLevel: 10,
                jobTitle: "戦士",
                previousJobTitle: "見習い戦士",
                improvementMetric: "前回より3日早く",
                consecutiveDays: 14,
                totalTasksCompleted: 45,
                completionRate: 87.5,
                averageCompletionTime: 1.5,
                jobCategory: .fighter,
                isFirstJobAcquisition: false,
                isJobEvolution: true,
                isConsecutiveStreak: true
            ),
            onActionSelected: { _ in }
        )
    }
}