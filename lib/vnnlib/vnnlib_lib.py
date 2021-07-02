import vnnlib_base

import numpy as np
import re

class vnn():
    def __init__(self, filename, name=None):
        self.name = name
        
        vars_in, vars_out = self._count_variables(filename)
        vnn_data = vnnlib_base.read_vnnlib_simple(filename, vars_in, vars_out)
        self.inputs = vnn_data[0][0]
        self.outputs = vnn_data[0][1]
        
        self.simple = self._simplify()
    
    def _count_variables(self, filename):
        vars_in = 0
        vars_out = 0
        statements = vnnlib_base.read_statements(filename)
        regex_declare_in = re.compile(r"^\(declare-const X_(\S+) Real\)$")
        regex_declare_out = re.compile(r"^\(declare-const Y_(\S+) Real\)$")
        for statement in statements:
            if regex_declare_in.match(statement):
                vars_in += 1
            elif regex_declare_out.match(statement):
                vars_out += 1
        return vars_in, vars_out

    def _simplify(self):
        mat_add = self.outputs[0][0]
        rhs_add = self.outputs[0][1]
        mat_mult = self.outputs[0][0]
        rhs_mult = self.outputs[0][1]
        for i in range(1, len(self.outputs)):
            mat_add = np.add(mat_add, self.outputs[i][0])
            rhs_add = np.add(rhs_add, self.outputs[i][1])
            mat_mult = np.multiply(mat_mult, self.outputs[i][0])
            rhs_mult = np.multiply(rhs_mult, self.outputs[i][1])
        return (mat_add, rhs_add), (mat_mult, rhs_mult)

    def get_centerpoint(self):
        centerpoint = []
        for r in self.inputs:
            centerpoint.append(r[0] + (r[1] - r[0]) / 2)
        return centerpoint
    
    def get_radii(self):
        radii = []
        for r in self.inputs:
            radii.append((r[1] - r[0]) / 2)
        return radii

    def get_type(self, verbose=False):
        # "Not Minimal": [-n 1 1 1 ...] <= [0]
        # "Not Maximal": [n -1 -1 -1 ...] <= [0]
        if not self.simple[0][1].all() == 0 and not self.simple[1][1].all() == 0:
            if verbose:
                print("FAIL: RHS+ and RHS* should both be all zeros")
                print("RHS+: " + str(self.simple[0][1]))
                print("RHS*: " + str(self.simple[1][1]))
            return "OTHER"
        if not v.simple[0][0].shape[0] == 1:
            if verbose:
                print("FAIL: MAT+ ought to be 1-dimensional")
                print("OUT : " + str(self.outputs))
                print("MAT+: " + str(self.simple[0][0]))
            return "OTHER"

        maximal = -1
        minimal = -1
        invalid_maximal = False
        invalid_minimal = False
        for i, n in enumerate(self.simple[0][0][0]):
            if n == len(self.simple[0][0][0]) - 1:
                if maximal == -1:
                    maximal = i
                else:
                    invalid_maximal = True
            elif n == -(len(self.simple[0][0][0]) - 1):
                if minimal == -1:
                    minimal = i
                else:
                    invalid_minimal = True
            elif n == 1:
                invalid_maximal = True
            elif n == -1:
                invalid_minimal = True
            else:
                invalid_maximal = True
                invalid_minimal = True
                break
        if maximal != -1 and invalid_maximal:
            if verbose:
                print("FAIL: Has invalid maximal")
                print("MAT+: " + str(self.simple[0][0]))
            return "OTHER"
        if minimal != -1 and invalid_minimal:
            if verbose:
                print("FAIL: Has invalid minimal")
                print("MAT+: " + str(self.simple[0][0]))
            return "OTHER"
        if maximal != -1:
            if verbose:
                print("SUCC: Has valid maximal")
            return "MAXIMAL," + str(maximal)
        if minimal != -1:
            if verbose:
                print("SUCC: Has valid minimal")
            return "MINIMAL," + str(minimal)

        if verbose:
            print("FAIL: No valid maximal or minimal")
            print(self)
        return "UNKNOWN"
    def __str__(self):
        s = ""
        s += ("IN C: " + str(self.get_centerpoint()) + "\n")
        s += ("IN R: " + str(self.get_radii()) + "\n\n")
        s += ("OUT : " + str(self.outputs) + "\n")
        s += ("MAT+: " + str(self.simple[0][0]) + "\n")
        s += ("RHS+: " + str(self.simple[0][1]) + "\n")
        s += ("MAT*: " + str(self.simple[1][0]) + "\n")
        s += ("RHS*: " + str(self.simple[1][1]))
        return s


