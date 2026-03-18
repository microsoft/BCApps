namespace System.IO;

using System.Environment;
using System.Reflection;
using System.Security.AccessControl;
using System.Security.User;

table 8622 "Config. Line"
{
    Caption = 'Config. Line';
    DataCaptionFields = Name;
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(2; "Line Type"; Option)
        {
            Caption = 'Line Type';
            OptionCaption = 'Area,Group,Table';
            OptionMembers = "Area",Group,"Table";

            trigger OnValidate()
            begin
                if "Line Type" <> "Line Type"::Table then
                    TestField("Table ID", 0);
            end;
        }
        field(3; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            TableRelation = if ("Line Type" = const(Table)) AllObjWithCaption."Object ID" where("Object Type" = const(Table),
                                                                                               "Object ID" = filter(.. 1260 | 1262 .. 99999999 | 2000000004 | 2000000005));

            trigger OnLookup()
            var
                ConfigValidateMgt: Codeunit "Config. Validate Management";
            begin
                TestField("Line Type", "Line Type"::Table);
                ConfigValidateMgt.LookupTable("Table ID");
                Validate("Table ID");
            end;

            trigger OnValidate()
            var
                RecRef: RecordRef;
            begin
                if CurrFieldNo > 0 then
                    TestField("Line Type", "Line Type"::Table);

                if ("Table ID" <> xRec."Table ID") and (xRec."Table ID" > 0) then
                    TestField("Dimensions as Columns", false);

                if ("Table ID" <> xRec."Table ID") and ("Package Code" <> '') then
                    if Confirm(RemovePackageLinkQst, false) then
                        "Package Code" := ''
                    else begin
                        "Table ID" := xRec."Table ID";
                        exit;
                    end;

                if "Table ID" > 0 then begin
                    RecRef.Open("Table ID");
                    Validate(Name, RecRef.Caption);
                    "Page ID" := ConfigMgt.FindPage("Table ID");
                    "Copying Available" := ConfigMgt.TransferContents("Table ID", '', false);
                    GetRelatedTables();
                end else
                    if xRec."Table ID" > 0 then
                        Error(DeleteLineInsteadErr);
            end;
        }
        field(4; Name; Text[250])
        {
            Caption = 'Name';
        }
        field(5; "Company Filter"; Text[30])
        {
            Caption = 'Company Filter';
            FieldClass = FlowFilter;
            TableRelation = Company;
        }
        field(6; "Company Filter (Source Table)"; Text[30])
        {
            Caption = 'Company Filter (Source Table)';
            FieldClass = FlowFilter;
            TableRelation = Company;
        }
        field(8; "No. of Records"; Integer)
        {
            BlankZero = true;
            CalcFormula = sum("Table Information"."No. of Records" where("Company Name" = field("Company Filter"),
                                                                          "Table No." = field("Table ID")));
            Caption = 'No. of Records';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "No. of Records (Source Table)"; Integer)
        {
            BlankZero = true;
            CalcFormula = sum("Table Information"."No. of Records" where("Company Name" = field("Company Filter (Source Table)"),
                                                                          "Table No." = field("Table ID")));
            Caption = 'No. of Records (Source Table)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; "Licensed Table"; Boolean)
        {
            BlankZero = true;
            CalcFormula = exist("License Permission" where("Object Type" = const(TableData),
                                                            "Object Number" = field("Table ID"),
                                                            "Read Permission" = const(Yes),
                                                            "Insert Permission" = const(Yes),
                                                            "Modify Permission" = const(Yes),
                                                            "Delete Permission" = const(Yes)));
            Caption = 'Licensed Table';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; "Promoted Table"; Boolean)
        {
            Caption = 'Promoted Table';

            trigger OnValidate()
            begin
                if "Promoted Table" then
                    TestField("Line Type", "Line Type"::Table);
            end;
        }
        field(12; "Dimensions as Columns"; Boolean)
        {
            Caption = 'Dimensions as Columns';

            trigger OnValidate()
            var
                ConfigPackageTable: Record "Config. Package Table";
            begin
                TestField("Line Type", "Line Type"::Table);
                TestField("Table ID");
                TestField("Package Code");
                ConfigPackageTable.Get("Package Code", "Table ID");
                ConfigPackageTable.SetHideValidationDialog(HideValidationDialog);
                ConfigPackageTable.Validate("Dimensions as Columns", "Dimensions as Columns");
                ConfigPackageTable.Modify();
            end;
        }
        field(13; "Copying Available"; Boolean)
        {
            Caption = 'Copying Available';
            Editable = false;
        }
        field(14; "Page ID"; Integer)
        {
            Caption = 'Page ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Page));

            trigger OnLookup()
            var
                ConfigValidateMgt: Codeunit "Config. Validate Management";
            begin
                ConfigValidateMgt.LookupPage("Page ID");
                Validate("Page ID");
            end;
        }
        field(15; "Page Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Name" where("Object Type" = const(Page),
                                                                        "Object ID" = field("Page ID")));
            Caption = 'Page Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(18; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                if ("Starting Date" <> 0D) and (xRec."Starting Date" <> 0D) and ("Ending Date" <> 0D) then
                    "Ending Date" := "Ending Date" + ("Starting Date" - xRec."Starting Date");
            end;
        }
        field(19; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
        }
        field(20; "Responsible ID"; Code[50])
        {
            Caption = 'Responsible ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                UserSelection: Codeunit "User Selection";
            begin
                UserSelection.ValidateUserName("Responsible ID");
            end;
        }
        field(21; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = ' ,In Progress,Completed,Ignored,Blocked';
            OptionMembers = " ","In Progress",Completed,Ignored,Blocked;
        }
        field(25; "Vertical Sorting"; Integer)
        {
            Caption = 'Vertical Sorting';
        }
        field(26; "Data Origin"; Text[50])
        {
            Caption = 'Data Origin';
        }
        field(28; Reference; Text[250])
        {
            Caption = 'Reference';
            ExtendedDatatype = URL;
        }
        field(30; "Licensed Page"; Boolean)
        {
            BlankZero = true;
            CalcFormula = exist("License Permission" where("Object Type" = const(Page),
                                                            "Object Number" = field("Page ID"),
                                                            "Execute Permission" = const(Yes)));
            Caption = 'Licensed Page';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31; "No. of Question Groups"; Integer)
        {
            CalcFormula = count("Config. Question Area" where("Table ID" = field("Table ID")));
            Caption = 'No. of Question Groups';
            Editable = false;
            FieldClass = FlowField;
        }
        field(32; "Parent Line No."; Integer)
        {
            Caption = 'Parent Line No.';
        }
        field(36; "Package Code"; Code[20])
        {
            Caption = 'Package Code';
            TableRelation = "Config. Package";
        }
        field(37; "Package Caption"; Text[50])
        {
            CalcFormula = lookup("Config. Package"."Package Name" where(Code = field("Package Code")));
            Caption = 'Package Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(38; "Package Exists"; Boolean)
        {
            CalcFormula = exist("Config. Package" where(Code = field("Package Code")));
            Caption = 'Package Exists';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Line Type", Status, "Promoted Table")
        {
        }
        key(Key3; "Table ID")
        {
        }
        key(Key4; "Vertical Sorting")
        {
        }
        key(Key5; "Line Type", "Parent Line No.")
        {
        }
        key(Key6; "Package Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ConfigRelatedTable: Record "Config. Related Table";
    begin
        if CountWorksheetTableOccurrences("Table ID") = 1 then begin
            ConfigRelatedTable.SetRange("Table ID", "Table ID");
            ConfigRelatedTable.DeleteAll(true);
        end;
    end;

    var
        ConfigMgt: Codeunit "Config. Management";
        ConfigPackageMgt: Codeunit "Config. Package Management";
        DeleteLineInsteadErr: Label 'Delete the line instead.';
#pragma warning disable AA0470
        UnsupportedStatusErr: Label 'The status %1 is not supported.';
#pragma warning restore AA0470
        RemovePackageLinkQst: Label 'The table you are trying to rename is linked to a package. Do you want to remove the link?';
#pragma warning disable AA0470
        BlockedTableErr: Label 'You cannot process line for table %1 and package code %2 because it is blocked.';
#pragma warning restore AA0470
        NoDuplicateLinesMsg: Label 'There are no duplicate lines.';
#pragma warning disable AA0470
        NoOfDuplicateLinesDeletedMsg: Label '%1 line(s) were deleted.';
#pragma warning restore AA0470

    protected var
        HideValidationDialog: Boolean;

    procedure CheckBlocked()
    begin
        if Status = Status::Blocked then
            Error(BlockedTableErr, "Table ID", "Package Code");
    end;

    procedure ShowTableData()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowTableData(Rec, IsHandled);
        if IsHandled then
            exit;

        if ("Line Type" = "Line Type"::Table) and ("Page ID" <> 0) then
            PAGE.Run("Page ID");
    end;

    procedure ShowQuestions()
    var
        ConfigQuestionArea: Record "Config. Question Area";
        ConfigQuestionAreaPage: Page "Config. Question Area";
    begin
        TestField("Line Type", "Line Type"::Table);
        TestField("Table ID");

        ConfigQuestionArea.SetRange("Table ID", "Table ID");
        ConfigQuestionArea.FindFirst();

        ConfigQuestionArea.Reset();
        ConfigQuestionArea.FilterGroup(2);
        ConfigQuestionArea.SetRange("Table ID", "Table ID");
        ConfigQuestionArea.FilterGroup(0);
        ConfigQuestionAreaPage.SetTableView(ConfigQuestionArea);
        ConfigQuestionAreaPage.RunModal();
        Clear(ConfigQuestionAreaPage);
    end;

    procedure GetProgress(): Integer
    var
        Total: Integer;
        TotalStatusWeight: Decimal;
    begin
        Total := GetNoTables();
        TotalStatusWeight := GetTotalStatusWeight();

        if Total = 0 then
            exit(0);

        exit(Round(100 * TotalStatusWeight / Total, 1));
    end;

    procedure GetNoOfDirectChildrenTables(): Integer
    var
        ConfigLine: Record "Config. Line";
    begin
        ConfigLine.Reset();
        ConfigLine.SetCurrentKey("Line Type");
        ConfigLine.SetRange("Line Type", ConfigLine."Line Type"::Table);
        ConfigLine.SetRange("Parent Line No.", Rec."Line No.");
        exit(ConfigLine.Count);
    end;

    procedure GetDirectChildrenTablesStatusWeight() StatusWeight: Decimal
    var
        ConfigLine: Record "Config. Line";
    begin
        ConfigLine.Reset();
        ConfigLine.SetCurrentKey("Line Type");
        ConfigLine.SetRange("Line Type", ConfigLine."Line Type"::Table);
        ConfigLine.SetRange("Parent Line No.", Rec."Line No.");
        if ConfigLine.FindSet() then
            repeat
                StatusWeight += ConfigLine.GetLineStatusWeight();
            until ConfigLine.Next() = 0;
    end;

    procedure GetNoTables() Total: Integer
    var
        ConfigLine: Record "Config. Line";
    begin
        case "Line Type" of
            "Line Type"::Table:
                Total := 0;
            "Line Type"::Group:
                Total := GetNoOfDirectChildrenTables();
            "Line Type"::Area:
                begin
                    Total := GetNoOfDirectChildrenTables();

                    ConfigLine.SetRange("Line Type", ConfigLine."Line Type"::Group);
                    ConfigLine.SetRange("Parent Line No.", "Line No.");
                    if ConfigLine.FindSet() then
                        repeat
                            Total += ConfigLine.GetNoOfDirectChildrenTables();
                        until ConfigLine.Next() = 0;
                end;
        end;
    end;

    local procedure GetTotalStatusWeight() Total: Decimal
    var
        ConfigLine: Record "Config. Line";
    begin
        case "Line Type" of
            "Line Type"::Table:
                Total := 0;
            "Line Type"::Group:
                Total := GetDirectChildrenTablesStatusWeight();
            "Line Type"::Area:
                begin
                    Total := GetDirectChildrenTablesStatusWeight();

                    ConfigLine.SetRange("Line Type", ConfigLine."Line Type"::Group);
                    ConfigLine.SetRange("Parent Line No.", "Line No.");
                    if ConfigLine.FindSet() then
                        repeat
                            Total += ConfigLine.GetDirectChildrenTablesStatusWeight();
                        until ConfigLine.Next() = 0;
                end;
        end;
    end;

    local procedure GetRelatedTables()
    var
        ConfigRelatedTable: Record "Config. Related Table";
        ConfigRelatedField: Record "Config. Related Field";
        "Field": Record "Field";
    begin
        ConfigPackageMgt.SetFieldFilter(Field, "Table ID", 0);
        OnGetRelatedTablesOnAfterFieldSetFilters(Rec, Field);
        if Field.FindSet() then
            repeat
                if Field.RelationTableNo <> 0 then
                    if not ConfigRelatedField.Get("Table ID", Field."No.") then begin
                        ConfigRelatedField.Init();
                        ConfigRelatedField."Table ID" := "Table ID";
                        ConfigRelatedField."Field ID" := Field."No.";
                        ConfigRelatedField."Relation Table ID" := Field.RelationTableNo;
                        ConfigRelatedField.Insert();
                    end;
            until Field.Next() = 0;

        if ConfigRelatedField.FindSet() then
            repeat
                if not ConfigRelatedTable.Get(ConfigRelatedField."Table ID", ConfigRelatedField."Relation Table ID") then begin
                    ConfigRelatedTable."Table ID" := ConfigRelatedField."Table ID";
                    ConfigRelatedTable."Relation Table ID" := ConfigRelatedField."Relation Table ID";
                    ConfigRelatedTable.Insert();
                end;
            until ConfigRelatedField.Next() = 0;
    end;

    procedure GetLineStatusWeight(): Decimal
    begin
        case Status of
            Status::" ":
                exit(0);
            Status::Completed, Status::Ignored:
                exit(1);
            Status::"In Progress", Status::Blocked:
                exit(0.5);
            else
                Error(UnsupportedStatusErr, Status);
        end;
    end;

    local procedure CountWorksheetTableOccurrences(TableID: Integer): Integer
    var
        ConfigLine: Record "Config. Line";
    begin
        ConfigLine.SetRange("Table ID", TableID);
        exit(ConfigLine.Count);
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure GetNoOfRecords(): Integer
    begin
        exit(GetNoOfDatabaseRecords("Table ID", "Company Filter"));
    end;

    procedure GetNoOfRecordsSourceTable(): Integer
    begin
        exit(GetNoOfDatabaseRecords("Table ID", "Company Filter (Source Table)"));
    end;

    local procedure GetNoOfDatabaseRecords(TableID: Integer; "Filter": Text): Integer
    var
        RecRef: RecordRef;
    begin
        if TableID = 0 then
            exit(0);

        RecRef.Open(TableID, false, Filter);
        if not RecRef.ReadPermission() then
            exit(0);
        exit(RecRef.Count());
    end;

    procedure GetNoOfRecordsText(): Text
    var
        RecRef: RecordRef;
    begin
        if "Table ID" = 0 then
            exit;

        RecRef.Open("Table ID", false, "Company Filter");
        if not RecRef.ReadPermission() then
            exit;
        exit(Format(RecRef.Count()));
    end;

    procedure DeleteDuplicateLines()
    var
        ConfigLine: Record "Config. Line";
        TempConfigLine: Record "Config. Line" temporary;
        NoOfDuplicateLines: Integer;
    begin
        if FindSet() then
            repeat
                TempConfigLine.Reset();
                TempConfigLine.SetRange("Line Type", "Line Type"::Table);
                TempConfigLine.SetRange("Table ID", "Table ID");
                TempConfigLine.SetRange("Package Code", "Package Code");
                if not TempConfigLine.IsEmpty() then begin
                    ConfigLine.Get("Line No.");
                    ConfigLine.Delete(true);
                    NoOfDuplicateLines := NoOfDuplicateLines + 1;
                end else begin
                    TempConfigLine.Init();
                    TempConfigLine := Rec;
                    TempConfigLine.Insert();
                end;
            until Next() = 0;

        if NoOfDuplicateLines = 0 then
            Message(NoDuplicateLinesMsg)
        else
            Message(NoOfDuplicateLinesDeletedMsg, NoOfDuplicateLines);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowTableData(ConfigLine: Record "Config. Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetRelatedTablesOnAfterFieldSetFilters(var ConfigLine: Record "Config. Line"; var "Field": Record "Field")
    begin
    end;
}

