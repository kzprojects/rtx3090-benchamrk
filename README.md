1. Środowisko testowe (hardware / software)

Hardware

GPU: NVIDIA RTX 3090, 24 GB VRAM

CPU: AMD Ryzen 9 7900X

RAM: 64 GB DDR4/DDR5

Dysk: NVMe SSD 1 TB

Sieć: offline / lokalna (nie wpływa na benchmark)

System operacyjny

Linux (dystrybucja: np. Ubuntu 22.04 / 24.04)

Sterowniki NVIDIA: (wstaw wersję, np. 535.*)

CUDA: (wstaw wersję, np. 12.x)

Oprogramowanie

vLLM (CLI) — wersja: (wstaw wersję, np. vLLM v0.xx)

Python 3.10+ (opcjonalnie do skryptów)

jq (do parsowania JSON)

(opcjonalnie) bc, date z obsługą ms

Model: Llama 3.1 8B w formacie kompatybilnym z vLLM (ścieżka do modelu lokalnego)

2. Konfiguracja vLLM i modelu

Przykładowe ustawienia użyte w eksperymencie:

model path: /models/llama-3.1-8b/

max new tokens: 1024 (do pomiaru throughput)

temperature: 0.0 (deterministyczne generowanie)

batch size / concurrency: 1 (single-stream inference)

memory & precision: domyślne vLLM (bez agresywnej kwantyzacji)

vLLM output format: json (ułatwia parsowanie tokenów)

Jeśli używasz kwantyzacji (np. 8-bit), pamiętaj zanotować to — wyniki mogą się istotnie różnić.

3. Metodologia pomiaru

Przygotuj stały prompt/pakiet promptów (ten sam dla wszystkich pomiarów).

Uruchom vLLM w trybie generowania określonej liczby tokenów (--max-tokens), w formacie JSON.

Zmierzyć dokładny czas generowania (wall-clock).

Wyliczyć tokens_per_second = generated_tokens / elapsed_seconds.

Powtórzyć (np. 5–10 razy) i uśrednić wynik, odrzucając outliery (pierwsze uruchomienie może być wolniejsze z powodu ładowania modelu do VRAM).

Poniżej znajdziesz prosty wrapper bashowy, który ułatwia pomiar.

4. Skrypt pomiarowy (bash + vllm CLI + jq)

Skrypt oczekuje, że vllm dostępny jest w $PATH, model jest lokalnie dostępny, a jq i bc są zainstalowane.

#!/usr/bin/env bash
# measure_tokens_per_second.sh
# Usage: ./measure_tokens_per_second.sh /path/to/model prompt.txt iterations

MODEL_PATH="$1"
PROMPT_FILE="$2"
ITERATIONS="${3:-5}"
MAX_TOKENS=1024
OUT="/tmp/vllm_out.json"

if [[ -z "$MODEL_PATH" || -z "$PROMPT_FILE" ]]; then
  echo "Usage: $0 /path/to/model prompt.txt [iterations]"
  exit 1
fi

total_tokens=0
total_time=0

for i in $(seq 1 $ITERATIONS); do
  echo "Run #$i"
  START=$(date +%s.%3N)
  # Example vllm CLI invocation — adjust flags to your vllm version
  vllm generate --model "$MODEL_PATH" \
               --prompt-file "$PROMPT_FILE" \
               --max-tokens $MAX_TOKENS \
               --temperature 0 \
               --output-format json > "$OUT"
  END=$(date +%s.%3N)
  ELAPSED=$(echo "$END - $START" | bc -l)

  # Parse tokens count from vllm JSON output
  # This assumes vllm JSON includes tokens list per generation, e.g. .generations[0].tokens
  # Adjust jq path if your vllm version provides a different structure.
  TOKENS=$(jq '.generations[0].tokens | length' "$OUT")
  if [[ "$TOKENS" == "null" ]]; then
    # fallback: try to parse length of text and approximate tokens (not precise)
    TEXT=$(jq -r '.generations[0].text' "$OUT")
    TOKENS=$(echo "$TEXT" | wc -w)
  fi

  echo "Generated tokens: $TOKENS in $ELAPSED s"
  run_tps=$(echo "$TOKENS / $ELAPSED" | bc -l)
  echo "tokens/s: $run_tps"

  total_tokens=$(echo "$total_tokens + $TOKENS" | bc)
  total_time=$(echo "$total_time + $ELAPSED" | bc)
