#!/usr/bin/env python3
import argparse
import json
import sys

def main():
    # Set up command-line arguments
    parser = argparse.ArgumentParser(
        description="Read charity JSON data from a file and print it out in a formatted way."
    )
    parser.add_argument(
        "input_filename",
        type=str,
        help="The JSON file containing the charity records."
    )
    args = parser.parse_args()

    try:
        # Read data from the specified JSON file.
        with open(args.input_filename, "r") as infile:
            data = json.load(infile)
        
        # Print the JSON data with an indent of 4 for readability.
        print(json.dumps(data, indent=4))
    except Exception as e:
        print(f"Error reading or parsing file '{args.input_filename}': {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()

