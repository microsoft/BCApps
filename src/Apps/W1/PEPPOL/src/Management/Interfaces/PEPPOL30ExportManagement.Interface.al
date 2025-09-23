interface "PEPPOL30 Export Management"
{
    procedure Init(RecRef: RecordRef; var TempSalesLineRounding: Record "Sales Line" temporary; var DocumentAttachments: Record "Document Attachment");
    procedure FindNextRec(Position: Integer; EDocumentFormat: Enum "E-Document Format"): Boolean
    procedure FindNextLineRec(Position: Integer; EDocumentFormat: Enum "E-Document Format"): Boolean
    procedure GetTotals(var TempVATAmtLine: Record "VAT Amount Line" temporary; var TempVATProductPostingGroup: Record "VAT Product Posting Group" temporary);
}