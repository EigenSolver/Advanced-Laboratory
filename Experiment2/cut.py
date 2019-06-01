def remove_points(data, file_name):
    direction = input("remove rising or falling? r for rising, f for falling, else to quit.")
    if direction == "r" or direction == "f":
        threshold = float(input("threshold value?"))
        if direction=="r":
            data = data[data["v_{y}"] < threshold]
            data.to_csv(file_name)
        else:
            data=data[data["v_{y}"] > threshold]
            data.to_csv(file_name)
        print("points removed!")
    else:
        print("invalid_input...")

import pandas as pd
data_path = "./data/"

while 1:
    file_name = input("input file name: ")
    try:
        data = pd.read_csv(data_path + file_name).dropna()
    except:
        print("invalid filename...")
        continue
    remove_points(data,data_path+file_name)
    cmd = input("type c to continue, else to exit..")
    if cmd == "c":
        continue
    else:
        break
