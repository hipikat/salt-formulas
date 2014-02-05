#!/usr/bin/env python

import argparse
import sys


arg_parser = argparse.ArgumentParser(description=__doc__)
#arg_parser.add_argument('source', type=str,
#                                help="File or URL containing HTML from a Matrix site map.")
#arg_parser.add_argument('--type1s', metavar='SOURCE', required=False, type=str,
#                                help="Source for a site map with Type 1-only pages. If given, "
#                                                        "a column with Type 1/2 will appear!")
#arg_parser.add_argument('--format', default=default_output_format, choices=output_formats,
#                                help="Output format for the site map. "
#                                                        "(default: " + default_output_format + ")")
#arg_parser.add_argument('--path-only', default=False, action='store_true',
#                                help="Just output paths (without the protocol and domain).")
#arg_parser.add_argument('--exclude-paths', metavar='PAT', default=default_exclude_path,
#                                help="Regular expression for paths to exclude from the list. "
#                                                        "(default: r'" + default_exclude_path + "')")
#arg_parser.add_argument('--soup', default=False, action='store_true',
#                                help="Use the BeautifulSoup parser to read (broken) HTML.")
arg_parser.add_argument('--assume-defaults', default=False, action='store_true',
                                help="Do not prompt; assume defaults for any parameters "
                                "that haven't been explicitely defined via options.")
#arg_parser.add_argument()


def main(*argv, **kwargs):
    opts = arg_parser.parse_args()


if __name__ == '__main__':
    main(sys.argv)
