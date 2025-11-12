namespace System.IO;

using System.Environment;
using System.Environment.Configuration;
using System.Telemetry;
using System.Utilities;

page 8615 "Config. Packages"
{
    AdditionalSearchTerms = 'rapidstart rapid start implementation migrate setup packages';
    ApplicationArea = Suite;
    Caption = 'Configuration Packages';
    CardPageID = "Config. Package Card";
    Editable = false;
    PageType = List;
    AboutTitle = 'About Configuration Packages';
    AboutText = 'Import, export, and validate company setup and master data using configuration packages, with support for mapping tables and fields, preparing data in Excel, and managing data migration processes to ensure data integrity.';
    SourceTable = "Config. Package";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the configuration package.';
                }
                field("Package Name"; Rec."Package Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the package.';
                }
                field("Language ID"; Rec."Language ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the Windows language to use for the configuration package. Choose the field and select a language ID from the list.';
                }
                field("Product Version"; Rec."Product Version")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the version of the product that you are configuring. You can use this field to help differentiate among various versions of a solution.';
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
                field("No. of Tables"; Rec."No. of Tables")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of tables that the package contains.';
                }
                field("No. of Records"; Rec."No. of Records")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of records in the package.';
                }
                field("No. of Errors"; Rec."No. of Errors")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of errors that the package contains.';
                }
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
                action(ImportPredefinedPackage)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import Predefined Package';
                    Ellipsis = true;
                    Image = Import;
                    ToolTip = 'Import one of the preloaded files with packages, such as Evaluation or Standard.';
                    Visible = ImportPredefinedPackageVisible;

                    trigger OnAction()
                    var
                        ConfigurationPackageFile: Record "Configuration Package File";
                        TempBlob: Codeunit "Temp Blob";
                        TempBlobUncompressed: Codeunit "Temp Blob";
                        ConfigurationPackageFiles: Page "Configuration Package Files";
                        InStream: InStream;
                    begin
                        ConfigurationPackageFiles.LookupMode(true);
                        if ConfigurationPackageFiles.RunModal() <> ACTION::LookupOK then
                            exit;

                        ConfigurationPackageFiles.GetRecord(ConfigurationPackageFile);
                        TempBlob.FromRecord(ConfigurationPackageFile, ConfigurationPackageFile.FieldNo(Package));
                        ConfigXMLExchange.DecompressPackageToBlob(TempBlob, TempBlobUncompressed);
                        TempBlobUncompressed.CreateInStream(InStream);
                        ConfigXMLExchange.ImportPackageXMLFromStream(InStream);
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
                        if ConfirmManagement.GetResponseOrDefault(StrSubstNo(ExportPackageQst, Rec.Code), true) then
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
                        ConfigExcelExchange.ImportExcelFromPackage();
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
                        ActiveSession: Record "Active Session";
                        SessionEvent: Record "Session Event";
                        ConfigProgressBar: Codeunit "Config. Progress Bar";
                        ConfirmManagement: Codeunit "Confirm Management";
                        Canceled: Boolean;
                    begin
                        if ConfirmManagement.GetResponseOrDefault(StrSubstNo(ValidatePackageQst, Rec."Package Name"), true) then begin
                            ConfigPackageTable.SetRange("Package Code", Rec.Code);
                            ConfigProgressBar.Init(ConfigPackageTable.Count, 1, ValidatingTableRelationsMsg);

                            BackgroundSessionId := 0;
                            StartSession(BackgroundSessionId, CODEUNIT::"Config. Validate Package", CompanyName, ConfigPackageTable);

                            ConfigPackageTable.SetRange(Validated, false);
                            ConfigPackageTable.SetCurrentKey("Package Processing Order", "Processing Order");

                            Sleep(1000);
                            while not Canceled and ActiveSession.Get(ServiceInstanceId(), BackgroundSessionId) and ConfigPackageTable.FindFirst() do begin
                                ConfigPackageTable.CalcFields("Table Name");
                                Canceled := not ConfigProgressBar.UpdateCount(ConfigPackageTable."Table Name", ConfigPackageTable.Count);
                                Sleep(1000);
                            end;

                            if ActiveSession.Get(ServiceInstanceId(), BackgroundSessionId) then
                                StopSession(BackgroundSessionId, ValidationCanceledMsg);

                            if not Canceled and ConfigPackageTable.FindFirst() then begin
                                SessionEvent.SetAscending("Event Datetime", true);
                                SessionEvent.SetRange("User ID", UserId);
                                SessionEvent.SetRange("Server Instance ID", ServiceInstanceId());
                                SessionEvent.SetRange("Session ID", BackgroundSessionId);
                                SessionEvent.FindLast();
                                Message(SessionEvent.Comment);
                            end;

                            ConfigProgressBar.Close();
                        end;
                    end;
                }
                action(ExportToTranslation)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export to Translation';
                    Image = Export;
                    ToolTip = 'Export the data to a file that is suited translation.';
                    Visible = false;

                    trigger OnAction()
                    var
                        ConfigPackageTable: Record "Config. Package Table";
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        Rec.TestField(Code);
                        ConfigXMLExchange.SetAdvanced(true);
                        ConfigPackageTable.SetRange("Package Code", Rec.Code);
                        if ConfirmManagement.GetResponseOrDefault(StrSubstNo(ExportPackageQst, Rec.Code), true) then
                            ConfigXMLExchange.ExportPackageXML(ConfigPackageTable, '');
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                group(Category_Import)
                {
                    Caption = 'Import';
                    ShowAs = SplitButton;

                    actionref(ImportPackage_Promoted; ImportPackage)
                    {
                    }
                    actionref(ImportFromExcel_Promoted; ImportFromExcel)
                    {
                    }
                    actionref(ImportPredefinedPackage_Promoted; ImportPredefinedPackage)
                    {
                    }
                }
                group(Category_Category5)
                {
                    Caption = 'Package', Comment = 'Generated from the PromotedActionCategories property index 4.';

                    actionref(ApplyPackage_Promoted; ApplyPackage)
                    {
                    }
                    actionref(ValidatePackage_Promoted; ValidatePackage)
                    {
                    }
                    actionref(CopyPackage_Promoted; CopyPackage)
                    {
                    }
                }
                group(Category_Export)
                {
                    Caption = 'Export';
                    ShowAs = SplitButton;

                    actionref(ExportPackage_Promoted; ExportPackage)
                    {
                    }
                    actionref(ExportToExcel_Promoted; ExportToExcel)
                    {
                    }
                }
                actionref(GetTables_Promoted; GetTables)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Manage', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnOpenPage()
    var
        ConfigurationPackageFile: Record "Configuration Package File";
        ConfigPackageMgt: Codeunit "Config. Package Management";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000E3A', 'Configuration packages', Enum::"Feature Uptake Status"::Discovered);
        ImportPredefinedPackageVisible := not ConfigurationPackageFile.IsEmpty();
        ConfigPackageMgt.ShowRapidStartNotification();
    end;

    var
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
#pragma warning disable AA0470
        ValidatePackageQst: Label 'Validate package %1?';
        ApplyDataConfirmMsg: Label 'Apply data from package %1?';
        ExportPackageQst: Label 'Export package %1?';
#pragma warning restore AA0470
        ValidatingTableRelationsMsg: Label 'Validating table relations';
        ValidationCanceledMsg: Label 'Validation canceled.';
        BackgroundSessionId: Integer;
        ImportPredefinedPackageVisible: Boolean;
}