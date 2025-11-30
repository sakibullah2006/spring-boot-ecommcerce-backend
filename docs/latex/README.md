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

> **📖 Detailed Guide**: See [REPLACE_PLACEHOLDERS.md](./REPLACE_PLACEHOLDERS.md) for step-by-step instructions on replacing all placeholders.

The document includes placeholders for backend/system diagrams and frontend screenshots:

### Backend/System Diagrams

- System Architecture Diagram (Figure~\ref{fig:architecture})
- UML Class Diagram (Figure~\ref{fig:classdiagram})
- Use Case Diagram (Figure~\ref{fig:usecase})
- Project Structure Screenshot (Figure~\ref{fig:structure})
- Code Implementation Screenshot (Figure~\ref{fig:code})
- Testing Screenshot (Figure~\ref{fig:testing})
- Database Schema Diagram (Figure~\ref{fig:database})
- API Documentation Screenshot (Figure~\ref{fig:api})

### Frontend Screenshots
- Product Listing Page (Figure~\ref{fig:product-listing})
- Product Detail Page (Figure~\ref{fig:product-detail})
- Shopping Cart Page (Figure~\ref{fig:shopping-cart})
- Checkout Page (Figure~\ref{fig:checkout})
- Order History Page (Figure~\ref{fig:order-history})
- Admin Dashboard (Figure~\ref{fig:admin-dashboard})
- Admin Product Management (Figure~\ref{fig:admin-products})
- Admin Order Management (Figure~\ref{fig:admin-orders})
- Authentication Pages (Figure~\ref{fig:auth})
- Mobile Responsive View (Figure~\ref{fig:mobile})
- Frontend Homepage (Figure~\ref{fig:frontend})

### How to Replace Placeholders

To replace a placeholder with an actual image:

1. **Prepare your image file:**
   - Save your image (PNG, JPG, or PDF format recommended) in the `docs/latex/images/` directory
   - Recommended formats: PNG for screenshots, PDF for diagrams
   - Suggested naming: `architecture-diagram.png`, `class-diagram.png`, etc.

2. **Update the LaTeX figure environment:**
   
   Replace the placeholder `\fbox{\parbox{...}}` block with:
   ```latex
   \includegraphics[width=0.9\textwidth]{images/your-image-file.png}
   ```
   
   Or for better control:
   ```latex
   \includegraphics[width=\textwidth,height=0.6\textheight,keepaspectratio]{images/your-image-file.png}
   ```

3. **Example replacement:**
   
   **Before (placeholder):**
   ```latex
   \begin{figure}[H]
       \centering
       \fbox{\parbox{0.9\textwidth}{\centering
           \textbf{[PLACEHOLDER: System Architecture Diagram]}\\
           \textit{Insert frontend screenshot or diagram showing:}\\
           \textit{Client Layer → API Layer → Service Layer → Repository Layer → Database}
       }}
       \caption{System Architecture Overview}
       \label{fig:architecture}
   \end{figure}
   ```
   
   **After (with image):**
   ```latex
   \begin{figure}[H]
       \centering
       \includegraphics[width=0.9\textwidth,keepaspectratio]{images/architecture-diagram.png}
       \caption{System Architecture Overview}
       \label{fig:architecture}
   \end{figure}
   ```

4. **Create the images directory:**
   ```bash
   mkdir -p docs/latex/images
   ```

5. **Image recommendations:**
   - **Architecture Diagram**: Use tools like draw.io, Lucidchart, or PlantUML
   - **Class Diagram**: Generate from code using tools like IntelliJ IDEA's diagram feature or PlantUML
   - **Use Case Diagram**: Use draw.io or Lucidchart
   - **Screenshots**: Take high-resolution screenshots (at least 1920x1080)
   - **Database Schema**: Export from database tools or use ER diagram tools

### Quick Reference: All Placeholder Locations

| Figure Label | Line Number | Image File Suggestion |
|--------------|-------------|----------------------|
| `fig:architecture` | ~135-144 | `images/architecture-diagram.png` |
| `fig:classdiagram` | ~162-172 | `images/class-diagram.png` |
| `fig:usecase` | ~183-193 | `images/use-case-diagram.png` |
| `fig:structure` | ~239-247 | `images/project-structure.png` |
| `fig:code` | ~287-295 | `images/service-implementation.png` |
| `fig:testing` | ~339-347 | `images/test-results.png` |
| `fig:frontend` | ~394-403 | `images/frontend-features.png` |
| `fig:database` | ~424-432 | `images/database-schema.png` |
| `fig:api` | ~450-458 | `images/api-documentation.png` |

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

