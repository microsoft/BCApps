namespace System.IO;

codeunit 8622 "Config. Insert With Validation"
{

    trigger OnRun()
    begin
        InsertWithValidation();
    end;

    var
        RecRefToInsert: RecordRef;

    procedure SetInsertParameters(var RecRef: RecordRef)
    begin
        RecRefToInsert := RecRef;
    end;

    local procedure InsertWithValidation()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertWithValidation(RecRefToInsert, IsHandled);
        if not IsHandled then
            RecRefToInsert.Insert(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertWithValidation(var RecRefToInsert: RecordRef; var IsHandled: Boolean)
    begin
    end;
}

