//! R2 storage service for image upload and retrieval.
//!
//! Provides typed operations for uploading images to Cloudflare R2
//! and serving them back with proper Content-Type and cache headers.
//! Used by the cover generation service and image upload routes.
//!
//! ## R2 Binding
//!
//! The service expects an R2 bucket binding named `IMAGES` in `wrangler.toml`:
//!
//! ```toml
//! [[r2_buckets]]
//! binding = "IMAGES"
//! bucket_name = "dishy-images"
//! ```

#[cfg(target_arch = "wasm32")]
use crate::logging::Logger;
use crate::types::ids::AssetId;
#[cfg(target_arch = "wasm32")]
use std::collections::HashMap;

/// Maximum allowed image size in bytes (10 MB).
const MAX_IMAGE_SIZE: usize = 10 * 1024 * 1024;

/// Supported image MIME types and their corresponding file extensions.
const SUPPORTED_TYPES: &[(&str, &str)] = &[
    ("image/jpeg", "jpg"),
    ("image/png", "png"),
    ("image/webp", "webp"),
];

/// Errors that can occur during storage operations.
#[derive(Debug, thiserror::Error)]
pub enum StorageError {
    /// The image exceeds the maximum allowed size.
    #[error("image too large: {size_bytes} bytes (max {max_bytes})")]
    ImageTooLarge {
        /// Actual size of the uploaded image.
        size_bytes: usize,
        /// Maximum allowed size.
        max_bytes: usize,
    },

    /// The image MIME type is not supported.
    #[error("unsupported image type: {content_type}")]
    UnsupportedType {
        /// The provided content type.
        content_type: String,
    },

    /// The R2 bucket binding is not available.
    #[error("R2 bucket binding not available: {message}")]
    BucketNotAvailable {
        /// Details about the binding failure.
        message: String,
    },

    /// An R2 operation failed.
    #[error("R2 operation failed: {message}")]
    R2Error {
        /// Details about the R2 failure.
        message: String,
    },

    /// The requested object was not found in R2.
    #[error("object not found: {asset_id}")]
    NotFound {
        /// The asset ID that was not found.
        asset_id: String,
    },
}

/// Result of a successful image upload.
#[derive(Debug, Clone)]
pub struct UploadResult {
    /// The generated asset ID for the uploaded image.
    pub asset_id: AssetId,
    /// The R2 object key.
    pub key: String,
    /// The content type of the uploaded image.
    pub content_type: String,
    /// The size of the uploaded image in bytes.
    pub size_bytes: usize,
}

/// Result of a successful image retrieval from R2.
#[derive(Debug)]
pub struct RetrieveResult {
    /// The raw image bytes.
    pub data: Vec<u8>,
    /// The content type of the image.
    pub content_type: String,
}

/// Validates the content type against supported image types.
///
/// Returns the file extension for the given content type.
///
/// # Errors
///
/// Returns `StorageError::UnsupportedType` if the content type is not
/// one of: `image/jpeg`, `image/png`, `image/webp`.
pub fn validate_content_type(content_type: &str) -> Result<&'static str, StorageError> {
    let normalized = content_type.to_lowercase();
    for (mime, ext) in SUPPORTED_TYPES {
        if normalized == *mime {
            return Ok(ext);
        }
    }
    Err(StorageError::UnsupportedType {
        content_type: content_type.to_string(),
    })
}

/// Validates the image size against the maximum allowed size.
///
/// # Errors
///
/// Returns `StorageError::ImageTooLarge` if the data exceeds 10 MB.
pub fn validate_image_size(data: &[u8]) -> Result<(), StorageError> {
    if data.len() > MAX_IMAGE_SIZE {
        return Err(StorageError::ImageTooLarge {
            size_bytes: data.len(),
            max_bytes: MAX_IMAGE_SIZE,
        });
    }
    Ok(())
}

/// Generates a unique R2 object key for an image.
///
/// Keys follow the pattern `images/{asset_id}.{ext}` to keep
/// images organized in a virtual directory.
pub fn generate_object_key(asset_id: &AssetId, extension: &str) -> String {
    format!("images/{}.{}", asset_id.as_str(), extension)
}

