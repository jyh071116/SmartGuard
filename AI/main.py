from flask import Flask, request, jsonify
from openai import OpenAI
from flask_cors import CORS
import json

app = Flask(__name__)
CORS(app)

client = OpenAI()

@app.route("/request", methods=["POST"])
def chat():
    user_input = request.json.get("message", "")
    
    completion = client.chat.completions.create(
        model="ft:gpt-4o-2024-08-06:personal::AewufuGK",
        messages=[
            {
                "role": "system",
                "content": "You are an expert in identifying vulnerabilities in smart contracts.",
            },
            {"role": "user", "content": user_input},
        ],
    )
    vuln = completion.choices[0].message.content
    
    completion = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {
                "role": "system",
                "content": "당신은 스마트 계약의 취약점을 분석하는 전문가입니다. "
                        "주어진 취약점과 소스 코드를 기반으로 마크다운 형식의 보고서를 작성해주세요. "
                        "반드시 한국어로 작성해야 하며 보고서에는 다음 내용을 포함해야 합니다:\n\n"
                        "1. **취약점 설명**: 코드에서 발견된 취약점에 대한 설명.\n"
                        "2. **취약점 원인**: 해당 코드가 왜 취약한지 설명.\n"
                        "3. **Mitigation Checklist**:\n"
                        " - 체크리스트 항목은 반드시 `[ ]` 형식의 마크다운으로 작성해주세요.\n"
                        " - 각 체크리스트 항목에는 반드시 **기존 코드**(`old`)와 **수정된 코드**(`correct`)를 포함해야 합니다.\n"
                        " - 기존 코드는 `old` 섹션에 작성하고, 코드 블록은 ``` ``` 로 감싸주세세요.\n"
                        " - 수정된 코드는 `correct` 섹션에 작성하고, 코드 블록은 ``` ``` 로 감싸주세요."
            },
            {"role": "user", "content": json.dumps({"vulnerability": vuln, "sourcecode": user_input})},
        ],
    )
    response = completion.choices[0].message.content
    
    return jsonify({"vuln": json.loads(vuln), "response": response})

if __name__ == "__main__":
    app.run(debug=True)