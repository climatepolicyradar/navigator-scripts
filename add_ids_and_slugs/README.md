# Script to add IDs & Slugs to Import file

These scripts operate on the new format Documnet/Family/Collection import file and additional data.

`main.py` does the following:

  - Basic validation of the input file using some of Marcus' comments in #tech-dev
  - Consistently add IDs for Documents, Families & Collections based on the row order in the CSV
  - Generate slugs for families & documents where none exists

`main_events.py` does the following:

  - Identification of Events that cannot be automatically assigned to a single family
  - Outputs these events for inspection & manual assignment
