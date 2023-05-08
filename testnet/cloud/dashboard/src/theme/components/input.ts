import type { SystemStyleFunction } from '@chakra-ui/theme-tools';
import { mode } from '@chakra-ui/theme-tools';

const variantFilled: SystemStyleFunction = (props) => {
  const { colorScheme: c } = props;
  return {
    field: {
      color: mode(`${c}.600`, `${c}.200`)(props),
      bg: mode(`${c}.50`, `${c}.800`)(props),
      shadow: mode('base', 'none')(props),
      _hover: {
        bg: mode(`${c}.100`, `${c}.700`)(props),
      },
      _focus: {
        bg: mode(`${c}.100`, `${c}.700`)(props),
      },
    },
  };
};

const variantDefault: SystemStyleFunction = (props) => ({
  field: {
    borderRadius: 'xl',
    bg: mode(`app.background.inner.light`, `app.background.inner.dark`)(props),
    border: '1px solid',
    borderColor: mode(`app.border.light`, `app.border.dark`)(props),
    _hover: {
      borderColor: mode('gray.300', 'whiteAlpha.400')(props),
    },
    _readOnly: {
      boxShadow: 'none !important',
      userSelect: 'all',
    },
    _disabled: {
      opacity: 0.4,
      cursor: 'not-allowed',
    },
    _invalid: {
      borderColor: 'custom.negative',
      boxShadow: `0 0 0 1px custom.negative`,
    },
    _focus: {
      zIndex: 1,
      borderColor: 'app.primary',
      boxShadow: `0 0 4px 0px ${props.theme.colors.app.primary}`,
    },
  },
});

const variants = {
  filled: variantFilled,
  default: variantDefault,
};

const defaultProps = {
  variant: 'default',
  size: 'md',
  colorScheme: 'gray',
};

export default {
  variants,
  defaultProps,
};
