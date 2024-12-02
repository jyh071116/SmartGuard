const handleEditorWillMount = (monaco: any) => {
  monaco.languages.register({ id: "solidity" });

  monaco.languages.setMonarchTokensProvider("solidity", {
    keywords: [
      "pragma",
      "solidity",
      "contract",
      "function",
      "event",
      "modifier",
      "public",
      "private",
      "internal",
      "external",
      "pure",
      "view",
      "payable",
      "returns",
      "mapping",
      "address",
      "uint",
      "uint256",
      "string",
      "bool",
    ],
    operators: [
      "=",
      "+=",
      "-=",
      "*=",
      "/=",
      "==",
      "!=",
      "<",
      "<=",
      ">",
      ">=",
      "&&",
      "||",
      "!",
      "++",
      "--",
    ],
    escapes: /\\(?:[abfnrtv\\"']|x[0-9A-Fa-f]{2}|u[0-9A-Fa-f]{4})/,
    tokenizer: {
      root: [
        [
          /[a-z_$][\w$]*/,
          { cases: { "@keywords": "keyword", "@default": "identifier" } },
        ],
        [/\d+/, "number"],
        [/\/\/.*$/, "comment"],
        [/\/\*/, { token: "comment", bracket: "@open", next: "@comment" }],
        [/"([^"\\]|\\.)*$/, "string.invalid"],
        [/"/, { token: "string.quote", bracket: "@open", next: "@string" }],
        [/[=+\-*/<>!&|]+/, "operator"],
      ],
      string: [
        [/[^\\"]+/, "string"],
        [/@escapes/, "string.escape"],
        [/\\./, "string.escape.invalid"],
        [/"/, { token: "string.quote", bracket: "@close", next: "@pop" }],
      ],
      comment: [
        [/[^/*]+/, "comment"],
        [/\/\*/, "comment", "@push"],
        [/\*\//, "comment", "@pop"],
        [/[\/*]/, "comment"],
      ],
    },
  });

  monaco.editor.defineTheme("solidityTheme", {
    base: "vs-dark",
    inherit: true,
    rules: [
      { token: "keyword", foreground: "569CD6" },
      { token: "identifier", foreground: "9CDCFE" },
      { token: "number", foreground: "B5CEA8" },
      { token: "comment", foreground: "6A9955", fontStyle: "italic" },
      { token: "string", foreground: "CE9178" },
      { token: "operator", foreground: "D4D4D4" },
    ],
    colors: {
      "editor.background": "#1E1E1E",
    },
  });
};

export default handleEditorWillMount;