namespace System.IO;

using System.Reflection;
using System.Security.User;
using System.Telemetry;

page 8625 "Config. Package Subform"
{
    Caption = 'Tables';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Config. Package Table";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = NoOfErrorsStyleTxt;
                    ToolTip = 'Specifies the name of the table that is part of the migration process. The name comes from the Name property of the table.';

                    trigger OnValidate()
                    begin
                        Rec.CalcFields("Table Name");
                    end;
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    StyleExpr = NoOfErrorsStyleTxt;
                    ToolTip = 'Specifies the name of the configuration table. After you select a table ID from the list of tables, the table name is automatically filled in.';
                }
                field("Table Caption"; Rec."Table Caption")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the caption of the table that is part of the migration process. The name comes from the Caption property of the table.';
                    Visible = false;
                }
                field("Parent Table ID"; Rec."Parent Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the table that holds the configuration data.';
                }
                field("Data Template"; Rec."Data Template")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the data template that is being used as part of the migration process.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ConfigTemplateHeader: Record "Config. Template Header";
                    begin
                        ConfigTemplateHeader.SetRange("Table ID", Rec."Table ID");
                        if PAGE.RunModal(PAGE::"Config. Template List", ConfigTemplateHeader, ConfigTemplateHeader.Code) = ACTION::LookupOK then
                            Rec."Data Template" := ConfigTemplateHeader.Code;
                    end;
                }
                field("Processing Order"; Rec."Processing Order")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the processing order. This is used to track the migration process.';
                    Visible = false;
                }
                field("Dimensions as Columns"; Rec."Dimensions as Columns")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether dimensions should be displayed in columns. If you select No, then the dimensions are not displayed in any format.';
                }
                field("Skip Table Triggers"; Rec."Skip Table Triggers")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether codeunit triggers related to tables should be skipped during the configuration process.';
                }
                field("Delete Recs Before Processing"; Rec."Delete Recs Before Processing")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Delete Table Records Before Processing';
                    ToolTip = 'Specifies whether table records should be deleted before the migration process is begun.';
                }
                field("Processing Report ID"; Rec."Processing Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the codeunit that has been set up to process data before you apply it to a Business Central database. By default, Business Central uses codeunit 8621.';
                    Visible = false;
                }
                field("No. of Package Records"; Rec."No. of Package Records")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the count of the number of configuration package records.';

                    trigger OnDrillDown()
                    begin
                        Rec.ShowPackageRecords(Show::All, Rec."Dimensions as Columns");
                        CurrPage.Update();
                    end;
                }
                field("No. of Fields Available"; Rec."No. of Fields Available")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = true;
                    DrillDownPageID = "Config. Package Fields";
                    ToolTip = 'Specifies the count of the number of fields that are available in the migration table.';
                }
                field("No. of Fields Included"; Rec."No. of Fields Included")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = true;
                    DrillDownPageID = "Config. Package Fields";
                    ToolTip = 'Specifies the count of the number of fields that are included in the migration table.';
                }
                field("No. of Fields to Validate"; Rec."No. of Fields to Validate")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = true;
                    DrillDownPageID = "Config. Package Fields";
                    ToolTip = 'Specifies the number of fields to validate. The count of the number of fields to validate is based on how many fields in the table have the Validate Field check box selected.';
                }
                field("No. of Package Errors"; Rec."No. of Package Errors")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = true;
                    Editable = false;
                    StyleExpr = NoOfErrorsStyleTxt;
                    ToolTip = 'Specifies the count of the number of package errors.';

                    trigger OnDrillDown()
                    begin
                        Rec.ShowPackageRecords(Show::Errors, Rec."Dimensions as Columns");
                        CurrPage.Update();
                    end;
                }
                field(NoOfDatabaseRecords; Rec.GetNoOfDatabaseRecordsText())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No. of Database Records';
                    DrillDown = true;
                    ToolTip = 'Specifies how many database records have been created in connection with the migration.';

                    trigger OnDrillDown()
                    begin
                        Rec.ShowDatabaseRecords();
                    end;
                }
                field(Filtered; Rec.Filtered)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the package is filtered. This field is set depending on filter settings you have specified.';
                }
                field("Page ID"; Rec."Page ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the page that is used to show the journal or worksheet that uses the template.';
                }
                field(Comments; Rec.Comments)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a comment in which you can provide a description';
                }
                field("Created Date and Time"; Rec."Created Date and Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date and time that the configuration package was created. The field is updated each time you save the package.';
                }
                field("Created by User ID"; Rec."Created by User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who created the configuration package.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."Created by User ID");
                    end;
                }
                field("Imported Date and Time"; Rec."Imported Date and Time")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date and time that migration records were imported from Excel or from an .xml file.';
                }
                field("Imported by User ID"; Rec."Imported by User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who has imported the package.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."Imported by User ID");
                    end;
                }
                field("Delayed Insert"; Rec."Delayed Insert")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that a record will only be inserted after validation that it contains key and non-key fields. If you do not select the Delayed Insert check box, then empty lines may be imported, for records with errors in non-key fields.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("Table")
            {
                Caption = 'Table';
                action(PackageRecords)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Package Data';
                    Image = Grid;
                    ToolTip = 'View or edit information about the package.';

                    trigger OnAction()
                    begin
                        Rec.ShowPackageRecords(Show::Records, Rec."Dimensions as Columns");
                    end;
                }
                action(DatabaseRecords)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Database Data';
                    Image = Database;
                    ToolTip = 'View the data that has been applied to the database.';

                    trigger OnAction()
                    begin
                        Rec.ShowDatabaseRecords();
                    end;
                }
                action(PackageErrors)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Errors';
                    Image = ErrorLog;
                    ToolTip = 'View a list of errors that resulted from the data migration. For example, if you are importing a customer into Business Central and assign to that customer a salesperson who is not in the database, you get an error during migration. You can fix the error by removing the incorrect salesperson ID or by updating the information about salespeople so that the list of salespeople is correct and up-to-date.';

                    trigger OnAction()
                    begin
                        Rec.ShowPackageRecords(Show::Errors, Rec."Dimensions as Columns");
                    end;
                }
                action(PackageFields)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Fields';
                    Image = CheckList;
                    ToolTip = 'View the fields that are used in the company configuration process. For each table in the list of configuration tables, the Config. Package Fields window displays a list of all the fields in the table and indicates the order in which the data in a field is to be processed.';

                    trigger OnAction()
                    begin
                        Rec.ShowPackageFields();
                    end;
                }
                action(PackageFilters)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Filters';
                    Image = "Filter";
                    ToolTip = 'View or set field filter values for a configuration package filter. By setting a value, you specify that only records with that value are included in the configuration package.';

                    trigger OnAction()
                    begin
                        Rec.ShowFilters();
                    end;
                }
                action(ProcessingRules)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Processing Rules';
                    Image = SetupList;
                    ToolTip = 'View or edit the filters that are used to process data.';

                    trigger OnAction()
                    begin
                        Rec.ShowProcessingRules();
                    end;
                }
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(GetRelatedTables)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Get Related Tables';
                    Image = GetLines;
                    ToolTip = 'Select tables that relate to existing selected tables that you also want to add to the configuration package.';

                    trigger OnAction()
                    var
                        ConfigPackageTable: Record "Config. Package Table";
                        ConfigPackageMgt: Codeunit "Config. Package Management";
                    begin
                        CurrPage.SetSelectionFilter(ConfigPackageTable);
                        ConfigPackageMgt.GetRelatedTables(ConfigPackageTable);
                    end;
                }
                action(ValidateRelations)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Validate Relations';
                    Image = CheckRulesSyntax;
                    ToolTip = 'Determine if you have introduced errors, such as not including tables that the configuration relies on.';

                    trigger OnAction()
                    var
                        TempConfigPackageTable: Record "Config. Package Table" temporary;
                        ConfigPackageMgt: Codeunit "Config. Package Management";
                    begin
                        CurrPage.SetSelectionFilter(ConfigPackageTable);

                        if Confirm(SelectionConfirmMessage(), true) then
                            ConfigPackageMgt.ValidatePackageRelations(ConfigPackageTable, TempConfigPackageTable, true);
                    end;
                }
                action(ApplyData)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply Data';
                    Image = Apply;
                    ToolTip = 'Apply the data in the package to the database. After you apply data, you can only see it in the database.';

                    trigger OnAction()
                    var
                        ConfigPackage: Record "Config. Package";
                        ConfigPackageMgt: Codeunit "Config. Package Management";
                    begin
                        CurrPage.SetSelectionFilter(ConfigPackageTable);
                        if Confirm(SelectionConfirmMessage(), true) then begin
                            ConfigPackage.Get(Rec."Package Code");
                            ConfigPackageMgt.ApplyPackage(ConfigPackage, ConfigPackageTable, true);
                        end;
                    end;
                }
            }
            group("E&xcel")
            {
                Caption = 'E&xcel';
                action(ExportToExcel)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export to Excel';
                    Image = ExportToExcel;
                    ToolTip = 'Export the data from selected tables in the package to Excel.';

                    trigger OnAction()
                    var
                        ConfigExcelExchange: Codeunit "Config. Excel Exchange";
                    begin
                        CurrPage.SetSelectionFilter(ConfigPackageTable);
                        if Confirm(SelectionConfirmMessage(), true) then
                            ConfigExcelExchange.ExportExcelFromTables(ConfigPackageTable);
                    end;
                }
                action(ImportFromExcel)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import from Excel';
                    Image = ImportExcel;
                    ToolTip = 'Import data from Excel to selected tables in the package.';

                    trigger OnAction()
                    var
                        ConfigPackageTable: Record "Config. Package Table";
                        ConfigExcelExchange: Codeunit "Config. Excel Exchange";
                    begin
                        CurrPage.SetSelectionFilter(ConfigPackageTable);
                        ConfigExcelExchange.SetSelectedTables(ConfigPackageTable);
                        ConfigExcelExchange.ImportExcelFromSelectedPackage(Rec."Package Code");
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        NoOfErrorsStyleTxt := Rec.SetFieldStyle(Rec.FieldNo("No. of Package Errors"));
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000GD5', 'Configuration packages', Enum::"Feature Uptake Status"::"Set up");
        CheckFieldsMultiRelations();
    end;

    trigger OnOpenPage()
    var
        ConfigPackageManagement: Codeunit "Config. Package Management";
    begin
        Rec.SetFilter("Company Filter (Source Table)", '%1', CompanyName);
        ConfigPackageManagement.RemoveRecordsWithObsoleteTableID(
          DATABASE::"Config. Package Table", Rec.FieldNo("Table ID"));
    end;

    var
        MultipleTablesSelectedQst: Label '%1 tables have been selected. Do you want to continue?', Comment = '%1 = Number of selected tables';
        Show: Option Records,Errors,All;
        NoOfErrorsStyleTxt: Text;
        SingleTableSelectedQst: Label 'One table has been selected. Do you want to continue?', Comment = '%1 = Table name';
        MultiRelationQst: Label 'Some fields have two or more related tables.\Do you want to check them?';

    protected var
        ConfigPackageTable: Record "Config. Package Table";

    local procedure SelectionConfirmMessage(): Text
    begin
        if ConfigPackageTable.Count <> 1 then
            exit(StrSubstNo(MultipleTablesSelectedQst, ConfigPackageTable.Count));

        exit(SingleTableSelectedQst);
    end;

    local procedure CheckFieldsMultiRelations()
    var
        "Field": Record "Field";
        ConfigPackageManagement: Codeunit "Config. Package Management";
        FieldsWithMultiRelations: Boolean;
        FilterMultiRelationFields: Text;
    begin
        ConfigPackageManagement.SetFieldFilter(Field, Rec."Table ID", 0);
        if Field.FindSet() then
            repeat
                if ConfigPackageManagement.IsFieldMultiRelation(Rec."Table ID", Field."No.") then begin
                    FieldsWithMultiRelations := true;
                    FilterMultiRelationFields += Format(Field."No.") + '|';
                end;
            until Field.Next() = 0;
        if FieldsWithMultiRelations then
            if Confirm(MultiRelationQst) then
                Rec.ShowFilteredPackageFields(DelChr(FilterMultiRelationFields, '>', '|'));
    end;
}

