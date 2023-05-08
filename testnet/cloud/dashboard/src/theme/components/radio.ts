import { radioAnatomy as parts } from '@chakra-ui/anatomy';
import { PartsStyleObject, SystemStyleObject } from '@chakra-ui/theme-tools';

const baseStyleControl: SystemStyleObject = {
  borderRadius: 'full',
  _checked: {
    bg: 'custom.chart',
    borderColor: 'custom.chart',
    _before: {
      content: `""`,
      display: 'inline-block',
      pos: 'relative',
      w: '50%',
      h: '50%',
      borderRadius: '50%',
      bg: 'white',
    },
  },
};

const baseStyle: PartsStyleObject<typeof parts> = {
  control: baseStyleControl,
};

export default {
  baseStyle,
};
