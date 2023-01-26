import csv
import json
import sys
from collections import defaultdict
from pathlib import Path
from uuid import uuid4

from slugify import slugify

REQUIRED_COLUMNS = [
    "ID",
    "Document ID",
    "CCLW Description",
    "Part of collection?",
    "Create new family/ies?",
    "Collection ID",
    "Collection name",
    "Collection summary",
    "Document title",
    "Family name",
    "Family summary",
    "Family ID",
    "Document role",
    "Applies to ID",
    "Geography ISO",
    "Documents",
    "Category",
    "Events",
    "Sectors",
    "Instruments",
    "Frameworks",
    "Responses",
    "Natural Hazards",
    "Document Type",
    "Year",
    "Language",
    "Keywords",
    "Geography",
    "Parent Legislation",
    "Comment",
]
EXTRA_COLUMNS = [
    "CPR Document ID",
    "CPR Family ID",
    "CPR Collection ID",
    "CPR Family Slug",
    "CPR Document Slug",
]


def _read_existing_data(
    csv_file_path: Path,
    existing_slugs: set[str],
    existing_doc_info: dict[str, str],
    existing_family_info: dict[str, dict[str, str]],
) -> None:
    # First pass to load existing IDs/Slugs
    with open(csv_file_path) as csv_file:
        reader = csv.DictReader(csv_file)
        from pprint import pprint
        pprint(reader.fieldnames)
        assert set(REQUIRED_COLUMNS).issubset(set(reader.fieldnames))
        row_count = 0
        errors = False

        for row in reader:
            row_count += 1
            if not row['Category'].strip():
                print(f"Error on row {row_count}: no category specified")
                errors = True 

            if not row["ID"].strip():
                print(f"Error on row {row_count}: no ID specified")
                errors = True

            if not row["Document title"].strip():
                print(f"Error on row {row_count}: not document title specified")
                errors = True 
            
            family_name = row.get("Family name").strip()
            if not family_name:
                print(f"Error on row {row_count}: family name is empty")
                errors = True
            
            # If CPR Document Slug is already set, look for existing info & validate it
            if (cpr_document_slug := row.get("CPR Document Slug")):
                cpr_document_slug = cpr_document_slug.strip()
                if cpr_document_slug in existing_slugs:
                    print(f"Error on row {row_count}: slug for document already exists!")
                    errors = True
                else:
                    existing_doc_slugs.add(cpr_document_slug)
                
            # If CPR Document ID is already set, look for existing info & validate it
            if (cpr_document_id := row.get("CPR Document ID")):
                cpr_document_id = cpr_document_id.strip()
                if cpr_document_id in existing_doc_info:
                    print(f"Error on row {row_count}: ID for row already exists!")
                    errors = True
                else:
                    existing_doc_info[cpr_document_id] = cpr_document_slug

            # If CPR Family ID is already set, look for existing info & validate it
            if (cpr_family_id := row.get("CPR Family ID")):
                cpr_family_id = cpr_family_id.strip()
                if (cpr_family_info := existing_family_info.get(cpr_family_id)):
                    # We've seen this family before, so make sure the values we already have are consistent
                    if family_name != cpr_family_info["Family name"]:
                        print(f"Error on row {row_count}: Multiple names for family id {cpr_family_id}")
                        errors = True
                else:
                    # We've not seen this family before, so make sure the slug is unique if set & store info
                    if (cpr_family_slug := row.get("CPR Family Slug")):
                        cpr_family_slug = cpr_family_slug.strip()
                        if cpr_document_slug in existing_slugs:
                            print(f"Error on row {row_count}: slug for family already exists!")
                            errors = True
                        else:
                            existing_slugs.add(cpr_document_slug)
                    
                    existing_family_info[cpr_family_id] = {
                        "Family name": row.get("Family name").strip(),
                        "CPR Family Slug": cpr_family_slug,
                    }

            # TODO: Make sure we don't have duplicated collection IDs by keeping track of the mapping
            #       between "Collection name" and "CPR Collection ID"

        if errors:
            sys.exit(10)


