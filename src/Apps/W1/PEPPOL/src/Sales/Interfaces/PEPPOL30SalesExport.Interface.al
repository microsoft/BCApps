interface "PEPPOL30 Sales Export"
{
    procedure GetTotals(DocumentNo: Code[20]; var TempVATAmtLine: Record "VAT Amount Line" temporary; var TempVATProductPostingGroup: Record "VAT Product Posting Group" temporary);
}