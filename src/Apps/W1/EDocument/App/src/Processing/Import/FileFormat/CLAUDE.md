# File format handlers

File format handlers implement IEDocFileFormat interface to identify blob types and define structure preferences. This subsystem provides concrete implementations for XML, JSON, and PDF formats, bridging the gap between raw file bytes and structured data processing.

## How it works

Each file format handler is a codeunit implementing IEDocFileFormat interface. The handler provides three key methods: FileExtension returns the file extension string ("xml", "json", "pdf"), PreviewContent displays file contents in-client (for XML/JSON opens in text viewer, for PDF opens in document viewer), and PreferredStructureDataImplementation indicates how to process the format into structured data.

When an e-document arrives as a blob (email attachment, API payload), the system determines the file format from the file extension or content-type header. It instantiates the corresponding IEDocFileFormat implementation and calls PreferredStructureDataImplementation to get the structure method. For XML and JSON, this returns "Already Structured" (no parsing needed, use as-is). For PDF, this returns "MLLM" (requires AI extraction to convert image/text to structured JSON).

The Structure step uses this preference to route processing: XML/JSON formats skip MLLM and proceed directly to ADI path-based extraction, while PDF formats invoke EDocumentMLLMHandler for AI-powered extraction. This routing enables format-specific optimization while maintaining a unified processing pipeline.

## Things to know

- **Format detection priority** -- System checks file extension first, then inspects content bytes (magic number detection) if extension is ambiguous. This handles cases where files have wrong extensions or no extension.
- **Preview limitations** -- XML and JSON formats display raw text in browser, limited to 1MB content size. PDF formats open in browser's native PDF viewer. Binary formats (images, archives) show error message "Content can't be previewed".
- **Structure preference is advisory** -- PreferredStructureDataImplementation returns a suggestion, but services can override via "Structure Data Impl." field on E-Document record. This enables testing alternate structure methods.
- **ADI fallback for all** -- Even formats preferring MLLM can fall back to ADI if AI fails. This requires formats to be structurally parseable (PDF must contain extractable text, not just images).
- **Extension registration** -- New file formats are added by implementing IEDocFileFormat and registering via E-Doc. File Format enum extension. No core code changes required.
- **Content-type mapping** -- HTTP Content-Type headers map to file formats: "application/xml" → XML, "application/json" → JSON, "application/pdf" → PDF. Used when files arrive via API without explicit extension.
- **Preview security** -- Preview functionality sanitizes XML/JSON content to prevent script injection. Large files are truncated to prevent browser memory issues.
