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
  overflow-y: auto;
  input[type="checkbox"] {
    cursor: pointer;
  }
  * {
    margin: 10px 0px;
  }
`;

export const CodeBox = styled.div`
  background-color: #1e1e1e;
  width: 50%;
  height: 100%;
`;

export const Text = styled.p`
  font-size: 2rem;
  font-weight: 700;
  margin: 20px 0;
`

export const ChartBox = styled.div`
  height: 200px;
`