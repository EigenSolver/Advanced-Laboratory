print("loading...")
import pandas as pd
import matplotlib.pylab as plt


def plot(data):
    plt.figure().dpi = 100
    plt.subplot("121")
    plt.xlabel("t [s]")
    plt.ylabel("y [m]")
    plt.title("t-y scatter plot ")
    t = data["t"]
    y = data["y"]
    # plt.xlim((t.min,t.max))
    # plt.ylim((-0.001,0.001))
    plt.scatter(t, y, s=2)

    plt.subplot("122")
    data["v_{y}"].hist(bins=50)
    plt.title("Vertical Velocity Distribution")
    plt.xlabel("v_y [m/s]")
    plt.ylabel("n [1]")
    plt.show()

data_path = "./data/"

while 1:
    file_name = input("input file name: ")
    try:
        data = pd.read_csv(data_path + file_name).dropna()
    except:
        print("invalid filename...")
        continue
    
    plot(data)
    print("plot complete...")
    cmd = input("type c to continue, else to exit..")
    if cmd == "c":
        continue
    else:
        break