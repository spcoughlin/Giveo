import h5py
import numpy as np
from nonprofit import NonProfit
from helpers import recover_nonprofit_tags

class Database:
    def __init__(self, userFile, nonprofitFile):
        self.userFile = h5py.File(userFile, "a")
        self.nonprofitFile = h5py.File(nonprofitFile, "a")
        self.ensureDatasets(self.userFile, "user")
        self.ensureDatasets(self.nonprofitFile, "nonprofit")

    def _to_bytes(self, id_val):
        """Store IDs as UTF-8–encoded bytes."""
        if isinstance(id_val, str):
            return id_val.encode("utf-8")
        return id_val

    def ensureDatasets(self, file, name):
        # Increase dtype length to 50 to store Firebase IDs
        if f"{name}_ids" not in file:
            file.create_dataset(f"{name}_ids", shape=(0,), maxshape=(None,), dtype="S50")
            file.create_dataset(f"{name}_vectors", shape=(0, 100), maxshape=(None, 100), dtype=np.float32)

    def addVector(self, file, name, id_val, vector):
        ids = file[f"{name}_ids"]
        vectors = file[f"{name}_vectors"]
        size = ids.shape[0]
        ids.resize((size + 1,))
        vectors.resize((size + 1, 100))
        ids[size] = self._to_bytes(id_val)
        vectors[size] = vector

    def addUser(self, id_val, vector):
        self.addVector(self.userFile, "user", id_val, vector)

    def addNonprofit(self, id_val, vector):
        self.addVector(self.nonprofitFile, "nonprofit", id_val, vector)

    def updateVector(self, file, name, id_val, newVector):
        id_bytes = self._to_bytes(id_val)
        ids = file[f"{name}_ids"][:]
        vectors = file[f"{name}_vectors"]
        index = np.where(ids == id_bytes)[0]
        if index.size == 0:
            raise ValueError(f"ID {id_val} not found in dataset {name}")
        vectors[index[0]] = newVector

    def updateUserVector(self, id_val, newVector):
        self.updateVector(self.userFile, "user", id_val, newVector)

    def updateNonprofitVector(self, id_val, newVector):
        self.updateVector(self.nonprofitFile, "nonprofit", id_val, newVector)

    def get(self, file, name, id_val):
        id_bytes = self._to_bytes(id_val)
        ids = file[f"{name}_ids"][:]
        vectors = file[f"{name}_vectors"]
        if id_bytes not in ids:
            return None
        index = np.where(ids == id_bytes)[0]
        return vectors[index[0]]

    def getUser(self, id_val):
        return self.get(self.userFile, "user", id_val)

    def getNonprofitVector(self, id_val):
        return self.get(self.nonprofitFile, "nonprofit", id_val)

    def getNonprofit(self, id_val):
        """
        Retrieve the nonprofit vector from the local HDF5 file and recover its primary and secondary tags.
        """
        vector = self.getNonprofitVector(id_val)
        if vector is None:
            return None
        primary, secondary = recover_nonprofit_tags(vector)
        return NonProfit(id_val, primary, secondary)

    def close(self):
        self.userFile.close()
        self.nonprofitFile.close()

    def backup(self):
        self.userFile.close()
        self.nonprofitFile.close()
        self.userFile = h5py.File(self.userFile.filename, "a")
        self.nonprofitFile = h5py.File(self.nonprofitFile.filename, "a")
        self.ensureDatasets(self.userFile, "user")
        self.ensureDatasets(self.nonprofitFile, "nonprofit")


