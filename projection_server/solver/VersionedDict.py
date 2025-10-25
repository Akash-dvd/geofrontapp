class VersionedDict:
  def __init__(self):
    self.versions = []
    self.current_version = {}

  def set(self, key, value):
    # Record the change
    self.versions.append((key, self.current_version.get(key, None), value))
    # Update the current version
    self.current_version[key] = value

  def get(self, key):
    return self.current_version.get(key)

  def delete(self, key):
    if key in self.current_version:
      # Record the change
      self.versions.append((key, self.current_version[key], None))
      # Update the current version
      del self.current_version[key]

  def get_version(self, version_number):
    # Reconstruct the dictionary up to the specified version
    result = {}
    for i in range(version_number + 1):
      key, _, value = self.versions[i]
      if value is None:
        result.pop(key, None)
      else:
        result[key] = value
    return result

  def get_changes(self, start_version, end_version):
    changes = []
    for i in range(start_version, end_version + 1):
      changes.append(self.versions[i])
    return changes
