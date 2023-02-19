"""
Read Event data & output a CSV containing only ambiguous Events for existing Families.

The output is to be used to simplify the task of identifying which families events
should be linked to in the cases where we have taken a single CCLW action and split it
into multiple families.
"""

import csv
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any

REQUIRED_DFC_COLUMNS = [
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
EXTRA_DFC_COLUMNS = [
    "CPR Document ID",
    "CPR Family ID",
    "CPR Collection ID",
    "CPR Family Slug",
    "CPR Document Slug",
]

REQUIRED_EVENTS_COLUMNS = [
    "Id",
    "Eventable type",
    "Eventable Id",
    "Eventable name",
    "Event type",
    "Title",
    "Description",
    "Date",
    "Url",
]


def _read_existing_dfc_data(
    dfc_csv_file_path: Path,
    existing_slugs: set[str],
    existing_doc_info: dict[str, str],
    existing_family_info: dict[str, dict[str, Any]],
    action_id_to_family_id: dict[str, set[str]],
) -> None:
    # First pass to load existing IDs/Slugs
    with open(dfc_csv_file_path) as dfc_csv_file:
        dfc_reader = csv.DictReader(dfc_csv_file)
        assert set(REQUIRED_DFC_COLUMNS).issubset(set(dfc_reader.fieldnames or []))
        row_count = 0
        errors = False

        for row in dfc_reader:
            row_count += 1
            if not row["Category"].strip():
                print(f"Error on row {row_count}: no category specified")
                errors = True

            if not row["ID"].strip():
                print(f"Error on row {row_count}: no ID specified")
                errors = True

            if not row["Document title"].strip():
                print(f"Error on row {row_count}: not document title specified")
                errors = True

            family_name = row.get("Family name", "").strip()
            if not family_name:
                print(f"Error on row {row_count}: family name is empty")
                errors = True

            # If CPR Document Slug is already set, look for existing info & validate it
            if cpr_document_slug := row.get("CPR Document Slug", ""):
                cpr_document_slug = cpr_document_slug.strip()
                if cpr_document_slug in existing_slugs:
                    print(
                        f"Error on row {row_count}: slug for document already exists!"
                    )
                    errors = True
                else:
                    existing_slugs.add(cpr_document_slug)

            # If CPR Document ID is already set, look for existing info & validate it
            if cpr_document_id := row.get("CPR Document ID", ""):
                cpr_document_id = cpr_document_id.strip()
                if cpr_document_id in existing_doc_info:
                    print(
                        f"Error on row {row_count}: ID {cpr_document_id} for "
                        "row already exists!"
                    )
                    errors = True
                else:
                    existing_doc_info[cpr_document_id] = cpr_document_slug

            # If CPR Family ID is already set, look for existing info & validate it
            if cpr_family_id := row.get("CPR Family ID", ""):
                cpr_family_id = cpr_family_id.strip()
                if cpr_family_info := existing_family_info.get(cpr_family_id):
                    # We've seen this family before, so make sure the values we
                    # already have are consistent
                    if family_name != cpr_family_info["Family name"]:
                        print(
                            f"Error on row {row_count}: Multiple names for "
                            f"family id {cpr_family_id}: {family_name}, "
                            f"{cpr_family_info['Family name']}"
                        )
                        errors = True
                    else:
                        existing_family_info[cpr_family_id]["Document IDs"].append(
                            cpr_document_id
                        )
                else:
                    # We've not seen this family before, so make sure the slug is
                    # unique if set & store info
                    if cpr_family_slug := row.get("CPR Family Slug", ""):
                        cpr_family_slug = cpr_family_slug.strip()
                        if cpr_family_slug in existing_slugs:
                            print(
                                f"Error on row {row_count}: slug for family "
                                "already exists!"
                            )
                            errors = True
                        else:
                            existing_slugs.add(cpr_document_slug)

                    existing_family_info[cpr_family_id] = {
                        "Family name": row.get("Family name", "").strip(),
                        "CPR Family Slug": cpr_family_slug,
                        "Document IDs": [cpr_document_id],
                    }

                if action_id := row.get("ID", ""):
                    action_id_to_family_id[action_id].add(cpr_family_id)

        if errors:
            sys.exit(10)


def _read_existing_event_data(
    event_csv_file_path: Path,
    ambiguous_event_info: dict[str, list[dict[str, Any]]],
    action_id_to_family_id: dict[str, set[str]],
) -> None:
    # First pass to load existing IDs/Slugs
    with open(event_csv_file_path) as event_csv_file:
        event_reader = csv.DictReader(event_csv_file)
        print(event_reader.fieldnames)
        assert set(REQUIRED_EVENTS_COLUMNS).issubset(set(event_reader.fieldnames or []))
        row_count = 0
        actions_identified = 0

        for row in event_reader:
            row_count += 1
            if action_id := row.get("Eventable Id", ""):
                if action_id in action_id_to_family_id:
                    actions_identified += 1
                    if len(action_id_to_family_id[action_id]) > 1:
                        ambiguous_event_info[action_id].append(row)
        print(f"Identified {actions_identified} actions related to known documents")


def _process_csvs(dfc_csv_file_path: Path, events_csv_file_path: Path):
    existing_slugs = set()
    existing_doc_info = {}
    existing_family_info = {}
    action_id_to_family_id = defaultdict(set)

    _read_existing_dfc_data(
        dfc_csv_file_path,
        existing_slugs,
        existing_doc_info,
        existing_family_info,
        action_id_to_family_id,
    )

    ambiguous_event_info = defaultdict(list)

    _read_existing_event_data(
        events_csv_file_path,
        ambiguous_event_info,
        action_id_to_family_id,
    )

    print(f"Identified {len(existing_family_info)} families")
    return ambiguous_event_info, action_id_to_family_id


def _write_file(
    ambiguous_event_info: dict[str, list[dict[str, Any]]],
    action_id_to_family_id: dict[str, set[str]],
    output_path: Path,
) -> None:
    csv_output_fieldnames = REQUIRED_EVENTS_COLUMNS + ["Action ID", "Family IDs"]
    with open(output_path, "w") as out_csv:
        writer = csv.DictWriter(out_csv, fieldnames=csv_output_fieldnames)
        writer.writeheader()
        for action_id, events in ambiguous_event_info.items():
            for row in events:
                row.update(
                    {
                        "Action ID": action_id,
                        "Family IDs": ";".join(action_id_to_family_id[action_id]),
                    }
                )
                writer.writerow(row)
            writer.writerow({})


def main():
    dfc_csv_file_path = Path(sys.argv[1]).absolute()
    events_csv_file_path = Path(sys.argv[2]).absolute()
    action_events, action_families = _process_csvs(
        dfc_csv_file_path, events_csv_file_path
    )
    _write_file(action_events, action_families, Path(f"{sys.argv[1]}_grouped_events"))
    print("DONE")


if __name__ == "__main__":
    main()
