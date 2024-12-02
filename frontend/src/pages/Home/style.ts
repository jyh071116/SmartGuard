import styled from "styled-components";

export const Container = styled.div`
  display: flex;
  justify-content: center;
  align-items: center;
  flex-direction: column;
  gap: 20px;
  height: 100vh;
  background-color: #181818;
`;

export const Text = styled.p`
  color: white;
  font-weight: 700;
  font-size: 2rem;
`;

export const InputBox = styled.div<{ height: number }>`
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  border-radius: 16px;
  padding: 16px 20px;
  width: 60%;
  height: 110px;
  min-height: calc(${({ height }) => height}px + 70px);
  background-color: #646464;
`;

export const input = styled.textarea`
  border: none;
  background-color: #646464;
  color: white;
  resize: none;
  font-size: 1rem;
  outline: none;
`;

export const IconBox = styled.div`
  display: flex;
  justify-content: space-between;
`;
