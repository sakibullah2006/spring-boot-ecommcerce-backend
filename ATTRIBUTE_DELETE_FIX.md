# Attribute Delete & N+1 Query Fix

## Issues Fixed

### 1. N+1 Query Problem
**Problem**: When fetching attributes, Hibernate was executing separate queries for each attribute's options, causing performance issues.

**Solution**: Added `@EntityGraph(attributePaths = {"options"})` to repository methods to eagerly fetch attribute options in a single query.

### 2. Cannot Delete Attributes
**Problem**: There was only a soft delete (deactivate) method, no actual delete functionality, and attempting to delete attributes that were in use would fail silently or with constraint violations.

**Solution**: Implemented proper delete functionality with validation.

## Changes Made

### 1. AttributeRepository.java
- Added `@EntityGraph(attributePaths = {"options"})` to:
  - `findByPublicId()`
  - `findByIsActiveTrue()`
  - `findAllActiveOrderByName()`
- Added new method `findAllWithOptions()` with EntityGraph
- Added `deleteByPublicId()` for hard delete
- Added `countProductUsages()` to check if attribute is used by products

### 2. Attribute.java (Entity)
- Updated `@OneToMany` relationship with AttributeOption to include `orphanRemoval = true`
- This ensures when an Attribute is deleted, its options are automatically removed

### 3. AttributeService.java
- Added `deleteAttribute()` method with product usage validation
  - Checks if attribute is used by any products before deletion
  - Throws descriptive error if attribute is in use
  - Cascades delete to associated options via orphanRemoval

### 4. AttributeController.java
- Separated soft delete and hard delete endpoints:
  - `PATCH /api/attributes/{id}/deactivate` - Soft delete (sets isActive=false)
  - `DELETE /api/attributes/{id}` - Hard delete (permanent removal)

### 5. AttributeOptionRepository.java
- Added `deleteByPublicId()` for hard delete
- Added `countProductUsages()` to check if option is used by products

### 6. AttributeOptionService.java
- Added `deleteOption()` method with product usage validation
  - Checks if option is used by any products before deletion
  - Throws descriptive error if option is in use
  - Removes option from parent attribute's collection

### 7. AttributeController.java (Options)
- Separated soft delete and hard delete endpoints:
  - `PATCH /api/attributes/options/{id}/deactivate` - Soft delete
  - `DELETE /api/attributes/options/{id}` - Hard delete

## API Endpoints

### Attributes

#### Soft Delete (Deactivate)
```http
PATCH /api/attributes/{attributeId}/deactivate
Authorization: Bearer {admin_token}
```
- Sets `isActive = false`
- Attribute remains in database
- Safe to use even if attribute is used by products

#### Hard Delete (Permanent)
```http
DELETE /api/attributes/{attributeId}
Authorization: Bearer {admin_token}
```
- Permanently removes attribute and its options
- Only works if attribute is NOT used by any products
- Returns 400 error with usage count if attribute is in use

### Attribute Options

#### Soft Delete (Deactivate)
```http
PATCH /api/attributes/options/{optionId}/deactivate
Authorization: Bearer {admin_token}
```
- Sets `isActive = false`
- Option remains in database
- Safe to use even if option is used by products

#### Hard Delete (Permanent)
```http
DELETE /api/attributes/options/{optionId}
Authorization: Bearer {admin_token}
```
- Permanently removes option
- Only works if option is NOT used by any products
- Returns 400 error with usage count if option is in use

## Error Messages

When attempting to delete an attribute/option that's in use:

```json
{
  "message": "Cannot delete attribute 'Color' because it is used by 5 product(s). Please remove it from all products first or use deactivate instead."
}
```

```json
{
  "message": "Cannot delete option 'Red' because it is used by 3 product(s). Please remove it from all products first or use deactivate instead."
}
```

## Performance Improvement

### Before (N+1 Problem)
```
Query 1: SELECT * FROM attribute
Query 2: SELECT * FROM attribute_option WHERE attribute_id = 1
Query 3: SELECT * FROM attribute_option WHERE attribute_id = 2
Query 4: SELECT * FROM attribute_option WHERE attribute_id = 3
... (one query per attribute)
```

### After (With EntityGraph)
```
Query 1: SELECT a.*, ao.* FROM attribute a 
         LEFT JOIN attribute_option ao ON a.id = ao.attribute_id
```

This reduces database queries from **N+1 to 1**, significantly improving performance.

## Best Practices

1. **Use Soft Delete (Deactivate) when**:
   - Attribute/option is currently used by products
   - You want to maintain data history
   - You might need to reactivate later

2. **Use Hard Delete when**:
   - Attribute/option was created by mistake
   - Attribute/option is obsolete and not used anywhere
   - You need to clean up test data

3. **Workflow**:
   - Always try soft delete first
   - Remove attribute/option from all products
   - Then perform hard delete if needed

## Testing

To verify the N+1 fix, check your logs - you should see a single JOIN query instead of multiple queries when fetching attributes with options.

To test delete functionality:
1. Create a test attribute/option
2. Try to delete it (should work)
3. Assign it to a product
4. Try to delete again (should fail with descriptive error)
5. Remove from product
6. Delete again (should work)
