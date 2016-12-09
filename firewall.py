#!/usr/bin/env python

from ishell.console import Console
from ishell.command import Command



def main():
    console = Console(prompt="firewall", prompt_delim=">")
    show = Command("show", help="Show command helper")
    setup = Command("setup", help="Setup options")


    console.loop()

if __name__ == '__main__':
    main()
