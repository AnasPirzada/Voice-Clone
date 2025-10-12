// API Configuration for F5-TTS
export const API_CONFIG = {
  // Local development - use Next.js API routes that proxy to F5-TTS server
  LOCAL_URL: '/api',
  
  // Production URL - update this when you deploy
  PRODUCTION_URL: 'https://voice-clone-3pyz.onrender.com',
  
  // Get the appropriate URL based on environment
  getBaseUrl(): string {
    // Check if we're in development (localhost)
    if (typeof window !== 'undefined') {
      const isLocalhost = window.location.hostname === 'localhost' || 
                         window.location.hostname === '127.0.0.1';
      
      if (isLocalhost) {
        return this.LOCAL_URL;
      }
    }
    
    // Use environment variable if available, otherwise fallback to production
    return process.env.NEXT_PUBLIC_API_URL || this.PRODUCTION_URL;
  }
};

// Export the base URL
export const API_BASE_URL = API_CONFIG.getBaseUrl();
