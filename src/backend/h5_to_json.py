#!/usr/bin/env python
"""
convert_h5_to_json.py

This script converts an HDF5 file (containing either user or nonprofit records)
to a JSON file.

Usage:
    python convert_h5_to_json.py input_file.h5 output_file.json
"""

import argparse
import h5py
import json

def convert_h5_to_json(h5_file, json_file):
    with h5py.File(h5_file, "r") as f:
        # Determine if this is a user or nonprofit file based on dataset keys.
        if "user_ids" in f and "user_vectors" in f:
            prefix = "user"
        elif "nonprofit_ids" in f and "nonprofit_vectors" in f:
            prefix = "nonprofit"
        else:
            raise ValueError("The HDF5 file does not contain the expected datasets.")

        # Load the datasets.
        ids_dataset = f[f"{prefix}_ids"][:]
        vectors_dataset = f[f"{prefix}_vectors"][:]

    # Convert the byte strings (fixed-length) to normal UTF-8 strings.
    ids = [id_bytes.decode("utf-8") for id_bytes in ids_dataset]
    # Convert numpy arrays to lists for JSON serialization.
    vectors = vectors_dataset.tolist()

    # Build a list of records.
    records = []
    for rec_id, vector in zip(ids, vectors):
        records.append({
            "id": rec_id,
            "vector": vector
        })

    # Write the records to a JSON file.
    with open(json_file, "w") as jf:
        json.dump(records, jf, indent=2)

    print(f"Successfully converted '{h5_file}' to '{json_file}'.")


def main():
    parser = argparse.ArgumentParser(
        description="Convert an HDF5 file (user or nonprofit records) to JSON."
    )
    parser.add_argument("h5_file", help="Path to the input HDF5 file.")
    parser.add_argument("json_file", help="Path to the output JSON file.")
    args = parser.parse_args()

    convert_h5_to_json(args.h5_file, args.json_file)


if __name__ == "__main__":
    main()

