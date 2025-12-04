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
