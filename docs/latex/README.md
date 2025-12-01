# dMart LaTeX Documentation

This directory contains the LaTeX source file for the dMart project documentation.

## File

- `dmart-documentation.tex` - Main LaTeX document following the project template

## Compilation

To compile the LaTeX document to PDF, you need a LaTeX distribution installed (e.g., TeX Live, MiKTeX, or Overleaf).

### Using pdflatex (recommended):

```bash
pdflatex dmart-documentation.tex
pdflatex dmart-documentation.tex  # Run twice for proper references
```

### Using Overleaf (online):

1. Upload `dmart-documentation.tex` to Overleaf
2. Click "Recompile" to generate the PDF

## Placeholders

The document includes placeholders for frontend screenshots and diagrams:

- System Architecture Diagram
- UML Class Diagram
- Use Case Diagram
- Project Structure Screenshot
- Code Implementation Screenshot
- Testing Screenshot
- Frontend Features Screenshot
- Database Schema Diagram
- API Documentation Screenshot

Replace these placeholders with actual images when available. Images should be placed in the same directory or a subdirectory, and the `\includegraphics` command should be updated accordingly.

## Dependencies

The document uses the following LaTeX packages:
- `geometry` - Page margins
- `graphicx` - Image inclusion
- `hyperref` - Hyperlinks
- `listings` - Code listings
- `xcolor` - Colors
- `enumitem` - List formatting
- `titlesec` - Title formatting
- `float` - Float positioning

These are standard packages available in most LaTeX distributions.

