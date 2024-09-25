#! /usr/bin/env python
# -*- coding: utf-8 -*-

import dendropy
import argparse

descr = """Find branches which lenght is bigger than p percentage of total three length.
"""

parser = argparse.ArgumentParser(description=descr)

parser._action_groups.pop()
required = parser.add_argument_group('required arguments')
optional = parser.add_argument_group('optional arguments')

required.add_argument("-t", "--tree", dest="tree", help="File with trees", required=True)
optional.add_argument("-p", "--brlen_max_proportion", dest="percent", default=0.5, help="The maximum percentage of total tree length for a branch to be acceptable. Default = 0.5")

args = parser.parse_args()

tree_file = args.tree
percent = args.percent

tree = dendropy.Tree.get(path=tree_file, schema='newick')
tree_len = tree.length()


for edge in tree.postorder_edge_iter():
    if edge.length is None:
        edge.length = 0


for edge in tree.postorder_edge_iter():
    brlen_prop = float(edge.length)/tree_len
    if brlen_prop >= float(percent):
       print("Check", edge.length, separator=",")
       break