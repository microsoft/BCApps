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
                    ToolTip = 'Specifies the type of purchase discounts to post separately. No Discounts: Discounts are not posted separately but instead will subtract the discount before posting. Invoice Discounts: The invoice discount and invoice amount are posted simultaneously, based on the Purch. Inv. Disc. Account field in the General Posting Setup window. Line Discounts: The line discount and the invoice amount will be posted simultaneously, based on Purch. Line Disc. Account field in the General Posting Setup window. All Discounts: The invoice and line discounts and the invoice amount will be posted simultaneously, based on the Purch. Inv. Disc. Account field and Purch. Line. Disc. Account fields in the General Posting Setup window.';
                }
                field("Receipt on Invoice"; Rec."Receipt on Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies that a posted receipt and a posted invoice are automatically created when you post an invoice.';
                }
                field("Return Shipment on Credit Memo"; Rec."Return Shipment on Credit Memo")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies that a posted return shipment and a posted purchase credit memo are automatically created when you post a credit memo.';
                }
                field("Invoice Rounding"; Rec."Invoice Rounding")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if amounts are rounded for purchase invoices. Rounding is applied as specified in the Inv. Rounding Precision (LCY) field in the General Ledger Setup window. ';
                }
                field(DefaultGLAccountQuantity; Rec."Default G/L Account Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that Quantity is set to 1 on lines of type G/L Account.';
                }
#if not CLEAN27                
                field("Create Item from Item No."; Rec."Create Item from Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the system will suggest to create a new item when no item matches the number that you enter in the No. Field on purchase lines.';
                    Visible = false;
                    ObsoleteReason = 'Discontinued functionality';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                }
