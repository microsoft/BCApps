# Sending profile extensions

Extends the Document Sending Profile to support E-Document workflows. This is the user-facing configuration point where "post and send this invoice" becomes "export to PEPPOL and transmit via my connector."

## How it works

The table extension (`EDocumentSendingProfile.TableExt.al`) adds `Electronic Service Flow` -- a Code[20] that references a Workflow record filtered to category `EDOC`. When the `Electronic Document` enum is set to `Extended E-Document Service Flow` (added by `EDocSendProfileElecDoc.EnumExt.al`), the workflow code determines which E-Document services process the document.

The `E-Mail Attachment` enum is extended with two values: `E-Document` and `PDF & E-Document` (`EDocSendingProfAttType.EnumExt.al`). These let users attach the generated e-document XML alongside or instead of a PDF when sending by email. Selecting either of these values validates that the profile has an active e-document workflow configured.

## Things to know

- The sending profile's `OnAfterValidate` trigger on `E-Mail Attachment` enforces that if you pick `PDF & E-Document` or `E-Document`, the electronic document mode must be `Extended E-Document Service Flow` and the referenced workflow must be enabled. This prevents misconfiguration.
- `Electronic Service Flow` links to `Workflow.Code` where `Template = false` and `Category = 'EDOC'` -- only non-template e-document workflows are valid targets.
- The page extensions (`EDocSelectSendingOptions.PageExt.al`, `EDocumentSendingProfile.PageExt.al`) surface the workflow selection field on the sending profile card and the send options dialog.
