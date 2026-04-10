namespace System.IO;

using System.Reflection;

table 1214 "Intermediate Data Import"
{
    Caption = 'Intermediate Data Import';
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Integer)
        {
            AutoIncrement = true;
            Caption = 'ID';
        }
        field(2; "Data Exch. No."; Integer)
        {
            Caption = 'Data Exch. No.';
            NotBlank = true;
            TableRelation = "Data Exch.";
        }
        field(3; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            NotBlank = true;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(4; "Record No."; Integer)
        {
            Caption = 'Record No.';
        }
        field(5; "Field ID"; Integer)
        {
            Caption = 'Field ID';
            TableRelation = Field."No." where(TableNo = field("Table ID"));
        }
        field(6; Value; Text[250])
        {
            Caption = 'Value';
        }
        field(7; "Validate Only"; Boolean)
        {
            Caption = 'Validate Only';
        }
        field(8; "Parent Record No."; Integer)
        {
            Caption = 'Parent Record No.';
        }
        field(16; "Value BLOB"; BLOB)
        {
            Caption = 'Value BLOB';
        }
    }

    keys
    {
        key(Key1; ID)
        {
        }
        key(Key2; "Data Exch. No.", "Table ID", "Record No.", "Field ID")
        {
            Clustered = true;
        }
        key(Key3; "Data Exch. No.", "Table ID", "Field ID")
        {
        }
    }

    fieldgroups
    {
    }

    procedure InsertOrUpdateEntry(EntryNo: Integer; TableID: Integer; FieldID: Integer; ParentRecordNo: Integer; RecordNo: Integer; NewValue: Text[250])
    begin
        if FindEntry(EntryNo, TableID, FieldID, ParentRecordNo, RecordNo) then
            SetValue(NewValue)
        else begin
            Clear(Rec);
            "Data Exch. No." := EntryNo;
            "Table ID" := TableID;
            "Record No." := RecordNo;
            "Field ID" := FieldID;
            SetValueWithoutModifying(NewValue);
            "Parent Record No." := ParentRecordNo;
            "Validate Only" := false;
            Insert();
        end;
    end;

    procedure FindEntry(EntryNo: Integer; TableID: Integer; FieldID: Integer; ParentRecordNo: Integer; RecordNo: Integer): Boolean
    begin
        Reset();

        SetRange("Data Exch. No.", EntryNo);
        SetRange("Table ID", TableID);
        SetRange("Field ID", FieldID);
        SetRange("Parent Record No.", ParentRecordNo);
        SetRange("Record No.", RecordNo);

        exit(FindFirst());
    end;

    procedure GetEntryValue(EntryNo: Integer; TableID: Integer; FieldID: Integer; ParentRecordNo: Integer; RecordNo: Integer): Text[250]
    begin
        if FindEntry(EntryNo, TableID, FieldID, ParentRecordNo, RecordNo) then
            exit(GetValue());

        exit('');
    end;

    procedure GetValue(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        if not "Value BLOB".HasValue() then
            exit(Value);
        CalcFields("Value BLOB");
        "Value BLOB".CreateInStream(InStream, TEXTENCODING::Windows);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

    procedure SetValue(NewValue: Text)
    begin
        SetValueWithoutModifying(NewValue);
        Modify();
    end;

    procedure SetValueWithoutModifying(NewValue: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Value BLOB");
        Value := CopyStr(NewValue, 1, MaxStrLen(Value));
        if StrLen(NewValue) <= MaxStrLen(Value) then
            exit; // No need to store anything in the blob
        if NewValue = '' then
            exit;
        "Value BLOB".CreateOutStream(OutStream, TEXTENCODING::Windows);
        OutStream.WriteText(NewValue);
    end;
}

