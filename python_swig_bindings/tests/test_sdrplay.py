#!/usr/bin/env python3
"""
Test script for SDR++ Python SWIG bindings with SDRPlay device
This script tests the basic functionality of the SDR++ Python bindings with an SDRPlay device
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

def test_config_manager():
    """Test basic ConfigManager functionality"""
    try:
        config = sdrpp.ConfigManager()
        print("Successfully created ConfigManager instance")
        return True
    except Exception as e:
        print(f"Error in ConfigManager test: {e}")
        return False

def test_source_manager():
    """Test SourceManager with SDRPlay device"""
    try:
        source_mgr = sdrpp.SourceManager()
        print("Successfully created SourceManager instance")
        
        # Get available sources
        sources = source_mgr.getSourceNames()
        print(f"Available sources: {sources}")
        
        # Check if SDRPlay is available
        if "sdrplay" in sources:
            print("SDRPlay source is available")
            
            # Try to select the SDRPlay source
            try:
                source_mgr.selectSource("sdrplay")
                print("Successfully selected SDRPlay source")
                return True
            except Exception as e:
                print(f"Error selecting SDRPlay source: {e}")
                return False
        else:
            print("SDRPlay source is not available")
            return False
    except Exception as e:
        print(f"Error in SourceManager test: {e}")
        return False

def run_all_tests():
    """Run all tests"""
    print("=== Starting SDR++ Python bindings tests ===")
    
    tests = [
        ("ConfigManager", test_config_manager),
        ("SourceManager with SDRPlay", test_source_manager),
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
    
    sys.exit(0 if all_passed else 1)

if __name__ == "__main__":
    run_all_tests()
