// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using System.Visualization;

page 9049 "Headline RC A/P Admin"
{
    Caption = 'Headline';
    PageType = HeadlinePart;
    RefreshOnActivate = true;
    ApplicationArea = Basic, Suite;

    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(GreetinHeadline)
            {
                ShowCaption = false;
                Visible = this.UserGreetingVisible;

                field(GreetingText; this.RCHeadlinesPageCommon.GetGreetingText())
                {
                    Caption = 'Greeting headline';
                    Editable = false;
                }
            }
            group(DocumentationHeadline)
            {
                ShowCaption = false;
                Visible = this.DefaultFieldsVisible;

                field(DocumentationText; this.RCHeadlinesPageCommon.GetDocumentationText())
                {
                    Caption = 'Documentation headline';
                    DrillDown = true;
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        HyperLink(this.RCHeadlinesPageCommon.DocumentationUrlTxt());
                    end;
                }
            }
            group(LargestPostedPurchInvHeadline)
            {
                ShowCaption = false;
                Visible = this.LargestPostedPurchInvVisible;

                field(LargestPostedPurchInvTxt; this.LargestPostedPurchInvTxt)
                {
                    Caption = 'Tasks headline';
                    DrillDown = true;
                    Editable = false;

                    trigger OnDrillDown()
                    var
                        VendorLedgerEntry: Record "Vendor Ledger Entry";
                        PurchInvHeader: Record "Purch. Inv. Header";
                    begin
                        if FindVendorLedgerEntryWithMaxAmountInLastQuater(VendorLedgerEntry) then begin
                            PurchInvHeader.Get(VendorLedgerEntry."Document No.");
                            Page.Run(Page::"Posted Purchase Invoice");
                        end;
                    end;
                }
            }
        }
    }

    var
        RCHeadlinesPageCommon: Codeunit "RC Headlines Page Common";
        DefaultFieldsVisible: Boolean;
        UserGreetingVisible: Boolean;
        LargestPostedPurchInvTxt: Text;
        LargestPostedPurchInvVisible: Boolean;
        LargestPurchaseInvoiceInLastQuaterLbl: Label '<qualifier>Insight from the last three months period.</qualifier><payload>The largest posted purchase invoice was for <emphasize>%1%2</emphasize></payload>', Comment = '%1 = Currency Symbol, %2 = Amount';

    trigger OnOpenPage()
    begin
        // Set the headline to be the first one in the list.
        this.RCHeadlinesPageCommon.HeadlineOnOpenPage(Page::"Headline RC A/P Admin");
        this.DefaultFieldsVisible := RCHeadlinesPageCommon.AreDefaultFieldsVisible();
        this.UserGreetingVisible := RCHeadlinesPageCommon.IsUserGreetingVisible();
        this.LargestPostedPurchInvTxt := GetLargestPostedPurchInvoiceInLastQuaterTxt();
    end;

    local procedure GetLargestPostedPurchInvoiceInLastQuaterTxt(): Text
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        CurrencySymbol: Text[10];
    begin
        if FindVendorLedgerEntryWithMaxAmountInLastQuater(VendorLedgerEntry) then begin
            GeneralLedgerSetup.Get();
            CurrencySymbol := GeneralLedgerSetup.GetCurrencySymbol();
            this.LargestPostedPurchInvVisible := true;
            exit(
                StrSubstNo(
                    LargestPurchaseInvoiceInLastQuaterLbl,
                    CurrencySymbol,
                    Format(Round(Abs(VendorLedgerEntry."Amount (LCY)"), GeneralLedgerSetup."Amount Rounding Precision"))
                )
            );
        end else
            this.LargestPostedPurchInvVisible := false;
    end;

    local procedure FindVendorLedgerEntryWithMaxAmountInLastQuater(var VendorLedgerEntryWithHighestAmt: Record "Vendor Ledger Entry"): Boolean
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        QuaterBack: Date;
        MaxAmount: Decimal;
    begin
        MaxAmount := 0;
        QuaterBack := CalcDate('<-3M>', WorkDate());
        VendorLedgerEntry.SetRange("Posting Date", QuaterBack, WorkDate());
        VendorLedgerEntry.SetRange("Document Type", Enum::"Gen. Journal Document Type"::Invoice);
        VendorLedgerEntry.SetFilter("Amount (LCY)", '<0');
        VendorLedgerEntry.SetAutoCalcFields("Amount (LCY)");
        if VendorLedgerEntry.FindSet() then begin
            repeat
                if VendorLedgerEntry."Amount (LCY)" < MaxAmount then begin
                    MaxAmount := VendorLedgerEntry."Amount (LCY)";
                    VendorLedgerEntryWithHighestAmt := VendorLedgerEntry;
                end;
            until VendorLedgerEntry.Next() = 0;
            MaxAmount := Abs(MaxAmount);
            exit(true);
        end;

        exit(false);
    end;
}
