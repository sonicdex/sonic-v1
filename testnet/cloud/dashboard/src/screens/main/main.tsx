import React, { useCallback, useState } from 'react';
import { Button, Flex, Heading, Input } from '@chakra-ui/react';
import { HttpRequestContainer, WebsocketLog } from '@/components';
import { env } from '@/constants';
import { useHttpRequest } from '@/hooks';

const PingReplica: React.FC = () => {
  const httpRequest = useHttpRequest({
    url: `${env.httpHost}/ping`,
    method: 'get',
  });
  const { isLoading, trigger } = httpRequest;

  return (
    <HttpRequestContainer
      httpRequest={httpRequest}
      title="Ping Replica"
      subtitle="Pings the running replica to verify if it is running."
    >
      <Button
        onClick={trigger}
        disabled={isLoading}
        isLoading={isLoading}
        variant="gradient"
      >
        Ping Replica
      </Button>
    </HttpRequestContainer>
  );
};

const RootBuckets: React.FC = () => {
  const httpRequest = useHttpRequest({
    url: `${env.httpHost}/root-buckets`,
    method: 'get',
  });
  const { isLoading, trigger } = httpRequest;

  return (
    <HttpRequestContainer
      httpRequest={httpRequest}
      title="CAP Root Buckets"
      subtitle="Get CAP services root bucket ids."
    >
      <Button
        onClick={trigger}
        disabled={isLoading}
        isLoading={isLoading}
        variant="gradient"
      >
        Fetch Root Buckets
      </Button>
    </HttpRequestContainer>
  );
};

const ReplicaStart: React.FC = () => {
  const httpRequest = useHttpRequest({
    url: `${env.httpHost}/start`,
    method: 'post',
  });
  const { isLoading, trigger } = httpRequest;

  return (
    <HttpRequestContainer
      httpRequest={httpRequest}
      title="Replica Start"
      subtitle="Stops and starts the running replica."
    >
      <Button
        onClick={trigger}
        disabled={isLoading}
        isLoading={isLoading}
        variant="gradient"
      >
        Replica Start
      </Button>
    </HttpRequestContainer>
  );
};

const CanisterIds: React.FC = () => {
  const httpRequest = useHttpRequest({
    url: `${env.httpHost}/canister-ids`,
    method: 'get',
  });
  const { isLoading, trigger } = httpRequest;

  return (
    <HttpRequestContainer
      httpRequest={httpRequest}
      title="Canister Ids"
      subtitle="Request the deployed canister ids."
    >
      <Button
        onClick={trigger}
        disabled={isLoading}
        isLoading={isLoading}
        variant="gradient"
      >
        Fetch Canister Ids
      </Button>
    </HttpRequestContainer>
  );
};

const FullDeploy: React.FC = () => {
  const httpRequest = useHttpRequest({
    url: `${env.httpHost}/full-deploy`,
    method: 'post',
  });
  const { isLoading, trigger } = httpRequest;

  const onClickHandler = useCallback(() => {
    // eslint-disable-next-line no-alert, no-restricted-globals
    if (confirm('This is going to clear all data stored. Are you sure?')) {
      trigger();
    }
  }, [trigger]);

  return (
    <HttpRequestContainer
      httpRequest={httpRequest}
      title="Full Deploy"
      subtitle="Full restart the IC replica and deploy all canisters again. This is going to clear all data stored."
    >
      <Button
        onClick={onClickHandler}
        disabled={isLoading}
        isLoading={isLoading}
        variant="gradient"
      >
        Trigger Full Deploy
      </Button>
    </HttpRequestContainer>
  );
};

const AddUser: React.FC = () => {
  const [principal, setPrincipal] = useState('');

  const httpRequest = useHttpRequest({
    url: `${env.httpHost}/add-user`,
    method: 'post',
    body: { principal },
  });
  const { isLoading, trigger } = httpRequest;

  return (
    <HttpRequestContainer
      httpRequest={httpRequest}
      title="Add User"
      subtitle="Mints a big amount of WICP, XTC and COIN for a given principal id. Also add this principal id to canisters whitelisting."
    >
      <Flex gap={2}>
        <Input
          placeholder="Insert a principal id"
          value={principal}
          onChange={(e) => setPrincipal(e.target.value)}
          disabled={isLoading}
        />
        <Button
          onClick={trigger}
          disabled={isLoading}
          isLoading={isLoading}
          variant="gradient"
        >
          Add User
        </Button>
      </Flex>
    </HttpRequestContainer>
  );
};

export const MainScreen: React.FC = () => (
  <Flex direction="row" height="100vh" w="100%" flexWrap="wrap">
    <Flex
      flex={1}
      direction="column"
      gap={4}
      width="100%"
      maxH="100%"
      overflow="auto"
      p={4}
      minW="md"
    >
      <Heading size="md">Sonic Testnet Dashboard</Heading>
      <ReplicaStart />
      <PingReplica />
      <CanisterIds />
      <RootBuckets />
      <AddUser />
      <FullDeploy />
    </Flex>

    <Flex flex={1} overflowY="hidden" minW="md" maxH="100%">
      <WebsocketLog />
    </Flex>
  </Flex>
);
