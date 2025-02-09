import random

try:
    while True:
        # Create a list of 10 random floats, each rounded to 5 decimal places.
        random_list = [round(random.random(), 5) for _ in range(30)]
        print(random_list)
except KeyboardInterrupt:
    print("\nProcess interrupted. Exiting...")

