#!/usr/bin/env python3
"""
Basic test script for SDR++ Python SWIG bindings with SDRPlay device
This script tests the fundamental functionality required to work with a SDRPlay device
"""

import sys
import os
import time

# Add the parent directory to the Python path to find the sdrpp module
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

try:
    import _sdrpp as sdrpp
    print("Successfully imported SDR++ Python bindings")
except ImportError as e:
    print(f"Failed to import SDR++ Python bindings: {e}")
    sys.exit(1)

def test_basic_config():
    """Test creating and using a basic configuration"""
    try:
        config = sdrpp.ConfigManager()
        print("Created ConfigManager instance")
        
        # Try to set a configuration path
        config.setPath("test_config.json")
        print("Set config path successfully")
        
        # Try to load a default config
        try:
            config.load("{}")
            print("Loaded empty config successfully")
            return True
        except Exception as e:
            print(f"Error loading config: {e}")
            return False
    except Exception as e:
        print(f"Error in basic config test: {e}")
        return False

def test_source_manager():
    """Test the source manager functionality"""
    try:
        source_mgr = sdrpp.SourceManager()
        print("Created SourceManager instance")
        
        # Get available sources
        sources = source_mgr.getSourceNames()
        print(f"Available sources: {sources}")
        
        # Check if SDRPlay is available
        if "sdrplay" in sources:
            print("SDRPlay source detected!")
            return True
        else:
            print("SDRPlay source not detected. Check if the sdrplay_source module is loaded.")
            return False
    except Exception as e:
        print(f"Error in source manager test: {e}")
        return False

def test_sdrplay_basic():
    """Test basic SDRPlay functionality"""
    try:
        source_mgr = sdrpp.SourceManager()
        
        # Check if SDRPlay is available
        sources = source_mgr.getSourceNames()
        if "sdrplay" not in sources:
            print("SDRPlay source not available")
            return False
        
        # Try to select the SDRPlay source
        try:
            source_mgr.selectSource("sdrplay")
            print("Selected SDRPlay source")
            
            # Try tuning to a frequency
            try:
                # Tune to 100 MHz FM
                freq = 100.0e6
                source_mgr.tune(freq)
                print(f"Tuned to {freq/1e6} MHz")
                
                # Start the source (should activate the SDRPlay device)
                try:
                    source_mgr.start()
                    print("Started source")
                    
                    # Wait a moment
                    time.sleep(2)
                    
                    # Stop the source
                    source_mgr.stop()
                    print("Stopped source")
                    
                    return True
                except Exception as e:
                    print(f"Error starting source: {e}")
                    return False
            except Exception as e:
                print(f"Error tuning: {e}")
                return False
        except Exception as e:
            print(f"Error selecting SDRPlay source: {e}")
            return False
    except Exception as e:
        print(f"Error in SDRPlay test: {e}")
        return False

def run_all_tests():
    """Run all tests in sequence"""
    print("=== Starting SDR++ Python bindings tests with SDRPlay ===")
    
    tests = [
        ("Basic Configuration", test_basic_config),
        ("Source Manager", test_source_manager),
        ("SDRPlay Basic", test_sdrplay_basic),
    ]
    
    results = []
    for name, test_func in tests:
        print(f"\n--- Testing {name} ---")
        result = test_func()
        results.append((name, result))
        
    print("\n=== Test Results ===")
    all_passed = True
    for name, result in results:
        status = "PASSED" if result else "FAILED"
        if not result:
            all_passed = False
        print(f"{name}: {status}")
    
    print("\nOverall status:", "PASSED" if all_passed else "FAILED")
    return all_passed

if __name__ == "__main__":
    success = run_all_tests()
    sys.exit(0 if success else 1)
