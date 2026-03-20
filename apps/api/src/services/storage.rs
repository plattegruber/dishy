//! R2 storage service for image uploads and retrieval.
//!
//! Provides functions to upload images to Cloudflare R2 and generate
//! public URLs for stored assets. Uses the `worker` crate's R2 bindings
//! to interact with the bucket directly, avoiding raw HTTP calls.
//!
//! ## Supported image formats
//!
//! - JPEG (`image/jpeg`)
//! - PNG (`image/png`)
//! - WebP (`image/webp`)
//!
//! ## Asset ID scheme
//!
//! Asset IDs follow the pattern: `{prefix}_{uuid}.{ext}` where:
//! - `prefix` is a category like `cover`, `source`, or `upload`
//! - `uuid` is a UUIDv4 for uniqueness
//! - `ext` is the file extension matching the content type

use crate::types::ids::AssetId;

/// Maximum allowed image upload size: 10 MB.
pub const MAX_IMAGE_SIZE: usize = 10 * 1024 * 1024;

/// Supported image content types and their corresponding file extensions.
const SUPPORTED_TYPES: &[(&str, &str)] = &[
    ("image/jpeg", "jpg"),
    ("image/png", "png"),
    ("image/webp", "webp"),
];

/// Errors that can occur during storage operations.
#[derive(Debug, thiserror::Error)]
pub enum StorageError {
    /// The uploaded file exceeds the maximum allowed size.
    #[error("file too large: {size} bytes exceeds maximum of {max} bytes")]
    FileTooLarge {
        /// Actual file size in bytes.
        size: usize,
        /// Maximum allowed size in bytes.
        max: usize,
    },

    /// The uploaded file has an unsupported content type.
    #[error("unsupported content type: {content_type}")]
    UnsupportedContentType {
        /// The content type that was rejected.
        content_type: String,
    },

    /// The image data is empty.
    #[error("empty image data")]
    EmptyData,

    /// An R2 operation failed.
    #[error("R2 operation failed: {message}")]
    R2Error {
        /// Description of the failure.
        message: String,
    },
}

/// Validates that an image meets upload requirements.
///
/// Checks:
/// - Data is not empty
/// - Data does not exceed [`MAX_IMAGE_SIZE`]
/// - Content type is in [`SUPPORTED_TYPES`]
///
/// # Errors
///
/// Returns `StorageError::EmptyData` if the data is empty.
/// Returns `StorageError::FileTooLarge` if the data exceeds the size limit.
/// Returns `StorageError::UnsupportedContentType` if the MIME type is not supported.
pub fn validate_image(data: &[u8], content_type: &str) -> Result<(), StorageError> {
    if data.is_empty() {
        return Err(StorageError::EmptyData);
    }

    if data.len() > MAX_IMAGE_SIZE {
        return Err(StorageError::FileTooLarge {
            size: data.len(),
            max: MAX_IMAGE_SIZE,
        });
    }

    if !is_supported_content_type(content_type) {
        return Err(StorageError::UnsupportedContentType {
            content_type: content_type.to_string(),
        });
    }

    Ok(())
}

/// Returns `true` if the content type is a supported image format.
pub fn is_supported_content_type(content_type: &str) -> bool {
    SUPPORTED_TYPES
        .iter()
        .any(|(mime, _)| *mime == content_type)
}

/// Returns the file extension for a supported content type.
///
/// Returns `None` if the content type is not supported.
pub fn extension_for_content_type(content_type: &str) -> Option<&'static str> {
    SUPPORTED_TYPES
        .iter()
        .find(|(mime, _)| *mime == content_type)
        .map(|(_, ext)| *ext)
}

/// Generates a unique asset ID with the given prefix and content type.
///
/// # Format
///
/// `{prefix}_{uuid}.{ext}` where `ext` is derived from the content type.
///
/// # Errors
///
/// Returns `StorageError::UnsupportedContentType` if the content type
/// is not in [`SUPPORTED_TYPES`].
pub fn generate_asset_id(prefix: &str, content_type: &str) -> Result<AssetId, StorageError> {
    let ext = extension_for_content_type(content_type).ok_or_else(|| {
        StorageError::UnsupportedContentType {
            content_type: content_type.to_string(),
        }
    })?;
    let uuid = uuid::Uuid::new_v4();
    Ok(AssetId::new(format!("{prefix}_{uuid}.{ext}")))
}

