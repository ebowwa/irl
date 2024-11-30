export interface DeviceData {
  os: string;
  browser: string;
  screenResolution: string;
  deviceType: string;
}

export class DeviceInfoService {
  private static instance: DeviceInfoService;

  private constructor() {}

  public static getInstance(): DeviceInfoService {
    if (!DeviceInfoService.instance) {
      DeviceInfoService.instance = new DeviceInfoService();
    }
    return DeviceInfoService.instance;
  }

  public getDeviceInfo(): DeviceData {
    return {
      os: navigator.platform || 'Unknown OS',
      browser: navigator.userAgent || 'Unknown Browser',
      screenResolution: `${window.screen.width}x${window.screen.height}`,
      deviceType: /Mobile|Android|iPhone/i.test(navigator.userAgent) ? 'Mobile' : 'Desktop'
    };
  }
}
/**
 *  USAGE: 
 * 
import { DeviceInfoService } from '@lib/services/device-info';

// Get the instance
const deviceInfoService = DeviceInfoService.getInstance();

// Get device information
const deviceInfo = deviceInfoService.getDeviceInfo();
 */