def _generate_slug(base, lookup, attempts=100):
    # TODO: fail after attempts are exhausted
    # TODO: extend length if attempts are exhausted
    suffix = str(uuid4())[:4]
    while (slug := f"{base}_{suffix}") in lookup:
        suffix = str(uuid4())[:4]
    return slug



def _process_csv(csv_file_path: Path) -> list[dict[str, str]]:
    existing_slugs = set()
    existing_doc_info = {}
    existing_family_info = {}

    _read_existing_data(
        csv_file_path,
        existing_slugs,
        existing_doc_info,
        existing_family_info,
    )

    family_lookup = defaultdict(lambda: defaultdict(dict))
    collection_lookup = defaultdict(dict) 
    documents = []
    with open(csv_file_path) as csv_file:
        reader = csv.DictReader(csv_file)
        row_count = 0
        for row in reader:
            row_count += 1
            category = row['Category'].strip().lower()
            action_id = row["ID"].strip()
            doc_id = row["Document ID"].strip() or "0"
            doc_title = row["Document title"].strip()

            # If CPR Document ID does not already exist, populate it
            if not (cpr_document_id := row.get("CPR Document ID", "").strip()):
                print(f"calculating cpr doc id for row {row_count}")
                cpr_document_id = f"CCLW.{category}.{action_id}.{doc_id}"

            # If CPR Document Slug doe not already exist, populate it
            if not (cpr_document_slug := row.get("CPR Document Slug", "").strip()):
                print(f"calculating doc slug for row {row_count}")
                slug_base = slugify(doc_title)
                cpr_document_slug = _generate_slug(slug_base, existing_slugs)

            # Populate Family ID & Slug if necessary 
            family_name = row["Family name"].strip().lower()
            # A family comes from a single CCLW "action ID"
            action_families = family_lookup[action_id]
            family_count = len(action_families)
            if (family_id := action_families[family_name].get("id")) is None:
                print(f"calculating cpr family id for row {row_count}")
                family_id = f"CCLW.family.{action_id}.{family_count}"
                action_families[family_name]["id"] = family_id
            if (family_slug := action_families[family_name].get("slug")) is None:
                print(f"calculating cpr family slug for row {row_count}")
                slug_base = slugify(family_name)
                family_slug = _generate_slug(slug_base, existing_slugs)
                action_families[family_name]["slug"] = family_slug

            # Populate Collection ID if necessary
            collection_name = row["Collection name"].strip().lower()
            collection_id = "N/A"
            if collection_name and collection_name not in {"n/a"}:
                # A Collection comes from a single CCLW "action ID"
                action_collections = collection_lookup[action_id]
                collection_id = action_collections.get(collection_name)
                if collection_id is None:
                    print(f"calculating cpr collection id for row {row_count}")
                    collection_id = f"CCLW.collection.{action_id}.{len(action_collections)}"
                    action_collections[collection_name] = collection_id

            documents.append({
                **row,
                **{
                    "CPR Document ID": cpr_document_id,
                    "CPR Document Slug": cpr_document_slug,
                    "CPR Family ID": family_id,
                    "CPR Family Slug": family_slug,
                    "CPR Collection ID": collection_id,
                },
            })

    return documents


def _write_file(processed_rows: list[dict[str, str]], output_path: Path) -> None:
    csv_output_fieldnames = REQUIRED_COLUMNS + EXTRA_COLUMNS
    with open(output_path, "w") as out_csv:
        writer = csv.DictWriter(out_csv, fieldnames=csv_output_fieldnames)
        writer.writeheader()
        for row in processed_rows:
            writer.writerow(row)


def main():
    csv_file_path = Path(sys.argv[1]).absolute()
    processed_rows = _process_csv(csv_file_path)
    _write_file(processed_rows, Path(f"{sys.argv[1]}_processed"))
    print("DONE")

if __name__ == "__main__":
    main()

