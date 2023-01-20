# Script to add IDs & Slugs to Import file

This script operates on the new format Doc/Family/Collection import file and attempts to do the following:

- Basic validation of the input file using some of Marcus' comments in #tech-dev
- Consistently add IDs for Documents, Families & Collections based on the row order in the CSV
- Generate slugs for families & documents where none exists
