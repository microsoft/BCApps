// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Payables;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Preview;

page 5239 "Empl. Ledger Entries Preview"
{
    Caption = 'Employee Entries Preview';
    DataCaptionFields = "Employee No.";
    Editable = false;
    PageType = List;
    SourceTable = "Employee Ledger Entry";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the employee entry''s posting date.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the document type that the employee entry belongs to.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the employee entry''s document number.';
                }
                field("Employee No."; Rec."Employee No.")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the number of the employee that the entry is linked to.';
                }
                field("Message to Recipient"; Rec."Message to Recipient")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the message exported to the payment file when you use the Export Payments to File function in the Payment Journal window.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies a description of the employee entry.';
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the payment method that was used to make the payment that resulted in the entry.';
                }
                field(OriginalAmountFCY; OriginalAmountFCY)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Original Amount';
                    Editable = false;
                    ToolTip = 'Specifies the amount on the employee ledger entry before you post.';

                    trigger OnDrillDown()
                    begin
                        DrilldownAmounts(2);
                    end;
                }
                field(OriginalAmountLCY; OriginalAmountLCY)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Original Amount (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the amount, in local currency, on the employee ledger entry before you post.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        DrilldownAmounts(2);
                    end;
                }
                field(AmountFCY; AmountFCY)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Amount';
                    Editable = false;
                    ToolTip = 'Specifies the net amount of all the lines in the employee entry.';

                    trigger OnDrillDown()
                    begin
                        DrilldownAmounts(0);
                    end;
                }
                field(AmountLCY; AmountLCY)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Amount (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the amount, in local currency, relating to the employee ledger entry';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        DrilldownAmounts(0);
                    end;
                }
                field(RemainingAmountFCY; RemainingAmountFCY)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Remaining Amount';
                    Editable = false;
                    ToolTip = 'Specifies the remaining amount on the employee ledger entry before you post.';

                    trigger OnDrillDown()
                    begin
                        DrilldownAmounts(1);
                    end;
                }
                field(RemainingAmountLCY; RemainingAmountLCY)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Remaining Amount (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the remaining amount, in local currency, on the employee ledger entry before you post.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        DrilldownAmounts(1);
                    end;
                }
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    ToolTip = 'Specifies the type of balancing account that is used for the entry.';
                    Visible = false;
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    ToolTip = 'Specifies the number of the balancing account that is used for the entry.';
                    Visible = false;
                }
                field(Open; Rec.Open)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies whether the amount on the entry has been fully paid or there is still a remaining amount that must be applied to.';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the entry number that is assigned to the entry.';
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = Dim1Visible;
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = Dim2Visible;
                }
                field("Shortcut Dimension 3 Code"; Rec."Shortcut Dimension 3 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 3, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim3Visible;
                }
                field("Shortcut Dimension 4 Code"; Rec."Shortcut Dimension 4 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 4, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim4Visible;
                }
                field("Shortcut Dimension 5 Code"; Rec."Shortcut Dimension 5 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 5, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim5Visible;
                }
                field("Shortcut Dimension 6 Code"; Rec."Shortcut Dimension 6 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 6, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim6Visible;
                }
                field("Shortcut Dimension 7 Code"; Rec."Shortcut Dimension 7 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 7, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim7Visible;
                }
                field("Shortcut Dimension 8 Code"; Rec."Shortcut Dimension 8 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 8, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim8Visible;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Ent&ry")
            {
                Caption = 'Ent&ry';
                Image = Entry;
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Ellipsis = true;
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    var
                        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
                    begin
                        GenJnlPostPreview.ShowDimensions(DATABASE::"Employee Ledger Entry", Rec."Entry No.", Rec."Dimension Set ID");
                    end;
                }
                action(SetDimensionFilter)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Set Dimension Filter';
                    Ellipsis = true;
                    Image = "Filter";
                    ToolTip = 'Limit the entries according to the dimension filters that you specify. NOTE: If you use a high number of dimension combinations, this function may not work and can result in a message that the SQL server only supports a maximum of 2100 parameters.';

                    trigger OnAction()
                    begin
                        Rec.SetFilter("Dimension Set ID", DimensionSetIDFilter.LookupFilter());
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalcAmounts(AmountFCY, AmountLCY, RemainingAmountFCY, RemainingAmountLCY, OriginalAmountFCY, OriginalAmountLCY);
    end;

    trigger OnOpenPage()
    begin
        SetDimVisibility();
    end;

    var
        TempDetailedEmplLedgEntry: Record "Detailed Employee Ledger Entry" temporary;
        DimensionSetIDFilter: Page "Dimension Set ID Filter";
        AmountFCY: Decimal;
        AmountLCY: Decimal;
        RemainingAmountFCY: Decimal;
        RemainingAmountLCY: Decimal;
        OriginalAmountLCY: Decimal;
        OriginalAmountFCY: Decimal;

    protected var
        Dim1Visible: Boolean;
        Dim2Visible: Boolean;
        Dim3Visible: Boolean;
        Dim4Visible: Boolean;
        Dim5Visible: Boolean;
        Dim6Visible: Boolean;
        Dim7Visible: Boolean;
        Dim8Visible: Boolean;

    local procedure SetDimVisibility()
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        DimensionManagement.UseShortcutDims(Dim1Visible, Dim2Visible, Dim3Visible, Dim4Visible, Dim5Visible, Dim6Visible, Dim7Visible, Dim8Visible);
    end;

    procedure Set(var TempEmplLedgerEntry: Record "Employee Ledger Entry" temporary; var TempDetailedEmplLedgEntry2: Record "Detailed Employee Ledger Entry" temporary)
    begin
        if TempEmplLedgerEntry.FindSet() then
            repeat
                Rec := TempEmplLedgerEntry;
                Rec.Insert();
            until TempEmplLedgerEntry.Next() = 0;

        if TempDetailedEmplLedgEntry2.FindSet() then
            repeat
                TempDetailedEmplLedgEntry := TempDetailedEmplLedgEntry2;
                TempDetailedEmplLedgEntry.Insert();
            until TempDetailedEmplLedgEntry2.Next() = 0;
    end;

    local procedure CalcAmounts(var AmountFCY: Decimal; var AmountLCY: Decimal; var RemainingAmountFCY: Decimal; var RemainingAmountLCY: Decimal; var OriginalAmountFCY: Decimal; var OriginalAmountLCY: Decimal)
    begin
        AmountFCY := 0;
        AmountLCY := 0;
        RemainingAmountLCY := 0;
        RemainingAmountFCY := 0;
        OriginalAmountLCY := 0;
        OriginalAmountFCY := 0;

        TempDetailedEmplLedgEntry.SetRange("Employee Ledger Entry No.", Rec."Entry No.");
        if TempDetailedEmplLedgEntry.FindSet() then
            repeat
                if TempDetailedEmplLedgEntry."Entry Type" = TempDetailedEmplLedgEntry."Entry Type"::"Initial Entry" then begin
                    OriginalAmountFCY += TempDetailedEmplLedgEntry.Amount;
                    OriginalAmountLCY += TempDetailedEmplLedgEntry."Amount (LCY)";
                end;
                if not (TempDetailedEmplLedgEntry."Entry Type" = TempDetailedEmplLedgEntry."Entry Type"::Application)
                then begin
                    AmountFCY += TempDetailedEmplLedgEntry.Amount;
                    AmountLCY += TempDetailedEmplLedgEntry."Amount (LCY)";
                end;
                RemainingAmountFCY += TempDetailedEmplLedgEntry.Amount;
                RemainingAmountLCY += TempDetailedEmplLedgEntry."Amount (LCY)";
            until TempDetailedEmplLedgEntry.Next() = 0;
    end;

    local procedure DrilldownAmounts(AmountType: Option Amount,"Remaining Amount","Original Amount")
    var
        DetailedEmplEntriesPreview: Page "Detailed Empl. Entries Preview";
    begin
        case AmountType of
            AmountType::Amount:
                TempDetailedEmplLedgEntry.SetFilter("Entry Type", '<>%1',
                  TempDetailedEmplLedgEntry."Entry Type"::Application);
            AmountType::"Original Amount":
                TempDetailedEmplLedgEntry.SetRange("Entry Type", TempDetailedEmplLedgEntry."Entry Type"::"Initial Entry");
            AmountType::"Remaining Amount":
                TempDetailedEmplLedgEntry.SetRange("Entry Type");
        end;
        DetailedEmplEntriesPreview.Set(TempDetailedEmplLedgEntry);
        DetailedEmplEntriesPreview.RunModal();
        Clear(DetailedEmplEntriesPreview);
    end;
}

