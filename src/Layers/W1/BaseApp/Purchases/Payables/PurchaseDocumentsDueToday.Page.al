// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Purchases.Vendor;

page 1161 "Purchase Documents Due Today"
{
    Caption = 'Purchase Documents Due Today';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = CardPart;
    ShowFilter = false;
    SourceTable = "Vendor Ledger Entry";
    SourceTableView = sorting("Entry No.")
                      order(descending);

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies which purchase documents are due today.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the type of document.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the purchase document number.';
                }
                field(Vendor; VendorName)
                {
                    ApplicationArea = All;
                    Caption = 'Vendor Name';
                    ToolTip = 'Specifies name of the Vendor.';
                }
                field("Remaining Amount"; Rec."Remaining Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount that remains to be paid on the purchase documents that are due today.';

                    trigger OnDrillDown()
                    var
                        HyperLinkUrl: Text[250];
                    begin
                        HyperLinkUrl := GetUrl(CLIENTTYPE::Web, CompanyName, OBJECTTYPE::Page, 574) + StrSubstNo(FilterForRemAmtDrillDwnTxt, Rec."Entry No.");
                        HyperLink(HyperLinkUrl);
                    end;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = All;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies when the purchase document is due.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(Rec."Vendor No.");
        VendorName := Vendor.Name;
        StyleTxt := Rec.SetStyle();
    end;

    trigger OnOpenPage()
    begin
        Rec.SetRange(Open, true);
        Rec.SetFilter("Document Type", 'Invoice|Credit Memo');
        Rec.SetFilter("Due Date", '<%1', WorkDate());
        Rec.Ascending := false;
    end;

    var
        VendorName: Text[250];
        StyleTxt: Text;
        FilterForRemAmtDrillDwnTxt: Label '&filter=''Detailed Vendor Ledg. Entry''.''Vendor Ledger Entry No.'' IS ''%1''', Comment = '%1 - Entry No. for Vendor ledger entry. ';
}

