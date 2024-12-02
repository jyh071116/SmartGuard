import React, { useState, useRef } from "react";
import * as S from "./style";
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
  return (
    <S.Container>
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
            onClick={() => {
              navigate("/report/1");
            }}
          />
        </S.IconBox>
      </S.InputBox>
    </S.Container>
  );
};

export default Home;
