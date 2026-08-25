# ==============================================================================
# update_kb.ps1
# Cykliczna aktualizacja bazy wiedzy TSL (Baza_Wiedzy\) przez Claude Code.
# Uruchamiaj przez Harmonogram zadań Windows (Task Scheduler). Wymaga
# zainstalowanego i zalogowanego Claude Code CLI na tej maszynie
# (patrz SETUP.md, krok 3-4).
# ==============================================================================

# --- KONFIGURACJA: dostosuj tę ścieżkę do lokalizacji Twojego projektu ---
$ProjectDir = "C:\Projekty\tsl-skill"          # <-- ZMIEŃ na realną ścieżkę
$LogDir     = Join-Path $ProjectDir ".kb_update_logs"
$DateTag    = Get-Date -Format "yyyy-MM-dd_HH-mm"
$LogFile    = Join-Path $LogDir "update_$DateTag.log"

New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
Set-Location $ProjectDir

"=== Start aktualizacji bazy wiedzy TSL: $DateTag ===" | Tee-Object -FilePath $LogFile -Append

$Prompt = @"
Przejrzyj plik CLAUDE.md w tym katalogu (glowny plik instrukcji projektu)
oraz wszystkie pliki w Baza_Wiedzy/. Dla kazdego pliku .txt w Baza_Wiedzy/:
sprawdz date 'Stan na dzien aktualizacji pliku' w naglowku, nastepnie
zweryfikuj przez web search (ISAP dla polskich ustaw, EUR-Lex dla
rozporzadzen UE, PUESC dla SENT), czy opisane w pliku kwoty kar, progi,
terminy i daty wejscia w zycie przepisow sa nadal aktualne. Jesli
znajdziesz zmiane - zaktualizuj tresc pliku (zachowujac dotychczasowa
strukture i styl), zaktualizuj date 'Stan na dzien aktualizacji pliku' na
dzisiejsza oraz dopisz link zrodlowy. Jesli nic sie nie zmienilo w danym
pliku - zostaw go bez zmian. NIE modyfikuj CLAUDE.md w ramach tego
zadania - czytaj go tylko jako kontekst/instrukcje, edytuj wylacznie
pliki .txt w Baza_Wiedzy/. Na koncu wypisz krotkie podsumowanie: ktore
pliki zostaly zmienione i co sie w nich zmienilo, a ktore pozostaly bez
zmian.
"@

# --dangerously-skip-permissions: potrzebne w trybie nienadzorowanym, bo
# nikt nie kliknie "zatwierdz" edycje pliku. Uruchamiaj TYLKO w katalogu
# projektu poswieconym tej bazie wiedzy.
claude -p $Prompt --dangerously-skip-permissions 2>&1 | Tee-Object -FilePath $LogFile -Append

"=== Koniec aktualizacji: $(Get-Date -Format 'yyyy-MM-dd_HH-mm') ===" | Tee-Object -FilePath $LogFile -Append

# Opcjonalnie: commit zmian do gita (odkomentuj, jesli projekt jest repo)
# UWAGA: celowo NIE dodajemy tu CLAUDE.md - ten skrypt ma aktualizowac
# wylacznie Baza_Wiedzy/, a CLAUDE.md zmieniac recznie, swiadomie.
# git add Baza_Wiedzy\
# git commit -m "auto-update bazy wiedzy TSL: $DateTag"

# Czyszczenie logow starszych niz 90 dni
Get-ChildItem -Path $LogDir -Filter "update_*.log" |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-90) } |
    Remove-Item -Force
