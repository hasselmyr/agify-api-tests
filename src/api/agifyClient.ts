import axios, { AxiosResponse } from 'axios';

export interface AgifyResponse {
  name: string;
  age: number | null;
  count: number;
  country_id?: string;
}

export interface AgifyErrorResponse {
  error?: string;
}

export type AgifyBatchResponse = AgifyResponse[] | AgifyErrorResponse;

export class AgifyClient {
  private baseUrl = 'https://api.agify.io';
  private lastResponseTime = 0;

  private async timedRequest<T>(request: () => Promise<AxiosResponse<T>>): Promise<AxiosResponse<T>> {
    const startTime = Date.now();

    try {
      const response = await request();
      this.lastResponseTime = Date.now() - startTime;
      return response;
    } catch (error) {
      this.lastResponseTime = Date.now() - startTime;
      throw error;
    }
  }

  async getAgePrediction(name: string): Promise<AxiosResponse<AgifyResponse>> {
    return this.timedRequest(() => (
      axios.get<AgifyResponse>(this.baseUrl, {
        params: { name },
        validateStatus: () => true // Don't throw on any status
      })
    ));
  }

  async getWithoutName(): Promise<AxiosResponse> {
    return this.timedRequest(() => (
      axios.get(this.baseUrl, {
        validateStatus: () => true
      })
    ));
  }

  async getAgePredictionWithCountry(name: string, countryCode: string): Promise<AxiosResponse<AgifyResponse>> {
    return this.timedRequest(() => (
      axios.get<AgifyResponse>(this.baseUrl, {
        params: { name, country_id: countryCode },
        validateStatus: () => true // Don't throw on any status
      })
    ));
  }

  async getAgePredictionWithAuth(name: string, apiKey: string): Promise<AxiosResponse<AgifyResponse>> {
    return this.timedRequest(() => (
      axios.get<AgifyResponse>(this.baseUrl, {
        params: { name, apikey: apiKey },
        validateStatus: () => true // Don't throw on any status
      })
    ));
  }

  async getBatchAgePredictions(names: string[]): Promise<AxiosResponse<AgifyBatchResponse>> {
    // Build query string with name[] parameters
    const params = new URLSearchParams();
    names.forEach(name => {
      params.append('name[]', name);
    });

    return this.timedRequest(() => (
      axios.get<AgifyBatchResponse>(this.baseUrl, {
        params,
        validateStatus: () => true // Don't throw on any status
      })
    ));
  }

  async getBatchAgePredictionsWithAuth(names: string[], apiKey: string): Promise<AxiosResponse<AgifyBatchResponse>> {
    // Build query string with name[] parameters
    const params = new URLSearchParams();
    names.forEach(name => {
      params.append('name[]', name);
    });
    params.append('apikey', apiKey);

    return this.timedRequest(() => (
      axios.get<AgifyBatchResponse>(this.baseUrl, {
        params,
        validateStatus: () => true // Don't throw on any status
      })
    ));
  }

  async getBatchAgePredictionsWithCountry(names: string[], countryCode: string): Promise<AxiosResponse<AgifyBatchResponse>> {
    // Build query string with name[] parameters and country_id
    const params = new URLSearchParams();
    names.forEach(name => {
      params.append('name[]', name);
    });
    params.append('country_id', countryCode);

    return this.timedRequest(() => (
      axios.get<AgifyBatchResponse>(this.baseUrl, {
        params,
        validateStatus: () => true // Don't throw on any status
      })
    ));
  }

  getLastResponseTime(): number {
    return this.lastResponseTime;
  }

  async getAgePredictionWithInvalidUtf8(): Promise<AxiosResponse> {
    // Send invalid UTF-8 byte sequences directly in the URL
    // %C0 and %C1 are invalid UTF-8 start bytes (overlong encoding)
    // %FF is never valid in UTF-8 (reserved for internal use)
    // These should trigger a 422 error according to API documentation
    const invalidUrl = `${this.baseUrl}?name=test%C0%C1%FF`;

    return this.timedRequest(() => (
      axios.get(invalidUrl, {
        validateStatus: () => true
      })
    ));
  }

  async getWithDuplicateNameParams(name1: string, name2: string): Promise<AxiosResponse> {
    // Manually construct URL with duplicate name parameters
    const url = `${this.baseUrl}?name=${encodeURIComponent(name1)}&name=${encodeURIComponent(name2)}`;

    return this.timedRequest(() => (
      axios.get(url, {
        validateStatus: () => true
      })
    ));
  }

  async getWithWrongParameterName(paramName: string): Promise<AxiosResponse> {
    // Use wrong parameter name (e.g., "Name" instead of "name")
    const url = `${this.baseUrl}?${paramName}=John`;

    return this.timedRequest(() => (
      axios.get(url, {
        validateStatus: () => true
      })
    ));
  }
}
