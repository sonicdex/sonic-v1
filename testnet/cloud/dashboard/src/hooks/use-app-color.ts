import { useColorModeValue, useToken } from '@chakra-ui/react';

export const useAppColor = (color: string): string =>
  useColorModeValue(`app.${color}.light`, `app.${color}.dark`);

export const useAppColorValue = (color: string): string => {
  const colorToken = useAppColor(color);
  return useToken('colors', colorToken);
};
