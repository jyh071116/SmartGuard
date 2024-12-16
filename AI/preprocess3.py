import json

lines = []
with open("processed_data.jsonl", "r", encoding="utf-8", errors="ignore") as f:
  for i in range(40):
    line = json.loads(f.readline())
    lines.append(line)

data = []

for line in lines:
  vuln = line['vulnerability']
  del line['vulnerability']
  del line['num']
  del line['bytecode']

  entry = {
      "messages": [
          {"role": "system", "content": "You are an expert in identifying vulnerabilities in smart contracts."},
          {"role": "user", "content": json.dumps(line)},
          {"role": "assistant", "content": json.dumps(vuln)},
      ],
  }
  
  data.append(entry)

with open("training_data.jsonl", "w") as f:
    for entry in data:
        f.write(json.dumps(entry) + "\n")