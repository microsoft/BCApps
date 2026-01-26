// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Reporting;

page 11609 "BAS Setup Preview"
{
    Caption = 'BAS Setup Preview';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    SourceTable = "BAS Setup Name";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies a name according to the requirements for setting up the BAS configuration rules.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the descriptive term for the Business Activity Statement (BAS) Name.';
                }
                field("Date Filter"; Rec."Date Filter")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date filter that is associated with the business activity statement (BAS) setup name.';

                    trigger OnValidate()
                    begin
                        UpdateSubForm();
                    end;
                }
                field(Selection; Selection)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Include GST entries';
                    ToolTip = 'Specifies that you want to include GST entries in the BAS.';

                    trigger OnValidate()
                    begin
                        SelectionOnAfterValidate();
                    end;
                }
                field(PeriodSelection; PeriodSelection)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Include GST entries';
                    ToolTip = 'Specifies that you want to include GST entries in the BAS.';

                    trigger OnValidate()
                    begin
                        PeriodSelectionOnAfterValidate();
                    end;
                }
                field(ExcludeClosingEntries; ExcludeClosingEntries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Exclude Closing Entries';
                    Enabled = ExcludeClosingEntriesEnable;
                    ToolTip = 'Specifies that you want to exclude closing entries from the report.';

                    trigger OnValidate()
                    begin
                        ExcludeClosingEntriesOnAfterVa();
                    end;
                }
            }
            part(BASSetupPreviewSubform; "BAS Setup Preview Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Setup Name" = field(Name);
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Export to Excel")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export to Excel';
                Image = ExportToExcel;
                ToolTip = 'Export the data to Excel for manual adjustment.';

                trigger OnAction()
                var
                    BASSetup: Record "BAS Setup";
                begin
                    BASSetup.SetFilter("Setup Name", Rec.Name);
                    ExportBASSetupReport.SetValues(BASCalcSheet, Selection, PeriodSelection, ExcludeClosingEntries, BASCalcSheet.A1,
                      BASCalcSheet."BAS Version");
                    ExportBASSetupReport.SetTableView(BASSetup);
                    ExportBASSetupReport.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Export to Excel_Promoted"; "Export to Excel")
                {
                }
            }
        }
    }

    trigger OnInit()
    begin
        ExcludeClosingEntriesEnable := true;
    end;

    trigger OnOpenPage()
    begin
        UpdateSubForm();
    end;

    var
        BASCalcSheet: Record "BAS Calculation Sheet";
        ExportBASSetupReport: Report "Export BAS Setup to Excel";
        Selection: Enum "VAT Statement Report Selection";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        ExcludeClosingEntries: Boolean;
        ExcludeClosingEntriesEnable: Boolean;
        YouCannotPreviewErr: Label 'You cannot preview a %1 %2.', Comment = '%1 - Consolidated field; %2 - BAS Calculation Seeet table';

    [Scope('OnPrem')]
    procedure UpdateSubForm()
    begin
        ExcludeClosingEntriesEnable := PeriodSelection = PeriodSelection::"Before and Within Period";
        if ExcludeClosingEntriesEnable = false then
            ExcludeClosingEntries := false;
        CurrPage.BASSetupPreviewSubform.PAGE.SetValues(BASCalcSheet, Selection, PeriodSelection, ExcludeClosingEntries, BASCalcSheet.A1,
          BASCalcSheet."BAS Version");
    end;

    [Scope('OnPrem')]
    procedure SetBASCalcSheet(var NewBASCalcSheet: Record "BAS Calculation Sheet"; var NewBASSetupName: Record "BAS Setup Name")
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        if NewBASCalcSheet.Consolidated and not GLSetup."BAS Group Company" then
            Error(YouCannotPreviewErr, NewBASCalcSheet.FieldCaption(Consolidated), NewBASCalcSheet.TableCaption());
        BASCalcSheet.Copy(NewBASCalcSheet);
        Rec.SetRange(Name, NewBASSetupName.Name);
        Rec.SetRange("Date Filter", NewBASCalcSheet.A3, NewBASCalcSheet.A4);
    end;

    local procedure ExcludeClosingEntriesOnAfterVa()
    begin
        UpdateSubForm();
    end;

    local procedure SelectionOnAfterValidate()
    begin
        UpdateSubForm();
    end;

    local procedure PeriodSelectionOnAfterValidate()
    begin
        UpdateSubForm();
    end;
}

