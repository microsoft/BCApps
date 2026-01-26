// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Reporting;

page 11601 "BAS Calculation Sheet"
{
    Caption = 'BAS Calculation Sheet';
    PageType = Card;
    Permissions = TableData "BAS Calculation Sheet" = rm;
    SourceTable = "BAS Calculation Sheet";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(A1; Rec.A1)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
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
                field(A2a; Rec.A2a)
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
                field("BAS Setup Name"; Rec."BAS Setup Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the Business Activity Statement (BAS) setup information that was used to populate the BAS calculation sheet.';
                }
                field(Exported; Rec.Exported)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the file has been exported.';
                }
                field(Updated; Rec.Updated)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the field is checked when the user has run the Update function.';
                }
                field(Consolidated; Rec.Consolidated)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if there has been a consolidation performed on the nominated entity required for reporting VAT.';
                }
                field("Group Consolidated"; Rec."Group Consolidated")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the BAS was included in the group consolidated BAS.';
                }
                field(Settled; Rec.Settled)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the corresponding BAS calculation sheet report was settled after running the calculate VAT settlement function.';
                }
            }
            group(Totals)
            {
                Caption = 'Totals';
                field("1A"; Rec."1A")
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(Rec.FieldName("1A"));
                    end;
                }
                field("1C"; Rec."1C")
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(Rec.FieldName("1C"));
                    end;
                }
                field("1E"; Rec."1E")
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(Rec.FieldName("1E"));
                    end;
                }
                field("4"; Rec."4")
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(Rec.FieldName("4"));
                    end;
                }
                field("1B"; Rec."1B")
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(Rec.FieldName("1B"));
                    end;
                }
                field("1D"; Rec."1D")
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(Rec.FieldName("1D"));
                    end;
                }
                field("1F"; Rec."1F")
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(Rec.FieldName("1F"));
                    end;
                }
                field("1G"; Rec."1G")
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(Rec.FieldName("1G"));
                    end;
                }
                field("1H"; Rec."1H")
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
                field("5B"; Rec."5B")
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(Rec.FieldName("5B"));
                    end;
                }
                field("6B"; Rec."6B")
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(Rec.FieldName("6B"));
                    end;
                }
                field("7C"; Rec."7C")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
                field("7D"; Rec."7D")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
            }
            group(GST)
            {
                Caption = 'GST';
                field(G1; Rec.G1)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(Rec.FieldName(G1));
                    end;
                }
                field(G2; Rec.G2)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(Rec.FieldName(G2));
                    end;
                }
                field(G3; Rec.G3)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(Rec.FieldName(G3));
                    end;
                }
                field(G4; Rec.G4)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(Rec.FieldName(G4));
                    end;
                }
                field(G7; Rec.G7)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(Rec.FieldName(G7));
                    end;
                }
                field(G9; Rec.G9)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
                field(G10; Rec.G10)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(Rec.FieldName(G10));
                    end;
                }
                field(G11; Rec.G11)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(Rec.FieldName(G11));
                    end;
                }
                field(G13; Rec.G13)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(Rec.FieldName(G13));
                    end;
                }
                field(G14; Rec.G14)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(Rec.FieldName(G14));
                    end;
                }
                field(G15; Rec.G15)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(Rec.FieldName(G15));
                    end;
                }
                field(G18; Rec.G18)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(Rec.FieldName(G18));
                    end;
                }
                field(G20; Rec.G20)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
                field(G22; Rec.G22)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
                field(G24; Rec.G24)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
            }
            group("Amounts Withheld")
            {
                Caption = 'Amounts Withheld';
                field(W1; Rec.W1)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(Rec.FieldName(W1));
                    end;
                }
                field(W2; Rec.W2)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(Rec.FieldName(W2));
                    end;
                }
                field(W3; Rec.W3)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(Rec.FieldName(W3));
                    end;
                }
                field(W4; Rec.W4)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(Rec.FieldName(W4));
                    end;
                }
            }
            group("Income Tax Installment")
            {
                Caption = 'Income Tax Installment';
                field(T1; Rec.T1)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(Rec.FieldName(T1));
                    end;
                }
                field(T2; Rec.T2)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
                field(T3; Rec.T3)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
                field(T4; Rec.T4)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
                field(T8; Rec.T8)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
                field(T9; Rec.T9)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
            }
            group("FBT Installment")
            {
                Caption = 'FBT Installment';
                field(F1; Rec.F1)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
                field(F2; Rec.F2)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
                field(F4; Rec.F4)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&BAS Calculation Sheet")
            {
                Caption = '&BAS Calculation Sheet';
                Image = CalculateVAT;
                action("BAS Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'BAS Setup';
                    Image = VATStatement;
                    ToolTip = 'View or edit the business activity statement (BAS) configuration information.';

                    trigger OnAction()
                    var
                        BASSetup: Record "BAS Setup";
                        BASSetupForm: Page "BAS Setup";
                    begin
                        Rec.TestField("BAS Setup Name");
                        BASSetup.FilterGroup(2);
                        BASSetup.SetRange("Setup Name", Rec."BAS Setup Name");
                        BASSetup.FilterGroup(0);
                        BASSetupForm.SetTableView(BASSetup);
                        BASSetupForm.SetValues(Rec.A1, Rec."BAS Version");
                        BASSetupForm.RunModal();
                    end;
                }
                action(Comment)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Comment';
                    Image = ViewComments;
                    RunObject = Page "BAS Comment Lines";
                    RunPageLink = "No." = field(A1),
                                  "Version No." = field("BAS Version");
                    ToolTip = 'Specifies an optional comment for this entry.';
                }
            }
        }
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
                action("E&xport")
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
                separator(Action214)
                {
                    Caption = '';
                }
                action("Calculate GST Settlement")
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
                actionref("E&xport_Promoted"; "E&xport")
                {
                }
                actionref("Calculate GST Settlement_Promoted"; "Calculate GST Settlement")
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

    trigger OnInit()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.TestField("Enable GST (Australia)", true);
    end;

    var
        BASCalcSheetEntry: Record "BAS Calc. Sheet Entry";
        BASCalcSheet: Record "BAS Calculation Sheet";
        BASMngmt: Codeunit "BAS Management";
        BASImportExport: Report "BAS - Import/Export";

    local procedure BASEntryDrillDown(FieldID: Text[30])
    begin
        BASCalcSheetEntry.Reset();
        if Rec."Group Consolidated" then begin
            BASCalcSheetEntry.SetCurrentKey("Consol. BAS Doc. No.", "Consol. Version No.");
            BASCalcSheetEntry.SetRange("Consol. BAS Doc. No.", Rec.A1);
            BASCalcSheetEntry.SetRange("Consol. Version No.", Rec."BAS Version");
        end else begin
            BASCalcSheetEntry.SetRange("Company Name", CompanyName);
            BASCalcSheetEntry.SetRange("BAS Document No.", Rec.A1);
            BASCalcSheetEntry.SetRange("BAS Version", Rec."BAS Version");
        end;
        BASCalcSheetEntry.SetRange("Field Label No.", FieldID);
        PAGE.RunModal(PAGE::"BAS Calc. Sheet Entries", BASCalcSheetEntry);
    end;
}

