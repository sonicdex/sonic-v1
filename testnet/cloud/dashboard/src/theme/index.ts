import { extendTheme } from '@chakra-ui/react';
import { mode } from '@chakra-ui/theme-tools';
import { colors } from './foundations';

import Button from './components/button';
import CloseButton from './components/close-button';
import Menu from './components/menu';
import Modal from './components/modal';
import Popover from './components/popover';
import Tabs from './components/tabs';
import Input from './components/input';
import Textarea from './components/textarea';
import Skeleton from './components/skeleton';
import Radio from './components/radio';
import Table from './components/table';
import Checkbox from './components/checkbox';
import Slider from './components/slider';
import FormLabel from './components/form-label';

const appTheme = {
  styles: {
    global: (props: any) => ({
      body: {
        bg: mode(
          'app.background.body.light',
          'app.background.body.dark'
        )(props),
      },
    }),
  },
  fonts: {
    heading: 'Nunito Sans',
    body: 'Nunito Sans',
  },
  config: {
    initialColorMode: 'dark',
    useSystemColorMode: false,
  },
  sizes: {
    modalHeight: '345px',
  },
  colors,
  components: {
    Button,
    Tabs,
    CloseButton,
    Modal,
    Popover,
    Menu,
    Input,
    Skeleton,
    Radio,
    Table,
    Textarea,
    Checkbox,
    Slider,
    FormLabel,
  },
};

export const theme = extendTheme(appTheme);
