import { tableAnatomy as parts } from '@chakra-ui/anatomy';
import type {
  PartsStyleObject,
  SystemStyleObject,
} from '@chakra-ui/theme-tools';

const baseStyle: PartsStyleObject<typeof parts> = {
  th: {
    textTransform: 'none',
  },
};

const variantSimple: SystemStyleObject = {
  table: {
    position: 'relative',
  },
  tr: {
    td: {
      position: 'relative',
      zIndex: 3,
    },
    _last: {
      td: {
        borderBottom: 'none',
      },
    },
  },
};

const variants = {
  simple: variantSimple,
};

export default {
  parts: parts.keys,
  baseStyle,
  variants,
};
