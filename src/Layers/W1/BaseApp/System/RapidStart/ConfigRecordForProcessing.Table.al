namespace System.IO;

table 8632 "Config. Record For Processing"
{
    Caption = 'Config. Record For Processing';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Package Code"; Code[20])
        {
            Caption = 'Package Code';
            TableRelation = "Config. Package";
        }
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
        field(3; "Rule No."; Integer)
        {
            Caption = 'Rule No.';
        }
        field(4; "Record No."; Integer)
        {
            Caption = 'Record No.';
        }
    }

    keys
    {
        key(Key1; "Package Code", "Table ID", "Rule No.", "Record No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure AddRecord(ConfigPackageRecord: Record "Config. Package Record"; ProcessingRuleNo: Integer)
    begin
        Init();
        "Package Code" := ConfigPackageRecord."Package Code";
        "Table ID" := ConfigPackageRecord."Table ID";
        "Rule No." := ProcessingRuleNo;
        "Record No." := ConfigPackageRecord."No.";
        Insert();
    end;

    procedure FindConfigRecord(var ConfigPackageRecord: Record "Config. Package Record"): Boolean
    begin
        exit(ConfigPackageRecord.Get("Package Code", "Table ID", "Record No."));
    end;

    procedure FindConfigRule(var ConfigTableProcessingRule: Record "Config. Table Processing Rule"): Boolean
    begin
        Clear(ConfigTableProcessingRule);
        exit(ConfigTableProcessingRule.Get("Package Code", "Table ID", "Rule No."));
    end;

    procedure FindInsertedRecord(var RecRef: RecordRef): Boolean
    var
        ConfigPackageField: Record "Config. Package Field";
        FieldRef: FieldRef;
        FieldValue: Text;
    begin
        RecRef.Open("Table ID");
        if FindPrimaryKeyFields(ConfigPackageField) then
            repeat
                FieldRef := RecRef.Field(ConfigPackageField."Field ID");
                FieldValue := GetFieldValue(ConfigPackageField."Field ID");
                if FieldValue <> '' then
                    FieldRef.SetFilter(FieldValue)
                else
                    FieldRef.SetFilter('%1', '');
            until ConfigPackageField.Next() = 0;
        if RecRef.HasFilter then
            exit(RecRef.FindFirst());
        exit(false);
    end;

    local procedure FindPrimaryKeyFields(var ConfigPackageField: Record "Config. Package Field"): Boolean
    begin
        ConfigPackageField.SetRange("Package Code", "Package Code");
        ConfigPackageField.SetRange("Table ID", "Table ID");
        ConfigPackageField.SetRange("Primary Key", true);
        exit(ConfigPackageField.FindSet());
    end;

    local procedure GetFieldValue(FieldId: Integer): Text[2048]
    var
        ConfigPackageData: Record "Config. Package Data";
    begin
        ConfigPackageData.Get("Package Code", "Table ID", "Record No.", FieldId);
        exit(ConfigPackageData.Value);
    end;
}

