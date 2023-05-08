import Input from './input';

const variants = {
  default: (props: any) => (Input.variants.default(props) as any).field ?? {},
};

const defaultProps = {
  size: 'md',
  variant: 'default',
};

export default {
  variants,
  defaultProps,
};
