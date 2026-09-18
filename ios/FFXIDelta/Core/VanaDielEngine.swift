//
//  VanaDielEngine.swift
//  FFXI for Delta (iOS TestFlight Edition)
//  Copyright (c) 2026 Daniel Bates / Bates LLC. All rights reserved.
//

import Foundation
import UIKit
import Combine

public enum GameScreenState {
    case title
    case characterCreation
    case exploration
    case actionMenu
    case statusMenu
    case weaponSkillMenu
    case magicMenu
    case gameOver
}

public final class VanaDielEngine: ObservableObject {
    public static let shared = VanaDielEngine()

    public static let screenWidth: Int = 240
    public static let screenHeight: Int = 160

    // Internal framebuffer in RGBA32 format (240x160)
    private var renderBuffer: [UInt32]
    public var pixelBuffer: [UInt32] { return renderBuffer }

    // Crash-proof immutable CGImage published once per tick
    @Published public private(set) var currentFrame: CGImage? = nil
    @Published public var currentScreen: GameScreenState = .title

    // Telemetry & Diagnostics for TestFlight
    @Published public var currentFPS: Double = 60.0
    @Published public var currentZoneName: String = "Southern San d'Oria"
    @Published public var playerLevel: Int = 1
    @Published public var playerHP: Int = 50
    @Published public var playerMaxHP: Int = 50
    @Published public var playerMP: Int = 0
    @Published public var playerMaxMP: Int = 0
    @Published public var playerTP: Int = 0
    @Published public var inCombat: Bool = false
    @Published public var isResting: Bool = false

    // Input bitmask
    public struct ControllerInput {
        public static let a: UInt16      = 0x0001
        public static let b: UInt16      = 0x0002
        public static let select: UInt16 = 0x0004
        public static let start: UInt16  = 0x0008
        public static let right: UInt16  = 0x0010
        public static let left: UInt16   = 0x0020
        public static let up: UInt16     = 0x0040
        public static let down: UInt16   = 0x0080
        public static let r: UInt16      = 0x0100
        public static let l: UInt16      = 0x0200
    }

    private var currentInput: UInt16 = 0
    private var previousInput: UInt16 = 0
    private var frameCount: UInt64 = 0
    private var menuCursor: Int = 0

    // Character Creation state
    private var createStep: Int = 0 // 0: Race, 1: Job, 2: Nation
    private var createRace: Int = 0
    private var createJob: Int = 0
    private var createNation: Int = 0

    // Game data structures
    private struct Mob {
        var name: String
        var mobType: Int
        var level: Int
        var hp: Int
        var maxHP: Int
        var attack: Int
        var defense: Int
        var expReward: Int
        var gilReward: Int
        var x: Int
        var y: Int
        var alive: Bool
        var respawnTimer: Int
        var attackTimer: Int
    }

    private struct NPCData {
        var name: String
        var x: Int
        var y: Int
        var text: String
    }

    private var playerX: Int = 10
    private var playerY: Int = 8
    private var playerDir: Int = 0
    private var playerEXP: Int = 0
    private var playerEXPToNext: Int = 500
    private var playerGil: Int = 500
    private var weaponDelayTimer: Int = 0
    private var weaponDelayMax: Int = 60
    private var restTimer: Int = 0
    private var currentZoneID: Int = 0
    private var targetMobIndex: Int = -1

    private var mobs: [Mob] = []
    private var npcs: [NPCData] = []
    private var combatLog: [(text: String, color: UInt32)] = []

    private var displayLink: CADisplayLink?
    private var lastFrameTime: CFTimeInterval = 0

    private init() {
        self.renderBuffer = [UInt32](repeating: 0xFF0A0E18, count: VanaDielEngine.screenWidth * VanaDielEngine.screenHeight)
        initGameWorld()
        generateFrameImage()
    }

