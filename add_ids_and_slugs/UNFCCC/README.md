# Script to add IDs & Slugs to Import file

These scripts operate on the UNFCCC import document & collection files and additional data.

`main.py` does the following:

- Basic validation of the input file
- Consistently add IDs for Documents & Families based on the row order in the CSV
- Generate slugs for families & documents where none exists

`main_collections.py` does the following:

- Generate IDs for collections
- Identification of Collections that are not referenced by a family
- Outputs these collections for inspection & manual assignment
