// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Ledger;

/// <summary>
/// Subform component displaying ECSL report lines with customer VAT numbers and supply values.
/// Provides read-only detailed view of generated EU Sales List data with country and indicator breakdowns.
/// </summary>
page 322 "ECSL Report Subform"
{
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "ECSL VAT Report Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = BasicEU;
                }
                field("Report No."; Rec."Report No.")
                {
                    ApplicationArea = BasicEU;
                }
                field("Country Code"; Rec."Country Code")
                {
                    ApplicationArea = BasicEU;
                }
                field("Customer VAT Reg. No."; Rec."Customer VAT Reg. No.")
                {
                    ApplicationArea = BasicEU;
                }
                field("Total Value Of Supplies"; Rec."Total Value Of Supplies")
                {
                    ApplicationArea = BasicEU;
                }
                field("Transaction Indicator"; Rec."Transaction Indicator")
                {
                    ApplicationArea = BasicEU;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ShowLines)
            {
                ApplicationArea = BasicEU;
                Caption = 'Show VAT Entries';
                Image = List;
                Scope = Repeater;
                ShortCutKey = 'Return';
                ToolTip = 'View the related VAT entries.';

                trigger OnAction()
                var
                    VATEntry: Record "VAT Entry";
                    ECSLVATReportLineRelation: Record "ECSL VAT Report Line Relation";
                    ECSLVATReportLine: Record "ECSL VAT Report Line";
                begin
                    CurrPage.SetSelectionFilter(ECSLVATReportLine);
                    if ECSLVATReportLine.FindFirst() then;
                    if ECSLVATReportLine."Line No." = 0 then
                        exit;
                    ECSLVATReportLineRelation.SetRange("ECSL Line No.", ECSLVATReportLine."Line No.");
                    ECSLVATReportLineRelation.SetRange("ECSL Report No.", ECSLVATReportLine."Report No.");
                    if not ECSLVATReportLineRelation.FindSet() then
                        exit;

                    repeat
                        if VATEntry.Get(ECSLVATReportLineRelation."VAT Entry No.") then
                            VATEntry.Mark(true);
                    until ECSLVATReportLineRelation.Next() = 0;

                    VATEntry.MarkedOnly(true);
                    PAGE.Run(0, VATEntry);
                end;
            }
        }
    }

    /// <summary>
    /// Refreshes the subform display to reflect current ECSL report line data.
    /// Updates the user interface after data modifications or filtering changes.
    /// </summary>
    procedure UpdateForm()
    begin
        CurrPage.Update();
    end;
}

