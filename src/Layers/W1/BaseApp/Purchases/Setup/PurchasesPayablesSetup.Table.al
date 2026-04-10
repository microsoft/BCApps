// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Setup;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Pricing;
using Microsoft.Purchases.Vendor;
using Microsoft.Upgrade;
using Microsoft.Utilities;
using Microsoft.Warehouse.Structure;
using System.Environment;
using System.Threading;

table 312 "Purchases & Payables Setup"
{
    Caption = 'Purchases & Payables Setup';
    DrillDownPageID = "Purchases & Payables Setup";
    LookupPageID = "Purchases & Payables Setup";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "Discount Posting"; Option)
        {
            Caption = 'Discount Posting';
            ToolTip = 'Specifies the type of purchase discounts to post separately. No Discounts: Discounts are not posted separately but instead will subtract the discount before posting. Invoice Discounts: The invoice discount and invoice amount are posted simultaneously, based on the Purch. Inv. Disc. Account field in the General Posting Setup window. Line Discounts: The line discount and the invoice amount will be posted simultaneously, based on Purch. Line Disc. Account field in the General Posting Setup window. All Discounts: The invoice and line discounts and the invoice amount will be posted simultaneously, based on the Purch. Inv. Disc. Account field and Purch. Line. Disc. Account fields in the General Posting Setup window.';
            OptionCaption = 'No Discounts,Invoice Discounts,Line Discounts,All Discounts';
            OptionMembers = "No Discounts","Invoice Discounts","Line Discounts","All Discounts";

            trigger OnValidate()
            var
                DiscountNotificationMgt: Codeunit "Discount Notification Mgt.";
            begin
                DiscountNotificationMgt.NotifyAboutMissingSetup(RecordId, '', "Discount Posting", 0);
            end;
        }
        field(6; "Receipt on Invoice"; Boolean)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Receipt on Invoice';
            ToolTip = 'Specifies that a posted receipt and a posted invoice are automatically created when you post an invoice.';
        }
        field(7; "Invoice Rounding"; Boolean)
        {
            Caption = 'Invoice Rounding';
            ToolTip = 'Specifies if amounts are rounded for purchase invoices. Rounding is applied as specified in the Inv. Rounding Precision (LCY) field in the General Ledger Setup window.';
        }
        field(8; "Ext. Doc. No. Mandatory"; Boolean)
        {
            Caption = 'Ext. Doc. No. Mandatory';
            ToolTip = 'Specifies if it is mandatory to enter an external document number in the External Document No. field on a purchase header or the External Document No. field on a general journal line.';
            InitValue = true;
        }
        field(9; "Vendor Nos."; Code[20])
        {
            Caption = 'Vendor Nos.';
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to vendors.';
            TableRelation = "No. Series";
        }
        field(10; "Quote Nos."; Code[20])
        {
            Caption = 'Quote Nos.';
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to purchase quotes.';
            TableRelation = "No. Series";
        }
        field(11; "Order Nos."; Code[20])
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Order Nos.';
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to purchase orders.';
            TableRelation = "No. Series";
        }
        field(12; "Invoice Nos."; Code[20])
        {
            Caption = 'Invoice Nos.';
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to purchase invoices. To see the number series that have been set up in the No. Series table, click the field.';
            TableRelation = "No. Series";
        }
        field(13; "Posted Invoice Nos."; Code[20])
        {
            Caption = 'Posted Invoice Nos.';
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to posted purchase invoices.';
            TableRelation = "No. Series";
        }
        field(14; "Credit Memo Nos."; Code[20])
        {
            Caption = 'Credit Memo Nos.';
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to purchase credit memos. To see the number series that have been set up in the No. Series table, click the field.';
            TableRelation = "No. Series";
        }
        field(15; "Posted Credit Memo Nos."; Code[20])
        {
            Caption = 'Posted Credit Memo Nos.';
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to posted purchase credit memos.';
            TableRelation = "No. Series";
        }
        field(16; "Posted Receipt Nos."; Code[20])
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Posted Receipt Nos.';
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to posted receipts.';
            TableRelation = "No. Series";
        }
        field(17; "Posted Self-Billing Inv. Nos."; Code[20])
        {
            Caption = 'Posted Self-Billing Invoice Nos.';
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to posted self-billing purchase invoices.';
            TableRelation = "No. Series";
        }
        field(19; "Blanket Order Nos."; Code[20])
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Blanket Order Nos.';
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to blanket purchase orders. To see the number series that have been set up in the No. Series table, click the field.';
            TableRelation = "No. Series";
        }
        field(20; "Calc. Inv. Discount"; Boolean)
        {
            AccessByPermission = TableData "Vendor Invoice Disc." = R;
            Caption = 'Calc. Inv. Discount';
            ToolTip = 'Specifies if the invoice discount amount is automatically calculated with purchase documents. If this check box is selected, then the invoice discount amount is calculated automatically, based on purchase lines where the Allow Invoice Disc. field is selected.';
        }
        field(21; "Appln. between Currencies"; Option)
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Appln. between Currencies';
            ToolTip = 'Specifies whether it is allowed to apply vendor payments in different currencies. None: All entries involved in one application must be in the same currency. EMU: You can apply entries in euro and one of the old national currencies (for EMU countries/regions) to one another. All: You can apply entries in different currencies to one another. The entries can be in any currency.';
            OptionCaption = 'None,EMU,All';
            OptionMembers = "None",EMU,All;
        }
        field(22; "Copy Comments Blanket to Order"; Boolean)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Copy Comments Blanket to Order';
            ToolTip = 'Specifies whether to copy comments from blanket purchase orders to purchase orders.';
            InitValue = true;
        }
        field(23; "Copy Comments Order to Invoice"; Boolean)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Copy Comments Order to Invoice';
            ToolTip = 'Specifies whether to copy comments from purchase orders to purchase invoices.';
            InitValue = true;
        }
        field(24; "Copy Comments Order to Receipt"; Boolean)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Copy Comments Order to Receipt';
            ToolTip = 'Specifies whether to copy comments from purchase orders to receipts.';
            InitValue = true;
        }
        field(25; "Allow VAT Difference"; Boolean)
        {
            Caption = 'Allow VAT Difference';
            ToolTip = 'Specifies whether to allow the manual adjustment of VAT amounts in purchase documents.';
        }
        field(26; "Calc. Inv. Disc. per VAT ID"; Boolean)
        {
            Caption = 'Calc. Inv. Disc. per VAT ID';
            ToolTip = 'Specifies whether the invoice discount is calculated according to the VAT identifier that is defined in the VAT posting setup. If you choose not to select this check box, the invoice discount will be calculated based on the invoice total.';
        }
        field(27; "Posted Prepmt. Inv. Nos."; Code[20])
        {
            Caption = 'Posted Prepmt. Inv. Nos.';
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to posted purchase prepayment invoices.';
            TableRelation = "No. Series";
        }
        field(28; "Posted Prepmt. Cr. Memo Nos."; Code[20])
        {
            Caption = 'Posted Prepmt. Cr. Memo Nos.';
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to purchase prepayment credit memos.';
            TableRelation = "No. Series";
        }
        field(29; "Check Prepmt. when Posting"; Boolean)
        {
            Caption = 'Check Prepmt. when Posting';
            ToolTip = 'Specifies that you cannot receive or invoice an order that has an unpaid prepayment amount.';
        }
        field(33; "Prepmt. Auto Update Frequency"; Option)
        {
            Caption = 'Prepmt. Auto Update Frequency';
            ToolTip = 'Specifies how often the job must run that automatically updates the status of orders that are pending prepayment.';
            DataClassification = SystemMetadata;
            OptionCaption = 'Never,Daily,Weekly';
            OptionMembers = Never,Daily,Weekly;

            trigger OnValidate()
            var
                PrepaymentMgt: Codeunit "Prepayment Mgt.";
            begin
                if "Prepmt. Auto Update Frequency" = xRec."Prepmt. Auto Update Frequency" then
                    exit;

                PrepaymentMgt.CreateAndStartJobQueueEntryPurchase("Prepmt. Auto Update Frequency");
            end;
        }
        field(35; "Default Posting Date"; Enum "Default Posting Date")
        {
            Caption = 'Default Posting Date';
            ToolTip = 'Specifies which date must be used as the default posting date on purchase documents. If you select Work Date, the Posting Date field will be populated with the work date at the time of creating a new purchase document. If you select No Date, the Posting Date field will be empty by default and you must manually enter a posting date before posting.';
        }
        field(36; "Default Qty. to Receive"; Option)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Default Qty. to Receive';
            OptionCaption = 'Remainder,Blank';
            OptionMembers = Remainder,Blank;
            ToolTip = 'Specifies the default value for the Qty. to Receive field on purchase order lines and the Return Qty. to Ship field on purchase return order lines. If you choose Blank, the quantity to receive is not automatically calculated.';
        }
        field(38; "Post with Job Queue"; Boolean)
        {
            Caption = 'Post with Job Queue';
            ToolTip = 'Specifies if you use job queues to post purchase documents in the background.';

            trigger OnValidate()
            begin
                if not "Post with Job Queue" then
                    "Post & Print with Job Queue" := false;
            end;
        }
        field(39; "Job Queue Category Code"; Code[10])
        {
            Caption = 'Job Queue Category Code';
            ToolTip = 'Specifies the code for the category of the job queue that you want to associate with background posting.';
            TableRelation = "Job Queue Category";
        }
        field(40; "Job Queue Priority for Post"; Integer)
        {
            Caption = 'Job Queue Priority for Post';
            InitValue = 1000;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Job Queue Priority for Post" < 0 then
                    Error(Text001);
            end;
        }
        field(41; "Post & Print with Job Queue"; Boolean)
        {
            Caption = 'Post & Print with Job Queue';
            ToolTip = 'Specifies if you use job queues to post and print purchase documents in the background.';

            trigger OnValidate()
            begin
                if "Post & Print with Job Queue" then
                    "Post with Job Queue" := true;
            end;
        }
        field(42; "Job Q. Prio. for Post & Print"; Integer)
        {
            Caption = 'Job Q. Prio. for Post & Print';
            InitValue = 1000;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Job Queue Priority for Post" < 0 then
                    Error(Text001);
            end;
        }
        field(43; "Notify On Success"; Boolean)
        {
            Caption = 'Notify On Success';
            ToolTip = 'Specifies a setting that has no effect. Legacy field.';
        }
        field(46; "Allow Document Deletion Before"; Date)
        {
            Caption = 'Allow Document Deletion Before';
            ToolTip = 'Specifies if and when posted purchase invoices and credit memos can be deleted. If you enter a date, posted purchase documents with a posting date on or after this date cannot be deleted.';
        }
        field(47; "Report Output Type"; Enum "Setup Report Output Type")
        {
            Caption = 'Report Output Type';
            ToolTip = 'Specifies the output of the report that will be scheduled with a job queue entry when the Post and Print with Job Queue check box is selected.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                EnvironmentInformation: Codeunit "Environment Information";
            begin
                if "Report Output Type" = "Report Output Type"::Print then
                    if EnvironmentInformation.IsSaaS() then
                        TestField("Report Output Type", "Report Output Type"::PDF);
            end;
        }
        field(49; "Document Default Line Type"; Enum "Purchase Line Type")
        {
            Caption = 'Document Default Line Type';
            ToolTip = 'Specifies the default value for the Type field on the first line in new purchase documents. If needed, you can change the value on the line.';
        }
        field(51; "Default G/L Account Quantity"; Boolean)
        {
            Caption = 'Default G/L Account Quantity';
            ToolTip = 'Specifies that Quantity is set to 1 on lines of type G/L Account.';
        }
        field(52; "Archive Quotes"; Option)
        {
            Caption = 'Archive Quotes';
            ToolTip = 'Specifies if you want to automatically archive purchase quotes when: deleted, processed or printed.';
            OptionCaption = 'Never,Question,Always';
            OptionMembers = Never,Question,Always;
        }
        field(53; "Archive Orders"; Boolean)
        {
            Caption = 'Archive Orders';
            ToolTip = 'Specifies if you want to automatically archive purchase orders when: deleted, posted or printed.';
        }
        field(54; "Archive Blanket Orders"; Boolean)
        {
            Caption = 'Archive Blanket Orders';
            ToolTip = 'Specifies if you want to automatically archive purchase blanket orders when: deleted, processed or printed.';
        }
        field(55; "Archive Return Orders"; Boolean)
        {
            Caption = 'Archive Return Orders';
            ToolTip = 'Specifies if you want to automatically archive purchase return orders when deleted or posted.';
        }
        field(56; "Ignore Updated Addresses"; Boolean)
        {
            Caption = 'Ignore Updated Addresses';
            ToolTip = 'Specifies if changes to addresses made on purchase documents are copied to the vendor card. By default, changes are copied to the vendor card.';
        }
