import csv
import json
import pathlib
import sys


def infer_size(weight_kg: str) -> str:
    try:
        w = float(weight_kg)
    except Exception:
        return "Unknown"
    if w < 10:
        return "Small"
    if w < 25:
        return "Medium"
    if w < 40:
        return "Medium-Large"
    return "Large"


def main(input_csv: str, output_json: str) -> None:
    breeds_out = []
    seen = set()  # de-duplicate on breed name (case-insensitive)

    with open(input_csv, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            name = (row.get("Breed") or "").strip()
            if not name:
                continue

            lower = name.lower()
            if lower in seen:
                continue
            seen.add(lower)

            weight = (row.get("Weight (kg)") or "").strip()
            size = infer_size(weight)

            entry = {
                "name": name,
                "synonyms": [lower],
                "animalType": "Dog",
                "breedGroup": "Unknown",
                "size": size,
                "lifeSpan": "Unknown",
                "description": "",
                "characteristics": {
                    "Friendliness": 0,
                    "Trainability": 0,
                    "Energy Level": 0,
                    "Shedding": 0,
                },
                "careGuide": {
                    "nutrition": "",
                    "grooming": "",
                    "exercise": "",
                    "health": "",
                },
            }
            breeds_out.append(entry)

    out_path = pathlib.Path(output_json)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(breeds_out, f, ensure_ascii=False, indent=2)

    print(f"Wrote {out_path} with {len(breeds_out)} breeds")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python scripts/convert_dogs.py <input_csv> <output_json>")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])

