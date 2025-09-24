codeunit 37213 "Sales Export PEPPOL30 Mgmt." implements "PEPPOL30 Export Management"
{
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];

    procedure Init(NewRecordRef: RecordRef; var TempSalesLineRounding: Record "Sales Line" temporary; var DocumentAttachments: Record "Document Attachment")
    var
        PEPPOLMonetaryInfoProvider: Interface "PEPPOL Monetary Info Provider";
        SpecifyASalesCreditMemoNoErr: Label 'You must specify a sales credit memo number.';
    begin
        NewRecordRef.SetTable(SalesCrMemoHeader);
        if SalesCrMemoHeader."No." = '' then
            Error(SpecifyASalesCreditMemoNoErr);

        DocumentNo := SalesCrMemoHeader."No.";
        SalesCrMemoHeader.SetRecFilter();
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.SetFilter(Type, '<>%1', SalesCrMemoLine.Type::" ");

        if SalesCrMemoLine.FindSet() then
            repeat
                SalesLine.TransferFields(SalesCrMemoLine);
                PEPPOLMonetaryInfoProvider := "E-Document Format"::"PEPPOL 3.0";
                PEPPOLMonetaryInfoProvider.GetInvoiceRoundingLine(TempSalesLineRounding, SalesLine);
            until SalesCrMemoLine.Next() = 0;
        if TempSalesLineRounding."Line No." <> 0 then
            SalesCrMemoLine.SetFilter("Line No.", '<>%1', TempSalesLineRounding."Line No.");
        DocumentAttachments.SetRange("Table ID", Database::"Sales Cr.Memo Header");
        DocumentAttachments.SetRange("No.", SalesCrMemoHeader."No.");
    end;

    procedure FindNextRec(Position: Integer; EDocumentFormat: Enum "E-Document Format") Found: Boolean
    var
        PEPPOLPostedDocumentIterator: Interface "PEPPOL Posted Document Iterator";
    begin
        PEPPOLPostedDocumentIterator := EDocumentFormat;
        exit(PEPPOLPostedDocumentIterator.FindNextSalesCreditMemoRec(SalesCrMemoHeader, SalesHeader, Position));
    end;

    procedure FindNextLineRec(Position: Integer; EDocumentFormat: Enum "E-Document Format"): Boolean
    var
        PEPPOLPostedDocumentIterator: Interface "PEPPOL Posted Document Iterator";
    begin
        PEPPOLPostedDocumentIterator := EDocumentFormat;
        exit(PEPPOLPostedDocumentIterator.FindNextSalesCreditMemoLineRec(SalesCrMemoLine, SalesLine, Position));
    end;

    procedure GetTotals(var TempVATAmtLine: Record "VAT Amount Line" temporary; var TempVATProductPostingGroup: Record "VAT Product Posting Group" temporary);
    var
       PEPPOLTaxInfoProvider: Interface "PEPPOL Tax Info Provider";
    begin
        SalesCrMemoLine.SetRange("Document No.", DocumentNo);
        if SalesCrMemoLine.FindSet() then
            repeat
                SalesLine.TransferFields(SalesCrMemoLine);
                PEPPOLTaxInfoProvider := "E-Document Format"::"PEPPOL 3.0";
                PEPPOLTaxInfoProvider.GetTotals(SalesLine, TempVATAmtLine);
                PEPPOLTaxInfoProvider.GetTaxCategories(SalesLine, TempVATProductPostingGroup);
            until SalesCrMemoLine.Next() = 0;
    end;

}