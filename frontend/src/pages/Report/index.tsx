import React, { useState, useRef, useEffect } from "react";
import * as S from "./style";
import Editor from "@monaco-editor/react";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import handleEditorWillMount from "./handleEditorWillMount";
import { useLocation } from "react-router-dom";
import VulnerabilityChart from "./VulnerabilityChart";

const Report = () => {
  const location = useLocation();
  const { message, input, vuln } = location.state || {};
  const [content, setContent] = useState<string>(message || "");
  const [checkboxes, setCheckboxes] = useState<{ [key: number]: boolean }>({});
  const [parsedCodes, setParsedCodes] = useState<{ old: string; correct: string }[]>([]);
  const editorRef = useRef<any>(null);
  const [code, setCode] = useState(input || "");

  const parseMarkdown = (markdown: string) => {
    const oldCodeRegex = /old:\s*```solidity\s*([\s\S]*?)\s*```/g;
    const correctCodeRegex = /correct:\s*```solidity\s*([\s\S]*?)\s*```/g;

    const codes: { old: string; correct: string }[] = [];
    let oldMatch, correctMatch;

    while ((oldMatch = oldCodeRegex.exec(markdown)) && (correctMatch = correctCodeRegex.exec(markdown))) {
      codes.push({
        old: oldMatch[1].trim(),
        correct: correctMatch[1].trim(),
      });
    }

    setParsedCodes(codes);
  };

  const handleCheckboxChange = (index: number) => {
    setCheckboxes((prev) => ({ ...prev, [index]: !prev[index] }));

    console.log(parsedCodes)
    setContent((prevContent) => {
      const updatedContent = prevContent.replace(parsedCodes[index]?.old, parsedCodes[index]?.correct);
      return updatedContent;
    });

    if (editorRef.current) {
      editorRef.current.setValue(parsedCodes[index]?.correct);
    }
  };

  useEffect(() => {
    if (content) parseMarkdown(content);
  }, [content]);

  return (
    <S.Container>
      <S.ReportBox>
        <S.Text>취약점 분석 보고서</S.Text>
        <VulnerabilityChart data={vuln?.reduce((acc: Record<string, number>, curr: string) => {
          acc[curr] = (acc[curr] || 0) + 1;
          return acc;
        }, {}) || {}} />
        <ReactMarkdown
          remarkPlugins={[remarkGfm]}
          components={{
            input: ({ node, ...props }) => {
              const index = (node?.position?.start.line || 1) - 1;

              return (
                <label style={{ display: "flex", alignItems: "center" }}>
                  <input
                    type="checkbox"
                    checked={checkboxes[index] || false}
                    onChange={() => handleCheckboxChange(index)}
                  />
                  <span style={{ marginLeft: "8px" }}>적용</span>
                </label>
              );
            },
          }}
        >
          {content}
        </ReactMarkdown>
      </S.ReportBox>
      <S.CodeBox>
        <Editor
          height="100%"
          beforeMount={handleEditorWillMount}
          defaultLanguage="solidity"
          theme="solidityTheme"
          defaultValue={code}
          onMount={(editor) => (editorRef.current = editor)}
          options={{
            tabSize: 2,
            fontSize: 16,
            minimap: { enabled: false },
          }}
        />
      </S.CodeBox>
    </S.Container>
  );
};

export default Report;