/// Constructs the public URL for an asset stored in R2.
///
/// The URL follows the pattern: `/images/{asset_id}` which is served
/// by the image serving endpoint.
pub fn public_url_for_asset(asset_id: &AssetId) -> String {
    format!("/images/{}", asset_id.as_str())
}

/// Uploads image data to R2 and returns the asset ID.
///
/// Validates the image, generates a unique asset ID, and stores the
/// data in the R2 bucket with the correct content type.
///
/// # Arguments
///
/// * `bucket` -- The R2 bucket binding from the Worker environment.
/// * `data` -- The raw image bytes.
/// * `content_type` -- The MIME type of the image.
/// * `prefix` -- Category prefix for the asset ID (e.g., "cover", "upload").
///
/// # Errors
///
/// Returns `StorageError` if validation fails or the R2 put operation fails.
#[cfg(target_arch = "wasm32")]
pub async fn upload_image(
    bucket: &worker::Bucket,
    data: &[u8],
    content_type: &str,
    prefix: &str,
) -> Result<AssetId, StorageError> {
    validate_image(data, content_type)?;

    let asset_id = generate_asset_id(prefix, content_type)?;

    let mut http_metadata = worker::r2::HttpMetadata::default();
    http_metadata.content_type = Some(content_type.to_string());

    bucket
        .put(asset_id.as_str(), worker::r2::Data::Bytes(data.to_vec()))
        .http_metadata(http_metadata)
        .execute()
        .await
        .map_err(|e| StorageError::R2Error {
            message: format!("put failed: {e}"),
        })?;

    Ok(asset_id)
}

/// Retrieves an image from R2 by asset ID.
///
/// Returns the raw bytes and content type if the asset exists.
///
/// # Arguments
///
/// * `bucket` -- The R2 bucket binding.
/// * `asset_id` -- The asset ID to retrieve.
///
/// # Errors
///
/// Returns `StorageError::R2Error` if the get operation fails or the
/// asset is not found.
#[cfg(target_arch = "wasm32")]
pub async fn get_image(
    bucket: &worker::Bucket,
    asset_id: &str,
) -> Result<(Vec<u8>, String), StorageError> {
    let object = bucket
        .get(asset_id)
        .execute()
        .await
        .map_err(|e| StorageError::R2Error {
            message: format!("get failed: {e}"),
        })?
        .ok_or_else(|| StorageError::R2Error {
            message: format!("asset not found: {asset_id}"),
        })?;

    let content_type = object
        .http_metadata()
        .content_type
        .unwrap_or_else(|| "application/octet-stream".to_string());

    let body = object.body().ok_or_else(|| StorageError::R2Error {
        message: "object has no body".to_string(),
    })?;

    let bytes = body.bytes().await.map_err(|e| StorageError::R2Error {
        message: format!("failed to read body: {e}"),
    })?;

    Ok((bytes, content_type))
}

/// Non-WASM stub for upload_image (used in `cargo test`).
#[cfg(not(target_arch = "wasm32"))]
pub async fn upload_image(
    _bucket: &(),
    data: &[u8],
    content_type: &str,
    prefix: &str,
) -> Result<AssetId, StorageError> {
    validate_image(data, content_type)?;
    generate_asset_id(prefix, content_type)
}

