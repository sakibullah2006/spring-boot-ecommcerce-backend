# Guide to Replace Placeholders in LaTeX Documentation

This guide provides step-by-step instructions for replacing all placeholders in `dmart-documentation.tex`.

## Step 1: Create Images Directory

```bash
mkdir -p docs/latex/images
```

## Step 2: Prepare Your Images

Create or export the following images and save them in `docs/latex/images/`:

1. **architecture-diagram.png** - System architecture diagram showing layers
2. **class-diagram.png** - UML class diagram of domain entities
3. **use-case-diagram.png** - Use case diagram for Customer and Admin
4. **project-structure.png** - Screenshot of IDE showing package structure
5. **service-implementation.png** - Code screenshot of a key service class
6. **test-results.png** - Screenshot of test execution results
7. **database-schema.png** - ER diagram of database tables
8. **api-documentation.png** - Screenshot of API docs or Postman collection

### Frontend Screenshots (New)

9. **product-listing.png** - Product browsing page with grid, filters, and search
10. **product-detail.png** - Product detail page with images and attributes
11. **shopping-cart.png** - Shopping cart interface with items and totals
12. **checkout.png** - Checkout process with address and payment selection
13. **order-history.png** - Order history and tracking page
14. **admin-dashboard.png** - Admin dashboard with statistics
15. **admin-products.png** - Admin product management interface
16. **admin-orders.png** - Admin order management interface
17. **auth.png** - Login and registration pages
18. **mobile.png** - Mobile responsive view
19. **frontend-homepage.png** - Frontend homepage overview

## Step 3: Replace Each Placeholder

For each placeholder, find the `\begin{figure}[H]...\end{figure}` block and replace the `\fbox{\parbox{...}}` content with `\includegraphics`.

### Template for Replacement

**Find this pattern:**
```latex
\begin{figure}[H]
    \centering
    \fbox{\parbox{0.9\textwidth}{\centering
        \textbf{[PLACEHOLDER: ...]}
        ...
    }}
    \caption{...}
    \label{fig:...}
\end{figure}
```

**Replace with:**
```latex
\begin{figure}[H]
    \centering
    \includegraphics[width=0.9\textwidth,keepaspectratio]{images/your-image-file.png}
    \caption{...}
    \label{fig:...}
\end{figure}
```

## Step 4: Specific Replacements

### 1. System Architecture Diagram (Line ~135-144)

**Replace:**
```latex
\fbox{\parbox{0.9\textwidth}{\centering
    \textbf{[PLACEHOLDER: System Architecture Diagram]}\\
    \textit{Insert frontend screenshot or diagram showing:}\\
    \textit{Client Layer → API Layer → Service Layer → Repository Layer → Database}
}}
```

**With:**
```latex
\includegraphics[width=0.9\textwidth,keepaspectratio]{images/architecture-diagram.png}
```

### 2. Class Diagram (Line ~162-172)

**Replace:**
```latex
\fbox{\parbox{0.9\textwidth}{\centering
    \textbf{[PLACEHOLDER: UML Class Diagram]}\\
    ...
}}
```

**With:**
```latex
\includegraphics[width=0.9\textwidth,keepaspectratio]{images/class-diagram.png}
```

### 3. Use Case Diagram (Line ~183-193)

**Replace:**
```latex
\fbox{\parbox{0.9\textwidth}{\centering
    \textbf{[PLACEHOLDER: Use Case Diagram]}\\
    ...
}}
```

**With:**
```latex
\includegraphics[width=0.9\textwidth,keepaspectratio]{images/use-case-diagram.png}
```

### 4. Project Structure (Line ~239-247)

**Replace:**
```latex
\fbox{\parbox{0.9\textwidth}{\centering
    \textbf{[PLACEHOLDER: Project Structure Screenshot]}\\
    ...
}}
```

**With:**
```latex
\includegraphics[width=0.9\textwidth,keepaspectratio]{images/project-structure.png}
```

### 5. Code Implementation (Line ~287-295)

**Replace:**
```latex
\fbox{\parbox{0.9\textwidth}{\centering
    \textbf{[PLACEHOLDER: Code Screenshot]}\\
    ...
}}
```

**With:**
```latex
\includegraphics[width=0.9\textwidth,keepaspectratio]{images/service-implementation.png}
```

### 6. Testing Screenshot (Line ~339-347)

**Replace:**
```latex
\fbox{\parbox{0.9\textwidth}{\centering
    \textbf{[PLACEHOLDER: Testing Screenshot]}\\
    ...
}}
```

**With:**
```latex
\includegraphics[width=0.9\textwidth,keepaspectratio]{images/test-results.png}
```

### 7. Frontend Features (Line ~394-403)

**Replace:**
```latex
\fbox{\parbox{0.9\textwidth}{\centering
    \textbf{[PLACEHOLDER: Frontend Features Screenshot]}\\
    ...
}}
```

**With:**
```latex
\includegraphics[width=0.9\textwidth,keepaspectratio]{images/frontend-features.png}
```

### 8. Database Schema (Line ~424-432)

**Replace:**
```latex
\fbox{\parbox{0.9\textwidth}{\centering
    \textbf{[PLACEHOLDER: Database Schema Diagram]}\\
    ...
}}
```

**With:**
```latex
\includegraphics[width=0.9\textwidth,keepaspectratio]{images/database-schema.png}
```

### 9. API Documentation (Line ~450-458)

**Replace:**
```latex
\fbox{\parbox{0.9\textwidth}{\centering
    \textbf{[PLACEHOLDER: API Documentation Screenshot]}\\
    ...
}}
```

