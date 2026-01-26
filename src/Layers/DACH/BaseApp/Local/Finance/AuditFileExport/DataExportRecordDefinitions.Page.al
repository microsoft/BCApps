// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

using System.Telemetry;

page 11003 "Data Export Record Definitions"
{
    Caption = 'Data Export Record Definitions';
    DataCaptionFields = "Data Export Code";
    PageType = List;
    SourceTable = "Data Export Record Definition";

    layout
    {
        area(content)
        {
            repeater(Control1140000)
            {
                ShowCaption = false;
                field("Data Export Code"; Rec."Data Export Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the data export that contains the record definition.';
                    Visible = false;
                }
                field("Data Exp. Rec. Type Code"; Rec."Data Exp. Rec. Type Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the data export record definition.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the data export record definition.';
                }
                field("DTD File Name"; Rec."DTD File Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the DTD file that is required for digital audit.';
                }
                field("File Encoding"; Rec."File Encoding")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'File Encoding';
                    ToolTip = 'Specifies the encoding of the data files to be imported.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Record Definition")
            {
                Caption = 'Record Definition';
                Image = XMLFile;
                action("Data Export Record Source")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Record Source';
                    Image = EditLines;
                    RunObject = Page "Data Export Record Source";
                    RunPageLink = "Data Export Code" = field("Data Export Code"),
                                  "Data Exp. Rec. Type Code" = field("Data Exp. Rec. Type Code");
                    RunPageView = sorting("Data Export Code", "Data Exp. Rec. Type Code", "Line No.");
                    ToolTip = 'View information about the tables for the a data export record definition.';
                }
                action(Validate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Validate';
                    Image = Approve;
                    ToolTip = 'Test the specified data before you export it.';

                    trigger OnAction()
                    var
                        DataExportRecordDefinition: Record "Data Export Record Definition";
                    begin
                        DataExportRecordDefinition.Get(Rec."Data Export Code", Rec."Data Exp. Rec. Type Code");
                        DataExportRecordDefinition.ValidateExportSources();
                    end;
                }
                action(Action1140010)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export';
                    Image = ExportFile;
                    ToolTip = 'Send the specified data to a file.';

                    trigger OnAction()
                    var
                        DataExportRecordDefinition: Record "Data Export Record Definition";
                        ExportBusinessData: Report "Export Business Data";
                        IsHandled: Boolean;
                    begin
                        DataExportRecordDefinition.Reset();
                        DataExportRecordDefinition.SetRange("Data Export Code", Rec."Data Export Code");
                        DataExportRecordDefinition.SetRange("Data Exp. Rec. Type Code", Rec."Data Exp. Rec. Type Code");
                        IsHandled := false;
                        OnActionExportOnBeforeExportBusinessData(DataExportRecordDefinition, IsHandled);
                        if IsHandled then
                            exit;
                        ExportBusinessData.SetTableView(DataExportRecordDefinition);
                        ExportBusinessData.Run();
                        Clear(ExportBusinessData);
                    end;
                }
            }
            group("DTD File")
            {
                Caption = 'DTD File';
                Image = XMLFile;
                action(Import)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import';
                    Image = Import;
                    ToolTip = 'Import a file with financial data and tax data according to the process for data access and testability of digital audit documents. ';

                    trigger OnAction()
                    begin
                        Rec.ImportFile(Rec);
                        CurrPage.Update();
                    end;
                }
                action(Export)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export';
                    Image = Export;
                    ToolTip = 'Send the specified data to a file.';

                    trigger OnAction()
                    begin
                        Rec.ExportFile(Rec, true);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(Validate_Promoted; Validate)
                {
                }
                actionref(Action1140010_Promoted; Action1140010)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Record Definition', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("Data Export Record Source_Promoted"; "Data Export Record Source")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'DTD File', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(Import_Promoted; Import)
                {
                }
                actionref(Export_Promoted; Export)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        DataTok: Label 'DACH Data Export', Locked = true;
    begin
        FeatureTelemetry.LogUptake('0001Q0N', DataTok, Enum::"Feature Uptake Status"::"Set up");
        MoveFiltersToFilterGroup(2);
    end;

    [Scope('OnPrem')]
    procedure MoveFiltersToFilterGroup(FilterGroupNo: Integer)
    var
        Filters: Text;
    begin
        Rec.FilterGroup(0);
        Filters := Rec.GetView();
        Rec.FilterGroup(FilterGroupNo);
        Rec.SetView(Filters);
        Rec.FilterGroup(0);
        Rec.SetView('');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnActionExportOnBeforeExportBusinessData(var DataExportRecordDefinition: Record "Data Export Record Definition"; var IsHandled: Boolean);
    begin
    end;
}

