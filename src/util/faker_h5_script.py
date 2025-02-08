#!/usr/bin/env python
"""
create_fake_data.py

This script creates fake backend user and nonprofit records and appends them to HDF5 databases.
Each database uses the following datasets:
  - For users: "user_ids" (dtype S12) and "user_vectors" (shape (*, 100), float32)
  - For nonprofits: "nonprofit_ids" (dtype S12) and "nonprofit_vectors" (shape (*, 100), float32)

Usage:
    python create_fake_data.py --num_users 15 --num_nonprofits 12
"""

import argparse
import h5py
import numpy as np
import random
from faker import Faker

# Initialize Faker
fake = Faker()

# Define 100 valid tags.
VALID_TAGS = [
    "children", "women", "men", "LGBTQ", "suicide awareness", "mental health", "club", "elementary school",
    "middle school", "high school", "university", "sports", "housing", "addiction", "disasters", "food",
    "abuse", "animals", "veterans", "environment", "poverty", "education", "arts", "homelessness", "elderly",
    "cancer", "research", "disability", "human rights", "legal aid", "immigration", "refugees", "community",
    "youth empowerment", "domestic violence", "fundraising", "global health", "water", "sanitation",
    "refugee support", "community service", "social justice", "advocacy", "climate change", "sustainability",
    "conservation", "wildlife", "animal rescue", "elder care", "hunger relief", "disaster recovery",
    "mental illness", "substance abuse", "homeless shelters", "disability rights", "women's health",
    "children's health", "education access", "literacy", "after school programs", "recreation", "employment",
    "job training", "entrepreneurship", "nonprofit support", "community gardens", "urban development",
    "rural development", "technology access", "digital literacy", "public safety", "emergency response",
    "crisis intervention", "parenting support", "healthcare access", "suicide prevention", "disaster preparedness",
    "veteran support", "legal services", "justice reform", "humanitarian aid", "international aid",
    "childhood education", "early childhood", "environmental justice", "sustainable agriculture", "food banks",
    "community kitchens", "homeschooling", "religious organizations", "spiritual support", "mental health support",
    "senior support", "child advocacy", "disaster relief", "health education", "public health", "community outreach",
    "volunteerism", "capacity building"
]
NUM_TAGS = len(VALID_TAGS)  # Should be 100

# --- Fake Data Generation Functions ---

def random_user_vector(dim=NUM_TAGS, p_zero=0.1):
    """
    Create a random user vector of length `dim` where each element is 0 with probability p_zero,
    otherwise a random float in [0.05, 1]. The vector is L2-normalized.
    """
    vector = np.empty(dim, dtype=np.float32)
    for i in range(dim):
        if random.random() < p_zero:
            vector[i] = 0.0
        else:
            vector[i] = random.uniform(0.05, 1)
    norm = np.linalg.norm(vector)
    if norm == 0:
        idx = random.randint(0, dim - 1)
        vector[idx] = random.uniform(0.05, 1)
        norm = np.linalg.norm(vector)
    return vector

def random_nonprofit_vector(dim=NUM_TAGS):
    """
    Create a random nonprofit vector of length `dim` with 3 entries set to 1, 20 entries set to 0.1,
    and the remainder 0. The vector is L2-normalized.
    """
    vector = np.zeros(dim, dtype=np.float32)
    one_indices = random.sample(range(dim), 3)
    for idx in one_indices:
        vector[idx] = 1.0
    remaining = [i for i in range(dim) if i not in one_indices]
    small_indices = random.sample(remaining, 20)
    for idx in small_indices:
        vector[idx] = 0.1
    norm = np.linalg.norm(vector)
    if norm == 0:
        vector[random.randint(0, dim-1)] = 1.0
        norm = np.linalg.norm(vector)
    return vector
# --- Database Class ---

class Database:
    def __init__(self, userFile, nonprofitFile):
        self.userFile = h5py.File(userFile, "a")
        self.nonprofitFile = h5py.File(nonprofitFile, "a")
        # Ensure that the required datasets exist in each file.
        self.ensureDatasets(self.userFile, "user")
        self.ensureDatasets(self.nonprofitFile, "nonprofit")

    def ensureDatasets(self, file, name):
        if f"{name}_ids" not in file:
            file.create_dataset(f"{name}_ids", shape=(0,), maxshape=(None,), dtype="S12")
            file.create_dataset(f"{name}_vectors", shape=(0, NUM_TAGS), maxshape=(None, NUM_TAGS), dtype=np.float32)

    def addVector(self, file, name, id, vector):
        ids_ds = file[f"{name}_ids"]
        vectors_ds = file[f"{name}_vectors"]
        size = ids_ds.shape[0]
        # Resize to add one more record.
        ids_ds.resize((size + 1,))
        vectors_ds.resize((size + 1, NUM_TAGS))
        # Store the id as a bytestring.
        ids_ds[size] = id.encode("utf-8")
        vectors_ds[size] = vector

    def addUser(self, id, vector):
        self.addVector(self.userFile, "user", id, vector)

    def addNonprofit(self, id, vector):
        self.addVector(self.nonprofitFile, "nonprofit", id, vector)

    def close(self):
        self.userFile.close()
        self.nonprofitFile.close()

# --- Main: Create and Append Fake Data ---

def main():
    parser = argparse.ArgumentParser(
        description="Append fake user and nonprofit records to HDF5 databases."
    )
    parser.add_argument("--num_users", type=int, default=10,
                        help="Number of user records to add (default: 10)")
    parser.add_argument("--num_nonprofits", type=int, default=10,
                        help="Number of nonprofit records to add (default: 10)")
    args = parser.parse_args()

    # Define file names.
    user_file = "test_users.h5"
    nonprofit_file = "test_nonprofits.h5"

    db = Database(user_file, nonprofit_file)

    # Append user records.
    for i in range(1, args.num_users + 1):
        user_id = f"u{i:03d}"
        vector = random_user_vector()
        db.addUser(user_id, vector)

    # Append nonprofit records.
    for i in range(1, args.num_nonprofits + 1):
        nonprofit_id = f"n{i:03d}"
        vector = random_nonprofit_vector()
        db.addNonprofit(nonprofit_id, vector)

    db.close()
    print(f"Added {args.num_users} user record(s) to {user_file}")
    print(f"Added {args.num_nonprofits} nonprofit record(s) to {nonprofit_file}")

if __name__ == "__main__":
    main()

