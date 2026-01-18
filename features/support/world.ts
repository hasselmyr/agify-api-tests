import { World, IWorldOptions, setWorldConstructor } from '@cucumber/cucumber';
import { AgifyClient } from '../../src/api/agifyClient';
import { AxiosResponse } from 'axios';

export class CustomWorld extends World {
  public agifyClient: AgifyClient;
  public response?: AxiosResponse;
  public responses: AxiosResponse[] = [];
  public remainingQuota?: number;

  constructor(options: IWorldOptions) {
    super(options);
    this.agifyClient = new AgifyClient();
  }
}

setWorldConstructor(CustomWorld);
