//
//  SplashScreenView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 16/04/2025.
//


import SwiftUI

struct SplashScreenView: View {
    @State private var isLoading = true
    @State private var loadingProgress: CGFloat = 0
    @State private var trainMoving = false
    @State private var wheelRotation = 0.0
    @State private var steamOpacity = 0.8
    @State private var trainBounce = false
    @State private var isAnimating = false
    
    // Timer pour maintenir les animations actives
    @State private var animationTimer: Timer? = nil
    
    // Pour la transition
    @Binding var isFinished: Bool
    
    // Pour le chargement des données avec progression
    let onAppear: (@escaping (Double) -> Void) async -> Void
    
    var body: some View {
        ZStack {
            // Arrière-plan
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "e0f7fa"), Color(hex: "bbdefb")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Logo et titre
                Text("EaseIdf")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "1976d2"))
                    .padding(.bottom, 40)
                
                // Animation du train
                ZStack {
                    // Train avec animation
                    TrainView(
                        wheelRotation: isAnimating ? wheelRotation : 0,
                        steamOpacity: isAnimating ? steamOpacity : 0.8,
                        trainMoving: trainMoving,
                        isAnimating: isAnimating
                    )
                    .frame(width: 280, height: 160)
                    .offset(y: trainBounce ? 3 : 0)
                }
                .padding(.bottom, 60)
                
                // Barre de progression
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .frame(width: 250, height: 8)
                        .foregroundColor(Color.gray.opacity(0.3))
                    
                    RoundedRectangle(cornerRadius: 8)
                        .frame(width: loadingProgress * 250, height: 8)
                        .foregroundColor(Color(hex: "1976d2"))
                        .animation(.easeInOut(duration: 0.3), value: loadingProgress)
                }
                .padding(.bottom, 20)
                
                Text(loadingStatusText)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                // Mention copyright
                Text("© EaseIdf 2025")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            // Démarrer les animations
            startAnimations()
            
            // Charger les données
            Task {
                await loadData()
            }
        }
        .onDisappear {
            // S'assurer que le timer est invalidé lorsque la vue disparaît
            animationTimer?.invalidate()
            animationTimer = nil
        }
    }
    
    // Texte basé sur la progression
    private var loadingStatusText: String {
        if loadingProgress < 0.3 {
            return "Préparation..."
        } else if loadingProgress < 0.5 {
            return "Chargement des lignes..."
        } else if loadingProgress < 0.7 {
            return "Chargement des arrêts..."
        } else if loadingProgress < 0.9 {
            return "Configuration des services..."
        } else {
            return "Finalisation..."
        }
    }
    
    private func startAnimations() {
        // Marquer le début des animations
        isAnimating = true
        
        // Animation de démarrage du train
        withAnimation(.easeInOut(duration: 0.6)) {
            trainMoving = true
        }
        
        // Animation du rebond du train
        withAnimation(
            Animation.easeInOut(duration: 0.6)
                .repeatForever(autoreverses: true)
        ) {
            trainBounce = true
        }
        
        // Animation initiale de la barre de progression
        loadingProgress = 0.1
        
        // Créer un timer pour garantir que l'animation continue
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            // Rotation continuelle des roues
            self.wheelRotation += 2
            if self.wheelRotation >= 360 {
                self.wheelRotation = 0
            }
            
            // S'assurer que les autres animations persistent également
            if !self.trainBounce {
                withAnimation(
                    Animation.easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                ) {
                    self.trainBounce = true
                }
            }
            
            // Pulsation de la vapeur
            withAnimation(
                Animation.easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: true)
            ) {
                self.steamOpacity = self.steamOpacity == 0.8 ? 0.4 : 0.8
            }
        }
    }
    
    private func loadData() async {
        // Utiliser la fonction onAppear avec un callback pour la progression
        await onAppear { progress in
            // Mettre à jour l'UI sur le thread principal
            DispatchQueue.main.async {
                self.loadingProgress = CGFloat(progress)
            }
        }
        
        // Assurer que la progression soit complète
        await MainActor.run {
            self.loadingProgress = 1.0
        }
        
        // Ajouter un petit délai avant de terminer
        try? await Task.sleep(nanoseconds: 800_000_000)
        
        // Arrêter le timer d'animation avant de terminer
        DispatchQueue.main.async {
            self.animationTimer?.invalidate()
            self.animationTimer = nil
            
            // Terminer le splash screen
            self.isFinished = true
        }
    }
}

// Vue du train modifiée pour garantir des animations continues
struct TrainView: View {
    let wheelRotation: Double
    let steamOpacity: Double
    let trainMoving: Bool
    let isAnimating: Bool
    
    @State private var steamOffset: CGFloat = 0
    @State private var steamPulsate: Bool = false
    
