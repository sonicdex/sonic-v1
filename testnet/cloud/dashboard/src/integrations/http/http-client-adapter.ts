import httpProvider from 'axios';
import { AppLog } from '@/utils';
import { Http } from './models';

export class HttpClientAdapter {
  static async request<Request = any, Response = any>(
    params: Http.Request<Request>
  ): Promise<Http.Response<Response>> {
    try {
      return await httpProvider.request<Response>({
        url: params.url,
        method: params.method,
        data: params.body,
        headers: params.headers,
        params: params.params,
      });
    } catch (error) {
      AppLog.error(`Could not send request to ${params.url}`, error);
      throw error;
    }
  }
}