if __name__ == "__main__":
    import sys
    verbose = 0
    try:
        sys.argv.remove("-o")
        verbose = -1
    except Exception:
        try:
            sys.argv.remove("-v")
            verbose = 1
        except Exception:
            try:
                sys.argv.remove("-V")
                verbose = 2
            except Exception:
                pass

    if len(sys.argv) < 2: # No VNNLIBs provided
        sys.stderr.write("Usage: " + sys.argv[0] + """ [-o|-v|-V] <f.vnnlib> [f1.vnnlib [f2.vnnlib ...]]
                \t-o: Use only one line as a progress bar (only works with multiple files, and only on some terminals)
                \t-v: Verbosity +1 ; shows centerpoint and radii
                \t-V: Verbosity +2 ; shows centerpoint, radii, output, MAT*, MAT+, RHS*, RHS+, and reasonings\n""")

    elif len(sys.argv) == 2: # One VNNLIB
        v = vnn(sys.argv[1])
        vcenter = v.get_centerpoint()
        vradii = v.get_radii()
        vtype = v.get_type(verbose=(verbose > 1))
        vnum = None
        if "," in vtype:
            vt = vtype.split(",")
            vtype = vt[0]
            vnum = vt[1]
        if verbose == 2:
            print(v)
        elif verbose == 1:
            print("C:" + str(vcenter))
            print("R:" + str(vradii))
        print("T:" + str(vtype))
        if vnum is not None:
            print("N:" + str(vnum))

    else: # Multiple VNNLIBs
        typedict = {}
        num = str(len(sys.argv) - 1)
        i = 0
        try:
            for f in sys.argv[1:]:
                v = vnn(f)
                vtype = v.get_type(verbose=(verbose > 1))
                vnum = None
                if "," in vtype:
                    vt = vtype.split(",")
                    vtype = vt[0]
                    vnum = vt[1]
                if verbose == 2:
                    print(v)
                elif verbose == 1:
                    vcenter = v.get_centerpoint()
                    vradii = v.get_radii()
                    print("C:" + str(vcenter))
                    print("R:" + str(vradii))
                if verbose >= 0:
                    print("T:" + str(vtype))
                    if vnum is not None:
                        print("N:" + str(vnum))
                if verbose == -1:
                    i += 1
                    sys.stderr.write("\r\033[1;31m" + str(i) + "\033[0m / \033[31m" + num + ("\033[0m (\033[36m%10.10s\033[0m) : \033[1;36m%10.10s\033[0m" % (f, vtype) ))
                if vtype not in typedict:
                    typedict[vtype] = []
                typedict[vtype].append([f, vnum])
            if verbose == -1:
                sys.stderr.write("\n")
        except KeyboardInterrupt:
            sys.stderr.write("\n\033[1;31mKeyboard Interrupt\033[0m\n")
        def sublen(k):
            return -len(typedict[k])
        for k in sorted(typedict, key=sublen):
            v = typedict[k]
            print("\033[1;35m" + str(k) + "\033[0m : \033[1;36m" + str(len(v)) + "\033[0m")
            for f in v:
                if f[1] is None:
                    print("    " + f[0])
                else:
                    print("%3.3s %s" % (f[1], f[0]))
            
