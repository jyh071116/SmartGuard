import styled from "styled-components";

export const Container = styled.div`
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100vh;
  background-color: #202020;
`;

export const ReportBox = styled.div`
  background-color: #202020;
  padding: 20px;
  margin: 20px;
  width: 50%;
  height: 100%;
  color: white;
  font-size: 1rem;
  input[type="checkbox"] {
    cursor: pointer;
  }
`;

export const CodeBox = styled.div`
  background-color: black;
  width: 50%;
  height: 100%;
`;
