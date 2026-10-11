# Baza wiedzy TSL — wdrożenie i automatyczna aktualizacja

## 1. Struktura katalogu

Pliki powinny znaleźć się w katalogu projektu używanym z Claude Code:

```
tsl-skill/                          <- katalog projektu (dowolna nazwa)
├── CLAUDE.md
├── update_kb.sh                    <- Linux/Mac
├── update_kb.ps1                   <- Windows
└── Baza_Wiedzy/
    ├── Czas_pracy_i_Rozporzadzenie_561.txt
    ├── Rozporzadzenie_165_2014.txt
    ├── Ustawa_o_transporcie_drogowym.txt
    ├── Prawo_o_ruchu_drogowym.txt
    ├── Konwencja_CMR.txt
    ├── Prawo_przewozowe.txt
    ├── Ustawa_SENT.txt
    ├── Ustawa_o_czasie_pracy_kierowcow.txt
    ├── Pakiet_Mobilnosci_Delegowanie_Kierowcow.txt
    ├── ADR_Towary_Niebezpieczne.txt
    ├── Kabotaz_Przepisy_Krajowe.txt
    ├── eTOLL_Oplaty_Drogowe.txt
    ├── OCP_Ubezpieczenie_Przewoznika.txt
    ├── RODO_Dane_Lokalizacyjne_Kierowcow.txt
    └── AETR_Transport_Poza_UE.txt
```

`CLAUDE.md` musi znajdować się bezpośrednio w katalogu głównym projektu
(nie w podfolderze) — Claude Code traktuje ten plik jako główny,
wiążący zestaw instrukcji dla całego projektu i wczytuje go w całości
przy każdej sesji.

Alternatywa: umieszczenie tego samego zestawu w
`<projekt>/.claude/skills/tsl-transport/` (z plikiem `CLAUDE.md`
przemianowanym na `SKILL.md` w tej lokalizacji) sprawia, że Claude Code
sam decyduje, kiedy dany skill wczytać, na podstawie dopasowania tematu
rozmowy do opisu na górze pliku. Wadą tego podejścia jest niższy
priorytet egzekwowania reguł względem `CLAUDE.md` — w testach reguły
umieszczone w `CLAUDE.md` były przestrzegane rygorystycznie, podczas
gdy te same reguły w `SKILL.md` bywały pomijane przy krótszych,
prostszych zapytaniach. Rekomendowane podejście to `CLAUDE.md` w
katalogu głównym.

## 2. Weryfikacja działania

W terminalu, w katalogu projektu:

```bash
claude
```

Przykładowe zapytanie testowe: „Jaka jest kara za brak zgłoszenia
SENT?” — odpowiedź powinna odwoływać się do `Ustawa_SENT.txt` i, jeśli
dostępny jest web search, zawierać potwierdzenie aktualności podanej
kwoty.

## 3. Instalacja i logowanie Claude Code

```bash
npm install -g @anthropic-ai/claude-code
claude login
```

Logowanie wykonuje się raz, interaktywnie. Zapisana sesja jest później
wykorzystywana również przy uruchomieniach z crona / Harmonogramu
zadań, które same nie mogą przeprowadzić logowania.

## 4. Automatyczna aktualizacja — Linux/Mac (cron)

1. W pliku `update_kb.sh` zmienić linię:
   ```bash
   PROJECT_DIR="$HOME/projekty/tsl-skill"
   ```
   na docelową ścieżkę projektu.

2. Nadać uprawnienia do wykonania:
   ```bash
   chmod +x update_kb.sh
   ```

3. Otworzyć edytor crona:
   ```bash
   crontab -e
   ```

4. Dodać wpis. Przykład: uruchomienie raz w miesiącu, 1. dnia o 6:00:
   ```
   0 6 1 * * /bin/bash /pelna/sciezka/do/update_kb.sh >> /pelna/sciezka/do/tsl-skill/.kb_update_logs/cron.log 2>&1
   ```
   Przykład: co tydzień, w poniedziałek o 6:00:
   ```
   0 6 * * 1 /bin/bash /pelna/sciezka/do/update_kb.sh >> /pelna/sciezka/do/tsl-skill/.kb_update_logs/cron.log 2>&1
   ```

5. Po zapisaniu cron przejmuje zadanie automatycznie. Logi z każdego
   przebiegu zapisywane są w `.kb_update_logs/` obok skryptu.

## 5. Automatyczna aktualizacja — Windows (Harmonogram zadań)

1. W pliku `update_kb.ps1` zmienić linię:
   ```powershell
   $ProjectDir = "C:\Projekty\tsl-skill"
   ```
   na docelową ścieżkę projektu.

2. Otworzyć **Harmonogram zadań** (Task Scheduler) → **Utwórz zadanie
   podstawowe** (Create Basic Task).

