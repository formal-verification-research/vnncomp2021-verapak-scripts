def parse_benchmark(filename, benchmark_name, x_var=None):
    f = open(filename)
    s = []
    found = False
    while True:
        line = f.readline()
        if not line:
            break
        elif line.rstrip() == benchmark_name or line.rstrip() == "__default__":
            found = True
        elif found:
            if len(line.strip()) > 0:
                s.append(line.split("#")[0].strip())
            else:
                break
    f.close()
    return parse_benchmark_text(s, x_var=x_var)

def parse_benchmark_text(s, x_var=None):
    t = s[4]

    if x_var is not None and "," in x_var:
        x_var = x_var.split(",")
        for i in range(0,len(x_var)):
            x_var[i] = float(x_var[i])
        csv = True
    else:
        x_var = float(x_var)
        csv = False
    
    t = t.split(",")
    for i in range(0, len(t)):
        if t[i].endswith("x") and x_var is not None:
            if csv:
                t[i] = str(float(t[i][:-1]) * x_var[i])
            else:
                t[i] = str(float(t[i][:-1]) * x_var)
    s[4] = ",".join(t)

    return "\n".join(s)

def print_benchmark(filename, benchmark_name, x_var=None):
    print(parse_benchmark(filename, benchmark_name, x_var=x_var))

if __name__ == "__main__":
    import sys
    if len(sys.argv) < 3 or len(sys.argv) > 4:
        print("Usage: " + sys.argv[0] + " <filename> <category> [radius,radius,...]")
    else:
        print_benchmark(sys.argv[1], sys.argv[2], x_var=sys.argv[3])
