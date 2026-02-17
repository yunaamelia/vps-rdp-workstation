
// Plasma 6 Script to create a Latte-style Dock
// Based on official KDE Plasma Scripting API

// 1. Clean up existing empty panels at the bottom to avoid duplicates
// (Optional logic, but safer to just create a new one for now)

var panel = new Panel
var screen = 0 // Primary screen

// --- Basic Geometry & Position ---
panel.screen = screen
panel.location = "bottom"
panel.height = 48 // Standard dock size
panel.floating = true // The "Latte" look
// panel.alignment = "center" // Not directly exposed in older API, handled via "Fit Content" or length logic below?
// In Plasma 6 scripting, 'lengthMode' might be available or we use min/max length

// --- Visibility ---
panel.hiding = "dodgewindows" // "none", "autohide", "dodgewindows", "windowsbelow"

// --- Widgets ---
// 1. Application Launcher (optional, let's include it for completeness)
// panel.addWidget("org.kde.plasma.kickoff")

// 2. Task Manager (The core of the dock)
var taskManager = panel.addWidget("org.kde.plasma.icontasks")

// Configure Task Manager
taskManager.currentConfigGroup = ["General"]
taskManager.writeConfig("launchers", "applications:systemsettings.desktop,applications:org.kde.dolphin.desktop") // Default pinned apps
taskManager.writeConfig("showOnlyCurrentScreen", true)

// 3. Trash
panel.addWidget("org.kde.plasma.trash")

// --- Apply Settings ---
// Note: Plasma automatically saves when script finishes.
print("Dock created successfully!")