3. Nazwa: `Aktualizacja bazy wiedzy TSL`. Wyzwalacz: częstotliwość wg
   potrzeb (tydzień/miesiąc).

4. Akcja: **Uruchom program**:
   - Program/skrypt: `powershell.exe`
   - Dodaj argumenty:
     ```
     -NoProfile -ExecutionPolicy Bypass -File "C:\Projekty\tsl-skill\update_kb.ps1"
     ```

5. Alternatywnie, jednym poleceniem z linii komend (uruchomionej jako
   administrator), przykład dla wykonania co tydzień w poniedziałek o
   6:00:
   ```powershell
   schtasks /create /tn "AktualizacjaBazyTSL" /tr "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"C:\Projekty\tsl-skill\update_kb.ps1\"" /sc weekly /d MON /st 06:00
   ```

6. Logi z każdego przebiegu zapisywane są w `.kb_update_logs\` obok
   skryptu.

7. Jeśli plik `.ps1` zablokowany jest komunikatem o polityce
   wykonywania skryptów, pomaga jedno z poniższych:
   ```powershell
   Unblock-File -Path "C:\Projekty\tsl-skill\update_kb.ps1"
   ```
   lub uruchomienie z flagą pomijającą politykę wykonywania (jak w
   argumentach Harmonogramu zadań powyżej: `-ExecutionPolicy Bypass`).

## 6. Kodowanie znaków (Windows)

Claude Code zapisuje pliki `.txt` jako UTF-8 bez znacznika BOM. Notatnik
Windows przy takich plikach czasem błędnie odczytuje kodowanie i
wyświetla polskie znaki jako nieczytelne symbole, mimo że sama treść
pliku jest poprawna. Oba skrypty (`update_kb.ps1` i `update_kb.sh`)
zawierają automatyczny krok naprawy kodowania (zapis z BOM) po każdej
aktualizacji, więc problem nie powinien się powtarzać cyklicznie. Do
jednorazowej ręcznej naprawy istniejących plików:

```powershell
Get-ChildItem C:\Projekty\tsl-skill\Baza_Wiedzy\*.txt | ForEach-Object {
    $content = Get-Content -Encoding UTF8 -Raw $_.FullName
    [System.IO.File]::WriteAllText($_.FullName, $content, [System.Text.UTF8Encoding]::new($true))
}
```

## 7. Uwagi bezpieczeństwa i praktyczne

- Flaga `--dangerously-skip-permissions` jest wymagana w trybie
  automatycznym — bez niej Claude Code zatrzymałby się na pierwszym
  pytaniu o zgodę na edycję pliku, na które nikt nie mógłby
  odpowiedzieć. Z tego powodu skrypty powinny działać wyłącznie w
  katalogu projektu dedykowanym tej bazie wiedzy, nigdy w katalogu
  zawierającym inne, wrażliwe dane.
- Zalecane jest trzymanie projektu w repozytorium git, z odkomentowanymi
  liniami `git commit` w skrypcie — umożliwia to pełną historię zmian
  i łatwe cofnięcie błędnej automatycznej edycji. Skrypty celowo
  pomijają `CLAUDE.md` przy automatycznym commitowaniu — zmiany w tym
  pliku powinny pozostać ręczne i świadome.
- Maszyna wykonująca cron/Harmonogram zadań musi mieć dostęp do
  internetu (web search) — bez niego Claude Code nie zweryfikuje
  aktualności przepisów i pozostawi pliki bez zmian.
- Zalecana częstotliwość aktualizacji: `Ustawa_SENT.txt`,
  `Pakiet_Mobilnosci_Delegowanie_Kierowcow.txt` i
  `Ustawa_o_transporcie_drogowym.txt` (najczęściej nowelizowane
  obszary) — raz w tygodniu lub co dwa tygodnie. Pozostałe pliki
  (CMR, 561/2006, AETR) — raz w miesiącu jest wystarczające.
- Automatyzacja przyspiesza research, ale nie zastępuje okresowej,
  ręcznej weryfikacji zmienionych kwot i dat przy realnych decyzjach
  finansowych firmy.

## 8. Kontrola wersji (git) i wykluczanie plików

Jeśli projekt jest przechowywany w repozytorium (np. na GitHubie), plik
`.gitignore` w katalogu głównym pozwala wykluczyć z repozytorium
wybrane pliki lub foldery — typowo logi aktualizacji oraz pliki
zawierające dane wrażliwe (np. cennik firmy):

```
.kb_update_logs/
CENNIK.txt
```

Jeśli dany plik był już wcześniej dodany do repozytorium przed
utworzeniem `.gitignore`, samo dodanie wpisu do `.gitignore` go nie
usunie — wymaga to jednorazowego odśledzenia pliku:

```bash
git rm --cached CENNIK.txt
git rm -r --cached .kb_update_logs
```
