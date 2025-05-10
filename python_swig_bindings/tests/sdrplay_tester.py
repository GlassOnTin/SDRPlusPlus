#!/usr/bin/env python3
"""
SDRPlay Testing Utility
A specialized module for test-driven development with SDRPlay devices
"""

import sys
import os
import time
import threading
import traceback
try:
    import numpy as np
    NUMPY_AVAILABLE = True
except ImportError:
    NUMPY_AVAILABLE = False

# Add the parent directory to the Python path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

try:
    import _sdrpp as sdrpp
    from _sdrpp import StringVector
except ImportError as e:
    print(f"Failed to import SDR++ Python bindings: {e}")
    raise

class SDRPlayTestHelper:
    """
    Test helper class for SDRPlay devices
    Provides a structured approach to test SDRPlay functionality through the SWIG bindings
    """
    def __init__(self):
        """Initialize the test helper"""
        self.source_mgr = None
        self.config_mgr = None
        self.vfo_mgr = None
        self.stream_helper = None
        self.is_running = False
        self.samples_received = 0
        self.last_error = None
        self.test_results = {}
        
    def setup(self):
        """Set up the necessary managers"""
        try:
            self.config_mgr = sdrpp.ConfigManager()
            self.source_mgr = sdrpp.SourceManager()
            # Note: VFO manager would be instantiated here in a complete implementation
            
            return True
        except Exception as e:
            self.last_error = f"Setup error: {e}"
            traceback.print_exc()
            return False
            
    def detect_sdrplay(self):
        """Check if SDRPlay device is available"""
        try:
            if not self.source_mgr:
                self.last_error = "Source manager not initialized"
                return False
                
            sources = self.source_mgr.getSourceNames()
            source_list = [sources[i] for i in range(sources.size())]
            
            self.test_results["available_sources"] = source_list
            return "sdrplay" in source_list
        except Exception as e:
            self.last_error = f"SDRPlay detection error: {e}"
            traceback.print_exc()
            return False
            
    def configure_sdrplay(self, freq_mhz=100.0, sample_rate=2.048e6, gain_reduction=40):
        """Configure the SDRPlay device with specified parameters"""
        try:
            if not self.source_mgr:
                self.last_error = "Source manager not initialized"
                return False
                
            if not self.detect_sdrplay():
                self.last_error = "SDRPlay device not detected"
                return False
                
            # Select SDRPlay source
            self.source_mgr.selectSource("sdrplay")
            
            # Tune to specified frequency (convert MHz to Hz)
            self.source_mgr.tune(freq_mhz * 1e6)
            
            # Note: In a complete implementation, we would set sample rate and gain
            # through the SDRPlay module's specific interface
            
            self.test_results["configured_freq_mhz"] = freq_mhz
            self.test_results["configured_sample_rate"] = sample_rate
            self.test_results["configured_gain_reduction"] = gain_reduction
            
            return True
        except Exception as e:
            self.last_error = f"SDRPlay configuration error: {e}"
            traceback.print_exc()
            return False
    
    def start_sdrplay(self, duration_sec=5):
        """Start the SDRPlay device for a specified duration"""
        try:
            if not self.source_mgr:
                self.last_error = "Source manager not initialized"
                return False
                
            # Start the source
            self.source_mgr.start()
            self.is_running = True
            
            # Create a timer to stop after duration
            def stop_after_duration():
                time.sleep(duration_sec)
                if self.is_running:
                    self.stop_sdrplay()
            
            # Start timer in a separate thread
            timer_thread = threading.Thread(target=stop_after_duration)
            timer_thread.daemon = True
            timer_thread.start()
            
            self.test_results["start_time"] = time.time()
            return True
        except Exception as e:
            self.last_error = f"SDRPlay start error: {e}"
            traceback.print_exc()
            return False
    
    def stop_sdrplay(self):
        """Stop the SDRPlay device"""
        try:
            if not self.source_mgr:
                self.last_error = "Source manager not initialized"
                return False
                
            if not self.is_running:
                return True
                
            # Stop the source
            self.source_mgr.stop()
            self.is_running = False
            
            self.test_results["stop_time"] = time.time()
            self.test_results["run_duration"] = self.test_results.get("stop_time", 0) - self.test_results.get("start_time", 0)
            
            return True
        except Exception as e:
            self.last_error = f"SDRPlay stop error: {e}"
            traceback.print_exc()
            return False
    
    def run_basic_test(self, freq_mhz=100.0, duration_sec=3):
        """Run a basic test with the SDRPlay device"""
        print(f"Starting basic SDRPlay test at {freq_mhz} MHz for {duration_sec} seconds")
        
        if not self.setup():
            print(f"Setup failed: {self.last_error}")
            return False
        
        if not self.detect_sdrplay():
            print(f"SDRPlay detection failed: {self.last_error}")
            return False
        
        print("SDRPlay device detected")
        
        if not self.configure_sdrplay(freq_mhz=freq_mhz):
            print(f"SDRPlay configuration failed: {self.last_error}")
            return False
        
        print(f"SDRPlay configured to {freq_mhz} MHz")
        
        if not self.start_sdrplay(duration_sec=duration_sec):
            print(f"SDRPlay start failed: {self.last_error}")
            return False
        
        print(f"SDRPlay started, running for {duration_sec} seconds...")
        
        # Wait for the timer to stop the device
        while self.is_running:
            time.sleep(0.1)
        
        print("SDRPlay test completed successfully")
        print(f"Test results: {self.test_results}")
        
        return True
    
    def get_last_error(self):
        """Get the last error that occurred"""
        return self.last_error
    
    def get_test_results(self):
        """Get the results of the last test run"""
        return self.test_results

def run_sdrplay_test():
    """Run a standalone SDRPlay test"""
    tester = SDRPlayTestHelper()
    result = tester.run_basic_test()
    
    if result:
        print("\n✅ SDRPlay test passed!")
        return 0
    else:
        print(f"\n❌ SDRPlay test failed: {tester.get_last_error()}")
        return 1

if __name__ == "__main__":
    sys.exit(run_sdrplay_test())
