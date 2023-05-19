"""
Take a Document-Family-Collection input CSV & process it for import.

Performs the following actions:
  - Basic validation of the input data for consistency
  - Generation of Document IDs
  - Generation of Family IDs
  - Generation of Collection IDs when required
  - Generation of Document slugs
  - Generation of Family Slugs
"""

import csv
import sys
from collections import defaultdict
from pathlib import Path
from uuid import uuid4
from typing import Optional

from slugify import slugify

REQUIRED_COLUMNS = [
    "Category",
    "Submission type",
    "Family name",
    "Document title",
    "Documents",
    "Author",
    "Author type",
    "Geography",
    "Geography ISO",
    "Date",
    "Document role",
    "Document variant",
    "Language",
    "CPR Collection ID",
    "CPR Document ID",
]
EXTRA_COLUMNS = [
    "CPR Family ID",
    "CPR Family Slug",
    "CPR Document Slug",
    "CPR Document Status",
    "md5sum",
]


def _read_existing_data(
    csv_file_path: Path,
    existing_slugs: set[str],
    existing_doc_info: dict[str, str],
    existing_family_info: dict[str, dict[str, Optional[str]]],
) -> None:
    # First pass to load existing IDs/Slugs
    with open(csv_file_path) as csv_file:
        reader = csv.DictReader(csv_file)

        # Validate basic file structure
        if not set(REQUIRED_COLUMNS).issubset(set(reader.fieldnames or set())):
            missing = set(REQUIRED_COLUMNS) - set(reader.fieldnames or set())
            print(f"Error reading file, required DFC columns are missing: {missing}")
            sys.exit(1)

        row_count = 0
        errors = False
        for row in reader:
            row_count += 1
            if not row["Category"].strip():
                print(f"Error on row {row_count}: no category specified")
                errors = True

            if not row["CPR Document ID"].strip():
                print(f"Error on row {row_count}: no ID specified")
                errors = True

            if not row["Document title"].strip():
                print(f"Error on row {row_count}: no document title specified")
                errors = True

            family_name = row.get("Family name", "").strip()
            cpr_family_id = row.get("CPR Family ID", "").strip()
            cpr_family_slug = row.get("CPR Family Slug", "").strip()
            cpr_document_id = row.get("CPR Document ID", "").strip()
            cpr_document_slug = row.get("CPR Document Slug", "").strip()

            if not family_name:
                print(f"Error on row {row_count}: family name is empty")
                errors = True

            # If CPR Document Slug is already set, look for existing info & validate it
            if cpr_document_slug := row.get("CPR Document Slug", ""):
                cpr_document_slug = cpr_document_slug.strip()
                if cpr_document_slug in existing_slugs:
                    print(f"Error on row {row_count}: document slug already exists!")
                    errors = True

            # If CPR Document ID is already set, look for existing info & validate it
            if cpr_document_id:
                if cpr_document_id in existing_doc_info:
                    print(f"Error on row {row_count}: ID for row already exists!")
                    errors = True
                else:
                    existing_doc_info[cpr_document_id] = cpr_document_slug

            # If CPR Family ID is already set, look for existing info & validate it
            if cpr_family_id:
                expected_family_info = existing_family_info[family_name]
                if expected_family_info:
                    if family_name in existing_family_info:
                        # We've seen this family before, so make sure the values we
                        # already have are consistent
                        if cpr_family_id is not None:
                            if cpr_family_id != expected_family_info.get("CPR Family ID"):
                                print(
                                    f"Error on row {row_count}: Multiple IDs for family "
                                    f"with name {family_name}"
                                )
                                errors = True

                        if cpr_family_slug:
                            if cpr_family_slug != expected_family_info.get("CPR Family Slug"):
                                print(
                                    f"Error on row {row_count}: family slug already exists for a different ID!"
                                )
                                errors = True

            # If we've not seen this family before, so store info
            if not existing_family_info[family_name]:
                existing_family_info[family_name] = {
                    "CPR Family ID": cpr_family_id or None,
                    "CPR Family Slug": cpr_family_slug or None,
                }
            if cpr_document_slug:
                existing_slugs.add(cpr_document_slug)
            if cpr_family_slug:
                existing_slugs.add(cpr_family_slug)

        if errors:
            sys.exit(10)


