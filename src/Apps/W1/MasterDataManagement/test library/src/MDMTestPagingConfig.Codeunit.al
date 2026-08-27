#pragma warning disable AA0247
codeunit 139934 "MDM Test Paging Config"
{
    // Test hook: forces a small cross-environment page size so paging/resume can be exercised with a few records.
    // SingleInstance so the flag the test sets is the one the static subscriber reads.
    SingleInstance = true;
    Access = Public;

    var
        Active: Boolean;
        PageSizeValue: Integer;
        InlineBytesActive: Boolean;
        InlineBytesValue: Integer;

    procedure Activate(NewPageSize: Integer)
    begin
        Active := true;
        PageSizeValue := NewPageSize;
    end;

    procedure ActivateInlineBytes(NewMaxBytes: Integer)
    begin
        InlineBytesActive := true;
        InlineBytesValue := NewMaxBytes;
    end;

    procedure Deactivate()
    begin
        Active := false;
        PageSizeValue := 0;
        InlineBytesActive := false;
        InlineBytesValue := 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MDM Cross-Env Data Source", 'OnGetCrossEnvPageSize', '', false, false)]
    local procedure HandleGetCrossEnvPageSize(var PageSize: Integer)
    begin
        if Active then
            PageSize := PageSizeValue;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MDM Cross-Env Source API", 'OnGetMaxPageInlineBytes', '', false, false)]
    local procedure HandleGetMaxPageInlineBytes(var MaxBytes: Integer)
    begin
        if InlineBytesActive then
            MaxBytes := InlineBytesValue;
    end;
}
