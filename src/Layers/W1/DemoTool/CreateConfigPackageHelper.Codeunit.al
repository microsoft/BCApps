codeunit 101935 "Create Config. Package Helper"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        DemoDataSetup: Record "Demo Data Setup";
        ConfigPackageMgt: Codeunit "Config. Package Management";

    procedure GetCompanyType(): Integer
    begin
        exit(DemoDataSetup."Company Type")
    end;

    procedure GetDataType(): Integer
    begin
        exit(DemoDataSetup."Data Type")
    end;

    procedure GetPackageCode(): Code[20]
    begin
        exit(ConfigPackage.Code)
    end;

    procedure CreatePackage(ExcludeConfigTables: Boolean)
    var
        DemotoolSystemConstants: Codeunit "Demotool System Constants";
    begin
        DemoDataSetup.Get();
        if not ConfigPackage.IsEmpty() then
            ConfigPackage.DeleteAll(true);
        ConfigPackage.Init();
        ConfigPackage.Code := DemoDataSetup.GetRSPackageCode();
        ConfigPackage."Package Name" := CopyStr(PRODUCTNAME.Marketing(), 1, MaxStrLen(ConfigPackage."Package Name"));
        ConfigPackage."Language ID" := DemoDataSetup."Data Language ID";
        ConfigPackage."Product Version" := DemotoolSystemConstants.ProductVersion();
        ConfigPackage."Exclude Config. Tables" := ExcludeConfigTables;
        ConfigPackage.Insert(true);
    end;

    procedure CreateProcessingRule(RuleNo: Integer; "Action": Option)
    var
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
    begin
        ConfigTableProcessingRule.Init();
        ConfigPackageMgt.InsertProcessingRule(ConfigTableProcessingRule, ConfigPackageTable, RuleNo, Action);
    end;

    procedure CreateProcessingRuleCustom(RuleNo: Integer; CodeunitID: Integer)
    var
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
    begin
        ConfigTableProcessingRule.Init();
        ConfigPackageMgt.InsertProcessingRuleCustom(ConfigTableProcessingRule, ConfigPackageTable, RuleNo, CodeunitID);
    end;

    procedure CreateProcessingFilter(RuleNo: Integer; FieldID: Integer; FieldFilter: Text[250])
    var
        ConfigPackageFilter: Record "Config. Package Filter";
    begin
        ConfigPackageMgt.InsertPackageFilter(
          ConfigPackageFilter, ConfigPackageTable."Package Code", ConfigPackageTable."Table ID",
          RuleNo, FieldID, FieldFilter);
    end;

    procedure CreateTable(TableID: Integer)
    begin
        ConfigPackageMgt.InsertPackageTable(ConfigPackageTable, ConfigPackage.Code, TableID);
    end;

    procedure CreateTableChild(TableID: Integer; ParentTableID: Integer)
    begin
        ConfigPackageMgt.InsertPackageTable(ConfigPackageTable, ConfigPackage.Code, TableID);
        ConfigPackageTable."Parent Table ID" := ParentTableID;
        ConfigPackageTable.Modify();
    end;

    procedure CreateTableFilter(FieldID: Integer; FieldFilter: Text[250])
    var
        ConfigPackageFilter: Record "Config. Package Filter";
    begin
        ConfigPackageMgt.InsertPackageFilter(
          ConfigPackageFilter, ConfigPackageTable."Package Code", ConfigPackageTable."Table ID", 0, FieldID, FieldFilter);
    end;

    procedure DeleteTable(TableID: Integer)
    begin
        if ConfigPackageTable.Get(TableID) then
            ConfigPackageTable.DeleteAll(true);
    end;

    procedure DeleteRecsBeforeProcessing()
    begin
        ConfigPackageTable."Delete Recs Before Processing" := true;
        ConfigPackageTable.Modify();
    end;

    procedure SetParentTableID(TableID: Integer; ParentTableID: Integer)
    begin
        ConfigPackageTable.Get(GetPackageCode(), TableID);
        ConfigPackageTable."Parent Table ID" := ParentTableID;
        ConfigPackageTable.Modify();
    end;

    procedure SetSkipTableTriggers()
    begin
        ConfigPackageMgt.SetSkipTableTriggers(ConfigPackageTable, ConfigPackage.Code, ConfigPackageTable."Table ID", true);
    end;

    procedure TurnOffFieldValidation()
    var
        ConfigPackageField: Record "Config. Package Field";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageTable.ModifyAll("Skip Table Triggers", true);
        ConfigPackageField.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageField.SetRange("Validate Field", true);
        ConfigPackageField.ModifyAll("Validate Field", false);
    end;

    procedure IncludeField(FieldID: Integer; SetInclude: Boolean)
    var
        ConfigPackageField: Record "Config. Package Field";
    begin
        ConfigPackageField.SetRange("Package Code", ConfigPackageTable."Package Code");
        ConfigPackageField.SetRange("Table ID", ConfigPackageTable."Table ID");
        ConfigPackageField.SetRange("Field ID", FieldID);
        ConfigPackageMgt.SelectAllPackageFields(ConfigPackageField, SetInclude);
    end;

    procedure ExcludeAllFields()
    var
        ConfigPackageField: Record "Config. Package Field";
    begin
        ConfigPackageField.SetRange("Package Code", ConfigPackageTable."Package Code");
        ConfigPackageField.SetRange("Table ID", ConfigPackageTable."Table ID");
        ConfigPackageMgt.SelectAllPackageFields(ConfigPackageField, false);
    end;

    procedure MarkFieldAsPrimaryKey(FieldID: Integer)
    var
        ConfigPackageField: Record "Config. Package Field";
    begin
        if ConfigPackageField.Get(ConfigPackageTable."Package Code", ConfigPackageTable."Table ID", FieldID) then begin
            ConfigPackageField."Primary Key" := true;
            ConfigPackageField.Modify();
        end;
    end;

    procedure ValidateField(FieldID: Integer; SetValidate: Boolean)
    var
        ConfigPackageField: Record "Config. Package Field";
    begin
        ConfigPackageField.Get(ConfigPackageTable."Package Code", ConfigPackageTable."Table ID", FieldID);
        ConfigPackageField.Validate("Validate Field", SetValidate);
        ConfigPackageField.Modify();
    end;
}

