import base64, os
# This script decodes and writes patch_phase3.py
b64 = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), chr(112)+chr(104)+chr(97)+chr(115)+chr(101)+chr(51)+chr(46)+chr(98)+chr(54)+chr(52)), chr(114)).read()
data = base64.b64decode(b64).decode(chr(117)+chr(116)+chr(102)+chr(45)+chr(56))
out = os.path.join(os.path.dirname(os.path.abspath(__file__)), chr(112)+chr(97)+chr(116)+chr(99)+chr(104)+chr(95)+chr(112)+chr(104)+chr(97)+chr(115)+chr(101)+chr(51)+chr(46)+chr(112)+chr(121))
open(out, chr(119), encoding=chr(117)+chr(116)+chr(102)+chr(45)+chr(56)).write(data)
print(chr(87)+chr(114)+chr(105)+chr(116)+chr(116)+chr(101)+chr(110), len(data), chr(98)+chr(121)+chr(116)+chr(101)+chr(115))