/// Uploads an image to R2 storage.
///
/// Validates the content type and size, generates a unique asset ID,
/// and stores the image bytes in the R2 bucket.
///
/// # Arguments
///
/// * `bucket` - The R2 bucket to upload to.
/// * `data` - The raw image bytes.
/// * `content_type` - The MIME type of the image.
/// * `logger` - Request logger for structured logging.
///
/// # Errors
///
/// Returns `StorageError` if validation fails or the R2 put operation fails.
#[cfg(target_arch = "wasm32")]
pub async fn upload_image(
    bucket: &worker::Bucket,
    data: &[u8],
    content_type: &str,
    logger: &Logger,
) -> Result<UploadResult, StorageError> {
    // Validate
    let extension = validate_content_type(content_type)?;
    validate_image_size(data)?;

    // Generate asset ID and key
    let asset_id = AssetId::new(uuid::Uuid::new_v4().to_string());
    let key = generate_object_key(&asset_id, extension);

    logger.info(
        "Uploading image to R2",
        HashMap::from([
            (
                "asset_id".to_string(),
                serde_json::Value::String(asset_id.as_str().to_string()),
            ),
            ("key".to_string(), serde_json::Value::String(key.clone())),
            (
                "content_type".to_string(),
                serde_json::Value::String(content_type.to_string()),
            ),
            ("size_bytes".to_string(), serde_json::json!(data.len())),
        ]),
    );

    // Build HTTP metadata with content type
    let mut http_metadata = worker::HttpMetadata::default();
    http_metadata.content_type = Some(content_type.to_string());

    // Upload to R2
    bucket
        .put(&key, worker::Data::Bytes(data.to_vec()))
        .http_metadata(http_metadata)
        .execute()
        .await
        .map_err(|e| StorageError::R2Error {
            message: format!("put failed: {e}"),
        })?;

    logger.info(
        "Image uploaded to R2 successfully",
        HashMap::from([(
            "asset_id".to_string(),
            serde_json::Value::String(asset_id.as_str().to_string()),
        )]),
    );

    Ok(UploadResult {
        asset_id,
        key,
        content_type: content_type.to_string(),
        size_bytes: data.len(),
    })
}