#endif                
                field("Copy Vendor Name to Entries"; Rec."Copy Vendor Name to Entries")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want the name on vendor cards to be copied to vendor ledger entries during posting.';
                }
                field("Ext. Doc. No. Mandatory"; Rec."Ext. Doc. No. Mandatory")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if it is mandatory to enter an external document number in the External Document No. field on a purchase header or the External Document No. field on a general journal line.';
                }
                field("Allow VAT Difference"; Rec."Allow VAT Difference")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to allow the manual adjustment of VAT amounts in purchase documents.';
                }
                field("Calc. Inv. Discount"; Rec."Calc. Inv. Discount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the invoice discount amount is automatically calculated with purchase documents. If this check box is selected, then the invoice discount amount is calculated automatically, based on purchase lines where the Allow Invoice Disc. field is selected.';
                }
                field("Calc. Inv. Disc. per VAT ID"; Rec."Calc. Inv. Disc. per VAT ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the invoice discount is calculated according to the VAT identifier that is defined in the VAT posting setup. If you choose not to select this check box, the invoice discount will be calculated based on the invoice total.';
                }
                field("Appln. between Currencies"; Rec."Appln. between Currencies")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether it is allowed to apply vendor payments in different currencies. None: All entries involved in one application must be in the same currency. EMU: You can apply entries in euro and one of the old national currencies (for EMU countries/regions) to one another. All: You can apply entries in different currencies to one another. The entries can be in any currency.';
                }
                field("Copy Comments Blanket to Order"; Rec."Copy Comments Blanket to Order")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to copy comments from blanket purchase orders to purchase orders.';
                }
                field("Copy Comments Order to Invoice"; Rec."Copy Comments Order to Invoice")
                {
                    ApplicationArea = Comments;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to copy comments from purchase orders to purchase invoices.';
                }
                field("Copy Comments Order to Receipt"; Rec."Copy Comments Order to Receipt")
                {
                    ApplicationArea = Comments;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to copy comments from purchase orders to receipts.';
                }
                field("Copy Cmts Ret.Ord. to Cr. Memo"; Rec."Copy Cmts Ret.Ord. to Cr. Memo")
                {
                    ApplicationArea = Comments;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to copy comments from purchase return orders to purchase credit memos.';
                }
                field("Copy Cmts Ret.Ord. to Ret.Shpt"; Rec."Copy Cmts Ret.Ord. to Ret.Shpt")
                {
                    ApplicationArea = Comments;
                    Importance = Additional;
                    ToolTip = 'Specifies that comments are copied from the purchase return order to the posted return shipment.';
                }
                field("Exact Cost Reversing Mandatory"; Rec."Exact Cost Reversing Mandatory")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that a return transaction cannot be posted unless the Appl.-to Item Entry field on the purchase order line specifies an entry.';
                }
                field("Check Prepmt. when Posting"; Rec."Check Prepmt. when Posting")
                {
                    ApplicationArea = Prepayments;
                    Importance = Additional;
                    ToolTip = 'Specifies that you cannot receive or invoice an order that has an unpaid prepayment amount.';
                }
                field("Prepmt. Auto Update Frequency"; Rec."Prepmt. Auto Update Frequency")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies how often the job must run that automatically updates the status of orders that are pending prepayment.';
                }
                field("Default Posting Date"; Rec."Default Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which date must be used as the default posting date on purchase documents. If you select Work Date, the Posting Date field will be populated with the work date at the time of creating a new purchase document. If you select No Date, the Posting Date field will be empty by default and you must manually enter a posting date before posting.';
                }
                field("Default Qty. to Receive"; Rec."Default Qty. to Receive")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Posting Date Check on Posting"; Rec."Posting Date Check on Posting")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to see a warning when you post a purchase document with a posting date that is different from the Work Date.';
                }
                field("Auto Post Non-Invt. via Whse."; Rec."Auto Post Non-Invt. via Whse.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies if non-inventory item lines in a purchase document will be posted automatically when the document is posted via warehouse. None: Do not automatically post non-inventory item lines. Attached/Assigned: Post item charges and other non-inventory item lines assigned or attached to regular items. All: Post all non-inventory item lines.';
                }
                field("Allow Document Deletion Before"; Rec."Allow Document Deletion Before")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies if and when posted purchase invoices and credit memos can be deleted. If you enter a date, posted purchase documents with a posting date on or after this date cannot be deleted.';
                }
                field("Allow Multiple Posting Groups"; Rec."Allow Multiple Posting Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies if multiple posting groups can be used for the same vendor in purchase documents.';
                }
                field("Check Multiple Posting Groups"; Rec."Check Multiple Posting Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies implementation method of checking which posting groups can be used for the vendor.';
                }
                field("Ignore Updated Addresses"; Rec."Ignore Updated Addresses")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if changes to addresses made on purchase documents are copied to the vendor card. By default, changes are copied to the vendor card.';
                }
                field("Copy Line Descr. to G/L Entry"; Rec."Copy Line Descr. to G/L Entry")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies that the description on document lines of type G/L Account will be carried to the resulting general ledger entries.';
                }
                field("Copy Inv. No. To Pmt. Ref."; Rec."Copy Inv. No. To Pmt. Ref.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the value of the Vendor Invoice No. field must be copied to the Payment Reference field during posting unless the Payment Reference field is not blank.';
                    Importance = Additional;
                }
                field("Document Default Line Type"; Rec."Document Default Line Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the default value for the Type field on the first line in new purchase documents. If needed, you can change the value on the line.';
                }
                field("Disable Search by Name"; Rec."Disable Search by Name")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies that you can change the names of vendors on open purchase documents. The change applies only to the documents.';
                }
                field("Update Document Date When Posting Date Is Modified"; Rec."Link Doc. Date To Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the document date changes when the posting date is modified.';
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
                    ToolTip = 'Specifies the price calculation method that will be default for purchase transactions.';
                }
                field("Allow Editing Active Price"; Rec."Allow Editing Active Price")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies it the existing active purchase price line can be modified or removed, or a new price line can be added to the active price list.';
                }
                field("Default Price List Code"; Rec."Default Price List Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the existing purchase price list that stores all new price lines created in the price worksheet page.';
                }
            }
            group("Number Series")
            {
                Caption = 'Number Series';
                field("Vendor Nos."; Rec."Vendor Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to vendors.';
                }
                field("Quote Nos."; Rec."Quote Nos.")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to purchase quotes.';
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
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to purchase orders.';
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
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to posted purchase invoices.';
                }
                field("Credit Memo Nos."; Rec."Credit Memo Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to purchase credit memos.';
                }
                field("Posted Credit Memo Nos."; Rec."Posted Credit Memo Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to posted purchase credit memos.';
                }
                field("Posted Receipt Nos."; Rec."Posted Receipt Nos.")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to posted receipts.';
                }
                field("Posted Return Shpt. Nos."; Rec."Posted Return Shpt. Nos.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to posted return shipments.';
                }
                field("Posted Prepmt. Inv. Nos."; Rec."Posted Prepmt. Inv. Nos.")
                {
                    ApplicationArea = Prepayments;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to posted purchase prepayment invoices.';
                }
                field("Posted Prepmt. Cr. Memo Nos."; Rec."Posted Prepmt. Cr. Memo Nos.")
                {
                    ApplicationArea = Prepayments;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to purchase prepayment credit memos.';
                }
                field("Price List Nos."; Rec."Price List Nos.")
                {
                    Visible = ExtendedPriceEnabled;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to purchase price lists.';
                }
            }
            group("Background Posting")
            {
                Caption = 'Background Posting';
                field("Post with Job Queue"; Rec."Post with Job Queue")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if you use job queues to post purchase documents in the background.';
                }
                field("Post & Print with Job Queue"; Rec."Post & Print with Job Queue")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if you use job queues to post and print purchase documents in the background.';
                }
                field("Job Queue Category Code"; Rec."Job Queue Category Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the category of the job queue that you want to associate with background posting.';
                }
                field("Notify On Success"; Rec."Notify On Success")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a setting that has no effect. Legacy field.';
                    Visible = false;
                }
                field("Report Output Type"; Rec."Report Output Type")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the output of the report that will be scheduled with a job queue entry when the Post and Print with Job Queue check box is selected.';
                }
            }
            group(Archiving)
            {
                Caption = 'Archiving';
                field("Archive Quotes"; Rec."Archive Quotes")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to automatically archive purchase quotes when: deleted, processed or printed.';
                }
                field("Archive Orders"; Rec."Archive Orders")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to automatically archive purchase orders when: deleted, posted or printed.';
                }
                field("Archive Blanket Orders"; Rec."Archive Blanket Orders")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to automatically archive purchase blanket orders when: deleted, processed or printed.';
                }
                field("Archive Return Orders"; Rec."Archive Return Orders")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies if you want to automatically archive purchase return orders when deleted or posted.';
                }
            }
            group("Journal Templates")
            {
                Caption = 'Journal Templates';
                Visible = JnlTemplateNameVisible;

                field("P. Invoice Template Name"; Rec."P. Invoice Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that you can select the journal template to use for posting purchase invoices.';
                }
                field("P. Cr. Memo Template Name"; Rec."P. Cr. Memo Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that you can select the journal template to use for posting purchase credit memos.';
                }
                field("P. Prep. Inv. Template Name"; Rec."P. Prep. Inv. Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which general journal template to use for purchase prepayment invoices.';
                }
                field("P. Prep. Cr.Memo Template Name"; Rec."P. Prep. Cr.Memo Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which general journal template to use for purchase prepayment credit memos.';
                    Visible = JnlTemplateNameVisible;
                }
                field("IC Purch. Invoice Templ. Name"; Rec."IC Purch. Invoice Templ. Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the intercompany journal template to use for purchase invoices.';
                }
                field("IC Purch. Cr. Memo Templ. Name"; Rec."IC Purch. Cr. Memo Templ. Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the intercompany journal template to use for posting purchase credit memos.';
                }

            }
            group("Default Accounts")
            {
                Caption = 'Default Accounts';
                field("Debit Acc. for Non-Item Lines"; Rec."Debit Acc. for Non-Item Lines")
                {
                    ApplicationArea = Suite;
                    Caption = 'Default Debit Account for Non-Item Lines';
                    ToolTip = 'Specifies the G/L account that is automatically inserted on purchase lines of type debit that are created from electronic documents when the incoming document line does not contain an identifiable item. Any incoming document line that does not have a GTIN or the vendor''s item number will be converted to a purchase line of type G/L Account, and the No. field on the purchase line will contain the account that you select in the G/L Account for Non-Item Lines field.';
                }
                field("Credit Acc. for Non-Item Lines"; Rec."Credit Acc. for Non-Item Lines")
                {
                    ApplicationArea = Suite;
                    Caption = 'Default Credit Account for Non-Item Lines';
                    ToolTip = 'Specifies the G/L account that is automatically inserted on purchase lines of type credit that are created from electronic documents when the incoming document line does not contain an identifiable item. Any incoming document line that does not have a GTIN or the vendor''s item number will be converted to a purchase line of type G/L Account, and the No. field on the purchase line will contain the account that you select in the G/L Account for Non-Item Lines field.';
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

