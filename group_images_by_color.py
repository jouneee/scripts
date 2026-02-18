#!/bin/python

import os
import numpy as np
import cv2
import glob
import argparse
import time
from datetime import datetime, timedelta
from collections import defaultdict, deque

def transform(x,y,z):
    return ((x ^ y ^ z) |
            (((~x | y) & (x | ~z) & 0x55) << 1) |
            (((~x | y) & (~y | z) & 0x55) << 2))

# this shit so ass, but its fast
def bincount(a):
    a2D = a.reshape(-1, a.shape[-1])
    col_range = (256, 256, 256)
    a1D = np.ravel_multi_index(a2D.T, col_range)
    return np.unravel_index(np.bincount(a1D).argmax(), col_range)

#better
def get_dominant_color_weighted(image, sample_points=1000):
    hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)

    h, w = hsv.shape[:2]
    indices = np.random.choice(h * w, min(sample_points, h * w), replace=False)
    y_coords, x_coords = np.unravel_index(indices, (h, w))
    
    sampled_hsv = hsv[y_coords, x_coords]
    sampled_bgr = image[y_coords, x_coords]
    
    saturation = sampled_hsv[:, 1] / 255.0
    value = sampled_hsv[:, 2] / 255.0
    weights = saturation * value

    dominant_idx = np.argmax(weights)
    return tuple(sampled_bgr[dominant_idx].astype(int))

# hilbert curve for good sorting (this for knn)
def hilbert_index(bgr):
    b,g,r = int(bgr[0]) & 0xFF, int(bgr[1]) & 0xFF, int(bgr[2]) & 0xFF
    x,y,z = b ^ 0x80, g ^ 0x80, r ^ 0x80
    index = 0
    for i in range(7, -1, -1):
        mask = 1 << i
        xi = (x & mask) >> i
        yi = (y & mask) >> i
        zi = (z & mask) >> i
        octant = transform(xi,yi,zi)
        index = (index << 3) | octant
    return index

def get_image_files(folder):
    types = ('*.png', '*.jpg', '*.jpeg')
    images = []
    for t in types:
        for f in glob.glob(folder + t):
            images.append(f)
    return images

def get_dcolor(image_path):
    try:
        img = cv2.imread(image_path)
        if img is None:
            return None
        rimg = cv2.resize(img, (50, 50))
        bimg = cv2.GaussianBlur(rimg, (9, 9), 3)
        dcolor = get_dominant_color_weighted(bimg)
        if (dcolor[0]+dcolor[1]+dcolor[2]) / 3 > 240:
            return bincount(bimg)
        else:
            return dcolor
    except Exception as e:
        print(f"{str(e)}")
        return None

def group_images(dcolors, paths):
    n = len(dcolors)
    if n == 0: return {}
    
    si = sorted(range(n), key=lambda i: hilbert_index(dcolors[i]))
    scolors = [dcolors[i] for i in si]
    spaths = [paths[i] for i in si]
    
    graph = [[]for _ in range(n)]
    if USE_NEIGHBOURS:
        for i in range(n):
            start = max(0, i - NEIGHBOURS)
            end = min(n, i + NEIGHBOURS + 1)

            for j in range(start, end):
                if i == j: continue
            
                b1, g1, r1 = scolors[i]
                b2, g2, r2 = scolors[j]

                dist_sq = (b1 - b2) ** 2 + (g1 - g2) ** 2 + (r1 - r2) ** 2

                if dist_sq <= COLOR_THRESHOLD_SQ:
                    graph[i].append(j)
                    if j < 1 and i not in graph[j]:
                        graph[j].append(i)
    else:
        for i in range(n):
            for j in range(n):
                b1, g1, r1 = scolors[i]
                b2, g2, r2 = scolors[j]

                dist_sq = (b1 - b2) ** 2 + (g1 - g2) ** 2 + (r1 - r2) ** 2

                if dist_sq <= COLOR_THRESHOLD_SQ:
                    graph[i].append(j)
                    if j < i and i not in graph[j]:
                        graph[j].append(i)

    visited = [False] * n
    groups = defaultdict(list)
    group_id = 0

    for i in range(n):
        if visited[i]: continue
            
        queue = deque([i])
        visited[i] = True
        current_group = [spaths[i]]
        
        while queue:
            current = queue.popleft()
            for neighbor in graph[current]:
                if not visited[neighbor]:
                    visited[neighbor] = True
                    queue.append(neighbor)
                    current_group.append(spaths[neighbor])
        
        groups[group_id] = current_group
        group_id += 1

    return groups

def modify_timestamps(groups):
    start_time = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0) - timedelta(days=1)
    current_time = start_time
    
    similar_groups = {gid: files for gid, files in groups.items() if len(files) > 1}
    
    for group_id, files in similar_groups.items():
        group_timestamp = current_time
        
        for i, image_path in enumerate(files):
            try:
                image_timestamp = group_timestamp + timedelta(seconds=i * IMAGE_TIME_SPAN)
                timestamp_unix = time.mktime(image_timestamp.timetuple())
                os.utime(image_path, (timestamp_unix, timestamp_unix))
            except Exception as e:
                print(f"Timestamp error for {image_path}: {str(e)}")
        
        current_time += timedelta(seconds=GROUP_TIME_SPAN + (len(files) * IMAGE_TIME_SPAN))
    
    return current_time - start_time
    

parser = argparse.ArgumentParser(description="Program modifies image timestamps to group them by color similarity.")
parser.add_argument('directory')
parser.add_argument('-n', '--neighbours', default=None)
parser.add_argument('-t', '--threshold', default=10.0, help='Color similarity threshold. Low values work better.')
args = parser.parse_args()
if not os.path.isdir(args.directory):
    raise ValueError(f"Input folder not found.")
GROUP_TIME_SPAN = 5
IMAGE_TIME_SPAN = 2
USE_NEIGHBOURS = False
if (args.neighbours):
    NEIGHBOURS = int(args.neighbours)
    USE_NEIGHBOURS = True
    print("Using nearest neighbours")
COLOR_THRESHOLD = float(args.threshold)
COLOR_THRESHOLD_SQ = COLOR_THRESHOLD ** 2

dcolors = []
image_paths = get_image_files(args.directory)
for img in image_paths:
    dcolors.append(get_dcolor(img))
groups = group_images(dcolors, image_paths)
modify_timestamps(groups)
