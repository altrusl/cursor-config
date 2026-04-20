---
name: file-to-markdown
description: Convert documents (PDF, DOCX, PPTX, ODT, RTF, HTML) to Markdown format locally with high quality. Use when the user wants to convert a file to markdown, extract text from documents, or transform documents for editing.
---

# File to Markdown Converter

Convert various document formats to Markdown locally using pandoc and other tools.

## Quick Start

```bash
# DOCX to Markdown (best quality)
pandoc input.docx -o output.md

# PDF to Markdown (text-based PDFs)
pdftotext -layout input.pdf - | pandoc -f html -t markdown -o output.md

# HTML to Markdown
pandoc input.html -o output.md

# PPTX to Markdown
pandoc input.pptx -o output.md
```

## Conversion Workflows

### DOCX Files (Best Quality)

Pandoc provides excellent DOCX conversion:

```bash
# Standard conversion
pandoc document.docx -o document.md

# With track changes visible
pandoc --track-changes=all document.docx -o document.md

# Extract images to folder
pandoc document.docx --extract-media=./images -o document.md
```

### PDF Files

PDF conversion quality depends on the PDF type:

**Text-based PDFs** (best results):
```bash
# Method 1: pdftotext with layout preservation
pdftotext -layout input.pdf output.txt

# Method 2: Using pdfplumber (if installed)
python3 << 'EOF'
import pdfplumber
import sys

with pdfplumber.open("input.pdf") as pdf:
    for page in pdf.pages:
        text = page.extract_text()
        if text:
            print(text)
            print("\n---\n")
EOF
```

**Scanned PDFs** (requires OCR):
```bash
# Check if OCR tools are available
which tesseract pdftoppm

# Convert PDF to images then OCR
pdftoppm -png input.pdf page
for img in page-*.png; do
    tesseract "$img" "${img%.png}" -l rus+eng
done
cat page-*.txt > output.txt
```

### PPTX Files

```bash
# Convert presentation to markdown
pandoc presentation.pptx -o presentation.md

# Each slide becomes a section
```

### HTML Files

```bash
# Standard HTML to Markdown
pandoc page.html -o page.md

# From URL (if curl available)
curl -s "https://example.com" | pandoc -f html -t markdown -o page.md
```

### ODT/RTF Files

```bash
# LibreOffice formats
pandoc document.odt -o document.md
pandoc document.rtf -o document.md
```

## Output Quality Tips

1. **Preserve formatting**: Use `--wrap=none` for long lines
   ```bash
   pandoc --wrap=none input.docx -o output.md
   ```

2. **Extract images**: Use `--extract-media` to save embedded images
   ```bash
   pandoc input.docx --extract-media=./media -o output.md
   ```

3. **Tables**: Pandoc handles tables well from DOCX. For PDF tables:
   ```python
   # Using pdfplumber for tables
   import pdfplumber
   with pdfplumber.open("input.pdf") as pdf:
       for page in pdf.pages:
           tables = page.extract_tables()
           for table in tables:
               print(table)
   ```

## Dependencies

| Tool | Install | Purpose |
|------|---------|---------|
| pandoc | `sudo apt install pandoc` | Universal converter (DOCX, PPTX, HTML, ODT) |
| pdftotext | `sudo apt install poppler-utils` | PDF text extraction |
| pdfplumber | `pip install pdfplumber` | PDF with tables (Python) |
| tesseract | `sudo apt install tesseract-ocr` | OCR for scanned PDFs |
| pdftoppm | `sudo apt install poppler-utils` | PDF to image for OCR |

## Troubleshooting

**Empty output from PDF?**
- PDF may be scanned/image-based - use OCR workflow
- Check with: `pdftotext input.pdf - | head`

**Garbled characters?**
- Specify encoding: `pdftotext -enc UTF-8 input.pdf output.txt`
- For Russian: `tesseract image.png output -l rus`

**Missing images in DOCX?**
- Use `--extract-media` flag with pandoc

## Common Patterns

### Batch Convert Multiple Files

```bash
# Convert all DOCX in folder
for f in *.docx; do
    pandoc "$f" -o "${f%.docx}.md"
done

# Convert all PDFs
for f in *.pdf; do
    pdftotext -layout "$f" "${f%.pdf}.txt"
done
```

### Convert and Display

```bash
# Quick preview of PDF as markdown
pdftotext -layout input.pdf - | head -100

# DOCX preview
pandoc input.docx -t plain | head -100
```
