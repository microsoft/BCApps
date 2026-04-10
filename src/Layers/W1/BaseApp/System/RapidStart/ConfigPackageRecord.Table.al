namespace System.IO;

using System.Reflection;

table 8614 "Config. Package Record"
{
    Caption = 'Config. Package Record';
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
            Editable = true;
            NotBlank = true;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(3; "No."; Integer)
        {
            Caption = 'No.';
        }
        field(4; Invalid; Boolean)
        {
            Caption = 'Invalid';
        }
        field(10; "Parent Record No."; Integer)
        {
            Caption = 'Parent Record No.';
        }
    }

    keys
    {
        key(Key1; "Package Code", "Table ID", "No.")
        {
            Clustered = true;
        }
        key(Key2; "Package Code", "Table ID", Invalid)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageManagement: Codeunit "Config. Package Management";
    begin
        ConfigPackageData.SetRange("Package Code", "Package Code");
        ConfigPackageData.SetRange("Table ID", "Table ID");
        ConfigPackageData.SetRange("No.", "No.");
        ConfigPackageData.DeleteAll();

        ConfigPackageManagement.CleanRecordError(Rec);
    end;

    procedure FitsProcessingFilter(RuleNo: Integer): Boolean
    var
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageFilter: Record "Config. Package Filter";
        ConfigValidateMgt: Codeunit "Config. Validate Management";
        RecRefTemp: RecordRef;
        FieldRef: FieldRef;
    begin
        ConfigPackageData.Reset();
        ConfigPackageData.SetRange("Package Code", "Package Code");
        ConfigPackageData.SetRange("Table ID", "Table ID");
        ConfigPackageData.SetRange("No.", "No.");
        if FindProcessingRuleFilters(ConfigPackageFilter, RuleNo) then begin
            RecRefTemp.Open("Table ID", true);
            repeat
                ConfigPackageData.SetRange("Field ID", ConfigPackageFilter."Field ID");
                if ConfigPackageData.FindFirst() then begin
                    FieldRef := RecRefTemp.Field(ConfigPackageData."Field ID");
                    ConfigValidateMgt.EvaluateTextToFieldRef(ConfigPackageData.Value, FieldRef, false);
                    FieldRef.SetFilter(ConfigPackageFilter."Field Filter");
                end else
                    exit(false);
            until ConfigPackageFilter.Next() = 0;
            RecRefTemp.Insert();
            if RecRefTemp.IsEmpty() then
                exit(false);
        end;
        exit(true);
    end;

    local procedure FindProcessingRuleFilters(var ConfigPackageFilter: Record "Config. Package Filter"; RuleNo: Integer): Boolean
    begin
        ConfigPackageFilter.Reset();
        ConfigPackageFilter.SetRange("Package Code", "Package Code");
        ConfigPackageFilter.SetRange("Table ID", "Table ID");
        ConfigPackageFilter.SetRange("Processing Rule No.", RuleNo);
        exit(ConfigPackageFilter.FindSet());
    end;
}

