package com.saveitforlater.ecommerce.domain.util;

import java.text.Normalizer;
import java.util.Locale;
import java.util.regex.Pattern;

/**
 * Utility class for generating URL-friendly slugs from text.
 */
public class SlugGenerator {

    private static final Pattern NON_LATIN = Pattern.compile("[^\\w-]");
    private static final Pattern WHITESPACE = Pattern.compile("[\\s]");
    private static final Pattern EDGE_HYPHENS = Pattern.compile("(^-|-$)");

    /**
     * Generates a URL-friendly slug from the given text.
     * <p>
     * Examples:
     * - "Hello World" -> "hello-world"
     * - "Product Name 123" -> "product-name-123"
     * - "Special!@# Characters" -> "special-characters"
     *
     * @param input the text to convert to a slug
     * @return a URL-friendly slug
     */
    public static String generateSlug(String input) {
        if (input == null || input.isBlank()) {
            throw new IllegalArgumentException("Input text cannot be null or blank");
        }

        String slug = input.trim().toLowerCase(Locale.ENGLISH);

        // Normalize unicode characters (e.g., é -> e)
        slug = Normalizer.normalize(slug, Normalizer.Form.NFD);

        // Replace whitespace with hyphens
        slug = WHITESPACE.matcher(slug).replaceAll("-");

        // Remove non-latin characters and special characters (except hyphens)
        slug = NON_LATIN.matcher(slug).replaceAll("");

        // Remove edge hyphens
        slug = EDGE_HYPHENS.matcher(slug).replaceAll("");

        // Replace multiple consecutive hyphens with single hyphen
        slug = slug.replaceAll("-+", "-");

        if (slug.isBlank()) {
            throw new IllegalArgumentException("Generated slug is empty after processing");
        }

        return slug;
    }

    /**
     * Generates a unique slug by appending a counter if needed.
     *
     * @param baseSlug the base slug to start with
     * @param counter  the counter to append
     * @return the slug with counter appended
     */
    public static String generateUniqueSlug(String baseSlug, int counter) {
        return baseSlug + "-" + counter;
    }
}
