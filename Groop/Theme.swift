//
//  Theme.swift
//  Groop
//
//  Thème visuel océan pour l'application Groop.
//

import SwiftUI

// MARK: - Couleurs

extension Color {
    static let ocean = Color(red: 0.05, green: 0.30, blue: 0.50)
    static let oceanLight = Color(red: 0.10, green: 0.55, blue: 0.72)
    static let sand = Color(red: 0.96, green: 0.87, blue: 0.70)
    static let coral = Color(red: 0.95, green: 0.40, blue: 0.32)
    static let seafoam = Color(red: 0.30, green: 0.78, blue: 0.69)
    static let deepSea = Color(red: 0.02, green: 0.15, blue: 0.30)
    static let shell = Color(red: 1.0, green: 0.95, blue: 0.88)

    /// Bleu ocean en mode clair, blanc en mode sombre — pour le texte des boutons.
    static let oceanText = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? .white : UIColor(red: 0.05, green: 0.30, blue: 0.50, alpha: 1)
    })
    /// Vert très foncé en mode clair, blanc en mode sombre — pour le texte des boutons.
    static let seafoamText = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? .white : UIColor(red: 0.05, green: 0.35, blue: 0.25, alpha: 1)
    })
}

extension ShapeStyle where Self == Color {
    static var ocean: Color { Color.ocean }
    static var oceanLight: Color { Color.oceanLight }
    static var sand: Color { Color.sand }
    static var coral: Color { Color.coral }
    static var seafoam: Color { Color.seafoam }
    static var deepSea: Color { Color.deepSea }
    static var shell: Color { Color.shell }
    static var oceanText: Color { Color.oceanText }
    static var seafoamText: Color { Color.seafoamText }
}

// MARK: - Gradients

extension LinearGradient {
    static let oceanGradient = LinearGradient(
        colors: [.ocean, .oceanLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let sunsetGradient = LinearGradient(
        colors: [.coral, .orange],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let seaGradient = LinearGradient(
        colors: [.seafoam, .oceanLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let sandGradient = LinearGradient(
        colors: [.sand, .shell],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Carte statistique animée

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let gradient: LinearGradient
    var subtitle: String? = nil

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.9))
                    .symbolEffect(.bounce, value: appeared)
                Spacer()
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .contentTransition(.numericText())
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(gradient)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
        .scaleEffect(appeared ? 1 : 0.9)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }
}

// MARK: - Badge modernisé

struct ModernBadge: View {
    let text: String
    let color: Color
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(text)
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.gradient)
        .clipShape(Capsule())
    }
}

// MARK: - Section Header stylisée

struct StyledSectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(.oceanLight)
                .font(.subheadline)
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.ocean)
                .textCase(nil)
        }
    }
}

// MARK: - Ligne résumé améliorée

struct ModernSummaryRow: View {
    let label: String
    let value: String
    var valueColor: Color = .secondary
    var bold: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .fontWeight(bold ? .semibold : .regular)
            Spacer()
            Text(value)
                .foregroundStyle(valueColor)
                .fontWeight(bold ? .bold : .regular)
                .contentTransition(.numericText())
        }
    }
}

// MARK: - Wave Shape

struct WaveShape: Shape {
    var offset: CGFloat

    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height * 0.5

        path.move(to: CGPoint(x: 0, y: midHeight))

        for x in stride(from: 0, to: width, by: 1) {
            let relativeX = x / width
            let sine = sin((relativeX + offset) * .pi * 2)
            let y = midHeight + sine * height * 0.3
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        return path
    }
}
