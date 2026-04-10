namespace System.IO;

using System.Reflection;

table 8617 "Config. Package Error"
{
    Caption = 'Config. Package Error';
    DrillDownPageID = "Config. Package Errors";
    LookupPageID = "Config. Package Errors";
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Package Code"; Code[20])
        {
            Caption = 'Package Code';
            NotBlank = true;
            TableRelation = "Config. Package";
        }
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            Editable = false;
            NotBlank = true;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(3; "Record No."; Integer)
        {
            Caption = 'Record No.';
            Editable = false;
            NotBlank = true;
            TableRelation = "Config. Package Record"."No." where("Package Code" = field("Package Code"),
                                                                 "Table ID" = field("Table ID"));
        }
        field(4; "Field ID"; Integer)
        {
            Caption = 'Field ID';
            Editable = false;
            NotBlank = true;
        }
        field(5; "Field Name"; Text[30])
        {
            CalcFormula = lookup(Field.FieldName where(TableNo = field("Table ID"),
                                                        "No." = field("Field ID")));
            Caption = 'Field Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Error Text"; Text[250])
        {
            Caption = 'Error Text';
            Editable = false;
        }
        field(7; "Field Caption"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Table ID"),
                                                              "No." = field("Field ID")));
            Caption = 'Field Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Error Type"; Option)
        {
            Caption = 'Error Type';
            OptionCaption = ',TableRelation';
            OptionMembers = ,TableRelation;
        }
        field(9; "Record ID"; RecordID)
        {
            Caption = 'Record ID';
            DataClassification = CustomerContent;
        }
        field(10; "Table Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table),
                                                                           "Object ID" = field("Table ID")));
            Caption = 'Table Caption';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Package Code", "Table ID", "Record No.", "Field ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure ShowRecord()
    var
        ConfigPackageField: Record "Config. Package Field";
        ConfigPackageRecord: Record "Config. Package Record";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageRecords: Page "Config. Package Records";
        MatrixColumnCaptions: array[1000] of Text[100];
        i: Integer;
    begin
        ConfigPackageField.SetRange("Package Code", "Package Code");
        ConfigPackageField.SetRange("Table ID", "Table ID");
        ConfigPackageField.SetRange("Primary Key", true);
        i := 1;
        Clear(MatrixColumnCaptions);
        if ConfigPackageField.FindSet() then
            repeat
                MatrixColumnCaptions[i] := ConfigPackageField."Field Name";
                i := i + 1;
            until ConfigPackageField.Next() = 0;
        ConfigPackageField.Get("Package Code", "Table ID", "Field ID");
        MatrixColumnCaptions[i] := ConfigPackageField."Field Name";

        ConfigPackageTable.Get("Package Code", "Table ID");
        ConfigPackageTable.CalcFields("Table Caption");
        Clear(ConfigPackageRecords);
        ConfigPackageRecord.SetRange("Package Code", "Package Code");
        ConfigPackageRecord.SetRange("Table ID", "Table ID");
        ConfigPackageRecord.SetRange("No.", "Record No.");
        ConfigPackageRecords.SetTableView(ConfigPackageRecord);
        ConfigPackageRecords.LookupMode(true);
        ConfigPackageRecords.SetErrorFieldNo("Field ID");
        ConfigPackageRecords.Load(
          MatrixColumnCaptions, ConfigPackageTable."Table Caption", "Package Code", "Table ID", ConfigPackageField.Dimension);
        ConfigPackageRecords.RunModal();
    end;
}

