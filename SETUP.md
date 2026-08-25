# Wdrożenie bazy wiedzy TSL + automatyczna aktualizacja

## 1. Gdzie umieścić pobrane pliki

Struktura, którą pobrałeś, powinna trafić do katalogu Twojego projektu
(tam, gdzie pracujesz z Claude Code), np.:

```
tsl-skill/                          <- katalog projektu (dowolna nazwa)
├── SKILL.md
├── update_kb.sh                    <- (Linux/Mac)
├── update_kb.ps1                   <- (Windows)
└── Baza_Wiedzy/
    ├── Czas_pracy_i_Rozporzadzenie_561.txt
    ├── Rozporzadzenie_165_2014.txt
    ├── Ustawa_o_transporcie_drogowym.txt
    ├── Prawo_o_ruchu_drogowym.txt
    ├── Konwencja_CMR.txt
    ├── Prawo_przewozowe.txt
    └── Ustawa_SENT.txt
```

Jeśli chcesz, żeby to działało jako **skill Claude Code** (a nie tylko
zwykłe pliki w repo), umieść to w:

```
<Twój projekt>/.claude/skills/tsl-transport/
    SKILL.md
    Baza_Wiedzy/...
```

Claude Code automatycznie wykrywa skille w `.claude/skills/` i sam
decyduje, kiedy je wczytać na podstawie treści `SKILL.md` (opisu na
górze pliku) — nie musisz nic ręcznie „włączać”, wystarczy że pliki tam
leżą.

Jeśli wolisz trzymać to jako zwykłą bazę wiedzy dołączaną w kontekście
projektu (nie jako formalny skill), po prostu trzymaj folder
`Baza_Wiedzy/` i `SKILL.md` w głównym katalogu repo — Claude Code i tak
je odczyta, gdy poprosisz o coś związanego z transportem, albo gdy
odwołasz się do nich w `CLAUDE.md` (opcjonalnie dopisz tam linijkę:
`Przy pytaniach transportowych czytaj SKILL.md i pliki w Baza_Wiedzy/`).

## 2. Jednorazowa weryfikacja, że wszystko działa

W terminalu, w katalogu projektu:

```bash
claude
```

i zapytaj np. „Jaka jest kara za brak zgłoszenia SENT?” — Claude Code
powinien sam sięgnąć po `Ustawa_SENT.txt` i (jeśli masz dostęp do web
search) dosprawdzić aktualność kwoty.

## 3. Instalacja i logowanie Claude Code (jeśli jeszcze nie masz)

```bash
npm install -g @anthropic-ai/claude-code
claude login
```

Zaloguj się raz, interaktywnie — sesja/token zostanie zapisany lokalnie
i będzie używany także przy uruchomieniach z crona / Harmonogramu zadań
(które same nie potrafią się zalogować).

## 4. Automatyczna aktualizacja — Linux/Mac (cron)

1. Otwórz `update_kb.sh`, zmień linię:
   ```bash
   PROJECT_DIR="$HOME/projekty/tsl-skill"
   ```
   na prawdziwą ścieżkę do Twojego projektu.

2. Nadaj uprawnienia do wykonania:
   ```bash
   chmod +x update_kb.sh
   ```

3. Otwórz edytor crona:
   ```bash
   crontab -e
   ```

4. Dodaj linię (przykład: uruchomienie raz w miesiącu, 1. dnia o 6:00):
   ```
   0 6 1 * * /bin/bash /pelna/sciezka/do/update_kb.sh >> /pelna/sciezka/do/tsl-skill/.kb_update_logs/cron.log 2>&1
   ```
   Częściej (np. co tydzień, w każdy poniedziałek o 6:00):
   ```
   0 6 * * 1 /bin/bash /pelna/sciezka/do/update_kb.sh >> /pelna/sciezka/do/tsl-skill/.kb_update_logs/cron.log 2>&1
   ```

5. Zapisz i zamknij — cron sam podejmie zadanie od tego momentu. Logi
   z każdego przebiegu znajdziesz w `.kb_update_logs/` obok skryptu.

## 5. Automatyczna aktualizacja — Windows (Harmonogram zadań)

1. Otwórz `update_kb.ps1`, zmień linię:
   ```powershell
   $ProjectDir = "C:\Projekty\tsl-skill"
   ```
   na prawdziwą ścieżkę do Twojego projektu.

2. Otwórz **Harmonogram zadań** (Task Scheduler) → **Utwórz zadanie
   podstawowe** (Create Basic Task).

3. Nazwa: `Aktualizacja bazy wiedzy TSL`. Wyzwalacz: np. co miesiąc /
   co tydzień, wg uznania.

4. Akcja: **Uruchom program**:
   - Program/skrypt: `powershell.exe`
   - Dodaj argumenty:
     ```
     -NoProfile -ExecutionPolicy Bypass -File "C:\Projekty\tsl-skill\update_kb.ps1"
     ```

5. Dokończ kreator. Możesz też ustawić to jednym poleceniem z linii
   komend (uruchom jako administrator), np. dla wykonania co tydzień w
   poniedziałek o 6:00:
   ```powershell
   schtasks /create /tn "AktualizacjaBazyTSL" /tr "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"C:\Projekty\tsl-skill\update_kb.ps1\"" /sc weekly /d MON /st 06:00
   ```

6. Logi z każdego przebiegu znajdziesz w `.kb_update_logs\` obok
   skryptu.

## 6. Ważne uwagi bezpieczeństwa i praktyczne

- Flaga `--dangerously-skip-permissions` jest konieczna w trybie
  automatycznym (nikt nie kliknie "zatwierdź" zmianę pliku), ale
  oznacza, że Claude Code może modyfikować pliki bez pytania. Dlatego
  skrypt działa **wyłącznie w katalogu projektu** poświęconym tej
  bazie wiedzy — nie uruchamiaj go w katalogu z innymi, wrażliwymi
  danymi.
- Zalecane: trzymaj projekt w git i odkomentuj linijki `git commit` w
  skrypcie — dzięki temu będziesz miał pełną historię tego, co i kiedy
  zostało zmienione (łatwo cofnąć błędną automatyczną edycję).
- Maszyna, na której działa cron/Harmonogram zadań, musi mieć dostęp
  do internetu (web search) — inaczej Claude Code nie będzie w stanie
  nic zweryfikować i zostawi pliki bez zmian.
- Zalecana częstotliwość: dla `Ustawa_SENT.txt` i
  `Ustawa_o_transporcie_drogowym.txt` (najczęściej nowelizowane) —
  raz w tygodniu lub co dwa tygodnie. Dla reszty (CMR, 561/2006) —
  raz w miesiącu w zupełności wystarczy.
- Po każdym uruchomieniu warto raz na jakiś czas ręcznie przejrzeć log
  i zmiany w plikach (zwłaszcza kwoty kar) — automatyzacja przyspiesza
  research, ale nie zastępuje ludzkiej weryfikacji przy realnych
  decyzjach finansowych firmy.
