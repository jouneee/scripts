#!/usr/bin/python

import glob
import argparse
import xxhash
import os
 
def find_dupes(path, t):
    
    hash_table = {}
    duplicates = []

    for file in glob.glob(path + t):
        hash = xxhash.xxh3_64(open(file, 'rb').read()).hexdigest()
        if hash in hash_table:
            duplicates.append(file)
        else:
            hash_table[hash] = file
    return duplicates

parser = argparse.ArgumentParser(description="Remove duplicate files from directory. Will eat ram on big directories.")
parser.add_argument('directory', help="directory must end with a /")
parser.add_argument('-t', '--type', help="file type in format '*.type'; '*.*' for any type")
args = parser.parse_args()
duplicates = find_dupes(args.directory, args.type)
for dupe in duplicates:
    os.remove(dupe)
    print("Removed", dupe)

