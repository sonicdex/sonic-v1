import { sliderAnatomy as parts } from '@chakra-ui/anatomy';
import type {
  PartsStyleFunction,
  SystemStyleFunction,
  SystemStyleObject,
} from '@chakra-ui/theme-tools';
import { mode } from '@chakra-ui/theme-tools';

const baseStyleTrack: SystemStyleFunction = (props) => ({
  overflow: 'hidden',
  borderRadius: 'sm',
  bg: mode('app.border.light', 'app.border.dark')(props),
  _disabled: {
    bg: mode('gray.300', 'whiteAlpha.300')(props),
  },
});

const baseStyleFilledTrack: SystemStyleObject = {
  width: 'inherit',
  height: 'inherit',
  bg: 'app.primary',
};

const baseStyleThumb: SystemStyleObject = {
  bg: 'linear-gradient(99.61deg, #3D52F4 1.17%, #192985 100%)',
  border: 'none',
  boxShadow: '0px 1px 3px rgba(0, 0, 0, 0.1), 0px 1px 2px rgba(0, 0, 0, 0.06)',
};

const baseStyle: PartsStyleFunction<typeof parts> = (props) => ({
  track: baseStyleTrack(props),
  filledTrack: baseStyleFilledTrack,
  thumb: baseStyleThumb,
});

const defaultProps = {
  size: 'md',
  colorScheme: 'dark-blue',
};

export default {
  parts: parts.keys,
  baseStyle,
  defaultProps,
};
