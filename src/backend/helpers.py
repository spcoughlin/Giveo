import numpy as np
from models.user import User
from models.nonprofit import NonProfit

# -----------------
#   Helper Functions
# -----------------
def recover_nonprofit_tags(vector):
    primary = []
    secondary = []
    for i, val in enumerate(vector):
        if np.isclose(val, 10.0):
            primary.append(i)
        elif np.isclose(val, 1.0):
            secondary.append(i)
    return primary, secondary


# -----------------
#   Vector Functions
# -----------------
def compute_nonprofit_vector(nonprofit: dict, total_tags=100):
    vec = np.zeros(total_tags, dtype=np.float32)
    for tag in nonprofit.get("primary", []):
        if tag < total_tags:
            vec[tag] = 10
    for tag in nonprofit.get("secondary", []):
        if tag < total_tags:
            vec[tag] = 1
    return vec

def compute_query_vectory(query, total_tags=100):
    vec = np.zeros(total_tags, dtype=np.float32)
    for tag, weight in query.items():
        if tag < total_tags:
            vec[tag] = weight
    return vec

def cosine_similarity(vec1, vec2):
    dot_prod = np.dot(vec1, vec2)
    norm1 = np.linalg.norm(vec1)
    norm2 = np.linalg.norm(vec2)
    if norm1 == 0 or norm2 == 0:
        return 0.0
    return dot_prod / (norm1 * norm2)

# -----------------
#   Reaction Function
# -----------------
def react(n: int, user: User, nonProfit: NonProfit, amount=0.0):
    match n:
        case 0:
            user.like(nonProfit)
        case 1:
            user.dislike(nonProfit)
        case 2:
            user.ignore(nonProfit)
        case 3:
            user.donate(nonProfit, amount)
        case _:
            raise Exception("Invalid Reaction")


