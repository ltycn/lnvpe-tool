import sys
import os
import oss2

def sync_directory_to_oss(access_key_id, access_key_secret, endpoint, bucket_name, local_directory):
    auth = oss2.Auth(access_key_id, access_key_secret)
    bucket = oss2.Bucket(auth, endpoint, bucket_name)

    for root, dirs, files in os.walk(local_directory):
        for filename in files:
            local_path = os.path.join(root, filename)
            remote_path = os.path.relpath(local_path, local_directory)
            bucket.put_object_from_file(remote_path, local_path)

if __name__ == "__main__":
    access_key_id = sys.argv[1]
    access_key_secret = sys.argv[2]
    endpoint = sys.argv[3]
    bucket_name = sys.argv[4]
    local_directory = os.getcwd()

    sync_directory_to_oss(access_key_id, access_key_secret, endpoint, bucket_name, local_directory)
