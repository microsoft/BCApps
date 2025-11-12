// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Ledger;

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
                    ToolTip = 'Specifies the unique identifier for the line.';
                }
                field("Report No."; Rec."Report No.")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the unique identifier for the report.';
                }
                field("Country Code"; Rec."Country Code")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies country code of the customer used for the line calculation.';
                }
                field("Customer VAT Reg. No."; Rec."Customer VAT Reg. No.")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies VAT Registration Number of the customer.';
                }
                field("Total Value Of Supplies"; Rec."Total Value Of Supplies")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the total amount of the sold supplies.';
                }
                field("Transaction Indicator"; Rec."Transaction Indicator")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the transaction number.';
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

    procedure UpdateForm()
    begin
        CurrPage.Update();
    end;
}

