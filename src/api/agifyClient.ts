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

  async getAgePrediction(name: string): Promise<AxiosResponse<AgifyResponse>> {
    const startTime = Date.now();
    
    try {
      const response = await axios.get<AgifyResponse>(this.baseUrl, {
        params: { name },
        validateStatus: () => true // Don't throw on any status
      });
      
      this.lastResponseTime = Date.now() - startTime;
      return response;
    } catch (error) {
      this.lastResponseTime = Date.now() - startTime;
      throw error;
    }
  }

  async getWithoutName(): Promise<AxiosResponse> {
    const startTime = Date.now();
    
    try {
      const response = await axios.get(this.baseUrl, {
        validateStatus: () => true
      });
      
      this.lastResponseTime = Date.now() - startTime;
      return response;
    } catch (error) {
      this.lastResponseTime = Date.now() - startTime;
      throw error;
    }
  }

  async getAgePredictionWithCountry(name: string, countryCode: string): Promise<AxiosResponse<AgifyResponse>> {
    const startTime = Date.now();
    
    try {
      const response = await axios.get<AgifyResponse>(this.baseUrl, {
        params: { name, country_id: countryCode },
        validateStatus: () => true // Don't throw on any status
      });
      
      this.lastResponseTime = Date.now() - startTime;
      return response;
    } catch (error) {
      this.lastResponseTime = Date.now() - startTime;
      throw error;
    }
  }

  async getAgePredictionWithAuth(name: string, apiKey: string): Promise<AxiosResponse<AgifyResponse>> {
    const startTime = Date.now();
    
    try {
      const response = await axios.get<AgifyResponse>(this.baseUrl, {
        params: { name, apikey: apiKey },
        validateStatus: () => true // Don't throw on any status
      });
      
      this.lastResponseTime = Date.now() - startTime;
      return response;
    } catch (error) {
      this.lastResponseTime = Date.now() - startTime;
      throw error;
    }
  }

  async getBatchAgePredictions(names: string[]): Promise<AxiosResponse<AgifyBatchResponse>> {
    const startTime = Date.now();
    
    try {
      // Build query string with name[] parameters
      const params = new URLSearchParams();
      names.forEach(name => {
        params.append('name[]', name);
      });
      
      const response = await axios.get<AgifyBatchResponse>(this.baseUrl, {
        params,
        validateStatus: () => true // Don't throw on any status
      });
      
      this.lastResponseTime = Date.now() - startTime;
      return response;
    } catch (error) {
      this.lastResponseTime = Date.now() - startTime;
      throw error;
    }
  }

  async getBatchAgePredictionsWithAuth(names: string[], apiKey: string): Promise<AxiosResponse<AgifyBatchResponse>> {
    const startTime = Date.now();
    
    try {
      // Build query string with name[] parameters
      const params = new URLSearchParams();
      names.forEach(name => {
        params.append('name[]', name);
      });
      params.append('apikey', apiKey);
      
      const response = await axios.get<AgifyBatchResponse>(this.baseUrl, {
        params,
        validateStatus: () => true // Don't throw on any status
      });
      
      this.lastResponseTime = Date.now() - startTime;
      return response;
    } catch (error) {
      this.lastResponseTime = Date.now() - startTime;
      throw error;
    }
  }

  async getBatchAgePredictionsWithCountry(names: string[], countryCode: string): Promise<AxiosResponse<AgifyBatchResponse>> {
    const startTime = Date.now();
    
    try {
      // Build query string with name[] parameters and country_id
      const params = new URLSearchParams();
      names.forEach(name => {
        params.append('name[]', name);
      });
      params.append('country_id', countryCode);
      
      const response = await axios.get<AgifyBatchResponse>(this.baseUrl, {
        params,
        validateStatus: () => true // Don't throw on any status
      });
      
      this.lastResponseTime = Date.now() - startTime;
      return response;
    } catch (error) {
      this.lastResponseTime = Date.now() - startTime;
      throw error;
    }
  }

  getLastResponseTime(): number {
    return this.lastResponseTime;
  }
}
