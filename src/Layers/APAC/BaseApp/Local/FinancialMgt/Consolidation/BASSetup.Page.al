// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.GeneralLedger.Setup;

page 11600 "BAS Setup"
{
    AutoSplitKey = true;
    Caption = 'BAS Setup';
    DelayedInsert = true;
    PageType = Worksheet;
    SourceTable = "BAS Setup";

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(CurrentBASSetupNameCtrl; CurrentBASSetupName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Setup Name';
                    Editable = CurrentBASSetupNameCtrlEditabl;
                    Lookup = true;
                    ToolTip = 'Specifies the BAS setup name that you want to use.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        if CurrentBASSetupNameCtrlEditabl then begin
                            CurrPage.SaveRecord();
                            BASMngmt.LookupBASSetupName(CurrentBASSetupName, Rec);
                            CurrPage.Update(false);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        BASMngmt.CheckBASSetupName(CurrentBASSetupName);
                        CurrentBASSetupNameOnAfterVali();
                    end;
                }
                field(BASIdNoCtrl; BASIdNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'BAS ID.No.';
                    Editable = BASIdNoCtrlEditable;
                    ToolTip = 'Specifies the document number from the BAS Calculation Sheet table.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        BASCalcSheet: Record "BAS Calculation Sheet";
                    begin
                        if BASIdNoCtrlEditable then begin
                            BASCalcSheet.Reset();
                            if PAGE.RunModal(0, BASCalcSheet, BASCalcSheet.A1) = ACTION::LookupOK then begin
                                BASIdNo := BASCalcSheet.A1;
                                BASVersionNo := BASCalcSheet."BAS Version";
                            end;
                        end;
                    end;
                }
                field(BASVersionNoCtrl; BASVersionNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'BAS Version';
                    Editable = BASVersionNoCtrlEditable;
                    ToolTip = 'Specifies the Business Activity Statement (BAS) version number that you want to use.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        BASCalcSheet: Record "BAS Calculation Sheet";
                    begin
                        if BASVersionNoCtrlEditable then begin
                            BASCalcSheet.SetRange(A1, BASIdNo);
                            if PAGE.RunModal(0, BASCalcSheet, BASCalcSheet."BAS Version") = ACTION::LookupOK then
                                BASVersionNo := BASCalcSheet."BAS Version";
                        end;
                    end;
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Row No."; Rec."Row No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number for the BAS Setup line.';
                }
                field("Field No."; Rec."Field No.")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = "BAS Calc. Schedule Fields";
                    ToolTip = 'Specifies the internal program number that corresponds with the Field Label No., contained within the XML file received from the ATO.';
                }
                field("Field Label No."; Rec."Field Label No.")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the BAS Field Label, in both the xml file from the Australian Tax Office''s ECI Software and the ATO''s BAS Instructions.';
                }
                field("Field Description"; Rec."Field Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Business Activity Statement (BAS) Field Label Description.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies what the entries in the BAS line will include.';
                }
                field("Account Totaling"; Rec."Account Totaling")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an account interval or a series of account numbers.';
                }
                field("Gen. Posting Type"; Rec."Gen. Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a general posting type that will be used with the BAS.';
                }
                field("GST Bus. Posting Group"; Rec."GST Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a VAT business posting group code for the BAS.';
                }
                field("GST Prod. Posting Group"; Rec."GST Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that you can enter a VAT product posting group code for the BAS.';
                }
                field("Amount Type"; Rec."Amount Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the totaling of entries will consist of VAT amounts, or the amounts on which the VAT is based on.';
                }
                field("Row Totaling"; Rec."Row Totaling")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that you can enter a row-number interval, or a series of row numbers.';
                }
                field("Calculate with"; Rec."Calculate with")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to reverse the sign of the entries when calculations are made.';
                }
                field("BAS Adjustment"; Rec."BAS Adjustment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you would like the system to filter on transactions that are BAS Adjustments only.';
                }
                field(Print; Rec.Print)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the row number is printed on the BAS.';
                }
                field("Print with"; Rec."Print with")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the BAS is printed using the reverse sign from the entries, when the goods and services tax (GST) calculation is performed.';
                }
                field("New Page"; Rec."New Page")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if a new page is printed after each row of the BAS.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Preview)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Preview';
                Image = "Report";
                ToolTip = 'View a preview of the BAS.';

                trigger OnAction()
                var
                    BASCalcSheet: Record "BAS Calculation Sheet";
                    BASSetupPreview: Page "BAS Setup Preview";
                begin
                    BASCalcSheet.Get(BASIdNo, BASVersionNo);
                    BASSetupName.Get(Rec."Setup Name");
                    BASSetupPreview.SetBASCalcSheet(BASCalcSheet, BASSetupName);
                    BASSetupPreview.RunModal();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Preview_Promoted; Preview)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        AfterGetCurrentRecord();
    end;

    trigger OnInit()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        CurrentBASSetupNameCtrlEditabl := true;
        BASVersionNoCtrlEditable := true;
        BASIdNoCtrlEditable := true;
        GLSetup.Get();
        GLSetup.TestField("Enable GST (Australia)", true);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        AfterGetCurrentRecord();
    end;

    var
        BASSetupName: Record "BAS Setup Name";
        BASMngmt: Codeunit "BAS Management";
        CurrentBASSetupName: Code[20];
        BASIdNo: Code[11];
        BASVersionNo: Integer;
        BASIdNoCtrlEditable: Boolean;
        BASVersionNoCtrlEditable: Boolean;
        CurrentBASSetupNameCtrlEditabl: Boolean;

    [Scope('OnPrem')]
    procedure SetValues(NewBASIdNo: Code[11]; NewBASVerNo: Integer)
    begin
        BASIdNo := NewBASIdNo;
        BASVersionNo := NewBASVerNo;
        BASIdNoCtrlEditable := false;
        BASVersionNoCtrlEditable := false;
        CurrentBASSetupNameCtrlEditabl := false;
    end;

    local procedure CurrentBASSetupNameOnAfterVali()
    begin
        CurrPage.SaveRecord();
        BASMngmt.SetBASSetupName(CurrentBASSetupName, Rec);
        CurrPage.Update(false);
    end;

    local procedure AfterGetCurrentRecord()
    begin
        xRec := Rec;
        CurrentBASSetupName := Rec."Setup Name";
    end;
}