#if not CLEANSCHEMA29        
        field(57; "Create Item from Item No."; Boolean)
        {
            Caption = 'Create Item from Item No.';
            ToolTip = 'Specifies if the system will suggest to create a new item when no item matches the number that you enter in the No. Field on purchase lines.';
            ObsoleteReason = 'Discontinued function';
#if CLEAN27
            ObsoleteState = Removed;
            ObsoleteTag = '29.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '27.0';
#endif
        }
#endif        
        field(58; "Copy Vendor Name to Entries"; Boolean)
        {
            Caption = 'Copy Vendor Name to Entries';
            ToolTip = 'Specifies if you want the name on vendor cards to be copied to vendor ledger entries during posting.';

            trigger OnValidate()
            var
                UpdateNameInLedgerEntries: Codeunit "Update Name In Ledger Entries";
            begin
                if "Copy Vendor Name to Entries" then
                    UpdateNameInLedgerEntries.NotifyAboutBlankNamesInLedgerEntries(RecordId);
            end;
        }
        field(59; "Copy Inv. No. To Pmt. Ref."; Boolean)
        {
            Caption = 'Copy Invoice No. To Payment Reference';
            ToolTip = 'Specifies if the value of the Vendor Invoice No. field must be copied to the Payment Reference field during posting unless the Payment Reference field is not blank.';
        }
        field(160; "Disable Search by Name"; Boolean)
        {
            Caption = 'Disable Search by Name';
            ToolTip = 'Specifies that you can change the names of vendors on open purchase documents. The change applies only to the documents.';
            DataClassification = SystemMetadata;
        }
        field(175; "Allow Multiple Posting Groups"; Boolean)
        {
            Caption = 'Allow Multiple Posting Groups';
            ToolTip = 'Specifies if multiple posting groups can be used for the same vendor in purchase documents.';
            DataClassification = SystemMetadata;
        }
        field(176; "Check Multiple Posting Groups"; enum "Posting Group Change Method")
        {
            Caption = 'Check Multiple Posting Groups';
            ToolTip = 'Specifies implementation method of checking which posting groups can be used for the vendor.';
            DataClassification = SystemMetadata;
        }
        field(200; "P. Invoice Template Name"; Code[10])
        {
            Caption = 'Purch. Invoice Template Name';
            ToolTip = 'Specifies that you can select the journal template to use for posting purchase invoices.';
            TableRelation = "Gen. Journal Template" where(Type = filter(Purchases));
        }
        field(201; "P. Cr. Memo Template Name"; Code[10])
        {
            Caption = 'Purch. Cr. Memo Template Name';
            ToolTip = 'Specifies that you can select the journal template to use for posting purchase credit memos.';
            TableRelation = "Gen. Journal Template" where(Type = filter(Purchases));
        }
        field(202; "P. Prep. Inv. Template Name"; Code[10])
        {
            Caption = 'P. Prep. Invoice Template Name';
            ToolTip = 'Specifies which general journal template to use for purchase prepayment invoices.';
            TableRelation = "Gen. Journal Template" where(Type = filter(Purchases));
        }
        field(203; "P. Prep. Cr.Memo Template Name"; Code[10])
        {
            Caption = 'Purch. Prep. Cr. Memo Template Name';
            ToolTip = 'Specifies which general journal template to use for purchase prepayment credit memos.';
            TableRelation = "Gen. Journal Template" where(Type = filter(Purchases));
        }
        field(204; "IC Purch. Invoice Templ. Name"; Code[10])
        {
            Caption = 'IC Jnl. Templ. Purch. Invoice';
            ToolTip = 'Specifies the intercompany journal template to use for purchase invoices.';
            TableRelation = "Gen. Journal Template" where(Type = filter(Intercompany));
        }
        field(205; "IC Purch. Cr. Memo Templ. Name"; Code[10])
        {
            Caption = 'IC Jnl. Templ. Purch. Cr. Memo';
            ToolTip = 'Specifies the intercompany journal template to use for posting purchase credit memos.';
            TableRelation = "Gen. Journal Template" where(Type = filter(Intercompany));
        }
        field(210; "Copy Line Descr. to G/L Entry"; Boolean)
        {
            Caption = 'Copy Line Descr. to G/L Entry';
            ToolTip = 'Specifies that the description on document lines of type G/L Account will be carried to the resulting general ledger entries.';
            DataClassification = SystemMetadata;
        }
        field(1217; "Debit Acc. for Non-Item Lines"; Code[20])
        {
            Caption = 'Debit Acc. for Non-Item Lines';
            ToolTip = 'Specifies the G/L account that is automatically inserted on purchase lines of type debit that are created from electronic documents when the incoming document line does not contain an identifiable item. Any incoming document line that does not have a GTIN or the vendor''s item number will be converted to a purchase line of type G/L Account, and the No. field on the purchase line will contain the account that you select in the G/L Account for Non-Item Lines field.';
            TableRelation = "G/L Account" where("Direct Posting" = const(true),
                                                 "Account Type" = const(Posting),
                                                 Blocked = const(false));
        }
        field(1218; "Credit Acc. for Non-Item Lines"; Code[20])
        {
            Caption = 'Credit Acc. for Non-Item Lines';
            ToolTip = 'Specifies the G/L account that is automatically inserted on purchase lines of type credit that are created from electronic documents when the incoming document line does not contain an identifiable item. Any incoming document line that does not have a GTIN or the vendor''s item number will be converted to a purchase line of type G/L Account, and the No. field on the purchase line will contain the account that you select in the G/L Account for Non-Item Lines field.';
            TableRelation = "G/L Account" where("Direct Posting" = const(true),
                                                 "Account Type" = const(Posting),
                                                 Blocked = const(false));
        }
        field(5775; "Auto Post Non-Invt. via Whse."; Enum "Non-Invt. Item Whse. Policy")
        {
            Caption = 'Auto Post Non-Invt. via Whse.';
            ToolTip = 'Specifies if non-inventory item lines in a purchase document will be posted automatically when the document is posted via warehouse. None: Do not automatically post non-inventory item lines. Attached/Assigned: Post item charges and other non-inventory item lines assigned or attached to regular items. All: Post all non-inventory item lines.';
        }
        field(5800; "Posted Return Shpt. Nos."; Code[20])
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            Caption = 'Posted Return Shpt. Nos.';
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to posted return shipments.';
            TableRelation = "No. Series";
        }
        field(5801; "Copy Cmts Ret.Ord. to Ret.Shpt"; Boolean)
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            Caption = 'Copy Cmts Ret.Ord. to Ret.Shpt';
            ToolTip = 'Specifies that comments are copied from the purchase return order to the posted return shipment.';
            InitValue = true;
        }
        field(5802; "Copy Cmts Ret.Ord. to Cr. Memo"; Boolean)
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            Caption = 'Copy Cmts Ret.Ord. to Cr. Memo';
            ToolTip = 'Specifies whether to copy comments from purchase return orders to purchase credit memos.';
            InitValue = true;
        }
        field(6600; "Return Order Nos."; Code[20])
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            Caption = 'Return Order Nos.';
            ToolTip = 'Specifies the number series that is used to assign numbers to new purchase return orders.';
            TableRelation = "No. Series";
        }
        field(6601; "Return Shipment on Credit Memo"; Boolean)
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            Caption = 'Return Shipment on Credit Memo';
            ToolTip = 'Specifies that a posted return shipment and a posted purchase credit memo are automatically created when you post a credit memo.';
        }
        field(6602; "Exact Cost Reversing Mandatory"; Boolean)
        {
            Caption = 'Exact Cost Reversing Mandatory';
            ToolTip = 'Specifies that a return transaction cannot be posted unless the Appl.-to Item Entry field on the purchase order line specifies an entry.';
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
            ToolTip = 'Specifies the price calculation method that will be default for purchase transactions.';
            InitValue = "Lowest Price";

            trigger OnValidate()
            var
                PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
                PriceType: Enum "Price Type";
            begin
                PriceCalculationMgt.VerifyMethodImplemented("Price Calculation Method", PriceType::Purchase);
            end;
        }
        field(7001; "Price List Nos."; Code[20])
        {
            Caption = 'Price List Nos.';
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to purchase price lists.';
            TableRelation = "No. Series";
            DataClassification = CustomerContent;
        }
        field(7002; "Allow Editing Active Price"; Boolean)
        {
            Caption = 'Allow Editing Active Price';
            ToolTip = 'Specifies it the existing active purchase price line can be modified or removed, or a new price line can be added to the active price list.';
            DataClassification = SystemMetadata;
        }
        field(7003; "Default Price List Code"; Code[20])
        {
            Caption = 'Default Price List Code';
            ToolTip = 'Specifies the code of the existing purchase price list that stores all new price lines created in the price worksheet page.';
            TableRelation = "Price List Header" where("Price Type" = const(Purchase), "Source Group" = const(Vendor), "Allow Updating Defaults" = const(true));
            DataClassification = CustomerContent;

            trigger OnLookup()
            var
                PriceListHeader: Record "Price List Header";
            begin
                if Page.RunModal(Page::"Purchase Price Lists", PriceListHeader) = Action::LookupOK then begin
                    PriceListHeader.TestField("Allow Updating Defaults");
                    Validate("Default Price List Code", PriceListHeader.Code);
                end;
            end;
        }
        field(7004; "Link Doc. Date To Posting Date"; Boolean)
        {
            Caption = 'Link Doc. Date to Posting Date';
            ToolTip = 'Specifies whether the document date changes when the posting date is modified.';
            DataClassification = SystemMetadata;
        }
        field(10500; "Posting Date Check on Posting"; Boolean)
        {
            Caption = 'Posting Date Check on Posting';
            ToolTip = 'Specifies if you want to see a warning when you post a purchase document with a posting date that is different from the Work Date.';
        }
