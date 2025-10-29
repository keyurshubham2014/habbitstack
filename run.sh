#!/bin/bash

# StackHabit - Flutter Run Script
# Quick commands to run the app on different platforms

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper function to print colored messages
print_message() {
    echo -e "${2}${1}${NC}"
}

print_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${1}"
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo ""
}

# Show menu
show_menu() {
    print_header "StackHabit - Flutter Run Menu"
    echo -e "${GREEN}Available Options:${NC}"
    echo ""
    echo "  ${YELLOW}1${NC}) Run on Android Emulator"
    echo "  ${YELLOW}2${NC}) Run on iOS Simulator"
    echo "  ${YELLOW}3${NC}) Run on Chrome (Web)"
    echo "  ${YELLOW}4${NC}) Run on macOS (Desktop)"
    echo "  ${YELLOW}5${NC}) Run in Release Mode (Android)"
    echo "  ${YELLOW}6${NC}) List Available Devices"
    echo "  ${YELLOW}7${NC}) List Available Emulators"
    echo "  ${YELLOW}8${NC}) Start Android Emulator"
    echo "  ${YELLOW}9${NC}) Clean and Rebuild"
    echo "  ${YELLOW}10${NC}) Hot Reload (if app is running)"
    echo "  ${YELLOW}11${NC}) Open DevTools"
    echo "  ${YELLOW}q${NC}) Quit"
    echo ""
    echo -n "Select an option: "
}

# Function to check if device is available
check_device() {
    local device_id=$1
    if flutter devices | grep -q "$device_id"; then
        return 0
    else
        return 1
    fi
}

# Main script
main() {
    # Check if Flutter is installed
    if ! command -v flutter &> /dev/null; then
        print_message "❌ Flutter is not installed!" "$RED"
        exit 1
    fi

    while true; do
        show_menu
        read -r choice

        case $choice in
            1)
                print_header "Running on Android Emulator"

                # Check if emulator is running
                if check_device "emulator"; then
                    print_message "✅ Android emulator detected!" "$GREEN"
                    flutter run -d emulator-5554
                else
                    print_message "⚠️  No Android emulator detected!" "$YELLOW"
                    echo ""
                    echo "Options:"
                    echo "  a) Start emulator first (option 8)"
                    echo "  b) Manually start from Android Studio"
                    echo ""
                    read -p "Press Enter to continue..."
                fi
                ;;

            2)
                print_header "Running on iOS Simulator"

                if check_device "ios"; then
                    print_message "✅ iOS simulator detected!" "$GREEN"
                    flutter run -d ios
                else
                    print_message "⚠️  No iOS simulator detected!" "$YELLOW"
                    echo ""
                    echo "To start iOS simulator:"
                    echo "  open -a Simulator"
                    echo ""
                    read -p "Press Enter to continue..."
                fi
                ;;

            3)
                print_header "Running on Chrome (Web)"

                if check_device "chrome"; then
                    print_message "✅ Chrome detected!" "$GREEN"
                    flutter run -d chrome
                else
                    print_message "❌ Chrome not available!" "$RED"
                    read -p "Press Enter to continue..."
                fi
                ;;

            4)
                print_header "Running on macOS (Desktop)"

                if check_device "macos"; then
                    print_message "✅ macOS desktop mode available!" "$GREEN"
                    flutter run -d macos
                else
                    print_message "❌ macOS desktop not available!" "$RED"
                    read -p "Press Enter to continue..."
                fi
                ;;

            5)
                print_header "Running in Release Mode (Android)"

                if check_device "emulator"; then
                    print_message "✅ Building optimized release version..." "$GREEN"
                    flutter run --release -d emulator-5554
                else
                    print_message "⚠️  No Android emulator detected!" "$YELLOW"
                    read -p "Press Enter to continue..."
                fi
                ;;

            6)
                print_header "Available Devices"
                flutter devices
                echo ""
                read -p "Press Enter to continue..."
                ;;

            7)
                print_header "Available Emulators"
                flutter emulators
                echo ""
                read -p "Press Enter to continue..."
                ;;

            8)
                print_header "Start Android Emulator"

                echo "Available emulators:"
                flutter emulators
                echo ""
                read -p "Enter emulator ID (or press Enter to skip): " emulator_id

                if [ -n "$emulator_id" ]; then
                    print_message "🚀 Starting emulator: $emulator_id" "$CYAN"
                    flutter emulators --launch "$emulator_id" &
                    print_message "⏳ Waiting for emulator to boot (30 seconds)..." "$YELLOW"
                    sleep 30
                    print_message "✅ Emulator should be ready!" "$GREEN"
                fi

                read -p "Press Enter to continue..."
                ;;

            9)
                print_header "Clean and Rebuild"

                print_message "🧹 Cleaning Flutter project..." "$CYAN"
                flutter clean

                print_message "📦 Getting dependencies..." "$CYAN"
                flutter pub get

                print_message "🔨 Building app..." "$CYAN"

                if check_device "emulator"; then
                    flutter run -d emulator-5554
                else
                    print_message "⚠️  No device detected. Build complete, but not running." "$YELLOW"
                    read -p "Press Enter to continue..."
                fi
                ;;

            10)
                print_header "Hot Reload Instructions"
                echo "If your app is currently running:"
                echo ""
                echo "  ${GREEN}r${NC}  - Hot reload (fast refresh)"
                echo "  ${GREEN}R${NC}  - Hot restart (full restart)"
                echo "  ${GREEN}h${NC}  - Show all commands"
                echo "  ${GREEN}d${NC}  - Detach (keep app running)"
                echo "  ${GREEN}c${NC}  - Clear screen"
                echo "  ${GREEN}q${NC}  - Quit app"
                echo ""
                read -p "Press Enter to continue..."
                ;;

            11)
                print_header "Opening Flutter DevTools"

                print_message "🛠️  Launching Flutter DevTools..." "$CYAN"
                flutter pub global activate devtools
                flutter pub global run devtools &

                print_message "✅ DevTools will open in your browser" "$GREEN"
                echo ""
                read -p "Press Enter to continue..."
                ;;

            q|Q)
                print_message "👋 Goodbye!" "$CYAN"
                exit 0
                ;;

            *)
                print_message "❌ Invalid option. Please try again." "$RED"
                sleep 1
                ;;
        esac
    done
}

# Run main function
main
