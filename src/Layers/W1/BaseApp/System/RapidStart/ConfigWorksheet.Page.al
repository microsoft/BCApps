namespace System.IO;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Inventory.Journal;
using System.Environment.Configuration;
using System.Reflection;
using System.Security.User;

page 8632 "Config. Worksheet"
{
    AdditionalSearchTerms = 'rapid start implementation migrate setup worksheet';
    ApplicationArea = Suite;
    Caption = 'Configuration Worksheet';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Config. Line";
    SourceTableView = sorting("Vertical Sorting");
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowCaption = false;
                field("Line Type"; Rec."Line Type")
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = NameEmphasize;
                    ToolTip = 'Specifies the type of the configuration package line. The line can be one of the following types:';
                }
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the ID of the table that you want to use for the line type. After you select a table ID from the list of objects in the lookup table, the name of the table is automatically filled in the Name field.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = NameEmphasize;
                    ToolTip = 'Specifies the name of the line type.';
                }
                field("Promoted Table"; Rec."Promoted Table")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the table is promoted. Select the check box to promote the table in the configuration worksheet. You can use this designation as a signal that this table requires additional attention.';
                }
                field(Reference; Rec.Reference)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a url address. Use this field to provide a url address to a location that Specifies information about the table. For example, you could provide the address of a page that Specifies information about setup considerations that the solution implementer should consider.';
                    Width = 20;
                }
                field("Package Code"; Rec."Package Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the code of the package associated with the configuration. The code is filled in when you use the Assign Package function to select the package for the line type.';
                }
                field("Package Exists"; Rec."Package Exists")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies whether the package that has been assigned to the worksheet line has been created.';
                }
                field("Responsible ID"; Rec."Responsible ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = "User Lookup";
                    ToolTip = 'Specifies the ID of the Business Central user who is responsible for the configuration worksheet.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the table in the configuration worksheet. You can use the status information, which you provide, to help you in planning and tracking your work.';
                }
                field("Page ID"; Rec."Page ID")
                {
                    ApplicationArea = Basic, Suite;
                    AssistEdit = true;
                    BlankZero = true;
                    ToolTip = 'Specifies the number of the page that is used to show the journal or worksheet that uses the template.';

                    trigger OnAssistEdit()
                    begin
                        Rec.ShowTableData();
                    end;
                }
                field("Page Caption"; Rec."Page Caption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the displayed name of the journal or worksheet that uses the template.';
                }
                field("Licensed Table"; Rec."Licensed Table")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the table is covered by the license of the person creating the configuration package.';
                }
                field(NoOfRecords; Rec.GetNoOfRecordsText())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No. of Records';
                    ToolTip = 'Specifies how many records are created in connection with migration.';
                }
                field("Dimensions as Columns"; Rec."Dimensions as Columns")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies whether the configuration includes dimensions as columns. When you select the Dimensions as Columns check box, the dimensions are included in the Excel worksheet that you create for configuration. In order to select this check box, you must include the Default Dimension and Dimension Value tables in the configuration package.';
                }
                field("Copying Available"; Rec."Copying Available")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether copying is available in the configuration worksheet.';
                }
                field("No. of Question Groups"; Rec."No. of Question Groups")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the number of question groups that are contained on the configuration questionnaire.';
                    Visible = false;
                }
                field("Licensed Page"; Rec."Licensed Page")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the page that is associated with the table is licensed.';
                }
            }
        }
        area(factboxes)
        {
            part("Package Table"; "Config. Package Table FactBox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Package Table';
                SubPageLink = "Package Code" = field("Package Code"),
                              "Table ID" = field("Table ID");
                SubPageView = sorting("Package Code", "Table ID");
            }
            part("Related Tables"; "Config. Related Tables FactBox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Related Tables';
                SubPageLink = "Table ID" = field("Table ID");
            }
            part(Control22; "Config. Questions FactBox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Questions';
                SubPageLink = "Table ID" = field("Table ID");
            }
            systempart(Notes; Notes)
            {
                ApplicationArea = Notes;
                Caption = 'Notes';
                Visible = false;
            }
            systempart(Links; Links)
            {
                ApplicationArea = RecordLinks;
                Caption = 'Links';
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Setup")
            {
                Caption = '&Setup';
                Image = Setup;
                action(Questions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Questions';
                    Image = Answers;
                    ToolTip = 'View the questions that are to be answered on the setup questionnaire.';

                    trigger OnAction()
                    begin
                        Rec.ShowQuestions();
                    end;
                }
                action(Users)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Users';
                    Image = Users;
                    RunObject = Page Users;
                    ToolTip = 'View or edit users that will be configured in the database.';
                }
                action("Users Personalization")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Users Settings';
                    Image = UserSetup;
                    RunObject = Page "User Settings List";
                    ToolTip = 'View or edit UI changes that will be configured in the database.';
                }
            }
        }
        area(processing)
        {
            group("Sho&w")
            {
                Caption = 'Sho&w';
                Image = "Action";
                action(PackageCard)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Package Card';
                    Image = Bin;
                    ToolTip = 'View or edit information about the package.';

                    trigger OnAction()
                    begin
                        Rec.TestField("Package Code");
                        ConfigPackageTable.ShowPackageCard(Rec."Package Code");
                    end;
                }
                action(PromotedOnly)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Toggle Promoted Only';
                    Image = ShowSelected;
                    ToolTip = 'View tables that are marked as promoted, for example, because they are frequently by a typical customer during the setup process.';

                    trigger OnAction()
                    begin
                        if Rec.GetFilter("Promoted Table") = '' then
                            Rec.SetRange("Promoted Table", true)
                        else
                            Rec.SetRange("Promoted Table");
                    end;
                }
                action("Database Data")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Database Data';
                    Image = Database;
                    ToolTip = 'View the data that has been applied to the database.';

                    trigger OnAction()
                    begin
                        Rec.ShowTableData();
                    end;
                }
                action(PackageData)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Package Data';
                    Image = Grid;
                    ToolTip = 'View or edit information about the package.';

                    trigger OnAction()
                    begin
                        GetConfigPackageTable(ConfigPackageTable);
                        ConfigPackageTable.ShowPackageRecords(Show::Records, Rec."Dimensions as Columns");
                    end;
                }
                action(Errors)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Errors';
                    Image = ErrorLog;
                    ToolTip = 'View a list of errors that resulted from the data migration. For example, if you are importing a customer into Business Central and assign to that customer a salesperson who is not in the database, you get an error during migration. You can fix the error by removing the incorrect salesperson ID or by updating the information about salespeople so that the list of salespeople is correct and up-to-date.';

                    trigger OnAction()
                    begin
                        GetConfigPackageTable(ConfigPackageTable);
                        ConfigPackageTable.ShowPackageRecords(Show::Errors, Rec."Dimensions as Columns");
                    end;
                }
                action("Fields")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Fields';
                    Image = CheckList;
                    ToolTip = 'View the fields that are used in the company configuration process. For each table in the list of configuration tables, the Config. Package Fields window displays a list of all the fields in the table and indicates the order in which the data in a field is to be processed.';

                    trigger OnAction()
                    begin
                        GetConfigPackageTable(ConfigPackageTable);
                        ConfigPackageTable.ShowPackageFields();
                    end;
                }
                action(Filters)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Filters';
                    Image = FilterLines;
                    ToolTip = 'View or set field filter values for a configuration package filter. By setting a value, you specify that only records with that value are included in the configuration package.';

                    trigger OnAction()
                    begin
                        GetConfigPackageTable(ConfigPackageTable);
                        ConfigPackageTable.ShowFilters();
                    end;
                }
            }
            group(Functions)
            {
                Caption = 'Functions';
                action("Get Tables")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Get Tables';
                    Ellipsis = true;
                    Image = GetLines;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;
                    //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedIsBig = true;
                    ToolTip = 'Select tables that you want to add to the configuration package.';

                    trigger OnAction()
                    var
                        GetConfigTables: Report "Get Config. Tables";
                    begin
                        GetConfigTables.RunModal();
                        Clear(GetConfigTables);
                    end;
                }
                action(GetRelatedTables)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Get Related Tables';
                    Image = GetEntries;
                    ToolTip = 'Select tables that relate to existing selected tables that you also want to add to the configuration package.';

                    trigger OnAction()
                    var
                        AllObj: Record AllObj;
                        ConfigLine: Record "Config. Line";
                        ConfigMgt: Codeunit "Config. Management";
                    begin
                        CurrPage.SetSelectionFilter(ConfigLine);
                        if ConfigLine.FindSet() then
                            repeat
                                AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
                                AllObj.SetRange("Object ID", ConfigLine."Table ID");
                                ConfigMgt.GetConfigTables(AllObj, false, true, false, false, false);
                                Commit();
                            until ConfigLine.Next() = 0;
                    end;
                }
                action(DeleteDuplicateLines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Delete Duplicate Lines';
                    Image = RemoveLine;
                    //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedIsBig = true;
                    ToolTip = 'Remove duplicate tables that have the same package code.';

                    trigger OnAction()
                    begin
                        Rec.DeleteDuplicateLines();
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
                        ConfigLine: Record "Config. Line";
                        ConfigPackageMgt: Codeunit "Config. Package Management";
                    begin
                        CurrPage.SetSelectionFilter(ConfigLine);
                        CheckSelectedLines(ConfigLine);
                        if Confirm(ApplyPackageDataQst, false) then
                            ConfigPackageMgt.ApplyConfigLines(ConfigLine);
                    end;
                }
                action(MoveUp)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Move Up';
                    Image = MoveUp;
                    ToolTip = 'Move the selected line up in the list.';

                    trigger OnAction()
                    var
                        ConfigLine: Record "Config. Line";
                    begin
                        CurrPage.SaveRecord();
                        ConfigLine.SetCurrentKey("Vertical Sorting");
                        ConfigLine.SetFilter("Vertical Sorting", '..%1', Rec."Vertical Sorting" - 1);
                        if ConfigLine.FindLast() then begin
                            ExchangeLines(Rec, ConfigLine);
                            CurrPage.Update(false);
                        end;
                    end;
                }
                action(MoveDown)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Move Down';
                    Image = MoveDown;
                    ToolTip = 'Move the selected line down in the list.';

                    trigger OnAction()
                    var
                        ConfigLine: Record "Config. Line";
                    begin
                        CurrPage.SaveRecord();
                        ConfigLine.SetCurrentKey("Vertical Sorting");
                        ConfigLine.SetFilter("Vertical Sorting", '%1..', Rec."Vertical Sorting" + 1);
                        if ConfigLine.FindFirst() then begin
                            ExchangeLines(Rec, ConfigLine);
                            CurrPage.Update(false);
                        end;
                    end;
                }
                action(AssignPackage)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Assign Package';
                    Image = Migration;
                    ToolTip = 'Assign the tables that you want to treat as part of your configuration to a configuration package.';

                    trigger OnAction()
                    var
                        ConfigLine: Record "Config. Line";
                    begin
                        CurrPage.SetSelectionFilter(ConfigLine);
                        AssignPackagePrompt(ConfigLine);
                    end;
                }
            }
            group(Tools)
            {
                Caption = 'Tools';
                action(CopyDataFromCompany)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Data from Company';
                    Ellipsis = true;
                    Image = Copy;
                    ToolTip = 'Copy commonly used values from an existing company to a new one. For example, if you have a standard list of symptom codes that is common to all your service management implementations, you can copy the codes easily from one company to another.';

                    trigger OnAction()
                    begin
                        PAGE.RunModal(PAGE::"Copy Company Data");
                    end;
                }
            }
            group(Excel)
            {
                Caption = 'Excel';
                action("Export to Template")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export to Template';
                    Image = ExportToExcel;
                    ToolTip = 'Export the data to an Excel workbook to serve as a template that is based on the structure of an existing database table quickly. You can then use the template to gather together customer data in a consistent format for later import into Dynamics 365.';

                    trigger OnAction()
                    var
                        ConfigLine: Record "Config. Line";
                        ConfigExcelExchange: Codeunit "Config. Excel Exchange";
                    begin
                        CurrPage.SetSelectionFilter(ConfigLine);
                        CheckSelectedLines(ConfigLine);
                        if Confirm(ExportToExcelQst, true, ConfigLine.Count) then
                            ConfigExcelExchange.ExportExcelFromConfig(ConfigLine);
                    end;
                }
                action("Import from Template")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import from Template';
                    Image = ImportExcel;
                    ToolTip = 'Import data that exists in a configuration template.';

                    trigger OnAction()
                    var
                        ConfigExcelExchange: Codeunit "Config. Excel Exchange";
                    begin
                        if Confirm(ImportFromExcelQst, true) then
                            ConfigExcelExchange.ImportExcelFromConfig(Rec);
                    end;
                }
            }
        }
        area(reporting)
        {
            group("C&reate")
            {
                Caption = 'C&reate';
                action("Create G/L Journal Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create G/L Journal Lines';
                    Image = "Report";
                    RunObject = Report "Create G/L Acc. Journal Lines";
                    ToolTip = 'Create G/L journal lines for the legacy account balances that you will transfer to the new company.';
                }
                action("Create Customer Journal Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Customer Journal Lines';
                    Image = "Report";
                    RunObject = Report "Create Customer Journal Lines";
                    ToolTip = 'Create journal lines during the setup of the new company.';
                }
                action("Create Vendor Journal Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Vendor Journal Lines';
                    Image = "Report";
                    RunObject = Report "Create Vendor Journal Lines";
                    ToolTip = 'Prepare to transfer legacy vendor balances to the newly configured company.';
                }
                action("Create Item Journal Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Item Journal Lines';
                    Image = "Report";
                    RunObject = Report "Create Item Journal Lines";
                    ToolTip = 'Prepare to transfer legacy inventory balances to the newly configured company.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(ApplyData_Promoted; ApplyData)
                {
                }
                actionref(AssignPackage_Promoted; AssignPackage)
                {
                }
                actionref(MoveUp_Promoted; MoveUp)
                {
                }
                actionref(MoveDown_Promoted; MoveDown)
                {
                }
                actionref(PromotedOnly_Promoted; PromotedOnly)
                {
                }
            }
            group(Category_Prepare)
            {
                Caption = 'Prepare';

                group(Category_Excel)
                {
                    Caption = 'Excel';

                    actionref("Import from Template_Promoted"; "Import from Template")
                    {
                    }
                    actionref("Export to Template_Promoted"; "Export to Template")
                    {
                    }
                }
                actionref(CopyDataFromCompany_Promoted; CopyDataFromCompany)
                {
                }
                actionref("Get Tables_Promoted"; "Get Tables")
                {
                }
                actionref(GetRelatedTables_Promoted; GetRelatedTables)
                {
                }
                actionref(DeleteDuplicateLines_Promoted; DeleteDuplicateLines)
                {
                }
            }
            group(Category_Line)
            {
                Caption = 'Line';

                actionref(Fields_Promoted; Fields)
                {
                }
                actionref("Database Data_Promoted"; "Database Data")
                {
                }
                actionref(Filters_Promoted; Filters)
                {
                }
                actionref(PackageCard_Promoted; PackageCard)
                {
                }
                actionref(PackageData_Promoted; PackageData)
                {
                }
                actionref(Errors_Promoted; Errors)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Excel', Comment = 'Generated from the PromotedActionCategories property index 3.';

            }
            group(Category_Category5)
            {
                Caption = 'Show', Comment = 'Generated from the PromotedActionCategories property index 4.';

            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        NameIndent := 0;
        case Rec."Line Type" of
            Rec."Line Type"::Group:
                NameIndent := 1;
            Rec."Line Type"::Table:
                NameIndent := 2;
        end;

        NameEmphasize := (NameIndent in [0, 1]);
    end;

    trigger OnClosePage()
    var
        ConfigMgt: Codeunit "Config. Management";
    begin
        ConfigMgt.AssignParentLineNos();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        ConfigLine: Record "Config. Line";
    begin
        NextLineNo := 10000;
        ConfigLine.Reset();
        if ConfigLine.FindLast() then
            NextLineNo := ConfigLine."Line No." + 10000;

        ConfigLine.SetCurrentKey("Vertical Sorting");
        if BelowxRec then begin
            if ConfigLine.FindLast() then;
            Rec."Vertical Sorting" := ConfigLine."Vertical Sorting" + 1;
            Rec."Line No." := NextLineNo;
        end else begin
            NextVertNo := xRec."Vertical Sorting";

            ConfigLine.SetFilter("Vertical Sorting", '%1..', NextVertNo);
            if ConfigLine.Find('+') then
                repeat
                    ConfigLine."Vertical Sorting" := ConfigLine."Vertical Sorting" + 1;
                    ConfigLine.Modify();
                until ConfigLine.Next(-1) = 0;

            Rec."Line No." := NextLineNo;
            Rec."Vertical Sorting" := NextVertNo;
        end;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Line Type" := xRec."Line Type";
    end;

    trigger OnOpenPage()
    var
        ConfigPackageManagement: Codeunit "Config. Package Management";
    begin
        Rec.FilterGroup := 2;
        Rec.SetRange("Company Filter", CompanyName);
        Rec.FilterGroup := 0;
        ConfigPackageManagement.RemoveRecordsWithObsoleteTableID(
          DATABASE::"Config. Line", Rec.FieldNo("Table ID"));
    end;

    var
        ConfigPackageTable: Record "Config. Package Table";
        Show: Option Records,Errors,All;
        NameEmphasize: Boolean;
        NameIndent: Integer;
        NextLineNo: Integer;
        NextVertNo: Integer;
        NoPackageAssignedErr: Label 'You must assign a package code before you can carry out this action.';
        DifferentPackageCodeErr: Label 'You must select table lines with the same package code.';
        ApplyPackageDataQst: Label 'Do you want to apply package data for the selected tables?';
        ImportFromExcelQst: Label 'Do you want to import data from the Excel template?';
#pragma warning disable AA0470
        ExportToExcelQst: Label 'Do you want to export data from %1 tables to the Excel template?';
#pragma warning restore AA0470

    local procedure ExchangeLines(var ConfigLine1: Record "Config. Line"; var ConfigLine2: Record "Config. Line")
    var
        VertSort: Integer;
    begin
        VertSort := ConfigLine1."Vertical Sorting";
        ConfigLine1."Vertical Sorting" := ConfigLine2."Vertical Sorting";
        ConfigLine2."Vertical Sorting" := VertSort;
        ConfigLine1.Modify();
        ConfigLine2.Modify();
    end;

    local procedure AssignPackagePrompt(var ConfigLine: Record "Config. Line")
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageMgt: Codeunit "Config. Package Management";
        ConfigPackages: Page "Config. Packages";
    begin
        ConfigPackageMgt.CheckConfigLinesToAssign(ConfigLine);
        Clear(ConfigPackages);
        ConfigPackage.Init();
        ConfigPackages.LookupMode(true);
        if ConfigPackages.RunModal() = ACTION::LookupOK then begin
            ConfigPackages.GetRecord(ConfigPackage);
            ConfigPackageMgt.AssignPackage(ConfigLine, ConfigPackage.Code);
        end;
    end;

    local procedure CheckSelectedLines(var SelectedConfigLine: Record "Config. Line")
    var
        PackageCode: Code[20];
    begin
        PackageCode := '';
        if SelectedConfigLine.FindSet() then
            repeat
                SelectedConfigLine.CheckBlocked();
                if (SelectedConfigLine."Package Code" <> '') and
                   (SelectedConfigLine."Line Type" = SelectedConfigLine."Line Type"::Table) and
                   (SelectedConfigLine.Status <= SelectedConfigLine.Status::"In Progress")
                then begin
                    if PackageCode = '' then
                        PackageCode := SelectedConfigLine."Package Code"
                    else
                        if PackageCode <> SelectedConfigLine."Package Code" then
                            Error(DifferentPackageCodeErr);
                end else
                    if SelectedConfigLine."Package Code" = '' then
                        Error(NoPackageAssignedErr);
            until SelectedConfigLine.Next() = 0;
    end;

    local procedure GetConfigPackageTable(var ConfigPackageTable: Record "Config. Package Table")
    begin
        Rec.TestField("Table ID");
        if not ConfigPackageTable.Get(Rec."Package Code", Rec."Table ID") then
            Error(NoPackageAssignedErr);
    end;
}

