import os
import pandas as pd
from tqdm import trange

base_dir = "C:\\Users\\jyh07\\Documents\\SmartGuard\\AI\\data"
vulnerabilities = {"RE": "Reentrancy", "BN": "Block Number Dependency", "DE": "Dangerous Delegatecall", "EF": "Ether Frozen", "OF": "Integer Overflow/Underflow", "SE": "Ether Strict Equality", "UC": "Unchecked External Call", "TP": "Timestamp Dependency"}
data = []

for i in trange(50000):
  for vulnerability in os.listdir(base_dir):
    vuln_path = os.path.join(base_dir, vulnerability)
    vuln = vulnerabilities[vulnerability]
    row = {"num": i, "vulnerability": vuln}
    for code_type in ["binarycode", "bytecode", "sourcecode"]:
      code_path = os.path.join(vuln_path, code_type)
      for file in os.listdir(code_path):
        if file == f"{i}.sol":
          with open(f"data/{vulnerability}/{code_type}/{i}.sol", "r", encoding="utf-8", errors="ignore") as f:
            row[code_type] = f.read()
        elif file == f"{i}.dot":
          with open(f"data/{vulnerability}/{code_type}/{i}.dot", "r", encoding="utf-8", errors="ignore") as f:
            row[code_type] = f.read()
    data.append(row)
          

df = pd.DataFrame(data)
df = df.dropna(axis=0)
df = df[df["bytecode"] != ""]
df = (
    df.groupby("num")
    .agg({
        "vulnerability": lambda x: list(x.unique()),
        "binarycode": "first",
        "bytecode": "first",
    })
    .reset_index()
)

df.to_json("processed_data.jsonl", orient="records", lines=True, force_ascii=False)