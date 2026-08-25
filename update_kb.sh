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
claude -p "Przejrzyj plik CLAUDE.md w tym katalogu (glowny plik instrukcji
projektu) oraz wszystkie pliki w Baza_Wiedzy/. Dla kazdego pliku .txt w
Baza_Wiedzy/: sprawdz date 'Stan na dzien aktualizacji pliku' w naglowku,
nastepnie zweryfikuj przez web search (ISAP dla polskich ustaw, EUR-Lex
dla rozporzadzen UE, PUESC dla SENT), czy opisane w pliku kwoty kar, progi,
terminy i daty wejscia w zycie przepisow sa nadal aktualne. Jesli znajdziesz
zmiane - zaktualizuj tresc pliku (zachowujac dotychczasowa strukture i
styl), zaktualizuj date 'Stan na dzien aktualizacji pliku' na dzisiejsza
oraz dopisz link zrodlowy. Jesli nic sie nie zmienilo w danym pliku -
zostaw go bez zmian. NIE modyfikuj CLAUDE.md w ramach tego zadania - czytaj
go tylko jako kontekst/instrukcje, edytuj wylacznie pliki .txt w
Baza_Wiedzy/. Na koncu wypisz krotkie podsumowanie: ktore pliki zostaly
zmienione i co sie w nich zmienilo, a ktore pozostaly bez zmian." \
  --dangerously-skip-permissions \
  2>&1 | tee -a "$LOG_FILE"

echo "=== Koniec aktualizacji: $(date +%Y-%m-%d_%H-%M) ===" | tee -a "$LOG_FILE"

# Wymuszenie UTF-8 z BOM na plikach bazy wiedzy (Notatnik na Windows czasem
# błędnie odczytuje UTF-8 bez BOM jako inne kodowanie - nieszkodliwe, ale
# zapewnia spójność, gdyby ktoś otwierał te pliki też na Windows).
echo "--- Naprawa kodowania plikow (UTF-8 BOM) ---" | tee -a "$LOG_FILE"
for f in "$PROJECT_DIR"/Baza_Wiedzy/*.txt; do
    if [ -f "$f" ]; then
        content="$(cat "$f")"
        printf '\xEF\xBB\xBF%s' "$content" > "$f"
        echo "Naprawiono kodowanie: $(basename "$f")" | tee -a "$LOG_FILE"
    fi
done

# Opcjonalnie: commit zmian do gita, jeśli projekt jest repo (zakomentowane
# domyślnie - odkomentuj, jeśli chcesz mieć historię zmian w git log).
# UWAGA: celowo NIE dodajemy tu CLAUDE.md - ten skrypt ma aktualizować
# wyłącznie Baza_Wiedzy/, a CLAUDE.md zmieniać ręcznie, świadomie.
# git add Baza_Wiedzy/
# git commit -m "auto-update bazy wiedzy TSL: $DATE_TAG" || echo "Brak zmian do commitowania"

# Czyszczenie starych logów (starszych niż 90 dni)
find "$LOG_DIR" -name "update_*.log" -mtime +90 -delete
