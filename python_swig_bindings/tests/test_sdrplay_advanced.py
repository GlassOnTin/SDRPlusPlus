#!/usr/bin/env python3
"""
Advanced test script for SDR++ Python SWIG bindings with SDRPlay device
This script tests streaming samples from the SDRPlay device and other advanced functionality
"""

import sys
import os
import time
import struct
import threading
import numpy as np
import matplotlib.pyplot as plt

# Add the parent directory to the Python path to find the sdrpp module
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

try:
    import _sdrpp as sdrpp
    print("Successfully imported SDR++ Python bindings")
except ImportError as e:
    print(f"Failed to import SDR++ Python bindings: {e}")
    sys.exit(1)

class SDRPlayTester:
    """
    Class to test the SDRPlay device functionality through SDR++ Python bindings
    """
    def __init__(self):
        self.source_mgr = sdrpp.SourceManager()
        self.config_mgr = sdrpp.ConfigManager()
        self.samples = []
        self.running = False
        self.sample_thread = None
        
    def check_sdrplay_available(self):
        """Check if SDRPlay is available as a source"""
        sources = self.source_mgr.getSourceNames()
        return "sdrplay" in sources
    
    def setup_device(self, frequency=100.0e6):
        """Setup the SDRPlay device"""
        if not self.check_sdrplay_available():
            print("SDRPlay source not available")
            return False
        
        try:
            # Select SDRPlay source
            self.source_mgr.selectSource("sdrplay")
            print("Selected SDRPlay source")
            
            # Tune to the specified frequency
            self.source_mgr.tune(frequency)
            print(f"Tuned to {frequency/1e6} MHz")
            
            return True
        except Exception as e:
            print(f"Error setting up SDRPlay device: {e}")
            return False
    
    def start_streaming(self, duration=5):
        """Start streaming from the SDRPlay device for a specified duration"""
        if not self.check_sdrplay_available():
            return False
        
        try:
            self.running = True
            self.samples = []
            
            # Start the sample collection thread
            self.sample_thread = threading.Thread(target=self._collect_samples, args=(duration,))
            self.sample_thread.start()
            
            # Start the source
            self.source_mgr.start()
            print("Started SDRPlay device")
            
            return True
        except Exception as e:
            print(f"Error starting streaming: {e}")
            self.running = False
            return False
    
    def _collect_samples(self, duration):
        """Thread function to collect samples for a specified duration"""
        start_time = time.time()
        while self.running and (time.time() - start_time) < duration:
            # Placeholder for actual sample collection
            # In a real implementation, we would collect samples from the device
            # through a callback mechanism
            time.sleep(0.1)
        
        self.running = False
        self.source_mgr.stop()
        print("Stopped SDRPlay device")
    
    def plot_spectrum(self):
        """Plot the spectrum of collected samples"""
        if not self.samples:
            print("No samples to plot")
            return
        
        # Convert samples to numpy array
        samples_array = np.array(self.samples)
        
        # Calculate FFT
        spectrum = np.abs(np.fft.fftshift(np.fft.fft(samples_array)))
        
        # Plot
        plt.figure(figsize=(10, 6))
        plt.plot(spectrum)
        plt.title("SDRPlay Signal Spectrum")
        plt.xlabel("Frequency")
        plt.ylabel("Magnitude")
        plt.grid(True)
        plt.savefig("sdrplay_spectrum.png")
        print("Spectrum saved to sdrplay_spectrum.png")

def run_advanced_test():
    """Run advanced tests with the SDRPlay device"""
    print("=== Running Advanced SDRPlay Tests ===")
    
    tester = SDRPlayTester()
    
    if not tester.check_sdrplay_available():
        print("Error: SDRPlay device not available. Exiting test.")
        return False
    
    print("\n--- Setting up SDRPlay device ---")
    if not tester.setup_device(frequency=100.0e6):  # 100 MHz FM
        print("Error: Failed to setup SDRPlay device. Exiting test.")
        return False
    
    print("\n--- Testing streaming from SDRPlay ---")
    if not tester.start_streaming(duration=3):
        print("Error: Failed to start streaming. Exiting test.")
        return False
    
    # Wait for streaming to complete
    while tester.running:
        time.sleep(0.5)
    
    print("\n--- Advanced SDRPlay test completed ---")
    return True

if __name__ == "__main__":
    success = run_advanced_test()
    sys.exit(0 if success else 1)
