namespace System.IO;

using System.Reflection;

table 1221 "Data Exch. Field"
{
    Caption = 'Data Exch. Field';
    Permissions = TableData "Data Exch. Field" = rimd;
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Data Exch. No."; Integer)
        {
            Caption = 'Data Exch. No.';
            NotBlank = true;
            TableRelation = "Data Exch.";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            NotBlank = true;
        }
        field(3; "Column No."; Integer)
        {
            Caption = 'Column No.';
            NotBlank = true;
        }
        field(4; Value; Text[250])
        {
            Caption = 'Value';
        }
        field(5; "Node ID"; Text[250])
        {
            Caption = 'Node ID';
        }
        field(6; "Data Exch. Line Def Code"; Code[20])
        {
            Caption = 'Data Exch. Line Def Code';
            TableRelation = "Data Exch. Line Def".Code;
        }
        field(10; "Parent Node ID"; Text[250])
        {
            Caption = 'Parent Node ID';
        }
        field(11; "Data Exch. Def Code"; Code[20])
        {
            CalcFormula = lookup("Data Exch."."Data Exch. Def Code" where("Entry No." = field("Data Exch. No.")));
            Caption = 'Data Exch. Def Code';
            FieldClass = FlowField;
        }
        field(16; "Value BLOB"; BLOB)
        {
            Caption = 'Value BLOB';
        }
    }

    keys
    {
        key(Key1; "Data Exch. No.", "Line No.", "Column No.", "Node ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure InsertRec(DataExchNo: Integer; LineNo: Integer; ColumnNo: Integer; NewValue: Text; DataExchLineDefCode: Code[20])
    begin
        Init();
        Validate("Data Exch. No.", DataExchNo);
        Validate("Line No.", LineNo);
        Validate("Column No.", ColumnNo);
        SetValueWithoutModifying(NewValue);
        Validate("Data Exch. Line Def Code", DataExchLineDefCode);
        Insert();
    end;

    procedure InsertRecXMLField(DataExchNo: Integer; LineNo: Integer; ColumnNo: Integer; NodeId: Text[250]; NodeValue: Text; DataExchLineDefCode: Code[20])
    begin
        InsertRecXMLFieldWithParentNodeID(DataExchNo, LineNo, ColumnNo, NodeId, '', NodeValue, DataExchLineDefCode)
    end;

    procedure InsertRecXMLFieldWithParentNodeID(DataExchNo: Integer; LineNo: Integer; ColumnNo: Integer; NodeId: Text[250]; ParentNodeId: Text[250]; NodeValue: Text; DataExchLineDefCode: Code[20])
    begin
        Init();
        Validate("Data Exch. No.", DataExchNo);
        Validate("Line No.", LineNo);
        Validate("Column No.", ColumnNo);
        Validate("Node ID", NodeId);
        SetValueWithoutModifying(NodeValue);
        Validate("Parent Node ID", ParentNodeId);
        Validate("Data Exch. Line Def Code", DataExchLineDefCode);
        OnInsertRecXMLFieldWithParentNodeIDOnBeforeInsert(Rec, NodeValue);
        Insert();
    end;

    procedure InsertRecXMLFieldDefinition(DataExchNo: Integer; LineNo: Integer; NodeId: Text[250]; ParentNodeId: Text[250]; NewValue: Text[250]; DataExchLineDefCode: Code[20])
    begin
        // this record represents the line definition and it has ColumnNo set to -1
        // even if we are not extracting anything from the line, we need to insert the definition
        // so that the child nodes can hook up to their parent.
        InsertRecXMLFieldWithParentNodeID(DataExchNo, LineNo, -1, NodeId, ParentNodeId, NewValue, DataExchLineDefCode)
    end;

    procedure GetFieldName(): Text
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExch: Record "Data Exch.";
    begin
        DataExch.Get("Data Exch. No.");
        if DataExchColumnDef.Get(DataExch."Data Exch. Def Code", DataExch."Data Exch. Line Def Code", "Column No.") then
            exit(DataExchColumnDef.Name);
        exit('');
    end;

    procedure DeleteRelatedRecords(DataExchNo: Integer; LineNo: Integer)
    begin
        SetRange("Data Exch. No.", DataExchNo);
        SetRange("Line No.", LineNo);
        if not IsEmpty() then
            DeleteAll(true);
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

    [IntegrationEvent(false, false)]
    local procedure OnInsertRecXMLFieldWithParentNodeIDOnBeforeInsert(var DataExchField: Record "Data Exch. Field"; var NodeValue: Text)
    begin
    end;
}

