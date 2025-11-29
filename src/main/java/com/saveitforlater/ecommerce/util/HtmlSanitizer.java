package com.saveitforlater.ecommerce.util;

import org.jsoup.Jsoup;
import org.jsoup.safety.Safelist;
import org.springframework.stereotype.Component;

/**
 * Utility class for sanitizing HTML content to prevent XSS attacks.
 * Uses jsoup library to clean potentially dangerous HTML while preserving safe formatting.
 */
@Component
public class HtmlSanitizer {

    /**
     * Safelist for rich text content - allows common formatting tags and attributes
     */
    private static final Safelist RICH_TEXT_SAFELIST = Safelist.relaxed()
            // Basic text formatting
            .addTags("h1", "h2", "h3", "h4", "h5", "h6", 
                    "p", "br", "hr", 
                    "b", "i", "u", "s", "strong", "em", "mark", "small", "del", "ins", "sub", "sup")
            // Lists
            .addTags("ul", "ol", "li")
            // Tables
            .addTags("table", "thead", "tbody", "tfoot", "tr", "th", "td", "caption", "col", "colgroup")
            // Links (with controlled attributes)
            .addTags("a")
            .addAttributes("a", "href", "title", "target", "rel")
            // Images (with controlled attributes)
            .addTags("img")
            .addAttributes("img", "src", "alt", "title", "width", "height")
            // Block elements
            .addTags("blockquote", "pre", "code", "div", "span")
            // Styling attributes (limited)
            .addAttributes(":all", "class", "style")
            // Enforce protocols for links and images
            .addProtocols("a", "href", "http", "https", "mailto")
            .addProtocols("img", "src", "http", "https", "data");

    /**
     * Sanitize HTML content for rich text fields (like product descriptions)
     * 
     * @param html The raw HTML string from user input
     * @return Sanitized HTML string safe for storage and display
     */
    public String sanitizeRichText(String html) {
        if (html == null || html.isBlank()) {
            return html;
        }
        
        // Clean the HTML using the rich text safelist
        String cleaned = Jsoup.clean(html, RICH_TEXT_SAFELIST);
        
        // Additional security: remove any remaining javascript: protocols
        cleaned = cleaned.replaceAll("(?i)javascript:", "");
        
        return cleaned;
    }

    /**
     * Sanitize HTML to plain text - strips all HTML tags
     * Useful for fields that should contain plain text only
     * 
     * @param html The raw HTML string
     * @return Plain text with all HTML tags removed
     */
    public String sanitizeToPlainText(String html) {
        if (html == null || html.isBlank()) {
            return html;
        }
        
        // Parse and extract text only, removing all HTML tags
        return Jsoup.clean(html, Safelist.none());
    }

    /**
     * Sanitize HTML for basic formatting only (no links, images, or complex structures)
     * Useful for short descriptions or comments
     * 
     * @param html The raw HTML string
     * @return Sanitized HTML with only basic formatting tags
     */
    public String sanitizeBasicFormatting(String html) {
        if (html == null || html.isBlank()) {
            return html;
        }
        
        Safelist basicList = Safelist.basic()
                .addTags("h1", "h2", "h3", "h4", "h5", "h6");
        
        return Jsoup.clean(html, basicList);
    }
}
