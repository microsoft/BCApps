namespace System.Diagnostics;

using Microsoft.Finance.GeneralLedger.Ledger;
using System.Reflection;
using System.Security.AccessControl;

#pragma warning disable AS0039
table 405 "Change Log Entry"
{
    Caption = 'Change Log Entry';
    DrillDownPageID = "Change Log Entries";
    LookupPageID = "Change Log Entries";
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; BigInteger)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
        }
        field(2; "Date and Time"; DateTime)
        {
            Caption = 'Date and Time';
        }
        field(3; Time; Time)
        {
            Caption = 'Time';
        }
        field(4; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(5; "Table No."; Integer)
        {
            Caption = 'Table No.';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(6; "Table Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table),
                                                                           "Object ID" = field("Table No.")));
            Caption = 'Table Caption';
            FieldClass = FlowField;
        }
        field(7; "Field No."; Integer)
        {
            Caption = 'Field No.';
            TableRelation = Field."No." where(TableNo = field("Table No."));
        }
        field(8; "Field Caption"; Text[80])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Table No."),
                                                              "No." = field("Field No.")));
            Caption = 'Field Caption';
            FieldClass = FlowField;
            ToolTip = 'Specifies the field caption of the changed field.';
        }
        field(9; "Type of Change"; Enum "Change Log Entry Type")
        {
            Caption = 'Type of Change';
        }
        field(10; "Old Value"; Text[2048])
        {
            Caption = 'Old Value';
            ToolTip = 'Specifies the value that the field had before a user made changes to the field.';
        }
        field(11; "New Value"; Text[2048])
        {
            Caption = 'New Value';
            ToolTip = 'Specifies the value that the field had after a user made changes to the field.';
        }
        field(12; "Primary Key"; Text[250])
        {
            Caption = 'Primary Key';
        }
        field(13; "Primary Key Field 1 No."; Integer)
        {
            Caption = 'Primary Key Field 1 No.';
            TableRelation = Field."No." where(TableNo = field("Table No."));
        }
        field(14; "Primary Key Field 1 Caption"; Text[80])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Table No."),
                                                              "No." = field("Primary Key Field 1 No.")));
            Caption = 'Primary Key Field 1 Caption';
            FieldClass = FlowField;
        }
        field(15; "Primary Key Field 1 Value"; Text[50])
        {
            Caption = 'Primary Key Field 1 Value';
        }
        field(16; "Primary Key Field 2 No."; Integer)
        {
            Caption = 'Primary Key Field 2 No.';
            TableRelation = Field."No." where(TableNo = field("Table No."));
        }
        field(17; "Primary Key Field 2 Caption"; Text[80])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Table No."),
                                                              "No." = field("Primary Key Field 2 No.")));
            Caption = 'Primary Key Field 2 Caption';
            FieldClass = FlowField;
        }
        field(18; "Primary Key Field 2 Value"; Text[50])
        {
            Caption = 'Primary Key Field 2 Value';
        }
        field(19; "Primary Key Field 3 No."; Integer)
        {
            Caption = 'Primary Key Field 3 No.';
            TableRelation = Field."No." where(TableNo = field("Table No."));
        }
        field(20; "Primary Key Field 3 Caption"; Text[80])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Table No."),
                                                              "No." = field("Primary Key Field 3 No.")));
            Caption = 'Primary Key Field 3 Caption';
            FieldClass = FlowField;
        }
        field(21; "Primary Key Field 3 Value"; Text[50])
        {
            Caption = 'Primary Key Field 3 Value';
        }
        field(22; "Record ID"; RecordID)
        {
            Caption = 'Record ID';
            DataClassification = CustomerContent;
        }
        field(25; Protected; Boolean)
        {
            Caption = 'Protected';
            DataClassification = SystemMetadata;
        }
        field(26; "Changed Record SystemId"; Guid)
        {
            DataClassification = SystemMetadata;
        }
        field(27; "Notification Status"; Enum "Monitor Field Notification")
        {
            Caption = 'Notification status';
            DataClassification = SystemMetadata;
        }
        field(28; "Field Log Entry Feature"; Enum "Field Log Entry Feature")
        {
            DataClassification = SystemMetadata;
        }
        field(29; "Notification Message Id"; Guid)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Table No.", "Primary Key Field 1 Value", "Primary Key Field 2 Value")
        {
        }
        key(Key3; "Table No.", "Date and Time")
        {
        }
        key(Key4; "Notification Message Id")
        {
        }
        key(key5; "Field Log Entry Feature")
        {
        }
        key(key6; SystemCreatedAt, Protected, "Field Log Entry Feature")
        {
        }
        key(Key7; "Primary Key Field 2 Value", "Table No.", "Primary Key Field 1 Value")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        Protected := IsProtected();
    end;

    procedure GetFullPrimaryKeyFriendlyName(): Text
    var
        TableMetadata: Record "Table Metadata";
        RecRef: RecordRef;
        FriendlyName: Text;
        p: Integer;
    begin
        if "Primary Key" = '' then
            exit('');

        // Don't try and get obsoleted table PK name.
        if TableMetadata.Get("Table No.") then
            if TableMetadata.ObsoleteState = TableMetadata.ObsoleteState::Removed then
                exit('');

        // Retain existing formatting of old data
        if (StrPos("Primary Key", 'CONST(') = 0) and (StrPos("Primary Key", '0(') = 0) then
            exit("Primary Key");

        RecRef.Open("Table No.");
        RecRef.SetPosition("Primary Key");
        FriendlyName := RecRef.GetPosition(true);
        RecRef.Close();

        FriendlyName := DelChr(FriendlyName, '=', '()');
        p := StrPos(FriendlyName, 'CONST');
        while p > 0 do begin
            FriendlyName := DelStr(FriendlyName, p, 5);
            p := StrPos(FriendlyName, 'CONST');
        end;
        exit(FriendlyName);
    end;

    procedure GetLocalOldValue(): Text
    begin
        exit(GetLocalValue("Old Value"));
    end;

    procedure GetLocalNewValue(): Text
    begin
        exit(GetLocalValue("New Value"));
    end;

    local procedure GetLocalValue(Value: Text): Text
    var
        AllObj: Record AllObj;
        ChangeLogManagement: Codeunit "Change Log Management";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        EmptyRecordId: RecordId;
    begin
        if (Value = '') or ("Record ID" = EmptyRecordId) then
            exit(Value);

        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object ID", "Table No.");

        if not AllObj.IsEmpty() then begin
            RecordRef.Open("Table No.");
            if RecordRef.FieldExist("Field No.") then begin
                FieldRef := RecordRef.Field("Field No.");
                if ChangeLogManagement.EvaluateTextToFieldRef(Value, FieldRef) then
                    exit(Format(FieldRef.Value, 0, 1));
            end;
        end;

        exit(Value);
    end;

    local procedure IsProtected(): Boolean
    var
        ProtectedRecord: Boolean;
    begin
        ProtectedRecord := "Table No." = DATABASE::"G/L Entry";

        OnAfterIsProtected(Rec, ProtectedRecord);

        exit(ProtectedRecord);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsProtected(var ChangeLogEntry: Record "Change Log Entry"; var ProtectedRecord: Boolean)
    begin
    end;
}
#pragma warning restore AS0039
