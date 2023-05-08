import { AxiosResponse } from 'axios';

export namespace Http {
  export type Method = 'post' | 'get' | 'put' | 'delete';

  export type Request<RequestType = any> = {
    url: string;
    method: Method;
    body?: RequestType;
    headers?: any;
    params?: any;
  };

  export enum StatusCode {
    Ok = 200,
    NoContent = 204,
    BadRequest = 400,
    Unauthorized = 401,
    Forbidden = 403,
    NotFound = 404,
    ServerError = 500,
  }

  export type Response<ResponseType = any> = AxiosResponse<ResponseType>;
}

export namespace HttpRequests {}
