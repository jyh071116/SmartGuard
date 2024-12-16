import React, { useState, useRef } from "react";
import * as S from "./style";
import axios from "axios";
import Arrow from "../../assets/Arrow";
import Upload from "../../assets/Upload";
import { useNavigate } from "react-router-dom";

const Home = () => {
  const navigate = useNavigate();
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const [textareaHeight, setTextareaHeight] = useState(0);

  const handleInput = () => {
    const textarea = textareaRef.current;
    if (textarea) {
      textarea.style.height = "auto";
      textarea.style.height = `${textarea.scrollHeight}px`;
      setTextareaHeight(textarea.scrollHeight);
    }
  };

  const request = async (message: string | undefined) => {
    const res = await axios.post("http://localhost:5000/request", {
      message: message,
    });
    return res.data;
  };

  return (
    <S.Container height={textareaHeight}>
      <S.Text>SmartGuard에 오신 것을 환영합니다!</S.Text>
      <S.InputBox height={textareaHeight}>
        <S.input
          ref={textareaRef}
          onInput={handleInput}
          placeholder="입력"
        ></S.input>
        <S.IconBox>
          <Upload />{" "}
          <Arrow
            onClick={async () => {
              const res = await request(textareaRef.current?.value);
              navigate("/report/1", {
                state: {
                  message: res.response,
                  vuln: res.vuln,
                  input: textareaRef.current?.value,
                },
              });
            }}
          />
        </S.IconBox>
      </S.InputBox>
    </S.Container>
  );
};

export default Home;
