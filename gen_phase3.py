#!/usr/bin/env python3
import os
KERNEL_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "kernel", "kernel_v2.arnoldc")
MARKER = " " * 16 + "TALK TO YOURSELF " + chr(34) + "Check if we are in menu mode (use modeAtFrameStart to prevent fall-through)" + chr(34)
IM = "BECAUSE I" + chr(39) + "M GOING TO SAY PLEASE"
NB = "YOU" + chr(39) + "RE NOT BIG ENOUGH"
def sp(n): return " " * n
def cmt(t, i): return sp(i) + "TALK TO YOURSELF " + chr(34) + t + chr(34)