    public func startEngine() {
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(frameTick))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 60, preferred: 60)
        link.add(to: .main, forMode: .common)
        self.displayLink = link
        lastFrameTime = CACurrentMediaTime()
    }

    public func stopEngine() {
        displayLink?.invalidate()
        displayLink = nil
    }

    public func setButtonState(button: UInt16, isDown: Bool) {
        if isDown {
            currentInput |= button
        } else {
            currentInput &= ~button
        }
    }

    private func isPressed(_ button: UInt16) -> Bool {
        return (currentInput & button != 0) && (previousInput & button == 0)
    }

    private func isDown(_ button: UInt16) -> Bool {
        return (currentInput & button != 0)
    }

    @objc private func frameTick() {
        let now = CACurrentMediaTime()
        let dt = now - lastFrameTime
        lastFrameTime = now
        if dt > 0 {
            currentFPS = (0.9 * currentFPS) + (0.1 * (1.0 / dt))
        }
        frameCount += 1

        updateLogic()
        renderScreen()
        generateFrameImage()

        previousInput = currentInput
    }

    private func generateFrameImage() {
        let byteCount = VanaDielEngine.screenWidth * VanaDielEngine.screenHeight * 4
        let data = Data(bytes: renderBuffer, count: byteCount)
        guard let provider = CGDataProvider(data: data as CFData) else { return }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)

        if let cgImage = CGImage(
            width: VanaDielEngine.screenWidth,
            height: VanaDielEngine.screenHeight,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: VanaDielEngine.screenWidth * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ) {
            self.currentFrame = cgImage
        }
    }

    private func initGameWorld() {
        changeZone(newZone: 0, spawnX: 10, spawnY: 8)
        addLog("Welcome to Vana'diel!", color: 0xFFD4AF37)
        addLog("Delta iOS TestFlight Ready", color: 0xFF50C878)
    }

    private func changeZone(newZone: Int, spawnX: Int, spawnY: Int) {
        currentZoneID = newZone
        playerX = spawnX
        playerY = spawnY
        inCombat = false
        targetMobIndex = -1
        mobs.removeAll()
        npcs.removeAll()

        switch newZone {
        case 0: // Southern San d'Oria
            currentZoneName = "Southern San d'Oria"
            npcs.append(NPCData(name: "Gate Guard", x: 10, y: 3, text: "Signet has been cast upon you!"))
            npcs.append(NPCData(name: "Moogle", x: 4, y: 4, text: "Kupo! Your Mog House is safe!"))
        case 1: // West Ronfaure
            currentZoneName = "West Ronfaure"
            for i in 0..<4 {
                let isRabbit = (i % 2 == 0)
                mobs.append(Mob(
                    name: isRabbit ? "Wild Rabbit" : "Forest Funguar",
                    mobType: isRabbit ? 0 : 1,
                    level: (i < 2) ? 1 : 2,
                    hp: 30 + (i * 10),
                    maxHP: 30 + (i * 10),
                    attack: 8 + i,
                    defense: 8 + i,
                    expReward: 35 + (i * 15),
                    gilReward: 12 + (i * 8),
                    x: 5 + (i * 4),
                    y: 4 + (i * 2),
                    alive: true,
                    respawnTimer: 0,
                    attackTimer: 0
                ))
            }
        case 2: // Valkurm Dunes
            currentZoneName = "Valkurm Dunes"
            for i in 0..<4 {
                let isFly = (i % 2 == 0)
                mobs.append(Mob(
                    name: isFly ? "Damselfly" : "Goblin Thug",
                    mobType: isFly ? 4 : 3,
                    level: 10 + i,
                    hp: 120 + (i * 20),
                    maxHP: 120 + (i * 20),
                    attack: 24 + (i * 4),
                    defense: 20 + (i * 3),
                    expReward: 120 + (i * 30),
                    gilReward: 60 + (i * 20),
                    x: 4 + (i * 4),
                    y: 5 + (i * 2),
                    alive: true,
                    respawnTimer: 0,
                    attackTimer: 0
                ))
            }
        case 3: // Selbina
            currentZoneName = "Selbina"
            npcs.append(NPCData(name: "Isacio", x: 8, y: 5, text: "Bring me items for your Subjob!"))
        default:
            currentZoneName = "Vana'diel Wilderness"
        }
    }

    private func addLog(_ text: String, color: UInt32) {
        combatLog.append((text: text, color: color))
        if combatLog.count > 6 {
            combatLog.removeFirst()
        }
    }

    private func updateLogic() {
        switch currentScreen {
        case .title:
            if isPressed(ControllerInput.down) {
                menuCursor = (menuCursor + 1) % 2
            }
            if isPressed(ControllerInput.up) {
                menuCursor = (menuCursor + 1) % 2
            }
            if isPressed(ControllerInput.a) || isPressed(ControllerInput.start) {
                if menuCursor == 0 {
                    currentScreen = .characterCreation
                    createStep = 0
                } else {
                    loadGameSRAM()
                    currentScreen = .exploration
                }
            }
        case .characterCreation:
            if createStep == 0 { // Race
                if isPressed(ControllerInput.right) { createRace = (createRace + 1) % 5 }
                if isPressed(ControllerInput.left)  { createRace = (createRace + 4) % 5 }
                if isPressed(ControllerInput.a)     { createStep = 1 }
            } else if createStep == 1 { // Job
                if isPressed(ControllerInput.right) { createJob = (createJob + 1) % 6 }
                if isPressed(ControllerInput.left)  { createJob = (createJob + 5) % 6 }
                if isPressed(ControllerInput.b)     { createStep = 0 }
                if isPressed(ControllerInput.a)     { createStep = 2 }
            } else if createStep == 2 { // Nation
                if isPressed(ControllerInput.right) { createNation = (createNation + 1) % 3 }
                if isPressed(ControllerInput.left)  { createNation = (createNation + 2) % 3 }
                if isPressed(ControllerInput.b)     { createStep = 1 }
                if isPressed(ControllerInput.a) {
                    changeZone(newZone: 0, spawnX: 10, spawnY: 8)
                    currentScreen = .exploration
                }
            }
        case .exploration:
            updateExploration()
        case .actionMenu:
            if isPressed(ControllerInput.down) { menuCursor = (menuCursor + 1) % 5 }
            if isPressed(ControllerInput.up)   { menuCursor = (menuCursor + 4) % 5 }
            if isPressed(ControllerInput.b) || isPressed(ControllerInput.start) {
                currentScreen = .exploration
            }
            if isPressed(ControllerInput.a) {
                switch menuCursor {
                case 0: currentScreen = .statusMenu
                case 1: currentScreen = .weaponSkillMenu; menuCursor = 0
                case 2: currentScreen = .magicMenu; menuCursor = 0
                case 3:
                    isResting.toggle()
                    addLog(isResting ? "/heal (Kneeling to rest)" : "Stood up.", color: 0xFFFFFFFF)
                    currentScreen = .exploration
                case 4:
                    saveGameSRAM()
                    currentScreen = .exploration
                default: break
                }
            }
        case .statusMenu:
            if isPressed(ControllerInput.b) || isPressed(ControllerInput.a) {
                currentScreen = .actionMenu
            }
        case .weaponSkillMenu:
            if isPressed(ControllerInput.b) { currentScreen = .actionMenu }
            if isPressed(ControllerInput.a) {
                executeWeaponSkill(wsIndex: menuCursor)
                currentScreen = .exploration
            }
        case .magicMenu:
            if isPressed(ControllerInput.b) { currentScreen = .actionMenu }
            if isPressed(ControllerInput.a) {
                castSpell(spellIndex: menuCursor)
                currentScreen = .exploration
            }
        case .gameOver:
            if isPressed(ControllerInput.start) || isPressed(ControllerInput.a) {
                playerHP = playerMaxHP / 2
                inCombat = false
                changeZone(newZone: 0, spawnX: 10, spawnY: 8)
                currentScreen = .exploration
            }
        }
    }

    private func updateExploration() {
        if isResting {
            restTimer += 1
            if restTimer >= 60 {
                restTimer = 0
                if playerHP < playerMaxHP { playerHP = min(playerMaxHP, playerHP + 8) }
                if playerMP < playerMaxMP { playerMP = min(playerMaxMP, playerMP + 10) }
            }
        }

        // Auto attack timer
        if inCombat && targetMobIndex >= 0 && targetMobIndex < mobs.count && mobs[targetMobIndex].alive {
            weaponDelayTimer += 1
            if weaponDelayTimer >= weaponDelayMax {
                weaponDelayTimer = 0
                executePlayerAttack()
            }
        }

        // Mob attack & respawn tick
        for i in 0..<mobs.count {
            if !mobs[i].alive {
                if mobs[i].respawnTimer > 0 {
                    mobs[i].respawnTimer -= 1
                    if mobs[i].respawnTimer == 0 {
                        mobs[i].alive = true
                        mobs[i].hp = mobs[i].maxHP
                    }
                }
                continue
            }
            if inCombat && targetMobIndex == i {
                mobs[i].attackTimer += 1
                if mobs[i].attackTimer >= 75 {
                    mobs[i].attackTimer = 0
                    let dmg = max(1, mobs[i].attack - 6)
                    playerHP = max(0, playerHP - dmg)
                    addLog("\(mobs[i].name) hits for \(dmg) dmg!", color: 0xFFFF5555)
                    if playerHP <= 0 {
                        inCombat = false
                        currentScreen = .gameOver
                    }
                }
            }
        }

        // Open menu
        if isPressed(ControllerInput.start) {
            currentScreen = .actionMenu
            menuCursor = 0
            return
        }

        // Cycle target
        if isPressed(ControllerInput.select) {
            for i in 0..<mobs.count {
                let idx = (targetMobIndex + 1 + i) % mobs.count
                if mobs[idx].alive {
                    targetMobIndex = idx
                    addLog("Target: \(mobs[idx].name)", color: 0xFFFFFF00)
                    break
                }
            }
        }

        // Disengage
        if isPressed(ControllerInput.b) {
            if inCombat {
                inCombat = false
                targetMobIndex = -1
                addLog("Disengaged.", color: 0xFFAAAAAA)
            }
        }

        // Action / Talk / Engage
        if isPressed(ControllerInput.a) {
            var talked = false
            for npc in npcs {
                let dx = abs(playerX - npc.x)
                let dy = abs(playerY - npc.y)
                if dx <= 1 && dy <= 1 {
                    addLog("[\(npc.name)]: \(npc.text)", color: 0xFFFFD700)
                    talked = true
                    break
                }
            }
            if !talked {
                if targetMobIndex >= 0 && targetMobIndex < mobs.count && mobs[targetMobIndex].alive {
                    if !inCombat {
                        inCombat = true
                        weaponDelayTimer = 0
                        addLog("Engaged \(mobs[targetMobIndex].name)!", color: 0xFF00FFFF)
                    }
                } else {
                    for i in 0..<mobs.count where mobs[i].alive {
                        targetMobIndex = i
                        inCombat = true
                        weaponDelayTimer = 0
                        addLog("Engaged \(mobs[i].name)!", color: 0xFF00FFFF)
                        break
                    }
                }
            }
        }

        // Movement
        if !isResting {
            var nx = playerX
            var ny = playerY
            if isDown(ControllerInput.up) && frameCount % 6 == 0 && ny > 2 { ny -= 1; playerDir = 1 }
            if isDown(ControllerInput.down) && frameCount % 6 == 0 && ny < 9 { ny += 1; playerDir = 0 }
            if isDown(ControllerInput.left) && frameCount % 6 == 0 && nx > 1 { nx -= 1; playerDir = 2 }
            if isDown(ControllerInput.right) && frameCount % 6 == 0 && nx < 18 { nx += 1; playerDir = 3 }
            playerX = nx
            playerY = ny

            // Zone transitions
            if nx >= 18 {
                if currentZoneID == 0 { changeZone(newZone: 1, spawnX: 2, spawnY: 6) }
                else if currentZoneID == 1 { changeZone(newZone: 2, spawnX: 2, spawnY: 6) }
                else if currentZoneID == 2 { changeZone(newZone: 3, spawnX: 2, spawnY: 6) }
            } else if nx <= 1 {
                if currentZoneID == 1 { changeZone(newZone: 0, spawnX: 17, spawnY: 6) }
                else if currentZoneID == 2 { changeZone(newZone: 1, spawnX: 17, spawnY: 6) }
                else if currentZoneID == 3 { changeZone(newZone: 2, spawnX: 17, spawnY: 6) }
            }
        }
    }

    private func executePlayerAttack() {
        guard targetMobIndex >= 0 && targetMobIndex < mobs.count && mobs[targetMobIndex].alive else { return }
        let dmg = max(1, 15 - (mobs[targetMobIndex].defense / 2) + Int.random(in: 1...5))
        mobs[targetMobIndex].hp -= dmg
        playerTP = min(3000, playerTP + 140)
        addLog("Hits \(mobs[targetMobIndex].name) for \(dmg) dmg.", color: 0xFFFFFFFF)

        if mobs[targetMobIndex].hp <= 0 {
            mobs[targetMobIndex].hp = 0
            mobs[targetMobIndex].alive = false
            mobs[targetMobIndex].respawnTimer = 180
            inCombat = false
            addLog("Target defeated! +\(mobs[targetMobIndex].expReward) EXP", color: 0xFFFFD700)
            playerEXP += mobs[targetMobIndex].expReward
            playerGil += mobs[targetMobIndex].gilReward
            checkLevelUp()
        }
    }

    private func executeWeaponSkill(wsIndex: Int) {
        guard playerTP >= 1000 else {
            addLog("Not enough TP! (1000 required)", color: 0xFFFF5555)
            return
        }
        guard targetMobIndex >= 0 && targetMobIndex < mobs.count && mobs[targetMobIndex].alive else { return }
        playerTP -= 1000
        let wsNames = ["Fast Blade", "Combo", "Red Lotus Blade", "Viper Bite"]
        let dmg = 45 + Int.random(in: 5...15)
        mobs[targetMobIndex].hp -= dmg
        addLog("\(wsNames[wsIndex % 4]) hits for \(dmg) dmg!", color: 0xFFFFA500)
        if mobs[targetMobIndex].hp <= 0 {
            mobs[targetMobIndex].alive = false
            mobs[targetMobIndex].respawnTimer = 180
            inCombat = false
            addLog("Target defeated! +\(mobs[targetMobIndex].expReward) EXP", color: 0xFFFFD700)
            playerEXP += mobs[targetMobIndex].expReward
            checkLevelUp()
        }
    }

    private func castSpell(spellIndex: Int) {
        if spellIndex == 0 { // Cure
            if playerMP < 8 { addLog("Not enough MP!", color: 0xFFFF5555); return }
            playerMP -= 8
            playerHP = min(playerMaxHP, playerHP + 35)
            addLog("Cure casts! Recovered 35 HP.", color: 0xFF50C878)
        } else { // Stone
            if playerMP < 9 { addLog("Not enough MP!", color: 0xFFFF5555); return }
            guard targetMobIndex >= 0 && targetMobIndex < mobs.count && mobs[targetMobIndex].alive else { return }
            playerMP -= 9
            let dmg = 28 + Int.random(in: 2...8)
            mobs[targetMobIndex].hp -= dmg
            addLog("Stone deals \(dmg) earth damage!", color: 0xFFE5C158)
            if mobs[targetMobIndex].hp <= 0 {
                mobs[targetMobIndex].alive = false
                mobs[targetMobIndex].respawnTimer = 180
                inCombat = false
                addLog("Target defeated! +\(mobs[targetMobIndex].expReward) EXP", color: 0xFFFFD700)
                playerEXP += mobs[targetMobIndex].expReward
                checkLevelUp()
            }
        }
    }

    private func checkLevelUp() {
        if playerEXP >= playerEXPToNext {
            playerEXP -= playerEXPToNext
            playerLevel += 1
            playerEXPToNext = playerLevel * 750
            playerMaxHP += 14
            playerHP = playerMaxHP
            playerMaxMP += 12
            playerMP = playerMaxMP
            addLog("LEVEL UP! Now Level \(playerLevel)!", color: 0xFFFFD700)
        }
    }

    // Save/Load to iOS Documents as GBA SRAM file
    public func saveGameSRAM() {
        let saveURL = getSRAMURL()
        var sramData = Data(count: 65536)
        // Magic "FFXI"
        sramData[0] = 0x46; sramData[1] = 0x46; sramData[2] = 0x58; sramData[3] = 0x49
        sramData[4] = UInt8(playerLevel)
        sramData[5] = UInt8(currentZoneID)
        try? sramData.write(to: saveURL)
        addLog("Game saved to battery SRAM!", color: 0xFFFFD700)
    }

    public func loadGameSRAM() {
        let saveURL = getSRAMURL()
        guard let data = try? Data(contentsOf: saveURL), data.count >= 6 else { return }
        if data[0] == 0x46 && data[1] == 0x46 && data[2] == 0x58 && data[3] == 0x49 {
            playerLevel = Int(data[4])
            changeZone(newZone: Int(data[5]), spawnX: 10, spawnY: 8)
            addLog("Game loaded from SRAM!", color: 0xFF50C878)
        }
    }

    public func getSRAMURL() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("FFXI-Advance.sav")
    }

    public func getROMURL() -> URL? {
        if let bundleROM = Bundle.main.url(forResource: "FFXI-Advance", withExtension: "gba") {
            return bundleROM
        }
        let docROM = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("FFXI-Advance.gba")
        if FileManager.default.fileExists(atPath: docROM.path) {
            return docROM
        }
        return nil
    }

    // Render 240x160 buffer
    private func renderScreen() {
        switch currentScreen {
        case .title:
            drawTitle()
        case .characterCreation:
            drawCharCreate()
        case .exploration:
            drawExplore()
        case .actionMenu:
            drawExplore()
            drawActionMenu()
        case .statusMenu:
            drawStatus()
        case .weaponSkillMenu:
            drawExplore()
            drawWSMenu()
        case .magicMenu:
            drawExplore()
            drawMagicMenu()
        case .gameOver:
            drawGameOver()
        }
    }

    private func drawTitle() {
        fillBuffer(color: 0xFF050812)
        drawWindow(x: 15, y: 15, w: 210, h: 54, title: nil)
        drawString(x: 40, y: 24, text: "FINAL FANTASY XI", color: 0xFFFFD700)
        drawString(x: 48, y: 38, text: "Vana'diel Advance", color: 0xFFFFFFFF)
        drawString(x: 55, y: 50, text: "Playable on Delta iOS", color: 0xFF00FFFF)

        drawWindow(x: 60, y: 80, w: 120, h: 48, title: nil)
        drawString(x: 82, y: 88, text: "New Game", color: menuCursor == 0 ? 0xFFFFD700 : 0xFFFFFFFF)
        drawString(x: 82, y: 102, text: "Continue", color: menuCursor == 1 ? 0xFFFFD700 : 0xFFFFFFFF)
        drawString(x: 72, y: 88 + (menuCursor * 14), text: ">", color: 0xFFFFD700)

        drawString(x: 30, y: 142, text: "(c) 2026 Bates LLC / batesai.org", color: 0xFF888888)
    }

    private func drawCharCreate() {
        fillBuffer(color: 0xFF080C18)
        drawWindow(x: 10, y: 8, w: 220, h: 22, title: nil)
        let titles = ["Select Race (D-Pad < >)", "Select Job (D-Pad < >)", "Select Starting Nation"]
        drawString(x: 20, y: 14, text: titles[createStep], color: 0xFFFFD700)

        drawWindow(x: 10, y: 35, w: 105, h: 115, title: "Character")
        drawPlayerSprite(x: 48, y: 55, race: createRace, job: createJob)
        let races = ["Hume", "Elvaan", "Tarutaru", "Mithra", "Galka"]
        let jobs = ["Warrior (WAR)", "Monk (MNK)", "White Mage (WHM)", "Black Mage (BLM)", "Red Mage (RDM)", "Thief (THF)"]
        drawString(x: 20, y: 85, text: races[createRace], color: 0xFFFFFFFF)
        drawString(x: 15, y: 100, text: jobs[createJob], color: 0xFF00FFFF)

        drawWindow(x: 120, y: 35, w: 110, h: 115, title: "Details")
        drawString(x: 126, y: 55, text: "Vana'diel Hero\nReady for\nDelta on iOS!", color: 0xFFFFFFFF)
        drawString(x: 126, y: 135, text: "[A] Next [B] Back", color: 0xFFFFD700)
    }

    private func drawExplore() {
        // Environment top 100px
        let envColor: UInt32 = (currentZoneID == 2) ? 0xFFC2B280 : (currentZoneID == 0 ? 0xFF2A2A35 : 0xFF1B3D1B)
        fillRect(x: 0, y: 0, w: 240, h: 100, color: envColor)
        drawString(x: 8, y: 6, text: "\(currentZoneName)", color: 0xFFFFD700)

        // NPCs
        for npc in npcs {
            let px = npc.x * 12
            let py = npc.y * 8 + 10
            drawPlayerSprite(x: px, y: py, race: 0, job: 4)
            drawString(x: px - 8, y: py - 8, text: npc.name, color: 0xFFFFD700)
        }

        // Mobs
        for (i, mob) in mobs.enumerated() where mob.alive {
            let mx = mob.x * 12
            let my = mob.y * 8 + 10
            drawMobSprite(x: mx, y: my, mobType: mob.mobType)
            if targetMobIndex == i {
                drawRectOutline(x: mx - 2, y: my - 2, w: 20, h: 20, color: 0xFFFFFF00)
                drawString(x: mx - 12, y: my - 9, text: mob.name, color: 0xFFFFFF00)
            }
        }

        // Player
        let px = playerX * 12
        let py = playerY * 8 + 10
        drawPlayerSprite(x: px, y: py, race: createRace, job: createJob)
        if isResting {
            drawString(x: px - 4, y: py - 8, text: "/heal", color: 0xFF00FFFF)
        }

        // HUD bottom 60px
        drawWindow(x: 0, y: 100, w: 240, h: 60, title: nil)
        drawString(x: 6, y: 104, text: "Daniel Lv.\(playerLevel)", color: 0xFFFFFFFF)

        // HP Gauge
        drawString(x: 6, y: 116, text: "HP", color: 0xFFFFFFFF)
        drawGauge(x: 24, y: 117, w: 50, h: 7, current: playerHP, max: playerMaxHP, color: 0xFF50C878)

        // MP Gauge
        drawString(x: 6, y: 128, text: "MP", color: 0xFFFFFFFF)
        drawGauge(x: 24, y: 129, w: 50, h: 7, current: playerMP, max: max(1, playerMaxMP), color: 0xFF00BFFF)

        // TP Gauge
        drawString(x: 6, y: 140, text: "TP", color: 0xFFFFFFFF)
        drawGauge(x: 24, y: 141, w: 50, h: 7, current: playerTP, max: 3000, color: playerTP >= 1000 ? 0xFFFFD700 : 0xFF3A5BA0)

        // Combat log
        var ly = 104
        for item in combatLog.suffix(4) {
            drawString(x: 82, y: ly, text: item.text, color: item.color)
            ly += 12
        }

        if inCombat {
            drawString(x: 184, y: 102, text: "[BATTLE]", color: 0xFFFF3333)
        }
    }

    private func drawActionMenu() {
        drawWindow(x: 70, y: 20, w: 105, h: 86, title: "Action Menu")
        let opts = ["Status", "Weapon Skills", "Magic", "Rest (/heal)", "Save Game"]
        for (i, opt) in opts.enumerated() {
            let col: UInt32 = (menuCursor == i) ? 0xFFFFD700 : 0xFFFFFFFF
            drawString(x: 88, y: 34 + (i * 13), text: opt, color: col)
        }
        drawString(x: 76, y: 34 + (menuCursor * 13), text: ">", color: 0xFFFFD700)
    }

    private func drawWSMenu() {
        drawWindow(x: 60, y: 25, w: 120, h: 75, title: "Weapon Skills")
        let ws = ["Fast Blade (1000)", "Combo      (1000)", "Red Lotus  (1000)", "Viper Bite (1000)"]
        for (i, w) in ws.enumerated() {
            let col: UInt32 = (menuCursor == i) ? 0xFFFFD700 : (playerTP >= 1000 ? 0xFFFFFFFF : 0xFF888888)
            drawString(x: 76, y: 40 + (i * 12), text: w, color: col)
        }
        drawString(x: 66, y: 40 + (menuCursor * 12), text: ">", color: 0xFFFFD700)
    }

    private func drawMagicMenu() {
        drawWindow(x: 60, y: 30, w: 120, h: 55, title: "Magic")
        let spells = ["Cure    (8 MP)", "Stone   (9 MP)"]
        for (i, sp) in spells.enumerated() {
            let col: UInt32 = (menuCursor == i) ? 0xFFFFD700 : 0xFFFFFFFF
            drawString(x: 76, y: 45 + (i * 14), text: sp, color: col)
        }
        drawString(x: 66, y: 45 + (menuCursor * 14), text: ">", color: 0xFFFFD700)
    }

    private func drawStatus() {
        fillBuffer(color: 0xFF0A0F1E)
        drawWindow(x: 10, y: 10, w: 220, h: 140, title: "Player Status")
        drawPlayerSprite(x: 25, y: 30, race: createRace, job: createJob)
        drawString(x: 50, y: 30, text: "Daniel Bates", color: 0xFFFFD700)
        drawString(x: 50, y: 44, text: "Lv. \(playerLevel) Adventurer", color: 0xFFFFFFFF)
        drawString(x: 50, y: 58, text: "Gil: \(playerGil)", color: 0xFFFFD700)

        drawWindow(x: 20, y: 75, w: 200, h: 65, title: nil)
        drawString(x: 30, y: 85, text: "STR: 14   INT: 12", color: 0xFF00FFFF)
        drawString(x: 30, y: 98, text: "DEX: 12   MND: 11", color: 0xFF00FFFF)
        drawString(x: 30, y: 111, text: "VIT: 13   AGI: 11", color: 0xFF00FFFF)
        drawString(x: 140, y: 125, text: "[B] Back", color: 0xFFFFD700)
    }

    private func drawGameOver() {
        fillBuffer(color: 0xFF2A0000)
        drawWindow(x: 30, y: 40, w: 180, h: 70, title: nil)
        drawString(x: 45, y: 55, text: "You have been defeated...", color: 0xFFFF3333)
        drawString(x: 42, y: 80, text: "Press START to return Home", color: 0xFFFFFFFF)
    }

    // Primitives
    private func fillBuffer(color: UInt32) {
        for i in 0..<renderBuffer.count { renderBuffer[i] = color }
    }

    private func fillRect(x: Int, y: Int, w: Int, h: Int, color: UInt32) {
        let x0 = max(0, x), y0 = max(0, y)
        let x1 = min(VanaDielEngine.screenWidth, x + w)
        let y1 = min(VanaDielEngine.screenHeight, y + h)
        guard x1 > x0 && y1 > y0 else { return }
        for j in y0..<y1 {
            let rowOffset = j * VanaDielEngine.screenWidth
            for i in x0..<x1 {
                renderBuffer[rowOffset + i] = color
            }
        }
    }

    private func drawRectOutline(x: Int, y: Int, w: Int, h: Int, color: UInt32) {
        fillRect(x: x, y: y, w: w, h: 1, color: color)
        fillRect(x: x, y: y + h - 1, w: w, h: 1, color: color)
        fillRect(x: x, y: y, w: 1, h: h, color: color)
        fillRect(x: x + w - 1, y: y, w: 1, h: h, color: color)
    }

    private func drawWindow(x: Int, y: Int, w: Int, h: Int, title: String?) {
        // Shadow
        fillRect(x: x + 2, y: y + 2, w: w, h: h, color: 0xFF05050A)
        // Outer metallic border
        drawRectOutline(x: x, y: y, w: w, h: h, color: 0xFFB09050)
        // Dark blue marble body
        fillRect(x: x + 1, y: y + 1, w: w - 2, h: h - 2, color: 0xFF0C182E)

        if let title = title {
            fillRect(x: x + 1, y: y + 1, w: w - 2, h: 11, color: 0xFF142445)
            fillRect(x: x + 1, y: y + 12, w: w - 2, h: 1, color: 0xFFB09050)
            drawString(x: x + 5, y: y + 3, text: title, color: 0xFFFFD700)
        }
    }

    private func drawGauge(x: Int, y: Int, w: Int, h: Int, current: Int, max: Int, color: UInt32) {
        let safeMax = Swift.max(1, max)
        let fillW = (w * Swift.min(safeMax, Swift.max(0, current))) / safeMax
        drawRectOutline(x: x, y: y, w: w, h: h, color: 0xFF444444)
        fillRect(x: x + 1, y: y + 1, w: w - 2, h: h - 2, color: 0xFF111111)
        if fillW > 2 {
            fillRect(x: x + 1, y: y + 1, w: fillW - 2, h: h - 2, color: color)
        }
    }

    private func drawString(x: Int, y: Int, text: String, color: UInt32) {
        var cx = x
        var cy = y
        for char in text {
            if char == "\n" {
                cx = x
                cy += 9
                continue
            }
            drawChar(x: cx, y: cy, char: char, color: color)
            cx += 7
        }
    }

    private func drawChar(x: Int, y: Int, char: Character, color: UInt32) {
        guard let ascii = char.asciiValue, ascii >= 32 && ascii <= 126 else { return }
        let glyphIndex = Int(ascii - 32)
        // 8x8 bitmap drawing
        for row in 0..<8 {
            let py = y + row
            guard py >= 0 && py < VanaDielEngine.screenHeight else { continue }
            let rowOffset = py * VanaDielEngine.screenWidth
            for col in 0..<8 {
                let px = x + col
                guard px >= 0 && px < VanaDielEngine.screenWidth else { continue }
                // Use a simple font bit pattern
                if isFontBitSet(glyphIndex: glyphIndex, row: row, col: col) {
                    renderBuffer[rowOffset + px] = color
                }
            }
        }
    }

    private func isFontBitSet(glyphIndex: Int, row: Int, col: Int) -> Bool {
        // Fallback block/letter shape rendering
        if glyphIndex == 0 { return false } // space
        if row == 0 || row == 7 || col == 0 || col == 7 {
            return (glyphIndex % 3 == 0) && (row == col)
        }
        return (glyphIndex * 7 + row * 3 + col) % 5 == 0
    }

    private func drawPlayerSprite(x: Int, y: Int, race: Int, job: Int) {
        let armorColor: UInt32 = (job == 2) ? 0xFFFFFFFF : ((job == 4) ? 0xFFDC143C : 0xFF4682B4)
        fillRect(x: x + 5, y: y + 2, w: 6, h: 5, color: 0xFFF5DEB3) // Face
        fillRect(x: x + 4, y: y + 1, w: 8, h: 3, color: armorColor) // Helm
        fillRect(x: x + 4, y: y + 7, w: 8, h: 5, color: armorColor) // Chest
        fillRect(x: x + 4, y: y + 12, w: 3, h: 4, color: 0xFF333333) // Leg L
        fillRect(x: x + 9, y: y + 12, w: 3, h: 4, color: 0xFF333333) // Leg R
    }

    private func drawMobSprite(x: Int, y: Int, mobType: Int) {
        let mobColor: UInt32 = (mobType == 0) ? 0xFFE0E0E0 : ((mobType == 1) ? 0xFF8B0000 : 0xFFDAA520)
        fillRect(x: x + 4, y: y + 4, w: 8, h: 8, color: mobColor)
        fillRect(x: x + 5, y: y + 6, w: 2, h: 2, color: 0xFFFF0000) // Eyes
        fillRect(x: x + 9, y: y + 6, w: 2, h: 2, color: 0xFFFF0000)
    }
}
