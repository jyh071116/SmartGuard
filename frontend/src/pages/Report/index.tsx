import React, { useState, useRef } from "react";
import * as S from "./style";
import Editor from "@monaco-editor/react";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import handleEditorWillMount from "./handleEditorWillMount";

const Report = () => {
  const [content, setContent] = useState("- [ ] 안녕");
  const [checkboxes, setCheckboxes] = useState<{ [key: number]: boolean }>({});
  const editorRef = useRef<HTMLDivElement>(null);
  const [code, setCode] = useState("");

  const handleInput = () => {
    if (editorRef.current) {
      setContent(editorRef.current.innerText);
    }
  };

  const handleCheckboxChange = (index: number) => {
    setCheckboxes((prev) => ({ ...prev, [index]: !prev[index] }));
    const lines = content.split("\n");
    lines[index] = lines[index].includes("[x]")
      ? lines[index].replace("[x]", "[ ]")
      : lines[index].replace("[ ]", "[x]");
    setContent(lines.join("\n"));
  };

  return (
    <S.Container>
      <S.ReportBox
        ref={editorRef}
        onInput={handleInput}
        suppressContentEditableWarning
      >
        <ReactMarkdown
          remarkPlugins={[remarkGfm]}
          components={{
            input: ({ node, ...props }) => {
              if (props.type === "checkbox") {
                const index = (node?.position?.start.line || 1) - 1;
                return (
                  <input
                    type="checkbox"
                    checked={checkboxes[index] || props.checked}
                    onChange={() => handleCheckboxChange(index)}
                  />
                );
              }
              return <input {...props} />;
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
          options={{
            tabSize: 2,
            fontSize: "16px",
          }}
          onChange={(value) => setCode(value || "")}
        />
      </S.CodeBox>
    </S.Container>
  );
};

export default Report;
