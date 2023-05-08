import { useCallback, useState } from 'react';
import { Http, HttpClientAdapter } from '@/integrations';

export type HttpRequest<Response> = {
  data: Response | undefined;
  hasError: Error | undefined;
  isLoading: boolean;
  trigger: () => Promise<Response | undefined>;
};

export const useHttpRequest = <Request = any, Response = any>(
  params: Http.Request<Request>
): HttpRequest<Response> => {
  const [data, setData] = useState<Response | undefined>();
  const [isLoading, setIsLoading] = useState(false);
  const [hasError, setHasError] = useState<Error>();

  const triggerHandler = useCallback(async () => {
    setIsLoading(true);
    setHasError(undefined);
    setData(undefined);
    try {
      const response = await HttpClientAdapter.request<Request, Response>(
        params
      );
      setData(response.data);
      return response.data;
    } catch (error) {
      setHasError(error as Error);
    } finally {
      setIsLoading(false);
    }
  }, [params]);

  return {
    data,
    isLoading,
    hasError,
    trigger: triggerHandler,
  };
};
