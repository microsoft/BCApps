codeunit 101297 "Create Dispute Status"
{

    trigger OnRun()
    begin
        CreateDiputeStatus();
    end;

    local procedure CreateDiputeStatus()
    begin
        InsertData(InvoiceCodeLbl, InvocieDescriptionLbl);
        InsertData(PriceCodeLbl, PriceDescriptionLbl);
        InsertData(QualityCodeLbl, QualityDescriptionLbl);
    end;

    local procedure InsertData(Code: Code[10]; Description: Text)
    var
        DisputeStatus: Record "Dispute Status";
    begin
        DisputeStatus.Code := Code;
        DisputeStatus.Description := CopyStr(Description, 1, MaxStrLen(DisputeStatus.Description));
        DisputeStatus.Insert();
    end;

    var
        PriceCodeLbl: Label 'PRICE';
        PriceDescriptionLbl: Label 'Disputed invoices relating to the price';
        InvoiceCodeLbl: Label 'INVOICE';
        InvocieDescriptionLbl: Label 'Duplicate invoice dispute arguments';
        QualityCodeLbl: Label 'QUALITY';
        QualityDescriptionLbl: Label 'A disputed invoice due to quality';
}