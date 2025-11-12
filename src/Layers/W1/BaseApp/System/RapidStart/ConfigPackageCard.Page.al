namespace System.IO;

using Microsoft.Finance.Dimension;
using System.Telemetry;
using System.Utilities;

page 8614 "Config. Package Card"
{
    Caption = 'Config. Package Card';
    PageType = Document;
    SourceTable = "Config. Package";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies a code for the configuration package.';
                }
                field("Package Name"; Rec."Package Name")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the name of the package.';
                }
                field("Product Version"; Rec."Product Version")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the version of the product that you are configuring. You can use this field to help differentiate among various versions of a solution.';
                }
                field("Language ID"; Rec."Language ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the Windows language to use for the configuration package. Choose the field and select a language ID from the list.';
                }
                field("Processing Order"; Rec."Processing Order")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the order in which the package is to be processed.';
                }
                field("Exclude Config. Tables"; Rec."Exclude Config. Tables")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to exclude configuration tables from the package. Select the check box to exclude these types of tables.';
                }
            }
            group(Errors)
            {
                Caption = 'Errors';
                Visible = IsErrorTabVisible;
                field("No. of Errors"; Rec."No. of Errors")
                {
                    ApplicationArea = Basic, Suite;
                    Style = Unfavorable;
                    StyleExpr = true;
                    ToolTip = 'Specifies the count of package errors. One line reflects one field of a record that failed validation.';
                }
            }
            part(Control10; "Config. Package Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Package Code" = field(Code);
                SubPageView = sorting("Package Code", "Table ID");
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Package)
            {
                Caption = 'Package';

                action(GetTables)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Get Tables';
                    Ellipsis = true;
                    Image = GetLines;
                    ToolTip = 'Select tables that you want to add to the configuration package.';

                    trigger OnAction()
                    var
                        GetPackageTables: Report "Get Package Tables";
                    begin
                        CurrPage.SaveRecord();
                        GetPackageTables.Set(Rec.Code);
                        GetPackageTables.RunModal();
                        Clear(GetPackageTables);
                    end;
                }
                action(ExportPackage)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Package';
                    Ellipsis = true;
                    Image = Export;
                    ToolTip = 'Create a .rapidstart file that which delivers the package contents in a compressed format. Configuration questionnaires, configuration templates, and the configuration worksheet are added to the package automatically unless you specifically decide to exclude them.';

                    trigger OnAction()
                    begin
                        Rec.TestField(Code);
                        ConfigXMLExchange.ExportPackage(Rec);
                    end;
                }
                action(ImportPackage)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import Package';
                    Ellipsis = true;
                    Image = Import;
                    ToolTip = 'Import a .rapidstart package file.';

                    trigger OnAction()
                    begin
                        ConfigXMLExchange.ImportPackageXMLFromClient();
                    end;
                }
                action(ExportToExcel)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export to Excel';
                    Image = ExportToExcel;
                    ToolTip = 'Export the data in the package to Excel.';

                    trigger OnAction()
                    var
                        ConfigPackageTable: Record "Config. Package Table";
                        ConfigExcelExchange: Codeunit "Config. Excel Exchange";
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        Rec.TestField(Code);

                        ConfigPackageTable.SetRange("Package Code", Rec.Code);
                        if ConfirmManagement.GetResponseOrDefault(StrSubstNo(ExportPackageQst, Rec.Code, ConfigPackageTable.Count), true) then
                            ConfigExcelExchange.ExportExcelFromTables(ConfigPackageTable);
                    end;
                }
                action(ImportFromExcel)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import from Excel';
                    Image = ImportExcel;
                    ToolTip = 'Begin the migration of legacy data.';

                    trigger OnAction()
                    var
                        ConfigExcelExchange: Codeunit "Config. Excel Exchange";
                    begin
                        ConfigExcelExchange.ImportExcelFromSelectedPackage(Rec.Code);
                    end;
                }
                action(ShowError)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Errors';
                    Image = ErrorLog;
                    ToolTip = 'Open the list of package errors.';
                    Visible = IsErrorTabVisible;

                    trigger OnAction()
                    begin
                        Rec.ShowErrors();
                    end;
                }
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';

                action(ApplyPackage)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply Package';
                    Image = Apply;
                    ToolTip = 'Import the configuration package and apply the package database data at the same time.';

                    trigger OnAction()
                    var
                        ConfigPackageTable: Record "Config. Package Table";
                        ConfigPackageMgt: Codeunit "Config. Package Management";
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        Rec.TestField(Code);
                        if ConfirmManagement.GetResponseOrDefault(StrSubstNo(ApplyDataConfirmMsg, Rec.Code), true) then begin
                            ConfigPackageTable.SetRange("Package Code", Rec.Code);
                            ConfigPackageMgt.ApplyPackage(Rec, ConfigPackageTable, true);
                        end;
                    end;
                }
                action(CopyPackage)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Package';
                    Image = CopyWorksheet;
                    ToolTip = 'Copy an existing configuration package to create a new package based on the same content.';

                    trigger OnAction()
                    var
                        CopyPackage: Report "Copy Package";
                    begin
                        Rec.TestField(Code);
                        CopyPackage.Set(Rec);
                        CopyPackage.RunModal();
                        Clear(CopyPackage);
                    end;
                }
                action(ValidatePackage)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Validate Package';
                    Image = CheckRulesSyntax;
                    ToolTip = 'Determine if you have introduced errors, such as not including tables that the configuration relies on.';

                    trigger OnAction()
                    var
                        ConfigPackageTable: Record "Config. Package Table";
                        TempConfigPackageTable: Record "Config. Package Table" temporary;
                        ConfigPackageMgt: Codeunit "Config. Package Management";
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        if ConfirmManagement.GetResponseOrDefault(StrSubstNo(ValidatePackageQst, Rec."Package Name"), true) then begin
                            ConfigPackageTable.SetRange("Package Code", Rec.Code);
                            ConfigPackageMgt.ValidatePackageRelations(ConfigPackageTable, TempConfigPackageTable, true);
                        end;
                    end;
                }
                action(ExportToTranslation)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export to Translation';
                    Image = Export;
                    ToolTip = 'Export the data to a file that is suited for translation.';
                    Visible = false;

                    trigger OnAction()
                    var
                        ConfigPackageTable: Record "Config. Package Table";
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        Rec.TestField(Code);

                        ConfigXMLExchange.SetAdvanced(true);
                        ConfigPackageTable.SetRange("Package Code", Rec.Code);
                        if ConfirmManagement.GetResponseOrDefault(StrSubstNo(ExportPackageQst, Rec.Code, ConfigPackageTable.Count), true) then
                            ConfigXMLExchange.ExportPackageXML(ConfigPackageTable, '');
                    end;
                }
                action(ProcessData)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Process Data';
                    Image = DataEntry;
                    ToolTip = 'Process data in the configuration package before you apply it to the database. For example, convert dates and decimals to the format required by the regional settings on a user''s computer and remove leading/trailing spaces or special characters.';

                    trigger OnAction()
                    begin
                        ProcessPackageTablesWithDefaultProcessingReport();
                        ProcessPackageTablesWithCustomProcessingReports();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(ApplyPackage_Promoted; ApplyPackage)
                {
                }
                actionref(ValidatePackage_Promoted; ValidatePackage)
                {
                }
                group(Category_Import)
                {
                    Caption = 'Import';
                    ShowAs = SplitButton;

                    actionref(ImportFromExcel_Promoted; ImportFromExcel)
                    {
                    }
                    actionref(ImportPackage_Promoted; ImportPackage)
                    {
                    }
                }
                group(Category_Export)
                {
                    Caption = 'Export';
                    ShowAs = SplitButton;

                    actionref(ExportToExcel_Promoted; ExportToExcel)
                    {
                    }
                    actionref(ExportPackage_Promoted; ExportPackage)
                    {
                    }
                }
                actionref(GetTables_Promoted; GetTables)
                {
                }
                actionref(ShowError_Promoted; ShowError)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Manage', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
            group(Category_Category5)
            {
                Caption = 'Package', Comment = 'Generated from the PromotedActionCategories property index 4.';

            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnOpenPage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        DimensionsNotifications: Codeunit "Dimensions Notifications";
    begin
        FeatureTelemetry.LogUptake('0000E3C', 'Configuration packages', Enum::"Feature Uptake Status"::Discovered);
        DimensionsNotifications.SendConfigPackageNotificationIfEligible(Rec.Code);
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("No. of Errors");
        IsErrorTabVisible := Rec."No. of Errors" > 0;
    end;

    var
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
#pragma warning disable AA0470
        ValidatePackageQst: Label 'Validate package %1?';
#pragma warning restore AA0470
#pragma warning disable AA0470
        ApplyDataConfirmMsg: Label 'Apply data from package %1?';
#pragma warning restore AA0470
#pragma warning disable AA0470
        ExportPackageQst: Label 'Export package %1 with %2 tables?';
#pragma warning restore AA0470
        IsErrorTabVisible: Boolean;

    local procedure ProcessPackageTablesWithDefaultProcessingReport()
    var
        ConfigPackageTable: Record "Config. Package Table";
    begin
        ConfigPackageTable.SetRange("Package Code", Rec.Code);
        ConfigPackageTable.SetRange("Processing Report ID", 0);
        if not ConfigPackageTable.IsEmpty() then
            REPORT.RunModal(REPORT::"Config. Package - Process", false, false, ConfigPackageTable);
    end;

    local procedure ProcessPackageTablesWithCustomProcessingReports()
    var
        ConfigPackageTable: Record "Config. Package Table";
    begin
        ConfigPackageTable.SetRange("Package Code", Rec.Code);
        ConfigPackageTable.SetFilter("Processing Report ID", '<>0', 0);
        if ConfigPackageTable.FindSet() then
            repeat
                REPORT.RunModal(ConfigPackageTable."Processing Report ID", false, false, ConfigPackageTable)
            until ConfigPackageTable.Next() = 0;
    end;
}