#pragma warning disable AS0005
        field(11320; "Check Doc. Total Amounts"; Boolean)
        {
            Caption = 'Check Doc. Total Amounts';
            ToolTip = 'Specifies if you want the Doc. Amount Incl. VAT field in Purchase Invoice and Purchase Credit Memo to be compared to the sum of the VAT amounts fields in the purchase lines. If the amounts are not the same, you will be notified when posting the document. The totals will always be checked for invoices received from e-documents.';
        }
#pragma warning restore AS0005
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
#pragma warning disable AA0074
        Text001: Label 'Job Queue Priority must be zero or positive.';
#pragma warning restore AA0074
        RecordHasBeenRead: Boolean;

    procedure GetRecordOnce()
    begin
        if RecordHasBeenRead then
            exit;
        Get();
        RecordHasBeenRead := true;
    end;

    procedure JobQueueActive(): Boolean
    begin
        Get();
        exit("Post with Job Queue" or "Post & Print with Job Queue");
    end;

    procedure ShouldDocumentTotalAmountsBeChecked(PurchaseHeader: Record "Purchase Header"): Boolean
    var
        ValueFromExtension: Boolean;
    begin
        // Only invoices and credit memos are checked for document total amounts
        if (PurchaseHeader."Document Type" <> PurchaseHeader."Document Type"::Invoice) and
           (PurchaseHeader."Document Type" <> PurchaseHeader."Document Type"::"Credit Memo") and
           (PurchaseHeader."No." <> '') then
            exit(false);
        // If the system is setup to check the document totals, we will check it regardless of the extensions
        if Rec."Check Doc. Total Amounts" then
            exit(true);
        OnAfterShouldDocumentTotalAmountsBeChecked(PurchaseHeader, ValueFromExtension);
        exit(ValueFromExtension);
    end;

    procedure CanDocumentTotalAmountsBeEdited(PurchaseHeader: Record "Purchase Header") ExitValue: Boolean
    begin
        // By default, if the amounts are shown in the document they can be edited, however we provide an event to allow extensions to change this behavior.
        ExitValue := true;
        OnCanDocumentTotalAmountsBeEditable(PurchaseHeader, ExitValue);
    end;

    /// <summary>
    /// Event to customize whether the document total amounts should be checked or not. If the system is configured to check the document totals, it will be checked regardless of the code executed in this event.
    /// When using this event, consider that it can have multiple subscribers: it's a good practice to check the value that ShouldDocumentTotalAmountsBeChecked has before changing it.
    /// </summary>
    /// <param name="PurchaseHeader">The Purchase Header that we want to know if we should check the totals of.</param>
    /// <param name="ShouldDocumentTotalAmountsBeChecked">Out-parameter</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterShouldDocumentTotalAmountsBeChecked(PurchaseHeader: Record "Purchase Header"; var ShouldDocumentTotalAmountsBeChecked: Boolean)
    begin
    end;

    /// <summary>
    /// Event to customize whether the document total amounts can be edited or not. By default, if the amounts are shown in the document they can be edited, however we provide an event to allow extensions to change this behavior. 
    /// When using this event, consider that it can have multiple subscribers: it's a good practice to check the value that CanDocumentTotalAmountsBeEdited has before changing it.
    /// </summary>
    /// <param name="PurchaseHeader">The Purchase Header that we want to know if it can be edited.</param>
    /// <param name="CanDocumentTotalAmountsBeEdited">Out-parameter</param>
    [IntegrationEvent(false, false)]
    local procedure OnCanDocumentTotalAmountsBeEditable(PurchaseHeader: Record "Purchase Header"; var CanDocumentTotalAmountsBeEdited: Boolean)
    begin
    end;

}