/// Retrieves an image from R2 storage by asset ID.
///
/// Looks up the object by trying each supported extension. Returns
/// the raw image bytes and content type.
///
/// # Arguments
///
/// * `bucket` - The R2 bucket to read from.
/// * `asset_id` - The asset ID to look up.
/// * `logger` - Request logger for structured logging.
///
/// # Errors
///
/// Returns `StorageError::NotFound` if no matching object exists.
/// Returns `StorageError::R2Error` if the R2 get operation fails.
#[cfg(target_arch = "wasm32")]
pub async fn retrieve_image(
    bucket: &worker::Bucket,
    asset_id: &str,
    logger: &Logger,
) -> Result<RetrieveResult, StorageError> {
    logger.debug(
        "Retrieving image from R2",
        HashMap::from([(
            "asset_id".to_string(),
            serde_json::Value::String(asset_id.to_string()),
        )]),
    );

    // Try each supported extension
    for (mime, ext) in SUPPORTED_TYPES {
        let key = format!("images/{asset_id}.{ext}");
        match bucket.get(&key).execute().await {
            Ok(Some(obj)) => {
                let body = obj.body().ok_or_else(|| StorageError::R2Error {
                    message: "object has no body".to_string(),
                })?;
                let data = body.bytes().await.map_err(|e| StorageError::R2Error {
                    message: format!("failed to read body: {e}"),
                })?;

                // Use HTTP metadata content type if available, otherwise infer from extension
                let content_type = obj
                    .http_metadata()
                    .content_type
                    .unwrap_or_else(|| mime.to_string());

                logger.info(
                    "Image retrieved from R2",
                    HashMap::from([
                        (
                            "asset_id".to_string(),
                            serde_json::Value::String(asset_id.to_string()),
                        ),
                        (
                            "content_type".to_string(),
                            serde_json::Value::String(content_type.clone()),
                        ),
                        ("size_bytes".to_string(), serde_json::json!(data.len())),
                    ]),
                );

                return Ok(RetrieveResult { data, content_type });
            }
            Ok(None) => continue,
            Err(e) => {
                return Err(StorageError::R2Error {
                    message: format!("get failed for key {key}: {e}"),
                });
            }
        }
    }

    Err(StorageError::NotFound {
        asset_id: asset_id.to_string(),
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn validate_content_type_accepts_jpeg() {
        assert_eq!(validate_content_type("image/jpeg").ok(), Some("jpg"));
    }

    #[test]
    fn validate_content_type_accepts_png() {
        assert_eq!(validate_content_type("image/png").ok(), Some("png"));
    }

    #[test]
    fn validate_content_type_accepts_webp() {
        assert_eq!(validate_content_type("image/webp").ok(), Some("webp"));
    }

    #[test]
    fn validate_content_type_rejects_gif() {
        let result = validate_content_type("image/gif");
        assert!(result.is_err());
        match result {
            Err(StorageError::UnsupportedType { content_type }) => {
                assert_eq!(content_type, "image/gif");
            }
            other => panic!("expected UnsupportedType, got {other:?}"),
        }
    }

    #[test]
    fn validate_content_type_rejects_text() {
        assert!(validate_content_type("text/plain").is_err());
    }

    #[test]
    fn validate_content_type_is_case_insensitive() {
        assert_eq!(validate_content_type("Image/JPEG").ok(), Some("jpg"));
        assert_eq!(validate_content_type("IMAGE/PNG").ok(), Some("png"));
    }

    #[test]
    fn validate_image_size_accepts_small_image() {
        let data = vec![0u8; 1024]; // 1 KB
        assert!(validate_image_size(&data).is_ok());
    }

    #[test]
    fn validate_image_size_accepts_exactly_max() {
        let data = vec![0u8; MAX_IMAGE_SIZE];
        assert!(validate_image_size(&data).is_ok());
    }

    #[test]
    fn validate_image_size_rejects_oversized() {
        let data = vec![0u8; MAX_IMAGE_SIZE + 1];
        let result = validate_image_size(&data);
        assert!(result.is_err());
        match result {
            Err(StorageError::ImageTooLarge {
                size_bytes,
                max_bytes,
            }) => {
                assert_eq!(size_bytes, MAX_IMAGE_SIZE + 1);
                assert_eq!(max_bytes, MAX_IMAGE_SIZE);
            }
            other => panic!("expected ImageTooLarge, got {other:?}"),
        }
    }

    #[test]
    fn generate_object_key_format() {
        let asset_id = AssetId::new("abc-123");
        let key = generate_object_key(&asset_id, "jpg");
        assert_eq!(key, "images/abc-123.jpg");
    }

    #[test]
    fn generate_object_key_for_different_extensions() {
        let asset_id = AssetId::new("test-id");
        assert_eq!(generate_object_key(&asset_id, "png"), "images/test-id.png");
        assert_eq!(
            generate_object_key(&asset_id, "webp"),
            "images/test-id.webp"
        );
    }

    #[test]
    fn storage_error_display_formats() {
        let err = StorageError::ImageTooLarge {
            size_bytes: 15_000_000,
            max_bytes: MAX_IMAGE_SIZE,
        };
        assert!(err.to_string().contains("15000000"));
        assert!(err.to_string().contains("10485760"));

        let err = StorageError::UnsupportedType {
            content_type: "image/bmp".to_string(),
        };
        assert!(err.to_string().contains("image/bmp"));

        let err = StorageError::NotFound {
            asset_id: "missing-id".to_string(),
        };
        assert!(err.to_string().contains("missing-id"));
    }

    #[test]
    fn upload_result_has_expected_fields() {
        let result = UploadResult {
            asset_id: AssetId::new("test"),
            key: "images/test.jpg".to_string(),
            content_type: "image/jpeg".to_string(),
            size_bytes: 1024,
        };
        assert_eq!(result.asset_id.as_str(), "test");
        assert_eq!(result.key, "images/test.jpg");
        assert_eq!(result.content_type, "image/jpeg");
        assert_eq!(result.size_bytes, 1024);
    }
}
