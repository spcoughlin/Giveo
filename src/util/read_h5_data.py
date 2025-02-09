#!/usr/bin/env python
"""
read_data.py

This script reads and prints the contents of the HDF5 databases.
It expects each file to have datasets:
  - For users: "user_ids" (S12) and "user_vectors" (shape (*, 100), float32)
  - For nonprofits: "nonprofit_ids" and "nonprofit_vectors"
"""

import h5py
import numpy as np

def print_dataset(file, name):
    if f"{name}_ids" not in file or f"{name}_vectors" not in file:
        print(f"No dataset found for {name}.")
        return

    ids_ds = file[f"{name}_ids"]
    vectors_ds = file[f"{name}_vectors"]
    num_records = ids_ds.shape[0]
    print(f"\n{name.capitalize()} Records (Total: {num_records}):")
    for i in range(num_records):
        # Decode the ID (stored as a fixed-length bytestring).
        record_id = ids_ds[i].decode("utf-8")
        vector = vectors_ds[i]
        norm = np.linalg.norm(vector)
        # Print the first 5 elements of the vector for a quick overview.
        print(f"{name.capitalize()} ID: {record_id}, Vector (first 5): {vector[:5]}, Norm: {norm:.3f}")

def main():
    user_file = "test_users.h5"
    nonprofit_file = "test_nonprofits.h5"

    print("Reading user data from:", user_file)
    with h5py.File(user_file, "r") as uf:
        print_dataset(uf, "user")

    print("\nReading nonprofit data from:", nonprofit_file)
    with h5py.File(nonprofit_file, "r") as nf:
        print_dataset(nf, "nonprofit")

if __name__ == "__main__":
    main()

