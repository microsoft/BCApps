// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Ledger;

/// <summary>
/// Displays VAT report lines in a list format for reviewing and modifying VAT entry data.
/// Provides editable view of VAT entries included in VAT report calculations.
/// </summary>
page 741 "VAT Report Subform"
{
    Caption = 'Lines';
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "VAT Report Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Line Type"; Rec."Line Type")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the type of the line in the VAT report.';
                }
                field(Base; Rec.Base)
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the VAT amount for the report line. This is calculated based on the value of the Base field.';

                    trigger OnAssistEdit()
                    var
                    begin
                        ShowVATReportEntries(Rec."VAT Report No.", Rec."Line No.");
                    end;
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = VAT;
                }
                field("VAT Registration No."; Rec."VAT Registration No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the VAT registration number of the customer or vendor that the VAT entry is linked to.';
                }
                field("EU 3-Party Trade"; Rec."EU 3-Party Trade")
                {
                    ApplicationArea = VAT;
                }
                field("EU Service"; Rec."EU Service")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Indicates whether the line is associated with a EU Service.';
                }
            }
        }
    }

    actions
    {
    }

    local procedure ShowVATReportEntries(VATReportNo: Code[20]; VATReportLineNo: Integer)
    var
        VATReportLineRelation: Record "VAT Report Line Relation";
        VATEntry: Record "VAT Entry";
        VATEntryTmp: Record "VAT Entry" temporary;
    begin
        VATReportLineRelation.SetRange("VAT Report No.", VATReportNo);
        VATReportLineRelation.SetRange("VAT Report Line No.", VATReportLineNo);
        VATReportLineRelation.SetRange("Table No.", DATABASE::"VAT Entry");
        if VATReportLineRelation.FindSet() then begin
            repeat
                VATEntry.Get(VATReportLineRelation."Entry No.");
                VATEntryTmp.TransferFields(VATEntry, true);
                VATEntryTmp.Insert();
            until VATReportLineRelation.Next() = 0;
            PAGE.RunModal(0, VATEntryTmp);
        end;
    end;
}

