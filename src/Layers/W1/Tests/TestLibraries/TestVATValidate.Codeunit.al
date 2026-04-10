codeunit 132444 "Test VAT Validate"
{
    TableNo = "VAT Report Header";

    trigger OnRun()
    var
        ErrorMessage: Record "Error Message";
    begin
        ErrorMessage.SetContext(Rec);
        ErrorMessage.LogIfEmpty(Rec, FieldNo("Additional Information"), ErrorMessage."Message Type"::Error);
    end;
}