/// Non-WASM stub for get_image (used in `cargo test`).
#[cfg(not(target_arch = "wasm32"))]
pub async fn get_image(_bucket: &(), asset_id: &str) -> Result<(Vec<u8>, String), StorageError> {
    Err(StorageError::R2Error {
        message: format!("not available outside WASM runtime: {asset_id}"),
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn validate_image_rejects_empty_data() {
        let result = validate_image(&[], "image/jpeg");
        assert!(matches!(result, Err(StorageError::EmptyData)));
    }

    #[test]
    fn validate_image_rejects_oversized_data() {
        let data = vec![0u8; MAX_IMAGE_SIZE + 1];
        let result = validate_image(&data, "image/jpeg");
        assert!(matches!(result, Err(StorageError::FileTooLarge { .. })));
    }

    #[test]
    fn validate_image_rejects_unsupported_content_type() {
        let data = vec![0u8; 100];
        let result = validate_image(&data, "image/gif");
        assert!(matches!(
            result,
            Err(StorageError::UnsupportedContentType { .. })
        ));
    }

    #[test]
    fn validate_image_accepts_jpeg() {
        let data = vec![0u8; 100];
        assert!(validate_image(&data, "image/jpeg").is_ok());
    }

    #[test]
    fn validate_image_accepts_png() {
        let data = vec![0u8; 100];
        assert!(validate_image(&data, "image/png").is_ok());
    }

    #[test]
    fn validate_image_accepts_webp() {
        let data = vec![0u8; 100];
        assert!(validate_image(&data, "image/webp").is_ok());
    }

    #[test]
    fn validate_image_accepts_max_size_exactly() {
        let data = vec![0u8; MAX_IMAGE_SIZE];
        assert!(validate_image(&data, "image/jpeg").is_ok());
    }

    #[test]
    fn is_supported_content_type_returns_true_for_supported() {
        assert!(is_supported_content_type("image/jpeg"));
        assert!(is_supported_content_type("image/png"));
        assert!(is_supported_content_type("image/webp"));
    }

    #[test]
    fn is_supported_content_type_returns_false_for_unsupported() {
        assert!(!is_supported_content_type("image/gif"));
        assert!(!is_supported_content_type("application/pdf"));
        assert!(!is_supported_content_type("text/plain"));
    }

    #[test]
    fn extension_for_content_type_returns_correct_extensions() {
        assert_eq!(extension_for_content_type("image/jpeg"), Some("jpg"));
        assert_eq!(extension_for_content_type("image/png"), Some("png"));
        assert_eq!(extension_for_content_type("image/webp"), Some("webp"));
    }

    #[test]
    fn extension_for_content_type_returns_none_for_unsupported() {
        assert_eq!(extension_for_content_type("image/gif"), None);
        assert_eq!(extension_for_content_type("text/plain"), None);
    }

    #[test]
    fn generate_asset_id_has_correct_format() {
        let id = generate_asset_id("cover", "image/jpeg").expect("should succeed");
        let id_str = id.as_str();
        assert!(id_str.starts_with("cover_"), "should start with prefix");
        assert!(id_str.ends_with(".jpg"), "should end with .jpg extension");
        // UUID part: prefix_ (6) + uuid (36) + .jpg (4) = 46
        assert_eq!(id_str.len(), 46, "should have correct length");
    }

    #[test]
    fn generate_asset_id_produces_unique_ids() {
        let id1 = generate_asset_id("upload", "image/png").expect("should succeed");
        let id2 = generate_asset_id("upload", "image/png").expect("should succeed");
        assert_ne!(id1.as_str(), id2.as_str(), "should be unique");
    }

    #[test]
    fn generate_asset_id_rejects_unsupported_type() {
        let result = generate_asset_id("cover", "image/gif");
        assert!(matches!(
            result,
            Err(StorageError::UnsupportedContentType { .. })
        ));
    }

    #[test]
    fn public_url_for_asset_returns_correct_path() {
        let id = AssetId::new("cover_abc123.jpg");
        assert_eq!(public_url_for_asset(&id), "/images/cover_abc123.jpg");
    }

    #[tokio::test]
    async fn upload_image_stub_validates_and_returns_id() {
        let data = vec![0u8; 100];
        let result = upload_image(&(), &data, "image/jpeg", "test").await;
        assert!(result.is_ok());
        let id = result.expect("should succeed");
        assert!(id.as_str().starts_with("test_"));
        assert!(id.as_str().ends_with(".jpg"));
    }

    #[tokio::test]
    async fn upload_image_stub_rejects_invalid_data() {
        let result = upload_image(&(), &[], "image/jpeg", "test").await;
        assert!(matches!(result, Err(StorageError::EmptyData)));
    }

    #[test]
    fn storage_error_display_formats_correctly() {
        let err = StorageError::FileTooLarge {
            size: 20_000_000,
            max: 10_485_760,
        };
        assert_eq!(
            err.to_string(),
            "file too large: 20000000 bytes exceeds maximum of 10485760 bytes"
        );

        let err = StorageError::UnsupportedContentType {
            content_type: "image/gif".to_string(),
        };
        assert_eq!(err.to_string(), "unsupported content type: image/gif");

        let err = StorageError::EmptyData;
        assert_eq!(err.to_string(), "empty image data");

        let err = StorageError::R2Error {
            message: "put failed".to_string(),
        };
        assert_eq!(err.to_string(), "R2 operation failed: put failed");
    }
}
