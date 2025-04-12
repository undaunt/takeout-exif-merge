# Media Metadata Merger

This repository provides scripts to merge supplemental metadata into media files. The main functionality is provided by the script `merge_sidecar.sh`, which extracts zip archives, reads supplemental metadata from accompanying JSON sidecar files, and applies metadata changes to images and videos using `exiftool`.

## Files

- **merge_sidecar.sh**  
  Merges supplemental metadata from JSON sidecar files into media files, updating their EXIF data. The script requires `unzip`, `exiftool`, and `jq` to run correctly.

- **test_convert_date.sh**  
  Tests the date conversion function used by the main merging script. It demonstrates conversion of epoch timestamps, ensuring consistent output across platforms.


## Requirements

- Bash shell
- unzip
- exiftool
- jq
- iconv (for proper transliteration on Darwin/macOS)

## Usage

### Merging Metadata

To merge supplemental metadata into your media files, run:

```bash
./merge_sidecar.sh <input_zip_directory> <output_directory>
```

Replace `<input_zip_directory>` with the directory that contains your zip archives and `<output_directory>` with the directory where you want the merged files saved.

### Testing Date Conversion

For testing purposes or if you fork the repository, you can run:

```bash
./test_convert_date.sh
```

This script will output the conversion results for pre-configured timestamps, demonstrating the correctness of the date conversion logic.

## Development and Contributing

Contributions are welcome! If you modify the date conversion logic or other aspects of the metadata merge process, please validate your changes using `test_convert_date.sh` before submitting a pull request.

## License

This project is available under the MIT License.
