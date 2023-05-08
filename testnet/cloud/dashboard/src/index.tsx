import { ChakraProvider } from '@chakra-ui/react';
import ReactDOM from 'react-dom';
import { App } from '@/app';
import { theme } from '@/theme';

ReactDOM.render(
  <ChakraProvider theme={theme} resetCSS>
    <App />
  </ChakraProvider>,
  document.getElementById('app-root')
);
