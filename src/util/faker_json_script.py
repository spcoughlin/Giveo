#!/usr/bin/env python3
import argparse
import json
import random
from faker import Faker

# Preset list of tags.
tags = [
    "children",              # 0
    "women",                 # 1
    "men",                   # 2
    "LGBTQ",                 # 3
    "suicide awareness",     # 4
    "mental health",         # 5
    "club",                  # 6
    "elementary school",     # 7
    "middle school",         # 8
    "high school",           # 9
    "university",            # 10
    "sports",                # 11
    "housing",               # 12
    "addiction",             # 13
    "disasters",             # 14
    "food",                  # 15
    "abuse",                 # 16
    "animals",               # 17
    "veterans",              # 18
    "environment",           # 19
    "poverty",               # 20
    "education",             # 21
    "arts",                  # 22
    "homelessness",          # 23
    "elderly",               # 24
    "cancer",                # 25
    "research",              # 26
    "disability",            # 27
    "human rights",          # 28
    "legal aid",             # 29
    "immigration",           # 30
    "refugees",              # 31
    "community",             # 32
    "youth empowerment",     # 33
    "domestic violence",     # 34
    "fundraising",           # 35
    "global health",         # 36
    "water",                 # 37
    "sanitation",            # 38
    "refugee support",       # 39
    "community service",     # 40
    "social justice",        # 41
    "advocacy",              # 42
    "climate change",        # 43
    "sustainability",        # 44
    "conservation",          # 45
    "wildlife",              # 46
    "animal rescue",         # 47
    "elder care",            # 48
    "hunger relief",         # 49
    "disaster recovery",     # 50
    "mental illness",        # 51
    "substance abuse",       # 52
    "homeless shelters",     # 53
    "disability rights",     # 54
    "women's health",        # 55
    "children's health",     # 56
    "education access",      # 57
    "literacy",              # 58
    "after school programs", # 59
    "recreation",            # 60
    "employment",            # 61
    "job training",          # 62
    "entrepreneurship",      # 63
    "nonprofit support",     # 64
    "community gardens",     # 65
    "urban development",     # 66
    "rural development",     # 67
    "technology access",     # 68
    "digital literacy",      # 69
    "public safety",         # 70
    "emergency response",    # 71
    "crisis intervention",   # 72
    "parenting support",     # 73
    "healthcare access",     # 74
    "suicide prevention",    # 75
    "disaster preparedness", # 76
    "veteran support",       # 77
    "legal services",        # 78
    "justice reform",        # 79
    "humanitarian aid",      # 80
    "international aid",     # 81
    "childhood education",   # 82
    "early childhood",       # 83
    "environmental justice", # 84
    "sustainable agriculture",# 85
    "food banks",            # 86
    "community kitchens",    # 87
    "homeschooling",         # 88
    "religious organizations",# 89
    "spiritual support",     # 90
    "mental health support", # 91
    "senior support",        # 92
    "child advocacy",        # 93
    "disaster relief",       # 94
    "health education",      # 95
    "public health",         # 96
    "community outreach",    # 97
    "volunteerism",          # 98
    "capacity building"      # 99
]

def generate_record(fake):
    """
    Generate a fake charity record.
    
    Fields:
      - name: A company name to simulate the charity name.
      - description: A paragraph of text.
      - location: A realistic location string (e.g. "Springfield, IL").
      - heroImageURL: A simulated filename for the hero image.
      - logoImageURL: A simulated filename for the logo image.
      - primaryTags: A list of 3 tags chosen from the preset list.
      - secondarySpecs: A list of 20 tags chosen from the preset list.
    """
    return {
        "name": fake.company(),
        "description": fake.paragraph(nb_sentences=3),
        "location": f"{fake.city()}, {fake.state_abbr()}",
        "heroImageURL": f"hero_{fake.uuid4()}.png",
        "logoImageURL": f"logo_{fake.uuid4()}.png",
        "primaryTags": random.sample(tags, 3),
        "secondaryTags": random.sample(tags, 20)
    }

def main():
    parser = argparse.ArgumentParser(
        description="Generate fake charity data and save it as JSON."
    )
    parser.add_argument(
        "num_records",
        type=int,
        help="Total number of charity records to generate."
    )
    parser.add_argument(
        "output_filename",
        type=str,
        help="The JSON file to output the records to."
    )
    args = parser.parse_args()

    fake = Faker()
    records = [generate_record(fake) for _ in range(args.num_records)]
    
    with open(args.output_filename, "w") as outfile:
        json.dump(records, outfile, indent=4)
    
    print(f"Successfully generated {args.num_records} records in '{args.output_filename}'.")

if __name__ == "__main__":
    main()

