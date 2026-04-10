namespace System.IO;

using System;

table 1227 "Data Exch. Line Def"
{
    Caption = 'Data Exch. Line Def';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Data Exch. Def Code"; Code[20])
        {
            Caption = 'Data Exch. Def Code';
            NotBlank = true;
            TableRelation = "Data Exch. Def".Code;
        }
        field(2; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(3; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(4; "Column Count"; Integer)
        {
            Caption = 'Column Count';
        }
        field(5; "Data Line Tag"; Text[250])
        {
            Caption = 'Data Line Tag';
        }
        field(6; Namespace; Text[250])
        {
            Caption = 'Namespace';
        }
        field(10; "Parent Code"; Code[20])
        {
            Caption = 'Parent Code';
            TableRelation = "Data Exch. Line Def".Code where("Data Exch. Def Code" = field("Data Exch. Def Code"));

            trigger OnValidate()
            begin
                if "Parent Code" = '' then
                    exit;
                if "Parent Code" = Code then
                    Error(DontPointToTheSameLineErr, FieldCaption("Parent Code"), FieldCaption(Code));
            end;
        }
        field(11; "Line Type"; Option)
        {
            Caption = 'Line Type';
            OptionCaption = 'Detail,Header,Footer';
            OptionMembers = Detail,Header,Footer;
        }
    }

    keys
    {
        key(Key1; "Data Exch. Def Code", "Code")
        {
            Clustered = true;
        }
        key(Key2; "Data Exch. Def Code", "Parent Code")
        {
        }
        key(Key3; "Data Line Tag")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        DataExchMapping.SetRange("Data Exch. Def Code", "Data Exch. Def Code");
        DataExchMapping.SetRange("Data Exch. Line Def Code", Code);
        DataExchMapping.DeleteAll(true);

        DataExchColumnDef.SetRange("Data Exch. Def Code", "Data Exch. Def Code");
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", Code);
        DataExchColumnDef.DeleteAll(true);
    end;

    var
        IncorrectNamespaceErr: Label 'The imported file contains unsupported namespace "%1". The supported namespace is ''%2''.', Comment = '%1=file namespace,%2=supported namespace';
        DontPointToTheSameLineErr: Label '%1 cannot be the same as %2.', Comment = '%1 =Parent Code and %2 = Code';

    procedure InsertRec(DataExchDefCode: Code[20]; NewCode: Code[20]; NewName: Text[100]; ColumnCount: Integer)
    begin
        Validate("Data Exch. Def Code", DataExchDefCode);
        Validate(Code, NewCode);
        Validate(Name, NewName);
        Validate("Column Count", ColumnCount);
        Insert();
    end;

    [Scope('OnPrem')]
    procedure ValidateNamespace(XMLNode: DotNet XmlNode)
    var
        NamespaceURI: Text;
    begin
        if Namespace <> '' then begin
            NamespaceURI := XMLNode.NamespaceURI;
            if NamespaceURI <> Namespace then
                Error(IncorrectNamespaceErr, NamespaceURI, Namespace);
        end;
    end;

    procedure GetPath(TableId: Integer; FieldId: Integer): Text
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchDef: Record "Data Exch. Def";
    begin
        DataExchDef.Get("Data Exch. Def Code");
        DataExchFieldMapping.SetRange("Data Exch. Def Code", "Data Exch. Def Code");
        DataExchFieldMapping.SetRange("Data Exch. Line Def Code", Code);
        if DataExchDef.Type = DataExchDef.Type::"Generic Import" then begin
            DataExchFieldMapping.SetRange("Target Table ID", TableId);
            DataExchFieldMapping.SetRange("Target Field ID", FieldId);
        end else begin
            DataExchFieldMapping.SetRange("Table ID", TableId);
            DataExchFieldMapping.SetRange("Field ID", FieldId);
        end;
        if DataExchFieldMapping.FindFirst() then
            exit(DataExchFieldMapping.GetPath());
        exit('');
    end;
}

