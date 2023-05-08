import { checkboxAnatomy as parts } from '@chakra-ui/anatomy';
import type {
  PartsStyleObject,
  SystemStyleObject,
} from '@chakra-ui/theme-tools';

const baseStyleControl: SystemStyleObject = {
  w: '100%',
  transitionProperty: 'box-shadow',
  transitionDuration: 'normal',
  border: '2px solid',
  borderRadius: 'sm',
  borderColor: 'inherit',
  color: 'white',

  _checked: {
    bg: `app.primary`,
    borderColor: `app.primary`,
    color: `white`,
  },
};

const baseStyle: PartsStyleObject<typeof parts> = {
  control: baseStyleControl,
};

const defaultProps = {
  size: 'md',
  colorScheme: 'dark-blue',
};

export default {
  parts: parts.keys,
  baseStyle,
  defaultProps,
};
