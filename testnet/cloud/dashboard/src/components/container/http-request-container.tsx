import { Button, Flex, Heading } from '@chakra-ui/react';
import { useEffect, useMemo, useState } from 'react';
import { HttpRequest, useAppColor, useAppColorValue } from '@/hooks';

export type HttpRequestContainerProps = {
  httpRequest: HttpRequest<any>;
  children?: React.ReactNode;
  title: string;
  subtitle: string;
};

export const HttpRequestContainer: React.FC<HttpRequestContainerProps> = ({
  httpRequest: { data, hasError },
  children,
  title,
  subtitle,
}: HttpRequestContainerProps) => {
  const borderColor = useAppColorValue('border');
  const backgroundInner = useAppColorValue('background.inner');
  const subText = useAppColor('text.sub');
  const [enableResponse, setEnableResponse] = useState(false);

  const showResponse = useMemo(
    () => enableResponse && (data || hasError),
    [enableResponse, data, hasError]
  );

  useEffect(() => {
    if (data || hasError) {
      setEnableResponse(true);
    }
  }, [data, hasError]);

  return (
    <Flex
      direction="column"
      gap={2}
      p={2}
      border={`1px solid ${borderColor}`}
      borderRadius="lg"
    >
      <Heading size="md">{title}</Heading>
      <Flex mt={-2} color={subText}>
        {subtitle}
      </Flex>
      {children}
      {showResponse && (
        <Flex direction="column" width="100%">
          <Flex py={2} borderY={`1px solid ${borderColor}`} alignItems="center">
            <Heading size="sm" flex={1}>
              Response
            </Heading>
            <Button
              size="xs"
              variant="outline"
              colorScheme="gray"
              onClick={() => setEnableResponse(false)}
            >
              Clear
            </Button>
          </Flex>
          <Flex
            direction="column"
            width="100%"
            maxH="300px"
            overflow="auto"
            px={2}
            background={backgroundInner}
            borderBottom={`1px solid ${borderColor}`}
          >
            {data && (
              <Flex color="custom.positive" whiteSpace="pre">
                {data}
              </Flex>
            )}
            {hasError && (
              <Flex color="custom.negative" whiteSpace="pre">
                {JSON.stringify(hasError, null, 2)}
              </Flex>
            )}
          </Flex>
        </Flex>
      )}
    </Flex>
  );
};
