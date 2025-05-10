#!/usr/bin/env python3
"""
SDRPlay Standalone Test Module

This module provides a direct Python interface to test SDRPlay functionality
without requiring the full SDR++ Python bindings. It uses subprocess to
communicate with SDR++ for controlling the SDRPlay device.

This aligns with the test-driven development approach by letting us verify
SDRPlay functionality while the full Python bindings are being developed.
"""

import os
import sys
import time
import json
import subprocess
import threading
from typing import List, Dict, Any, Optional, Tuple, Callable

class SDRPlayDevice:
    """Class to control SDRPlay devices through SDR++"""
    
    def __init__(self, sdrpp_path: str = None):
        """Initialize the SDRPlay device controller
        
        Args:
            sdrpp_path: Path to SDR++ executable, if None will search in common locations
        """
        self.sdrpp_path = sdrpp_path
        if not self.sdrpp_path:
            self.sdrpp_path = self._find_sdrpp()
            
        self.process = None
        self.config_path = None
        self.running = False
        self.device_info = {}
        
    def _find_sdrpp(self) -> str:
        """Find SDR++ executable in common locations"""
        # Common locations on Windows
        if sys.platform == 'win32':
            paths = [
                r"C:\Program Files\SDR++\sdrpp.exe",
                r"C:\SDR++\sdrpp.exe",
                # Add your custom SDR++ path here if needed
            ]
            for path in paths:
                if os.path.exists(path):
                    return path
                    
        # Common locations on Linux
        elif sys.platform.startswith('linux'):
            # Use 'which' to find sdrpp
            try:
                result = subprocess.run(['which', 'sdrpp'], 
                                       stdout=subprocess.PIPE, 
                                       stderr=subprocess.PIPE, 
                                       text=True)
                if result.returncode == 0:
                    return result.stdout.strip()
            except:
                pass
                
            # Check common locations
            paths = [
                "/usr/bin/sdrpp",
                "/usr/local/bin/sdrpp",
                # Add your custom SDR++ path here if needed
            ]
            for path in paths:
                if os.path.exists(path):
                    return path
                    
        # If we couldn't find SDR++, return None
        return None
        
    def is_sdrplay_available(self) -> bool:
        """Check if SDRPlay device is available on the system
        
        This reads the SDR++ config to see if SDRPlay devices are detected
        
        Returns:
            True if SDRPlay device is available, False otherwise
        """
        # Get default config path
        config_path = self._get_config_path()
        if not config_path or not os.path.exists(config_path):
            return False
            
        # Read config
        try:
            with open(config_path, 'r') as f:
                config = json.load(f)
                
            # Check if SDRPlay source is listed in available sources
            if 'sources' in config and 'sdrplay' in config['sources']:
                self.device_info = config['sources']['sdrplay']
                return True
                
        except Exception as e:
            print(f"Error reading config: {e}")
            
        return False
        
    def _get_config_path(self) -> Optional[str]:
        """Get path to SDR++ config file"""
        if self.config_path:
            return self.config_path
            
        # Default config paths
        if sys.platform == 'win32':
            # Check in AppData/Roaming
            appdata = os.environ.get('APPDATA')
            if appdata:
                path = os.path.join(appdata, 'sdrpp', 'config.json')
                if os.path.exists(path):
                    self.config_path = path
                    return path
                    
        elif sys.platform.startswith('linux'):
            # Check in home directory
            home = os.environ.get('HOME')
            if home:
                path = os.path.join(home, '.config', 'sdrpp', 'config.json')
                if os.path.exists(path):
                    self.config_path = path
                    return path
                    
        return None
        
    def start_sdrpp(self) -> bool:
        """Start SDR++ application
        
        Returns:
            True if SDR++ was started successfully, False otherwise
        """
        if not self.sdrpp_path:
            print("SDR++ executable not found")
            return False
            
        try:
            # Start SDR++ process
            self.process = subprocess.Popen([self.sdrpp_path],
                                          stdout=subprocess.PIPE,
                                          stderr=subprocess.PIPE)
            self.running = True
            
            # Give SDR++ time to start
            time.sleep(2)
            
            return True
        except Exception as e:
            print(f"Error starting SDR++: {e}")
            return False
            
    def stop_sdrpp(self) -> bool:
        """Stop SDR++ application
        
        Returns:
            True if SDR++ was stopped successfully, False otherwise
        """
        if self.process:
            try:
                # On Windows, terminate should work
                self.process.terminate()
                
                # Give it time to shut down gracefully
                try:
                    self.process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    # Force kill if it doesn't terminate
                    self.process.kill()
                    
                self.running = False
                return True
            except Exception as e:
                print(f"Error stopping SDR++: {e}")
                
        return False
        
    def get_sdrplay_info(self) -> Dict[str, Any]:
        """Get information about the SDRPlay device
        
        Returns:
            Dictionary with device information
        """
        if not self.is_sdrplay_available():
            return {}
            
        return self.device_info
        
    def run_basic_test(self) -> bool:
        """Run a basic test with the SDRPlay device
        
        This starts SDR++, checks if SDRPlay device is available, and then stops SDR++
        
        Returns:
            True if test was successful, False otherwise
        """
        print("Starting SDR++ basic test...")
        
        # Check if SDRPlay is available without starting SDR++
        sdrplay_available = self.is_sdrplay_available()
        print(f"SDRPlay device {'available' if sdrplay_available else 'not available'} in config")
        
        if not sdrplay_available:
            print("No SDRPlay device found in SDR++ config - starting SDR++ to check")
            
            # Start SDR++
            if not self.start_sdrpp():
                print("Failed to start SDR++")
                return False
                
            print("SDR++ started successfully")
            
            # Wait a moment for SDR++ to detect devices
            time.sleep(5)
            
            # Check again after starting
            sdrplay_available = self.is_sdrplay_available()
            print(f"SDRPlay device {'available' if sdrplay_available else 'not available'} after starting SDR++")
            
            # Stop SDR++
            self.stop_sdrpp()
            print("SDR++ stopped")
            
        # If device is available, print info
        if sdrplay_available:
            print("SDRPlay device information:")
            info = self.get_sdrplay_info()
            for key, value in info.items():
                print(f"  {key}: {value}")
                
        return sdrplay_available

# If run directly, perform basic test
if __name__ == "__main__":
    print("=== SDRPlay Standalone Test ===")
    
    # Create device controller
    sdrplay = SDRPlayDevice()
    
    # Check if SDR++ was found
    if not sdrplay.sdrpp_path:
        print("ERROR: SDR++ executable not found! Please specify the path manually.")
        sys.exit(1)
    
    print(f"Using SDR++ at: {sdrplay.sdrpp_path}")
    
    # Run basic test
    success = sdrplay.run_basic_test()
    
    # Exit with appropriate status
    sys.exit(0 if success else 1)
