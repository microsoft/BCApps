namespace System.Security.User;

table 1306 "User Preference"
{
    Caption = 'User Preference';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Text[132])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(2; "Instruction Code"; Code[50])
        {
            Caption = 'Instruction Code';
        }
        field(3; "User Selection"; BLOB)
        {
            Caption = 'User Selection';
        }
    }

    keys
    {
        key(Key1; "User ID", "Instruction Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure DisableInstruction(InstrCode: Code[50])
    var
        UserPreference: Record "User Preference";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDisableInstruction(InstrCode, IsHandled);
        if IsHandled then
            exit;

        if not UserPreference.Get(UserId, InstrCode) then begin
            UserPreference.Init();
            UserPreference."User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
            UserPreference."Instruction Code" := InstrCode;
            UserPreference.Insert();
        end;
    end;

    procedure EnableInstruction(InstrCode: Code[50])
    var
        UserPreference: Record "User Preference";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeEnableInstruction(InstrCode, IsHandled);
        if IsHandled then
            exit;

        if UserPreference.Get(UserId, InstrCode) then
            UserPreference.Delete();
    end;

    procedure GetUserSelectionAsText() ReturnValue: Text
    var
        Instream: InStream;
    begin
        "User Selection".CreateInStream(Instream);
        Instream.ReadText(ReturnValue);
    end;

    procedure SetUserSelection(Variant: Variant)
    var
        OutStream: OutStream;
    begin
        "User Selection".CreateOutStream(OutStream);
        OutStream.WriteText(Format(Variant));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDisableInstruction(InstrCode: Code[50]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEnableInstruction(InstrCode: Code[50]; var IsHandled: Boolean)
    begin
    end;
}

