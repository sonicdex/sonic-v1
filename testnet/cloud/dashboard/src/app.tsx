import { BrowserRouter, Route, Routes } from 'react-router-dom';
import { env } from './constants';
import { MainScreen } from './screens';
import { AppLog } from './utils';

AppLog.warn('Environment:', env);

export const App: React.FC = () => (
  <BrowserRouter>
    <Routes>
      <Route path="/" element={<MainScreen />} />
    </Routes>
  </BrowserRouter>
);