**With:**
```latex
\includegraphics[width=0.9\textwidth,keepaspectratio]{images/api-documentation.png}
```

### 10. Product Listing Page (Line ~350-358)

**Replace:**
```latex
\fbox{\parbox{0.9\textwidth}{\centering
    \textbf{[PLACEHOLDER: Product Listing Page]}\\
    ...
}}
```

**With:**
```latex
\includegraphics[width=0.9\textwidth,keepaspectratio]{images/product-listing.png}
```

### 11. Product Detail Page (Line ~360-368)

**Replace:**
```latex
\fbox{\parbox{0.9\textwidth}{\centering
    \textbf{[PLACEHOLDER: Product Detail Page]}\\
    ...
}}
```

**With:**
```latex
\includegraphics[width=0.9\textwidth,keepaspectratio]{images/product-detail.png}
```

### 12. Shopping Cart Page (Line ~370-378)

**Replace:**
```latex
\fbox{\parbox{0.9\textwidth}{\centering
    \textbf{[PLACEHOLDER: Shopping Cart Page]}\\
    ...
}}
```

**With:**
```latex
\includegraphics[width=0.9\textwidth,keepaspectratio]{images/shopping-cart.png}
```

### 13. Checkout Page (Line ~380-388)

**Replace:**
```latex
\fbox{\parbox{0.9\textwidth}{\centering
    \textbf{[PLACEHOLDER: Checkout Page]}\\
    ...
}}
```

**With:**
```latex
\includegraphics[width=0.9\textwidth,keepaspectratio]{images/checkout.png}
```

### 14. Order History Page (Line ~390-398)

**Replace:**
```latex
\fbox{\parbox{0.9\textwidth}{\centering
    \textbf{[PLACEHOLDER: Order History Page]}\\
    ...
}}
```

**With:**
```latex
\includegraphics[width=0.9\textwidth,keepaspectratio]{images/order-history.png}
```

### 15. Admin Dashboard (Line ~420-428)

**Replace:**
```latex
\fbox{\parbox{0.9\textwidth}{\centering
    \textbf{[PLACEHOLDER: Admin Dashboard]}\\
    ...
}}
```

**With:**
```latex
\includegraphics[width=0.9\textwidth,keepaspectratio]{images/admin-dashboard.png}
```

### 16. Admin Product Management (Line ~430-438)

**Replace:**
```latex
\fbox{\parbox{0.9\textwidth}{\centering
    \textbf{[PLACEHOLDER: Product Management Page]}\\
    ...
}}
```

**With:**
```latex
\includegraphics[width=0.9\textwidth,keepaspectratio]{images/admin-products.png}
```

### 17. Admin Order Management (Line ~440-448)

**Replace:**
```latex
\fbox{\parbox{0.9\textwidth}{\centering
    \textbf{[PLACEHOLDER: Order Management Page]}\\
    ...
}}
```

**With:**
```latex
\includegraphics[width=0.9\textwidth,keepaspectratio]{images/admin-orders.png}
```

### 18. Authentication Pages (Line ~470-478)

**Replace:**
```latex
\fbox{\parbox{0.9\textwidth}{\centering
    \textbf{[PLACEHOLDER: Login/Registration Page]}\\
    ...
}}
```

**With:**
```latex
\includegraphics[width=0.9\textwidth,keepaspectratio]{images/auth.png}
```

### 19. Mobile Responsive View (Line ~480-488)

**Replace:**
```latex
\fbox{\parbox{0.9\textwidth}{\centering
    \textbf{[PLACEHOLDER: Mobile Responsive View]}\\
    ...
}}
```

**With:**
```latex
\includegraphics[width=0.9\textwidth,keepaspectratio]{images/mobile.png}
```

### 20. Frontend Homepage (Line ~550-558)

**Replace:**
```latex
\fbox{\parbox{0.9\textwidth}{\centering
    \textbf{[PLACEHOLDER: Frontend Homepage]}\\
    ...
}}
```

**With:**
```latex
\includegraphics[width=0.9\textwidth,keepaspectratio]{images/frontend-homepage.png}
```

## Step 5: Compile and Verify

After replacing all placeholders:

```bash
cd docs/latex
pdflatex dmart-documentation.tex
pdflatex dmart-documentation.tex  # Run twice for references
```

Check the generated PDF to ensure all images appear correctly.

## Tips

- **Image Quality**: Use high-resolution images (at least 1920x1080 for screenshots)
- **File Formats**: PNG works best for screenshots, PDF for vector diagrams
- **Aspect Ratio**: The `keepaspectratio` option maintains image proportions
- **Width Adjustment**: Adjust `width=0.9\textwidth` if images are too large/small
- **Centering**: Images are automatically centered with `\centering`

## Tools for Creating Diagrams

- **Architecture/Class/Use Case Diagrams**: 
  - [draw.io](https://app.diagrams.net/) (free, online)
  - [Lucidchart](https://www.lucidchart.com/)
  - [PlantUML](https://plantuml.com/) (code-based)
  - IntelliJ IDEA (built-in diagram generator)

- **Database ER Diagrams**:
  - MySQL Workbench
  - [dbdiagram.io](https://dbdiagram.io/)
  - [draw.io](https://app.diagrams.net/)

- **Screenshots**:
  - Use built-in screenshot tools (Windows: Snipping Tool, Mac: Cmd+Shift+4)
  - For code: Use IDE's screenshot feature or code formatters like Carbon.now.sh