    var body: some View {
        ZStack {
            // Vapeur (nuage)
            SteamView(opacity: steamOpacity)
                .offset(x: -90 + (isAnimating ? steamOffset : 0), y: -65)
                .scaleEffect(trainMoving ? (steamPulsate ? 1.1 : 1.0) : 0.3)
                .opacity(trainMoving ? 1.0 : 0)
            
            // Locomotive
            LocomotiveView(wheelRotation: wheelRotation)
                .offset(y: trainMoving ? 0 : 20)
            
            // Wagons
            HStack(spacing: -5) {
                Color.clear.frame(width: 110) // Espace pour la locomotive
                
                WagonView(wheelRotation: wheelRotation)
                    .offset(y: trainMoving ? 5 : 30)
                
                WagonView(wheelRotation: wheelRotation)
                    .offset(y: trainMoving ? 5 : 40)
            }
        }
        .onAppear {
            // Uniquement démarrer ces animations si isAnimating est vrai
            if isAnimating {
                // Animation continue pour la vapeur qui se déplace
                withAnimation(
                    Animation.linear(duration: 4.0)
                        .repeatForever(autoreverses: false)
                ) {
                    steamOffset = 40
                }
                
                // Animation pour la pulsation de la vapeur
                withAnimation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                ) {
                    steamPulsate = true
                }
            }
        }
        .onChange(of: isAnimating) { newValue in
            // Répondre aux changements de l'état d'animation
            if newValue {
                withAnimation(
                    Animation.linear(duration: 4.0)
                        .repeatForever(autoreverses: false)
                ) {
                    steamOffset = 40
                }
                
                withAnimation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                ) {
                    steamPulsate = true
                }
            }
        }
    }
}

// Vue de la locomotive
struct LocomotiveView: View {
    let wheelRotation: Double
    
    var body: some View {
        ZStack {
            // Corps de la locomotive
            Rectangle()
                .fill(Color(hex: "f44336"))
                .frame(width: 60, height: 40)
                .cornerRadius(8)
                .offset(x: -15, y: 0)
            
            // Cabine
            Rectangle()
                .fill(Color(hex: "ffa726"))
                .frame(width: 40, height: 50)
                .cornerRadius(8)
                .offset(x: -30, y: -5)
            
            // Fenêtre
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: "bbdefb"))
                .frame(width: 20, height: 25)
                .offset(x: -30, y: -5)
            
            // Cheminée
            Rectangle()
                .fill(Color(hex: "8bc34a"))
                .frame(width: 10, height: 25)
                .cornerRadius(2)
                .offset(x: -50, y: -20)
            
            // Roues
            WheelView(rotation: wheelRotation)
                .offset(x: -50, y: 20)
            
            WheelView(rotation: wheelRotation)
                .offset(x: -20, y: 20)
        }
    }
}

// Vue d'un wagon
struct WagonView: View {
    let wheelRotation: Double
    
    var body: some View {
        ZStack {
            // Corps du wagon
            Rectangle()
                .fill(Color(hex: "ffa726"))
                .frame(width: 70, height: 40)
                .cornerRadius(8)
            
            // Toit
            Rectangle()
                .fill(Color(hex: "e53935"))
                .frame(width: 70, height: 10)
                .cornerRadius(4)
                .offset(y: -20)
            
            // Fenêtres
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "bbdefb"))
                    .frame(width: 15, height: 20)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "bbdefb"))
                    .frame(width: 15, height: 20)
            }
            
            // Roues
            WheelView(rotation: wheelRotation)
                .offset(x: -20, y: 20)
                .scaleEffect(0.8)
            
            WheelView(rotation: wheelRotation)
                .offset(x: 20, y: 20)
                .scaleEffect(0.8)
        }
    }
}

// Vue d'une roue
struct WheelView: View {
    let rotation: Double
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "795548"))
                .frame(width: 20, height: 20)
            
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 12, height: 12)
                .rotationEffect(.degrees(rotation))
        }
    }
}

// Vue de la vapeur
struct SteamView: View {
    let opacity: Double
    
    var body: some View {
        ZStack {
            // Nuages de vapeur
            Circle()
                .fill(Color.white.opacity(opacity))
                .frame(width: 40, height: 30)
                .offset(x: -10, y: 5)
            
            Circle()
                .fill(Color.white.opacity(opacity))
                .frame(width: 30, height: 20)
                .offset(x: 10, y: -8)
            
            Circle()
                .fill(Color.white.opacity(opacity))
                .frame(width: 25, height: 25)
                .offset(x: 20, y: 0)
        }
    }
}

// Intégration du SplashScreen dans l'app
struct SplashScreenContainer: View {
    @State private var showingSplash = true
    @State private var loadingTimedOut = false
    let content: AnyView
    let onAppear: (@escaping (Double) -> Void) async -> Void
    
    init<Content: View>(content: Content, onAppear: @escaping (@escaping (Double) -> Void) async -> Void) {
        self.content = AnyView(content)
        self.onAppear = onAppear
    }
    
    var body: some View {
        ZStack {
            content
                .opacity(showingSplash ? 0 : 1)
            
            if showingSplash {
                SplashScreenView(isFinished: $showingSplash, onAppear: onAppear)
                    .transition(.opacity)
            }
        }
        .onAppear {
            // Ajouter un timer de sécurité pour éviter que l'application reste bloquée indéfiniment
            DispatchQueue.main.asyncAfter(deadline: .now() + 20.0) {
                if showingSplash {
                    print("⚠️ Délai d'attente dépassé sur le splash screen - Transition forcée")
                    loadingTimedOut = true
                    showingSplash = false
                }
            }
        }
    }
}
