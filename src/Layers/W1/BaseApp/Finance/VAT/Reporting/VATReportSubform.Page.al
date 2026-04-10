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
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = ListPart;
    SourceTable = "VAT Report Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = VAT;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = VAT;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = VAT;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = VAT;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = VAT;
                }
                field(Base; Rec.Base)
                {
                    ApplicationArea = VAT;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = VAT;

                    trigger OnAssistEdit()
                    var
                        VATReportLineRelation: Record "VAT Report Line Relation";
                        VATEntry: Record "VAT Entry";
                        FilterText: Text[1024];
                        TableNo: Integer;
                    begin
                        FilterText := VATReportLineRelation.CreateFilterForAmountMapping(Rec."VAT Report No.", Rec."Line No.", TableNo);
                        case TableNo of
                            DATABASE::"VAT Entry":
                                begin
                                    VATEntry.SetFilter("Entry No.", FilterText);
                                    PAGE.RunModal(0, VATEntry);
                                end;
                        end;
                    end;
                }
                field("VAT Calculation Type"; Rec."VAT Calculation Type")
                {
                    ApplicationArea = VAT;
                }
                field("Bill-to/Pay-to No."; Rec."Bill-to/Pay-to No.")
                {
                    ApplicationArea = VAT;
                }
                field("EU 3-Party Trade"; Rec."EU 3-Party Trade")
                {
                    ApplicationArea = VAT;
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = VAT;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = VAT;
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = VAT;
                }
                field("Internal Ref. No."; Rec."Internal Ref. No.")
                {
                    ApplicationArea = VAT;
                }
                field("Unrealized Amount"; Rec."Unrealized Amount")
                {
                    ApplicationArea = VAT;
                }
                field("Unrealized Base"; Rec."Unrealized Base")
                {
                    ApplicationArea = VAT;
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = VAT;
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = VAT;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = VAT;
                }
                field("VAT Registration No."; Rec."VAT Registration No.")
                {
                    ApplicationArea = VAT;
                }
            }
        }
    }

    actions
    {
    }
}

