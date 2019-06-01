import os

os.chdir('./data/')
for data_file in os.listdir():
    with open(data_file) as f:
        lines=f.readlines()
        header =lines[0]
    if not "v_{y}" in header:
        with open(data_file, "r+") as f:
            for line in lines[1:]:
                f.write(line)

input("go to hell headers!!!")
            
            
