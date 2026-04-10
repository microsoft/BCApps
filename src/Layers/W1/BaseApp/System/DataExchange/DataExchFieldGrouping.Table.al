namespace System.IO;

using System.Reflection;

table 1238 "Data Exch. Field Grouping"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Data Exch. Def Code"; Code[20])
        {
            Caption = 'Data Exch. Def Code';
            NotBlank = true;
            TableRelation = "Data Exch. Def".Code;
        }
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            NotBlank = true;
            TableRelation = "Data Exch. Mapping"."Table ID";
        }
        field(3; "Data Exch. Line Def Code"; Code[20])
        {
            Caption = 'Data Exch. Line Def Code';
            NotBlank = true;
            TableRelation = "Data Exch. Line Def".Code where("Data Exch. Def Code" = field("Data Exch. Def Code"));
        }
        field(4; "Field ID"; Integer)
        {
            Caption = 'Field ID';
            NotBlank = true;
            TableRelation = Field."No." where(TableNo = field("Table ID"));
        }
    }

    keys
    {
        key(Key1; "Data Exch. Def Code", "Data Exch. Line Def Code", "Table ID", "Field ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure GetFieldCaption(): Text
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open("Table ID");
        FieldRef := RecRef.Field("Field ID");
        exit(FieldRef.Caption);
    end;

    procedure FillSourceRecord("Field": Record "Field")
    begin
        SetRange("Field ID");
        Init();

        "Table ID" := Field.TableNo;
        "Field ID" := Field."No.";
    end;
}

