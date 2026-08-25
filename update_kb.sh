#!/bin/bash
# ==============================================================================
# update_kb.sh
# Cykliczna aktualizacja bazy wiedzy TSL (Baza_Wiedzy/) przez Claude Code.
# Uruchamiaj przez cron (Linux/Mac). Wymaga zainstalowanego i zalogowanego
# Claude Code CLI na tej maszynie (patrz SETUP.md, krok 3-4).
# ==============================================================================

set -euo pipefail

# --- KONFIGURACJA: dostosuj tę ścieżkę do lokalizacji Twojego projektu ---
PROJECT_DIR="$HOME/projekty/tsl-skill"      # <-- ZMIEŃ na realną ścieżkę
LOG_DIR="$PROJECT_DIR/.kb_update_logs"
DATE_TAG="$(date +%Y-%m-%d_%H-%M)"
LOG_FILE="$LOG_DIR/update_$DATE_TAG.log"

mkdir -p "$LOG_DIR"
cd "$PROJECT_DIR"

echo "=== Start aktualizacji bazy wiedzy TSL: $DATE_TAG ===" | tee -a "$LOG_FILE"

# --dangerously-skip-permissions: potrzebne w trybie headless/cron, bo nikt
# nie kliknie "zatwierdź" edycję pliku. Uruchamiaj TYLKO w katalogu projektu
# poświęconym tej bazie wiedzy, nigdy w katalogu z wrażliwymi danymi.
claude -p "Przejrzyj plik SKILL.md w tym katalogu oraz wszystkie pliki w
Baza_Wiedzy/. Dla każdego pliku .txt: sprawdź datę 'Stan na dzień
aktualizacji pliku' w nagłówku, następnie zweryfikuj przez web search
(ISAP dla polskich ustaw, EUR-Lex dla rozporządzeń UE, PUESC dla SENT),
czy opisane w pliku kwoty kar, progi, terminy i daty wejścia w życie
przepisów są nadal aktualne. Jeśli znajdziesz zmianę - zaktualizuj treść
pliku (zachowując dotychczasową strukturę i styl), zaktualizuj datę 'Stan
na dzień aktualizacji pliku' na dzisiejszą oraz dopisz link źródłowy.
Jeśli nic się nie zmieniło w danym pliku - zostaw go bez zmian. Na końcu
wypisz krótkie podsumowanie: które pliki zostały zmienione i co się w nich
zmieniło, a które pozostały bez zmian." \
  --dangerously-skip-permissions \
  2>&1 | tee -a "$LOG_FILE"

echo "=== Koniec aktualizacji: $(date +%Y-%m-%d_%H-%M) ===" | tee -a "$LOG_FILE"

# Opcjonalnie: commit zmian do gita, jeśli projekt jest repo (zakomentowane
# domyślnie - odkomentuj, jeśli chcesz mieć historię zmian w git log).
# git add Baza_Wiedzy/ SKILL.md
# git commit -m "auto-update bazy wiedzy TSL: $DATE_TAG" || echo "Brak zmian do commitowania"

# Czyszczenie starych logów (starszych niż 90 dni)
find "$LOG_DIR" -name "update_*.log" -mtime +90 -delete
