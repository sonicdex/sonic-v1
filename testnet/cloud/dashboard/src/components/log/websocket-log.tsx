import { Button, Flex, Heading, List, ListItem } from '@chakra-ui/react';
import { useCallback, useEffect, useMemo, useRef } from 'react';
import { useAppColorValue } from '@/hooks';
import { useWebsocketClient } from '@/integrations';

type ConnectedStateProps = { state: number };

const ConnectedState: React.FC<ConnectedStateProps> = ({
  state,
}: ConnectedStateProps) => {
  const color = useMemo(() => {
    switch (state) {
      case WebSocket.CLOSING:
      case WebSocket.CONNECTING:
        return 'custom.warning';
      case WebSocket.OPEN:
        return 'custom.positive';
      case WebSocket.CLOSED:
      default:
        return 'custom.negative';
    }
  }, [state]);

  return <Flex backgroundColor={color} w={2} h={2} borderRadius="full" />;
};

export const WebsocketLog: React.FC = () => {
  const borderColor = useAppColorValue('border');
  const highlightBackgroundColor = useAppColorValue('background.inner');
  const { messages, clear, state } = useWebsocketClient();
  const containerRef = useRef<HTMLDivElement>(null);

  const saveLogHandler = useCallback(() => {
    if (!containerRef.current) return;
    const head = document.querySelector('head');
    const body = `<body class="chakra-ui-dark">${containerRef.current.outerHTML}</body>`;
    const page = `<html lang="en" data-theme="dark" style="color-scheme: dark;">${head?.outerHTML}${body}</html>`;
    const blob = new Blob([page], {
      type: 'text/plain;charset=utf-8',
    });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = `websocket-log-${Date.now()}.html`;
    link.click();
  }, [containerRef]);

  useEffect(() => {
    if (containerRef.current) {
      containerRef.current.scrollTo({
        top: containerRef.current.scrollHeight,
        behavior: 'smooth',
      });
    }
  }, [messages, containerRef]);

  return (
    <Flex
      direction="column"
      h="100%"
      w="100%"
      borderLeft={`1px solid ${borderColor}`}
    >
      <Flex
        borderBottom={`1px solid ${borderColor}`}
        justifyContent="center"
        alignItems="center"
        px={4}
        py={2}
        gap={2}
      >
        <Heading size="sm" flex={1}>
          Server Log
        </Heading>
        <ConnectedState state={state} />
        <Button size="xs" variant="outline" colorScheme="gray" onClick={clear}>
          Clear
        </Button>
        <Button
          size="xs"
          variant="outline"
          colorScheme="gray"
          onClick={saveLogHandler}
        >
          Export
        </Button>
      </Flex>
      <Flex overflow="auto" flex={1} ref={containerRef}>
        <Flex as={List} direction="column" minW="fit-content" w="100%">
          {messages.map((item) => (
            <ListItem
              key={item.id}
              css={{
                ':nth-of-type(2n)': { background: highlightBackgroundColor },
              }}
              whiteSpace="pre"
            >
              {item.event.data}
            </ListItem>
          ))}
        </Flex>
      </Flex>
    </Flex>
  );
};

WebsocketLog.displayName = 'WebsocketLog';
