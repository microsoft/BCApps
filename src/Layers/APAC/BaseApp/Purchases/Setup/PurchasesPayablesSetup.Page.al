// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Setup;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Pricing.Calculation;
using Microsoft.Purchases.Vendor;

page 460 "Purchases & Payables Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Purchases & Payables Setup';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Purchases & Payables Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Discount Posting"; Rec."Discount Posting")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Receipt on Invoice"; Rec."Receipt on Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Return Shipment on Credit Memo"; Rec."Return Shipment on Credit Memo")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Invoice Rounding"; Rec."Invoice Rounding")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if amounts are rounded for purchase invoices. Rounding is applied as specified in the Inv. Rounding Precision (LCY) field in the General Ledger Setup window. ';
                }
                field(DefaultGLAccountQuantity; Rec."Default G/L Account Quantity")
                {
                    ApplicationArea = Basic, Suite;
                }
#if not CLEAN27                
                field("Create Item from Item No."; Rec."Create Item from Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                    ObsoleteReason = 'Discontinued functionality';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                }
#endif                
                field("Copy Vendor Name to Entries"; Rec."Copy Vendor Name to Entries")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Ext. Doc. No. Mandatory"; Rec."Ext. Doc. No. Mandatory")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Allow VAT Difference"; Rec."Allow VAT Difference")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Calc. Inv. Discount"; Rec."Calc. Inv. Discount")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Calc. Inv. Disc. per VAT ID"; Rec."Calc. Inv. Disc. per VAT ID")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Appln. between Currencies"; Rec."Appln. between Currencies")
                {
                    ApplicationArea = Suite;
                }
                field("Copy Comments Blanket to Order"; Rec."Copy Comments Blanket to Order")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                }
                field("Copy Comments Order to Invoice"; Rec."Copy Comments Order to Invoice")
                {
                    ApplicationArea = Comments;
                    Importance = Additional;
                }
                field("Copy Comments Order to Receipt"; Rec."Copy Comments Order to Receipt")
                {
                    ApplicationArea = Comments;
                    Importance = Additional;
                }
                field("Copy Cmts Ret.Ord. to Cr. Memo"; Rec."Copy Cmts Ret.Ord. to Cr. Memo")
                {
                    ApplicationArea = Comments;
                    Importance = Additional;
                }
                field("Copy Cmts Ret.Ord. to Ret.Shpt"; Rec."Copy Cmts Ret.Ord. to Ret.Shpt")
                {
                    ApplicationArea = Comments;
                    Importance = Additional;
                }
                field("Exact Cost Reversing Mandatory"; Rec."Exact Cost Reversing Mandatory")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Check Prepmt. when Posting"; Rec."Check Prepmt. when Posting")
                {
                    ApplicationArea = Prepayments;
                    Importance = Additional;
                }
                field("Prepmt. Auto Update Frequency"; Rec."Prepmt. Auto Update Frequency")
                {
                    ApplicationArea = Prepayments;
                }
                field("Default Posting Date"; Rec."Default Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Default Qty. to Receive"; Rec."Default Qty. to Receive")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Posting Date Check on Posting"; Rec."Posting Date Check on Posting")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Auto Post Non-Invt. via Whse."; Rec."Auto Post Non-Invt. via Whse.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Allow Document Deletion Before"; Rec."Allow Document Deletion Before")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Allow Multiple Posting Groups"; Rec."Allow Multiple Posting Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Check Multiple Posting Groups"; Rec."Check Multiple Posting Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Ignore Updated Addresses"; Rec."Ignore Updated Addresses")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Copy Line Descr. to G/L Entry"; Rec."Copy Line Descr. to G/L Entry")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Copy Inv. No. To Pmt. Ref."; Rec."Copy Inv. No. To Pmt. Ref.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Document Default Line Type"; Rec."Document Default Line Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Disable Search by Name"; Rec."Disable Search by Name")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Default Cancel Reason Code"; Rec."Default Cancel Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code that will be used by default when you use the Cancel function on a posted purchase invoice. Use the Create Corrective Credit Memo function if you want to set reason code manually.';
                    Importance = Additional;
                }
                field("Update Document Date When Posting Date Is Modified"; Rec."Link Doc. Date To Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Check Doc. Total Amounts"; Rec."Check Doc. Total Amounts")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Prices)
            {
                Caption = 'Prices';
                Visible = ExtendedPriceEnabled;
                field("Price Calculation Method"; Rec."Price Calculation Method")
                {
                    Visible = false;
                    ApplicationArea = Basic, Suite;
                }
                field("Allow Editing Active Price"; Rec."Allow Editing Active Price")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Default Price List Code"; Rec."Default Price List Code")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group("Number Series")
            {
                Caption = 'Number Series';
                field("Vendor Nos."; Rec."Vendor Nos.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Quote Nos."; Rec."Quote Nos.")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                }
                field("Blanket Order Nos."; Rec."Blanket Order Nos.")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to blanket purchase orders.';
                }
                field("Order Nos."; Rec."Order Nos.")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                }
                field("Return Order Nos."; Rec."Return Order Nos.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to new purchase return orders.';
                }
                field("Invoice Nos."; Rec."Invoice Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to purchase invoices.';
                }
                field("Posted Invoice Nos."; Rec."Posted Invoice Nos.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posted Self-Billing Inv. Nos."; Rec."Posted Self-Billing Inv. Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Credit Memo Nos."; Rec."Credit Memo Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to purchase credit memos.';
                }
                field("Posted Credit Memo Nos."; Rec."Posted Credit Memo Nos.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posted Receipt Nos."; Rec."Posted Receipt Nos.")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                }
                field("Posted Return Shpt. Nos."; Rec."Posted Return Shpt. Nos.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Importance = Additional;
                }
                field("Posted Prepmt. Inv. Nos."; Rec."Posted Prepmt. Inv. Nos.")
                {
                    ApplicationArea = Prepayments;
                    Importance = Additional;
                }
                field("Posted Prepmt. Cr. Memo Nos."; Rec."Posted Prepmt. Cr. Memo Nos.")
                {
                    ApplicationArea = Prepayments;
                    Importance = Additional;
                }
                field("Price List Nos."; Rec."Price List Nos.")
                {
                    Visible = ExtendedPriceEnabled;
                    ApplicationArea = Basic, Suite;
                }
            }
            group("Background Posting")
            {
                Caption = 'Background Posting';
                field("Post with Job Queue"; Rec."Post with Job Queue")
                {
                    ApplicationArea = Suite;
                }
                field("Post & Print with Job Queue"; Rec."Post & Print with Job Queue")
                {
                    ApplicationArea = Suite;
                }
                field("Job Queue Category Code"; Rec."Job Queue Category Code")
                {
                    ApplicationArea = Suite;
                }
                field("Notify On Success"; Rec."Notify On Success")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Report Output Type"; Rec."Report Output Type")
                {
                    ApplicationArea = Suite;
                }
            }
            group("WHT/GST")
            {
                Caption = 'WHT/GST';
                field("Posted Tax Invoice Nos."; Rec."Posted Tax Invoice Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the no. series for the posted tax invoice.';
                }
                field("Posted Tax Credit Memo Nos"; Rec."Posted Tax Credit Memo Nos")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the no. series for the posted tax Credit Memo.';
                }
                field("Posted Non Tax Invoice Nos."; Rec."Posted Non Tax Invoice Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to Posted Non Tax Invoice documents.';
                }
                field("Posted Non Tax Credit Memo Nos"; Rec."Posted Non Tax Credit Memo Nos")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to Posted Non Tax Credit Memo document for sales.';
                }
                field("WHT Certificate No. Series"; Rec."WHT Certificate No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the No. Series for the WHT Certificates.';
                }
                field("Print WHT Docs. on Pay. Post"; Rec."Print WHT Docs. on Pay. Post")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies to print WHT Certificates during posting of payment journal.';
                }
                field("Print Dialog"; Rec."Print Dialog")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to select the printer when printing purchases and payables reports.';
                }
                field("Print WHT Docs. on Credit Memo"; Rec."Print WHT Docs. on Credit Memo")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies to print withholding tax (WHT) documents during the posting of payment journal.';
                }
                field("Vendor Registration Warning"; Rec."Vendor Registration Warning")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether you want the program to warn you when a vendor has not Registered for VAT with the ATO.';
                }
                field("Enable Vendor GST Amount (ACY)"; Rec."Enable Vendor GST Amount (ACY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if GST reporting with foreign currency, set as LCY, has been activated.';
                }
                field("GST Prod. Posting Group"; Rec."GST Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the vendor does not have an ABN, the system will ignore the VAT Product Posting Group and look for this field.';
                }
                field("Payment Discount Reason Code"; Rec."Payment Discount Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies this is the Reason Code the system tags against each Payment Journal where a Payment Discount is automatically calculated.';
                }
            }
            group("Post Dated Checks")
            {
                Caption = 'Post Dated Checks';
                field("Post Dated Check Template"; Rec."Post Dated Check Template")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the post-dated check template where the post-dated journal will be transferred during posting.';
                }
                field("Post Dated Check Batch"; Rec."Post Dated Check Batch")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the post-dated check batch where the post-dated journal will be transferred during posting.';
                }
            }
            group(Archiving)
            {
                Caption = 'Archiving';
                field("Archive Quotes"; Rec."Archive Quotes")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Archive Orders"; Rec."Archive Orders")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Archive Blanket Orders"; Rec."Archive Blanket Orders")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Archive Return Orders"; Rec."Archive Return Orders")
                {
                    ApplicationArea = PurchReturnOrder;
                }
            }
            group("Journal Templates")
            {
                Caption = 'Journal Templates';
                Visible = JnlTemplateNameVisible;

                field("P. Invoice Template Name"; Rec."P. Invoice Template Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("P. Cr. Memo Template Name"; Rec."P. Cr. Memo Template Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("P. Prep. Inv. Template Name"; Rec."P. Prep. Inv. Template Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("P. Prep. Cr.Memo Template Name"; Rec."P. Prep. Cr.Memo Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = JnlTemplateNameVisible;
                }
                field("IC Purch. Invoice Templ. Name"; Rec."IC Purch. Invoice Templ. Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("IC Purch. Cr. Memo Templ. Name"; Rec."IC Purch. Cr. Memo Templ. Name")
                {
                    ApplicationArea = Basic, Suite;
                }

            }
            group("Default Accounts")
            {
                Caption = 'Default Accounts';
                field("Debit Acc. for Non-Item Lines"; Rec."Debit Acc. for Non-Item Lines")
                {
                    ApplicationArea = Suite;
                    Caption = 'Default Debit Account for Non-Item Lines';
                }
                field("Credit Acc. for Non-Item Lines"; Rec."Credit Acc. for Non-Item Lines")
                {
                    ApplicationArea = Suite;
                    Caption = 'Default Credit Account for Non-Item Lines';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action("Vendor Posting Groups")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor Posting Groups';
                Image = Vendor;
                RunObject = Page "Vendor Posting Groups";
                ToolTip = 'Set up the posting groups to select from when you set up vendor cards to link business transactions made for the vendor with the appropriate account in the general ledger.';
            }
            action("Incoming Documents Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Incoming Documents Setup';
                Image = Documents;
                RunObject = Page "Incoming Documents Setup";
                ToolTip = 'Set up the journal template that will be used to create general journal lines from electronic external documents, such as invoices from your vendors on email.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Vendor Posting Groups_Promoted"; "Vendor Posting Groups")
                {
                }
                actionref("Incoming Documents Setup_Promoted"; "Incoming Documents Setup")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
        GeneralLedgerSetup.Get();
        JnlTemplateNameVisible := GeneralLedgerSetup."Journal Templ. Name Mandatory";
    end;

    var
        ExtendedPriceEnabled: Boolean;
        JnlTemplateNameVisible: Boolean;
}

