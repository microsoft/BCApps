namespace System.IO;

using Microsoft.Finance.Dimension;
using System.Environment;
using System.Reflection;
using System.Security.AccessControl;

table 8613 "Config. Package Table"
{
    Caption = 'Config. Package Table';
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
            NotBlank = true;
            TableRelation = AllObj."Object ID" where("Object Type" = const(Table));

            trigger OnLookup()
            begin
                ConfigValidateMgt.LookupTable("Table ID");
                if "Table ID" <> 0 then
                    Validate("Table ID");
            end;

            trigger OnValidate()
            begin
                if ConfigMgt.IsSystemTable("Table ID") then
                    Error(SystemTableNotAllowedErr, "Table ID");

                if "Table ID" <> xRec."Table ID" then
                    "Page ID" := ConfigMgt.FindPage("Table ID");
            end;
        }
        field(3; "Table Name"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Name" where("Object Type" = const(Table),
                                                                        "Object ID" = field("Table ID")));
            Caption = 'Table Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "No. of Package Records"; Integer)
        {
            CalcFormula = count("Config. Package Record" where("Package Code" = field("Package Code"),
                                                                "Table ID" = field("Table ID")));
            Caption = 'No. of Package Records';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "No. of Package Errors"; Integer)
        {
            CalcFormula = count("Config. Package Error" where("Package Code" = field("Package Code"),
                                                               "Table ID" = field("Table ID")));
            Caption = 'No. of Package Errors';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Imported Date and Time"; DateTime)
        {
            Caption = 'Imported Date and Time';
            Editable = false;
        }
        field(8; "Exported Date and Time"; DateTime)
        {
            Caption = 'Exported Date and Time';
            Editable = false;
        }
        field(9; Comments; Text[250])
        {
            Caption = 'Comments';
        }
        field(10; "Created Date and Time"; DateTime)
        {
            Caption = 'Created Date and Time';
        }
        field(11; "Company Filter (Source Table)"; Text[30])
        {
            Caption = 'Company Filter (Source Table)';
            FieldClass = FlowFilter;
            TableRelation = Company;
        }
        field(12; "Table Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table),
                                                                           "Object ID" = field("Table ID")));
            Caption = 'Table Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; "Data Template"; Code[10])
        {
            Caption = 'Data Template';
            TableRelation = "Config. Template Header";
        }
        field(14; "Package Processing Order"; Integer)
        {
            Caption = 'Package Processing Order';
            Editable = false;
        }
        field(15; "Page ID"; Integer)
        {
            Caption = 'Page ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Page));

            trigger OnLookup()
            begin
                ConfigValidateMgt.LookupPage("Page ID");
                Validate("Page ID");
            end;
        }
        field(16; "Processing Order"; Integer)
        {
            Caption = 'Processing Order';
        }
        field(17; "No. of Fields Included"; Integer)
        {
            CalcFormula = count("Config. Package Field" where("Package Code" = field("Package Code"),
                                                               "Table ID" = field("Table ID"),
                                                               "Include Field" = const(true)));
            Caption = 'No. of Fields Included';
            Editable = false;
            FieldClass = FlowField;
        }
        field(18; "No. of Fields Available"; Integer)
        {
            CalcFormula = count("Config. Package Field" where("Package Code" = field("Package Code"),
                                                               "Table ID" = field("Table ID")));
            Caption = 'No. of Fields Available';
            Editable = false;
            FieldClass = FlowField;
        }
        field(19; "No. of Fields to Validate"; Integer)
        {
            CalcFormula = count("Config. Package Field" where("Package Code" = field("Package Code"),
                                                               "Table ID" = field("Table ID"),
                                                               "Validate Field" = const(true)));
            Caption = 'No. of Fields to Validate';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; "Package Caption"; Text[50])
        {
            CalcFormula = lookup("Config. Package"."Package Name" where(Code = field("Package Code")));
            Caption = 'Package Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(21; "Imported by User ID"; Code[50])
        {
            Caption = 'Imported by User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(22; "Created by User ID"; Code[50])
        {
            Caption = 'Created by User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(24; "Dimensions as Columns"; Boolean)
        {
            Caption = 'Dimensions as Columns';

            trigger OnValidate()
            begin
                if "Dimensions as Columns" then begin
                    InitDimensionFields();
                    UpdateDimensionsPackageData();
                end else
                    DeleteDimensionFields();
            end;
        }
        field(25; Filtered; Boolean)
        {
            CalcFormula = exist("Config. Package Filter" where("Package Code" = field("Package Code"),
                                                                "Table ID" = field("Table ID")));
            Caption = 'Filtered';
            Editable = false;
            FieldClass = FlowField;
        }
        field(26; "Skip Table Triggers"; Boolean)
        {
            Caption = 'Skip Table Triggers';
        }
        field(27; "Delete Recs Before Processing"; Boolean)
        {
            Caption = 'Delete Recs Before Processing';
        }
        field(28; "Processing Report ID"; Integer)
        {
            Caption = 'Processing Report ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
        }
        field(29; "Parent Table ID"; Integer)
        {
            Caption = 'Parent Table ID';
            TableRelation = "Config. Package Table"."Table ID" where("Package Code" = field("Package Code"));

            trigger OnValidate()
            var
                Levels: Integer;
            begin
                if "Table ID" = "Parent Table ID" then
                    Error(CannotBeItsOwnParentErr);

                Levels := CheckchildrenTables(Rec);
                Levels += CheckParentTables(Rec);

                // There should be no more than 2 level of parents, children or both for any table.
                if Levels > 2 then
                    Error(CannotAddParentErr);
            end;
        }
        field(30; Validated; Boolean)
        {
            Caption = 'Validated';
        }
        field(31; "Delayed Insert"; Boolean)
        {
            Caption = 'Delayed Insert';
        }
        field(32; "Cross-Column Filter"; Boolean)
        {
            Caption = 'Cross-Column Filter';
        }
    }

    keys
    {
        key(Key1; "Package Code", "Table ID")
        {
            Clustered = true;
        }
        key(Key2; "Package Processing Order", "Processing Order")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        DeletePackageDataForPackage("Package Code", "Table ID");
        DeleteRelatedTables("Package Code", "Table ID");
    end;

    trigger OnInsert()
    begin
        InitPackageFields();
    end;

    trigger OnRename()
    begin
        Error(CannotRenamePackageTableErr);
    end;

    var
        ConfigValidateMgt: Codeunit "Config. Validate Management";
        ConfigMgt: Codeunit "Config. Management";
        ConfigPackageMgt: Codeunit "Config. Package Management";
        i: Integer;

#pragma warning disable AA0470
        SystemTableNotAllowedErr: Label 'You cannot use system table %1 in the package.';
        DimensionsAsColumnsNotAllowedErr: Label 'You cannot use the Dimensions as Columns function for table %1.';
        MissingTablesAddQst: Label 'The Default Dimension and Dimension Value tables must be included in the package %1 to enable this option. The missing tables will be added to the package. Do you want to continue?';
#pragma warning restore AA0470
        CannotRenamePackageTableErr: Label 'You cannot rename the configuration package table.';
        DimensionsSetupCanceledMsg: Label 'The setup of Dimensions as Columns was canceled.';
#pragma warning disable AA0470
        DefineDrillDownPageMsg: Label 'Define the drill-down page in the %1 field.';
#pragma warning restore AA0470
        CannotAddParentErr: Label 'Cannot add a parent table. This table is already included in a three-level hierarchy, which is the maximum.';
        CannotBeItsOwnParentErr: Label 'Cannot add the parent table. A table cannot be its own parent or child.';
        CircularDependencyErr: Label 'Cannot add the parent table. The table is already the child of the selected tab.';
        ParentTableNotFoundErr: Label 'Cannot find table %1.', Comment = '%1 - Table number';

    protected var
        HideValidationDialog: Boolean;

    [Scope('OnPrem')]
    procedure DeleteRelatedTables(PackageCode: Code[20]; TableID: Integer)
    var
        ConfigLine: Record "Config. Line";
        ConfigPackageField: Record "Config. Package Field";
        ConfigFieldMap: Record "Config. Field Map";
        ConfigPackageFilter: Record "Config. Package Filter";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
    begin
        ConfigFieldMap.SetRange("Package Code", PackageCode);
        if TableID <> 0 then
            ConfigFieldMap.SetRange("Table ID", "Table ID");
        ConfigFieldMap.DeleteAll();

        ConfigPackageField.SetRange("Package Code", PackageCode);
        if TableID <> 0 then
            ConfigPackageField.SetRange("Table ID", "Table ID");
        ConfigPackageField.DeleteAll();

        ConfigPackageFilter.SetRange("Package Code", PackageCode);
        if TableID <> 0 then
            ConfigPackageFilter.SetRange("Table ID", "Table ID");
        ConfigPackageFilter.DeleteAll();

        ConfigTableProcessingRule.SetRange("Package Code", PackageCode);
        if TableID <> 0 then
            ConfigTableProcessingRule.SetRange("Table ID", "Table ID");
        ConfigTableProcessingRule.DeleteAll();

        ConfigLine.SetRange("Package Code", PackageCode);
        if TableID <> 0 then
            ConfigLine.SetRange("Table ID", "Table ID");
        ConfigLine.SetRange("Dimensions as Columns", true);
        ConfigLine.ModifyAll("Dimensions as Columns", false);
        ConfigLine.SetRange("Dimensions as Columns");
        OnDeleteRelatedTablesOnBeforeModifyAllConfigLineWithEmptyPackageCode(ConfigLine, PackageCode, TableID);
        ConfigLine.ModifyAll("Package Code", '');
    end;

    local procedure InitPackageFields(): Boolean
    var
        ConfigPackageField: Record "Config. Package Field";
        ConfigLine: Record "Config. Line";
        "Field": Record "Field";
        ConfigPackage: Record "Config. Package";
        ProcessingOrder: Integer;
        OldGlobalLanguageId: Integer;
        FieldsAdded: Boolean;
        ShouldAddField: Boolean;
    begin
        FieldsAdded := false;
        ConfigPackageMgt.SetFieldFilter(Field, "Table ID", 0);
        ConfigPackage.Get("Package Code");
        if ConfigPackage."Language ID" <> 0 then begin
            OldGlobalLanguageId := GlobalLanguage;
            GlobalLanguage(ConfigPackage."Language ID");
        end;
        if Field.FindSet() then
            repeat
                ShouldAddField := not ConfigPackageField.Get("Package Code", "Table ID", Field."No.") and
                   not ConfigPackageMgt.IsDimSetIDField("Table ID", Field."No.");
                OnInitPackageFieldsOnAfterCalcShouldAddField(Rec, Field, ShouldAddField);
                if ShouldAddField then begin
                    ConfigPackageMgt.InsertPackageField(
                      ConfigPackageField, "Package Code", "Table ID", Field."No.", Field.FieldName, Field."Field Caption",
                      true, true, false, false);
                    ConfigPackageField.SetRange("Package Code", "Package Code");
                    ConfigPackageField.SetRange("Table ID", "Table ID");
                    ConfigPackageField.SetRange("Field ID", Field."No.");
                    ConfigPackageMgt.SelectAllPackageFields(ConfigPackageField, true);
                    OnInitPackageFieldsOnAfterSelectAllPackageFields(ConfigPackageField);
                    FieldsAdded := true;
                end;
            until Field.Next() = 0;
        if ConfigPackage."Language ID" <> 0 then
            GlobalLanguage(OldGlobalLanguageId);
        if FieldsAdded then begin
            ProcessingOrder := 0;
            SetProcessingOrderPrimaryKey("Package Code", "Table ID", ProcessingOrder);
            ConfigPackageField.Reset();
            ConfigPackageField.SetRange("Package Code", "Package Code");
            ConfigPackageField.SetRange("Table ID", "Table ID");
            ConfigPackageField.SetRange("Primary Key", false);
            if "Table ID" <> Database::"Config. Line" then
                SetProcessingOrderFields(ConfigPackageField, ProcessingOrder)
            else begin
                ConfigPackageField.SetRange("Field ID", ConfigLine.FieldNo("Line Type"), ConfigLine.FieldNo("Table ID"));
                SetProcessingOrderFields(ConfigPackageField, ProcessingOrder);
                // package code must be processed just after table ID!
                ConfigPackageField.SetRange("Field ID", ConfigLine.FieldNo("Package Code"));
                SetProcessingOrderFields(ConfigPackageField, ProcessingOrder);
                ConfigPackageField.SetRange("Field ID", ConfigLine.FieldNo(Name), ConfigLine.FieldNo("Package Code") - 1);
                SetProcessingOrderFields(ConfigPackageField, ProcessingOrder);
                ConfigPackageField.SetFilter("Field ID", '%1..', ConfigLine.FieldNo("Package Code") + 1);
                SetProcessingOrderFields(ConfigPackageField, ProcessingOrder);
            end;
        end;

        exit(FieldsAdded);
    end;

    local procedure SetProcessingOrderPrimaryKey(PackageCode: Code[20]; TableID: Integer; var ProcessingOrder: Integer)
    var
        ConfigPackageField: Record "Config. Package Field";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        KeyFieldCount: Integer;
    begin
        RecRef.Open(TableID);
        KeyRef := RecRef.KeyIndex(1);
        for KeyFieldCount := 1 to KeyRef.FieldCount do begin
            FieldRef := KeyRef.FieldIndex(KeyFieldCount);
            ConfigPackageField.Get(PackageCode, TableID, FieldRef.Number);
            ProcessingOrder += 1;
            ConfigPackageField."Processing Order" := ProcessingOrder;
            ConfigPackageField.Modify();
        end;
    end;

    local procedure SetProcessingOrderFields(var ConfigPackageField: Record "Config. Package Field"; var ProcessingOrder: Integer)
    begin
        if ConfigPackageField.FindSet() then
            repeat
                ProcessingOrder += 1;
                ConfigPackageField."Processing Order" := ProcessingOrder;
                ConfigPackageField.Modify();
            until ConfigPackageField.Next() = 0;
    end;

    procedure InitDimensionFields()
    var
        Dimension: Record Dimension;
        ConfigPackageField: Record "Config. Package Field";
        ConfigPackageTable: Record "Config. Package Table";
        Confirmed: Boolean;
    begin
        if not (ConfigMgt.IsDimSetIDTable("Table ID") or ConfigMgt.IsDefaultDimTable("Table ID")) then
            Error(DimensionsAsColumnsNotAllowedErr, "Table ID");

        if ConfigMgt.IsDefaultDimTable("Table ID") then begin
            Confirmed :=
              (ConfigPackageTable.Get("Package Code", Database::"Dimension Value") and
               ConfigPackageTable.Get("Package Code", Database::"Default Dimension")) or
              (HideValidationDialog or not GuiAllowed);
            if not Confirmed then
                Confirmed := Confirm(MissingTablesAddQst, true, "Package Code");
            if Confirmed then begin
                ConfigPackageMgt.InsertPackageTable(ConfigPackageTable, "Package Code", Database::"Dimension Value");
                ConfigPackageMgt.InsertPackageTable(ConfigPackageTable, "Package Code", Database::"Default Dimension");
            end else
                Error(DimensionsSetupCanceledMsg);
        end;

        i := 0;
        if Dimension.FindSet() then
            repeat
                i := i + 1;
                ConfigPackageMgt.InsertPackageField(
                  ConfigPackageField, "Package Code", "Table ID", ConfigMgt.DimensionFieldID() + i,
                  Dimension.Code, Dimension."Code Caption", true, false, false, true);
            until Dimension.Next() = 0;
    end;

    procedure DeletePackageData()
    begin
        DeletePackageDataForPackage("Package Code", "Table ID");
    end;

    procedure DeletePackageDataForPackage(PackageCode: Code[20]; TableId: Integer)
    var
        ConfigPackageRecord: Record "Config. Package Record";
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageError: Record "Config. Package Error";
    begin
        ConfigPackageRecord.SetRange("Package Code", PackageCode);
        if TableId <> 0 then
            ConfigPackageRecord.SetRange("Table ID", TableId);
        ConfigPackageRecord.DeleteAll();

        ConfigPackageData.SetRange("Package Code", PackageCode);
        if TableId <> 0 then
            ConfigPackageData.SetRange("Table ID", TableId);
        ConfigPackageData.DeleteAll();

        ConfigPackageError.SetRange("Package Code", PackageCode);
        if TableId <> 0 then
            ConfigPackageError.SetRange("Table ID", TableId);
        ConfigPackageError.DeleteAll();
    end;

    local procedure DeleteDimensionFields()
    var
        ConfigPackageField: Record "Config. Package Field";
        ConfigPackageData: Record "Config. Package Data";
    begin
        ConfigPackageData.SetRange("Package Code", "Package Code");
        ConfigPackageData.SetRange("Table ID", "Table ID");
        ConfigPackageData.SetRange("Field ID", ConfigMgt.DimensionFieldID(), ConfigMgt.DimensionFieldID() + 999);
        ConfigPackageData.DeleteAll();

        ConfigPackageField.SetRange("Package Code", "Package Code");
        ConfigPackageField.SetRange("Table ID", "Table ID");
        ConfigPackageField.SetRange(Dimension, true);
        ConfigPackageField.DeleteAll();
    end;

    procedure DimensionFieldsCount(): Integer
    var
        ConfigPackageField: Record "Config. Package Field";
    begin
        ConfigPackageField.SetRange("Package Code", "Package Code");
        ConfigPackageField.SetRange("Table ID", "Table ID");
        ConfigPackageField.SetRange(Dimension, true);
        exit(ConfigPackageField.Count);
    end;

    procedure DimensionPackageDataExist(): Boolean
    var
        ConfigPackageData: Record "Config. Package Data";
    begin
        ConfigPackageData.SetRange("Package Code", "Package Code");
        ConfigPackageData.SetRange("Table ID", "Table ID");
        ConfigPackageData.SetRange("Field ID", ConfigMgt.DimensionFieldID(), ConfigMgt.DimensionFieldID() + 999);
        exit(not ConfigPackageData.IsEmpty);
    end;

    procedure ShowPackageRecords(Show: Option Records,Errors,All; ShowDim: Boolean)
    var
        ConfigPackageField: Record "Config. Package Field";
        ConfigPackageRecord: Record "Config. Package Record";
        ConfigPackageRecords: Page "Config. Package Records";
        MatrixColumnCaptions: array[1000] of Text[100];
        IsHandled: Boolean;
    begin
        ConfigPackageField.SetRange("Package Code", "Package Code");
        ConfigPackageField.SetRange("Table ID", "Table ID");
        ConfigPackageField.SetRange("Include Field", true);
        if not ShowDim then
            ConfigPackageField.SetRange(Dimension, false);
        FillMatrixColumnCaptions(MatrixColumnCaptions, ConfigPackageField);

        CalcFields("Table Caption");
        Clear(ConfigPackageRecords);
        ConfigPackageRecord.SetRange("Package Code", "Package Code");
        ConfigPackageRecord.SetRange("Table ID", "Table ID");
        case Show of
            Show::Records:
                ConfigPackageRecord.SetRange(Invalid, false);
            Show::Errors:
                ConfigPackageRecord.SetRange(Invalid, true);
        end;
        ConfigPackageRecords.SetTableView(ConfigPackageRecord);
        ConfigPackageRecords.LookupMode(true);
        ConfigPackageRecords.Load(MatrixColumnCaptions, "Table Caption", "Package Code", "Table ID", ShowDim);

        IsHandled := false;
        OnShowPackageRecordsOnBeforeShowRecords(ConfigPackageRecords, IsHandled);
        if not IsHandled then
            ConfigPackageRecords.RunModal();
    end;

    local procedure FillMatrixColumnCaptions(var MatrixColumnCaptions: array[1000] of Text[100]; var ConfigPackageField: Record "Config. Package Field")
    var
        IsHandled: Boolean;
    begin
        isHandled := false;
        OnBeforeFillMatrixColumnCaptions(MatrixColumnCaptions, ConfigPackageField, IsHandled);
        if IsHandled then
            exit;

        i := 1;
        Clear(MatrixColumnCaptions);
        if ConfigPackageField.FindSet() then
            repeat
                MatrixColumnCaptions[i] := ConfigPackageField."Field Name";
                i := i + 1;
            until ConfigPackageField.Next() = 0;
    end;

    procedure ShowDatabaseRecords()
    var
        ConfigLine: Record "Config. Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowDatabaseRecords(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Page ID" <> 0 then
            PAGE.Run("Page ID")
        else begin
            ConfigLine.SetRange("Package Code", "Package Code");
            ConfigLine.SetRange("Table ID", "Table ID");
            if ConfigLine.FindFirst() and (ConfigLine."Page ID" > 0) then
                PAGE.Run(ConfigLine."Page ID")
            else
                Error(DefineDrillDownPageMsg, FieldCaption("Page ID"));
        end;
    end;

    procedure ShowPackageFields()
    begin
        ShowFilteredPackageFields('');
    end;

    procedure ShowFilteredPackageFields(FilterValue: Text)
    begin
        if InitPackageFields() then
            Commit();

        if "Dimensions as Columns" then
            if not DimensionPackageDataExist() then
                if DimensionFieldsNotExist() then begin
                    if DimensionFieldsCount() > 0 then
                        DeleteDimensionFields();
                    InitDimensionFields();
                    Commit();
                end;

        SetFiltersAndRunConfigPackageFields(FilterValue);
    end;

    local procedure SetFiltersAndRunConfigPackageFields(FilterValue: Text)
    var
        ConfigPackageField: Record "Config. Package Field";
        ConfigPackageFields: Page "Config. Package Fields";
    begin
        OnBeforeSetFiltersAndRunConfigPackageFields(Rec);
        ConfigPackageField.FilterGroup(2);
        ConfigPackageField.SetRange("Package Code", "Package Code");
        ConfigPackageField.SetRange("Table ID", "Table ID");
        if FilterValue <> '' then
            ConfigPackageField.SetFilter("Field ID", FilterValue);
        ConfigPackageField.FilterGroup(0);
        ConfigPackageFields.SetTableView(ConfigPackageField);
        ConfigPackageFields.RunModal();
        Clear(ConfigPackageFields);
    end;

    procedure ShowPackageCard(PackageCode: Code[20])
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageCard: Page "Config. Package Card";
    begin
        ConfigPackage.FilterGroup(2);
        ConfigPackage.SetRange(Code, PackageCode);
        ConfigPackage.FilterGroup(0);
        ConfigPackageCard.SetTableView(ConfigPackage);
        ConfigPackageCard.RunModal();
        Clear(ConfigPackageCard);
    end;

    procedure SetFieldStyle(FieldNumber: Integer): Text
    begin
        case FieldNumber of
            FieldNo("No. of Package Records"):
                begin
                    CalcFields("No. of Package Records");
                    if "No. of Package Records" > 0 then
                        exit('Strong');
                end;
            FieldNo("No. of Package Errors"):
                begin
                    CalcFields("No. of Package Errors");
                    if "No. of Package Errors" > 0 then
                        exit('Unfavorable');
                end;
        end;

        exit('');
    end;

    procedure ShowFilters()
    var
        ConfigPackageFilter: Record "Config. Package Filter";
        ConfigPackageFilters: Page "Config. Package Filters";
    begin
        ConfigPackageFilter.FilterGroup(2);
        ConfigPackageFilter.SetRange("Package Code", "Package Code");
        ConfigPackageFilter.SetRange("Table ID", "Table ID");
        ConfigPackageFilter.SetRange("Processing Rule No.", 0);
        ConfigPackageFilter.FilterGroup(0);
        ConfigPackageFilters.SetTableView(ConfigPackageFilter);
        ConfigPackageFilters.RunModal();
        Clear(ConfigPackageFilters);
    end;

    procedure ShowProcessingRules()
    var
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        ConfigTableProcessingRules: Page "Config. Table Processing Rules";
    begin
        ConfigTableProcessingRule.FilterGroup(2);
        ConfigTableProcessingRule.SetRange("Package Code", "Package Code");
        ConfigTableProcessingRule.SetRange("Table ID", "Table ID");
        ConfigTableProcessingRule.FilterGroup(0);
        ConfigTableProcessingRules.SetTableView(ConfigTableProcessingRule);
        ConfigTableProcessingRules.RunModal();
        Clear(ConfigTableProcessingRules);
    end;

    local procedure UpdateDimensionsPackageData()
    var
        ConfigPackageField: Record "Config. Package Field";
        ConfigPackageRecord: Record "Config. Package Record";
        ConfigPackageData: Record "Config. Package Data";
    begin
        ConfigPackageRecord.SetRange("Package Code", "Package Code");
        ConfigPackageRecord.SetRange("Table ID", "Table ID");
        if ConfigPackageRecord.FindSet() then
            repeat
                ConfigPackageField.SetRange("Package Code", "Package Code");
                ConfigPackageField.SetRange("Table ID", "Table ID");
                ConfigPackageField.SetRange(Dimension, true);
                if ConfigPackageField.FindSet() then
                    repeat
                        ConfigPackageMgt.InsertPackageData(
                          ConfigPackageData, "Package Code", "Table ID", ConfigPackageRecord."No.",
                          ConfigPackageField."Field ID", '', ConfigPackageRecord.Invalid);
                    until ConfigPackageField.Next() = 0;
            until ConfigPackageRecord.Next() = 0;
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure GetNoOfDatabaseRecords(): Integer
    var
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        RecRef: RecordRef;
    begin
        if "Table ID" = 0 then
            exit(0);

        if not ConfigXMLExchange.TableObjectExists("Table ID") then
            exit(0);

        RecRef.Open("Table ID", false, "Company Filter (Source Table)");
        if not RecRef.ReadPermission() then
            exit(0);
        exit(RecRef.Count());
    end;

    procedure GetNoOfDatabaseRecordsText(): Text
    var
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        RecRef: RecordRef;
    begin
        if "Table ID" = 0 then
            exit;

        if not ConfigXMLExchange.TableObjectExists("Table ID") then
            exit;

        RecRef.Open("Table ID", false, "Company Filter (Source Table)");
        if not RecRef.ReadPermission() then
            exit;
        exit(Format(RecRef.Count()));
    end;

    local procedure CheckParentTables(ConfigPackageTable: Record "Config. Package Table"): Integer
    var
        ParentsFound: Integer;
    begin
        if ConfigPackageTable."Parent Table ID" <> 0 then
            repeat
                if not ConfigPackageTable.Get(ConfigPackageTable."Package Code", ConfigPackageTable."Parent Table ID") then
                    Error(ParentTableNotFoundErr, ConfigPackageTable."Parent Table ID");
                // Check there is no circular dependency
                if ConfigPackageTable."Parent Table ID" = "Table ID" then
                    Error(CircularDependencyErr);
                ParentsFound += 1;
                if ParentsFound > 2 then
                    exit(ParentsFound);
            until ConfigPackageTable."Parent Table ID" = 0;
        exit(ParentsFound);
    end;

    local procedure CheckchildrenTables(ConfigPackageTable: Record "Config. Package Table"): Integer
    var
        childrenFound: Integer;
        TempCounter: Integer;
    begin
        ConfigPackageTable.SetRange("Package Code", ConfigPackageTable."Package Code");
        ConfigPackageTable.SetRange("Parent Table ID", ConfigPackageTable."Table ID");
        childrenFound := 0;
        if ConfigPackageTable.FindSet() then begin
            repeat
                // Check there is no circular dependency
                if ConfigPackageTable."Table ID" = "Parent Table ID" then
                    Error(CircularDependencyErr);
                TempCounter := CheckchildrenTables(ConfigPackageTable);
                if childrenFound < TempCounter then
                    childrenFound := TempCounter;
                if childrenFound > 2 then
                    exit(childrenFound)
            until ConfigPackageTable.Next() = 0;
            childrenFound += 1;
        end;
        exit(childrenFound);
    end;

    local procedure DimensionFieldsNotExist(): Boolean
    var
        ConfigPackageField: Record "Config. Package Field";
    begin
        ConfigPackageField.SetRange("Package Code", "Package Code");
        ConfigPackageField.SetRange("Table ID", "Table ID");
        ConfigPackageField.SetRange("Processing Order", ConfigMgt.DimensionFieldID(), ConfigMgt.DimensionFieldID() + 999);
        exit(ConfigPackageField.IsEmpty);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFillMatrixColumnCaptions(var MatrixColumnCaptions: array[1000] of Text[100]; var ConfigPackageField: Record "Config. Package Field"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetFiltersAndRunConfigPackageFields(var ConfigPackageTable: Record "Config. Package Table")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDatabaseRecords(var ConfigPackageTable: Record "Config. Package Table"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteRelatedTablesOnBeforeModifyAllConfigLineWithEmptyPackageCode(var ConfigLine: Record "Config. Line"; PackageCode: Code[20]; TableID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitPackageFieldsOnAfterCalcShouldAddField(var ConfigPackageTable: Record "Config. Package Table"; "Field": Record "Field"; var ShouldAddField: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowPackageRecordsOnBeforeShowRecords(var ConfigPackageRecords: Page "Config. Package Records"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitPackageFieldsOnAfterSelectAllPackageFields(var ConfigPackageField: Record "Config. Package Field")
    begin
    end;
}

