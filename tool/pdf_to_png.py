"""Rasterise the generated invoice PDF to a PNG for the README.

Usage (needs `pip install pymupdf`):
    python tool/pdf_to_png.py build/screenshots/invoice.pdf docs/screenshots/08-pdf-invoice.png
"""
import sys

import pymupdf

src, dst = sys.argv[1], sys.argv[2]
page = pymupdf.open(src)[0]
page.get_pixmap(matrix=pymupdf.Matrix(2, 2)).save(dst)
print(f"wrote {dst}")