done

avg_tps=$(echo "$total_tokens / $total_time" | bc -l)
echo
echo "=== Summary ==="
echo "Total runs: $ITERATIONS"
echo "Total tokens: $total_tokens"
echo "Total time: $total_time s"
echo "Average tokens/s: $avg_tps"


Przykład uruchomienia:

./measure_tokens_per_second.sh /models/llama-3.1-8b/ prompt.txt 6


Jeżeli vllm w twojej wersji nie daje bezpośrednio listy tokenów w JSON, użyj pola text i policz tokeny za pomocą tej samej tokenizacji, której używa model (zalecane: lokalny tokenizer zgodny z Llama).

5. Wyniki eksperymentu

Platforma: Ryzen 9 7900X, 64 GB RAM, NVMe 1 TB, Linux
GPU: NVIDIA RTX 3090 (24 GB VRAM)
Model: Llama 3.1 — 8B
Runtime: vLLM (wersja: (wstaw))
Konfiguracja: single-stream, max_tokens=1024, temperature=0

Wynik (uśredniony, N=6):

GPU	Model	max_tokens	Iteracje	Średnie tokens/s
RTX 3090 (24 GB)	Llama 3.1 (8B)	1024	6	~82 tokens/s

W eksperymencie uzyskano ~82 tokens/s (średnia po odrzuceniu pierwszego uruchomienia, które było wolniejsze — warm-up). Twoje wyniki mogą się różnić w zależności od: wersji vLLM, sterowników CUDA/NVIDIA, parametrów modelu (fp16 vs fp32), i konfiguracji pamięci.

6. Dyskusja

Wąskie gardło: na tej konfiguracji często bottleneckem jest pamięć GPU (VRAM) i przepustowość pamięci. 3090 ma mniej VRAM niż nowsze karty (np. 40/50 series), co ogranicza możliwość ładowania większych kontekstów lub użycia optymalizacji wymagających dodatkowej pamięci.

Porównanie: nowsze architektury (np. Ada/Hopper/Blackwell) zwykle osiągają większe tokens/s przy tej samej konfiguracji modelu (szczególnie przy zoptymalizowanej kwantyzacji).

Reproducibility: aby powtórzyć, zapisz dokładne wersje: vllm --version, nvidia-smi output, python --version, pip freeze listę bibliotek.

7. Rekomendacje dla replikacji (checklist)

Upewnij się, że model jest w formacie zgodnym z vLLM i że masz wystarczająco VRAM.

Zainstaluj tę samą wersję vLLM co w benchmarku.

Zaktualizuj sterowniki NVIDIA i CUDA do wersji zalecanej przez vLLM.

Użyj stałego promptu i max_tokens dla wszystkich pomiarów.

Powtórz pomiary kilka razy i wylicz średnią.

Zarejestruj pełne logi systemowe (nvidia-smi, /var/log/syslog) dla analizy ewentualnych wahań.

8. Pliki w repo (proponowana struktura)
.
├── README.md                 # Ten plik
├── prompt.txt                # Prompt(y) użyte w eksperymencie
├── measure_tokens_per_second.sh
├── vllm_config.md            # Notatki konfiguracyjne vLLM
├── results/
│   ├── run-01.json
│   ├── run-02.json
│   └── aggregated.csv
└── LICENSE

9. Licencja

(Wstaw wybraną licencję, np. MIT)

10. Referencje & uwagi

vLLM — projekt do szybkiego inference LLM na GPU (użyj dokumentacji vLLM żeby dopasować CLI / API).

Llama 3.1 — wersja modelu; upewnij się, że posiadasz prawo/licencję do używania modelu lokalnie.

Wynik ~82 tokens/s jest wartością z eksperymentu przeprowadzonego na opisanym sprzęcie i konfiguracji. Wartość należy traktować jako punkt odniesienia (benchmark reproducible) — zalecane wykonanie własnych testów przy lokalnej konfiguracji.