def _generate_slug(
    base: str,
    lookup: set[str],
    attempts: int = 100,
    suffix_length: int = 4,
):
    # TODO: try to extend suffix length if attempts are exhausted
    suffix = str(uuid4())[:suffix_length]
    count = 0
    while (slug := f"{base}_{suffix}") in lookup:
        count += 1
        suffix = str(uuid4())[:suffix_length]
        if count > attempts:
            raise RuntimeError(
                f"Failed to generate a slug for {base} after {attempts} attempts."
            )
    lookup.add(slug)
    return slug


def _process_csv(
    documents_file_path: Path,
) -> list[dict[str, str]]:
    existing_slugs = set()
    existing_doc_info = {}
    existing_family_info = defaultdict(dict)

    _read_existing_data(
        documents_file_path,
        existing_slugs,
        existing_doc_info,
        existing_family_info,
    )

    documents = []
    with open(documents_file_path) as csv_file:
        reader = csv.DictReader(csv_file)
        row_count = 0
        for row in reader:
            row_count += 1
            cpr_document_id = row["CPR Document ID"].strip()
            doc_title = row["Document title"].strip()

            # If CPR Document Slug does not already exist, populate it
            if not (cpr_document_slug := row.get("CPR Document Slug", "").strip()):
                print(f"calculating doc slug for row {row_count}")
                slug_base = slugify(doc_title)
                cpr_document_slug = _generate_slug(slug_base, existing_slugs)

            # A family comes from a single name
            family_name = row["Family name"].strip()

            if not (cpr_family_id := row.get("CPR Family ID", "").strip()):
                existing_family_id = existing_family_info[family_name]["CPR Family ID"]
                if existing_family_id is None:
                    print(f"calculating CPR family id for row {row_count}")
                    cpr_family_id = f"UNFCCC.family.{row_count}.0"
                    existing_family_info[family_name]["CPR Family ID"] = cpr_family_id
                else:
                    cpr_family_id = existing_family_id

            if not (cpr_family_slug := row.get("CPR Family Slug", "").strip()):
                existing_family_slug = existing_family_info[family_name]["CPR Family Slug"]
                if existing_family_slug is None:
                    print(f"calculating cpr family slug for row {row_count}")
                    slug_base = slugify(family_name)
                    cpr_family_slug = _generate_slug(slug_base, existing_slugs)
                    existing_family_info[family_name]["CPR Family Slug"] = cpr_family_slug
                else:
                    cpr_family_slug = existing_family_slug

            documents.append(
                {
                    **row,
                    **{
                        "CPR Document ID": cpr_document_id,
                        "CPR Document Slug": cpr_document_slug,
                        "CPR Document Status": "PUBLISHED",
                        "CPR Family ID": cpr_family_id,
                        "CPR Family Slug": cpr_family_slug,
                    },
                }
            )

    return documents


def _write_file(processed_rows: list[dict[str, str]], output_path: Path) -> None:
    csv_output_fieldnames = REQUIRED_COLUMNS + EXTRA_COLUMNS
    with open(output_path, "w") as out_csv:
        writer = csv.DictWriter(out_csv, fieldnames=csv_output_fieldnames)
        writer.writeheader()
        for row in processed_rows:
            writer.writerow(row)


def main():
    documents_file_path = Path(sys.argv[1]).absolute()
    processed_rows = _process_csv(documents_file_path)
    _write_file(processed_rows, Path(f"{sys.argv[1]}_processed"))
    print("DONE")


if __name__ == "__main__":
    main()
