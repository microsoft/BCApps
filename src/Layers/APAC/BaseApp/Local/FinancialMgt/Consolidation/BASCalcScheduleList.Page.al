// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Reporting;

page 11603 "BAS Calc. Schedule List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'BAS Calculation Sheets';
    CardPageID = "BAS Calculation Sheet";
    Editable = false;
    PageType = List;
    SourceTable = "BAS Calculation Sheet";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(A1; Rec.A1)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the BAS document number that is provided by the Australian Tax Office (ATO).';
                }
                field("BAS Version"; Rec."BAS Version")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the version number of the BAS document.';
                }
                field(A2; Rec.A2)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
                field(A3; Rec.A3)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start date of the Business Activity Statement (BAS) that is provided by the Australian Tax Office (ATO).';
                }
                field(A4; Rec.A4)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
                field(A5; Rec.A5)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
                field(A6; Rec.A6)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
                field(Exported; Rec.Exported)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the file has been exported.';
                }
                field("User Id"; Rec."User Id")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the person who performs the import or export of the XML file.';
                }
                field("Date of Export"; Rec."Date of Export")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the file was exported.';
                }
                field("Time of Export"; Rec."Time of Export")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the time that the file was exported.';
                }
                field("File Name"; Rec."File Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the file.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Import)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import';
                    Ellipsis = true;
                    Image = Import;
                    ToolTip = 'Exports the XML field IDs from the BAS - XML Field IDs Setup window.';

                    trigger OnAction()
                    begin
                        BASImportExport.SetBASCalcSheetRecord(Rec);
                        BASImportExport.SetDirection(0);
                        BASImportExport.RunModal();
                        BASImportExport.ReturnRecord(Rec);
                        Clear(BASImportExport);
                    end;
                }
                action(Update)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Update';
                    Ellipsis = true;
                    Image = Refresh;
                    ToolTip = 'Start the process of submitting an update of your business activity statement.';

                    trigger OnAction()
                    begin
                        BASMngmt.UpdateBAS(Rec);
                        Clear(BASMngmt);
                    end;
                }
                action(Export)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'E&xport';
                    Ellipsis = true;
                    Image = Export;
                    ToolTip = 'Exports the XML field IDs to the BAS - XML Field IDs Setup window.';

                    trigger OnAction()
                    begin
                        BASImportExport.SetBASCalcSheetRecord(Rec);
                        BASImportExport.SetDirection(1);
                        BASImportExport.RunModal();
                        BASImportExport.ReturnRecord(Rec);
                        Clear(BASImportExport);
                    end;
                }
                separator(Action150004)
                {
                    Caption = '';
                }
                action(CalculateGSTSettlement)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calculate GST Settlement';
                    Image = CalculateSalesTax;
                    ToolTip = 'Start the process of calculating the GST settlement.';

                    trigger OnAction()
                    begin
                        BASCalcSheet.Reset();
                        BASCalcSheet.SetRange(A1, Rec.A1);
                        BASCalcSheet.SetRange("BAS Version", Rec."BAS Version");
                        REPORT.RunModal(REPORT::"Calculate GST Settlement", true, false, BASCalcSheet);
                    end;
                }
                action("GST Purchase Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'GST Purchase Entries';
                    RunObject = Page "GST Purchase Entries";
                    ToolTip = 'Start the process of creating the GST Purchase report.';
                }
                action("GST Sales Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'GST Sales Entries';
                    RunObject = Page "GST Sales Entries";
                    ToolTip = 'Start the process of creating the GST Sales report.';
                }
            }
        }
        area(reporting)
        {
            action("GST Purchase Report")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'GST Purchase Report';
                Image = "Report";
                RunObject = Report "GST Purchase Report";
                ToolTip = 'Start the process of creating the GST Purchase report.';
            }
            action("GST Sales Report")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'GST Sales Report';
                Image = "Report";
                RunObject = Report "GST Sales Report";
                ToolTip = 'Start the process of creating the GST Sales report.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Import_Promoted; Import)
                {
                }
                actionref(Update_Promoted; Update)
                {
                }
                actionref(Export_Promoted; Export)
                {
                }
                actionref(CalculateGSTSettlement_Promoted; CalculateGSTSettlement)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("GST Purchase Report_Promoted"; "GST Purchase Report")
                {
                }
                actionref("GST Sales Report_Promoted"; "GST Sales Report")
                {
                }
            }
        }
    }

    var
        BASCalcSheet: Record "BAS Calculation Sheet";
        BASImportExport: Report "BAS - Import/Export";
        BASMngmt: Codeunit "BAS Management";
}

