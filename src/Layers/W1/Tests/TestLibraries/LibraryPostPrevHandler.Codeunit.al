codeunit 131011 "Library - Post. Prev. Handler"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "G/L Entry" = i,
                  TableData "Cust. Ledger Entry" = i,
                  TableData "Vendor Ledger Entry" = i,
                  TableData "Item Ledger Entry" = i,
                  TableData "Job Ledger Entry" = i,
                  TableData "VAT Entry" = i,
                  TableData "Bank Account Ledger Entry" = i,
                  TableData "Detailed Cust. Ledg. Entry" = i,
                  TableData "Detailed Vendor Ledg. Entry" = i,
                  TableData "Employee Ledger Entry" = i,
                  TableData "Detailed Employee Ledger Entry" = i,
                  TableData "Value Entry" = i;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        ValueFieldNo: Integer;
        InvokeCommit: Boolean;

    procedure SetValueFieldNo(FieldNo: Integer)
    begin
        ValueFieldNo := FieldNo;
    end;

    procedure SetInvokeCommit(NewInvokeCommit: Boolean)
    begin
        InvokeCommit := NewInvokeCommit;
    end;

    local procedure InsertRecord(RecVar: Variant)
    var
        RecRef: RecordRef;
        RecRefInsert: RecordRef;
        FieldRefKey: FieldRef;
        FieldRefValue: FieldRef;
        Value: Variant;
    begin
        RecRef.GetTable(RecVar);
        FieldRefValue := RecRef.Field(ValueFieldNo);
        Value := FieldRefValue.Value();

        RecRefInsert.Open(RecRef.Number);
        RecRefInsert.Init();
        FieldRefKey := RecRefInsert.FieldIndex(1);
        FieldRefKey.Value(LibraryUtility.GetNewRecNo(RecVar, FieldRefKey.Number));

        FieldRefValue := RecRefInsert.Field(ValueFieldNo);
        FieldRefValue.Value(Value);

        RecRefInsert.Insert();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        InsertRecord(RecVar);
        Assert.IsTrue(GenJnlPostPreview.IsActive(), 'GenJnlPostPreview.IsActive');
        if InvokeCommit then
            asserterror Commit()
        else
            asserterror GenJnlPostPreview.ThrowError();
        Result := false;
    end;
}

