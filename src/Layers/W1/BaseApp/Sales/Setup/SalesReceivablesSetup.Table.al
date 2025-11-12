// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Setup;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Integration.D365Sales;
using Microsoft.Integration.Dataverse;
using Microsoft.Inventory.Item;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Pricing;
using Microsoft.Warehouse.Structure;
using Microsoft.Upgrade;
using Microsoft.Utilities;
using System.Environment;
using System.Threading;

table 311 "Sales & Receivables Setup"
{
    Caption = 'Sales & Receivables Setup';
    DrillDownPageID = "Sales & Receivables Setup";
    LookupPageID = "Sales & Receivables Setup";
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
            OptionCaption = 'No Discounts,Invoice Discounts,Line Discounts,All Discounts';
            OptionMembers = "No Discounts","Invoice Discounts","Line Discounts","All Discounts";
            ToolTip = 'Specifies the type of sales discounts to post separately. No Discounts: Discounts are not posted separately but instead will subtract the discount before posting. Invoice Discounts: The invoice discount and invoice amount are posted simultaneously, based on the Sales Inv. Disc. Account field in the General Posting Setup window. Line Discounts: The line discount and the invoice amount will be posted simultaneously, based on Sales Line Disc. Account field in the General Posting Setup window. All Discounts: The invoice and line discounts and the invoice amount will be posted simultaneously, based on the Sales Inv. Disc. Account field and Sales Line. Disc. Account fields in the General Posting Setup window.';

            trigger OnValidate()
            var
                DiscountNotificationMgt: Codeunit "Discount Notification Mgt.";
            begin
                DiscountNotificationMgt.NotifyAboutMissingSetup(RecordId, '', "Discount Posting", 0);
            end;
        }
        field(4; "Credit Warnings"; Option)
        {
            Caption = 'Credit Warnings';
            OptionCaption = 'Both Warnings,Credit Limit,Overdue Balance,No Warning';
            OptionMembers = "Both Warnings","Credit Limit","Overdue Balance","No Warning";
            ToolTip = 'Specifies whether to warn about the customer''s status when you create a sales order or invoice.';
        }
        field(5; "Stockout Warning"; Boolean)
        {
            Caption = 'Stockout Warning';
            InitValue = true;
            ToolTip = 'Specifies if a warning is displayed when you enter a quantity on a sales document that brings the item''s inventory level below zero.';
        }
        field(6; "Shipment on Invoice"; Boolean)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Shipment on Invoice';
            ToolTip = 'Specifies if a posted shipment and a posted invoice are automatically created when you post an invoice.';
        }
        field(7; "Invoice Rounding"; Boolean)
        {
            Caption = 'Invoice Rounding';
            ToolTip = 'Specifies if amounts are rounded for sales invoices. Rounding is applied as specified in the Inv. Rounding Precision (LCY) field in the General Ledger Setup window. ';
        }
        field(8; "Ext. Doc. No. Mandatory"; Boolean)
        {
            Caption = 'Ext. Doc. No. Mandatory';
            ToolTip = 'Specifies if it is mandatory to enter an external document number in the External Document No. field on a sales header or the External Document No. field on a general journal line.';
        }
        field(9; "Customer Nos."; Code[20])
        {
            Caption = 'Customer Nos.';
            TableRelation = "No. Series";
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to customers.';
        }
        field(10; "Quote Nos."; Code[20])
        {
            Caption = 'Quote Nos.';
            TableRelation = "No. Series";
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to sales quotes.';
        }
        field(11; "Order Nos."; Code[20])
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Order Nos.';
            TableRelation = "No. Series";
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to sales orders.';
        }
        field(12; "Invoice Nos."; Code[20])
        {
            Caption = 'Invoice Nos.';
            TableRelation = "No. Series";
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to sales invoices.';
        }
        field(13; "Posted Invoice Nos."; Code[20])
        {
            Caption = 'Posted Invoice Nos.';
            TableRelation = "No. Series";
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to posted sales invoices.';
        }
        field(14; "Credit Memo Nos."; Code[20])
        {
            Caption = 'Credit Memo Nos.';
            TableRelation = "No. Series";
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to sales credit memos.';
        }
        field(15; "Posted Credit Memo Nos."; Code[20])
        {
            Caption = 'Posted Credit Memo Nos.';
            TableRelation = "No. Series";
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to posted sales credit memos.';
        }
        field(16; "Posted Shipment Nos."; Code[20])
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Posted Shipment Nos.';
            TableRelation = "No. Series";
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to posted shipments.';
        }
        field(17; "Reminder Nos."; Code[20])
        {
            Caption = 'Reminder Nos.';
            TableRelation = "No. Series";
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to reminders.';
        }
        field(18; "Issued Reminder Nos."; Code[20])
        {
            Caption = 'Issued Reminder Nos.';
            TableRelation = "No. Series";
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to issued reminders.';
        }
        field(19; "Fin. Chrg. Memo Nos."; Code[20])
        {
            Caption = 'Fin. Chrg. Memo Nos.';
            TableRelation = "No. Series";
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to finance charge memos.';
        }
        field(20; "Issued Fin. Chrg. M. Nos."; Code[20])
        {
            Caption = 'Issued Fin. Chrg. M. Nos.';
            TableRelation = "No. Series";
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to issued finance charge memos.';
        }
        field(21; "Posted Prepmt. Inv. Nos."; Code[20])
        {
            Caption = 'Posted Prepmt. Inv. Nos.';
            TableRelation = "No. Series";
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to posted sales prepayment invoices.';
        }
        field(22; "Posted Prepmt. Cr. Memo Nos."; Code[20])
        {
            Caption = 'Posted Prepmt. Cr. Memo Nos.';
            TableRelation = "No. Series";
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to posted sales prepayment credit memos.';
        }
        field(23; "Blanket Order Nos."; Code[20])
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Blanket Order Nos.';
            TableRelation = "No. Series";
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to blanket sales orders.';
        }
        field(24; "Calc. Inv. Discount"; Boolean)
        {
            Caption = 'Calc. Inv. Discount';
            ToolTip = 'Specifies if the invoice discount amount is automatically calculated with sales documents. If this check box is selected, then the invoice discount amount is calculated automatically, based on sales lines where the Allow Invoice Disc. field is selected.';
        }
        field(25; "Appln. between Currencies"; Option)
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Appln. between Currencies';
            OptionCaption = 'None,EMU,All';
            OptionMembers = "None",EMU,All;
            ToolTip = 'Specifies whether it is allowed to apply customer payments in different currencies. None: All entries involved in one application must be in the same currency. EMU: You can apply entries in euro and one of the old national currencies (for EMU countries/regions) to one another. All: You can apply entries in different currencies to one another. The entries can be in any currency.';
        }
        field(26; "Copy Comments Blanket to Order"; Boolean)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Copy Comments Blanket to Order';
            InitValue = true;
            ToolTip = 'Specifies whether to copy comments from blanket sales orders to sales orders.';
        }
        field(27; "Copy Comments Order to Invoice"; Boolean)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Copy Comments Order to Invoice';
            InitValue = true;
            ToolTip = 'Specifies whether to copy comments from sales orders to sales invoices.';
        }
        field(28; "Copy Comments Order to Shpt."; Boolean)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Copy Comments Order to Shpt.';
            InitValue = true;
            ToolTip = 'Specifies whether to copy comments from sales orders to shipments.';
        }
        field(29; "Allow VAT Difference"; Boolean)
        {
            Caption = 'Allow VAT Difference';
            ToolTip = 'Specifies whether to allow the manual adjustment of VAT amounts in sales documents.';
        }
        field(30; "Calc. Inv. Disc. per VAT ID"; Boolean)
        {
            Caption = 'Calc. Inv. Disc. per VAT ID';
            ToolTip = 'Specifies whether the invoice discount is calculated according to the VAT identifier that is defined in the VAT posting setup. If you choose not to select this check box, the invoice discount will be calculated based on the invoice total.';
        }
        field(31; "Logo Position on Documents"; Option)
        {
            Caption = 'Logo Position on Documents';
            OptionCaption = 'No Logo,Left,Center,Right';
            OptionMembers = "No Logo",Left,Center,Right;
            ToolTip = 'Specifies the position of your company logo on business letters and documents.';
        }
        field(32; "Check Prepmt. when Posting"; Boolean)
        {
            Caption = 'Check Prepmt. when Posting';
            ToolTip = 'Specifies that you cannot ship or invoice an order that has an unpaid prepayment amount.';
        }
        field(33; "Prepmt. Auto Update Frequency"; Option)
        {
            Caption = 'Prepmt. Auto Update Frequency';
            DataClassification = SystemMetadata;
            OptionCaption = 'Never,Daily,Weekly';
            OptionMembers = Never,Daily,Weekly;
            ToolTip = 'Specifies how often the job must run that automatically updates the status of orders that are pending prepayment.';

            trigger OnValidate()
            var
                PrepaymentMgt: Codeunit "Prepayment Mgt.";
            begin
                if "Prepmt. Auto Update Frequency" = xRec."Prepmt. Auto Update Frequency" then
                    exit;

                PrepaymentMgt.CreateAndStartJobQueueEntrySales("Prepmt. Auto Update Frequency");
            end;
        }
        field(35; "Default Posting Date"; Enum "Default Posting Date")
        {
            Caption = 'Default Posting Date';
            ToolTip = 'Specifies which date must be used as the default posting date on sales documents. If you select Work Date, the Posting Date field will be populated with the work date at the time of creating a new sales document. If you select No Date, the Posting Date field will be empty by default and you must manually enter a posting date before posting.';
        }
        field(36; "Default Quantity to Ship"; Option)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Default Quantity to Ship';
            OptionCaption = 'Remainder,Blank';
            OptionMembers = Remainder,Blank;
            ToolTip = 'Specifies the default value for the Qty. to Ship field on sales order lines and the Return Qty. to Receive field on sales return order lines. If you choose Blank, the quantity to ship is not automatically calculated.';
        }
        field(38; "Post with Job Queue"; Boolean)
        {
            Caption = 'Post with Job Queue';
            ToolTip = 'Specifies if you use job queues to post sales documents in the background.';

            trigger OnValidate()
            begin
                if not "Post with Job Queue" then
                    "Post & Print with Job Queue" := false;
            end;
        }
        field(39; "Job Queue Category Code"; Code[10])
        {
            Caption = 'Job Queue Category Code';
            TableRelation = "Job Queue Category";
            ToolTip = 'Specifies the code for the category of the job queue that you want to associate with background posting.';
        }
        field(40; "Job Queue Priority for Post"; Integer)
        {
            Caption = 'Job Queue Priority for Post';
            InitValue = 1000;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Job Queue Priority for Post" < 0 then
                    Error(JobQueuePriorityErr);
            end;
        }
        field(41; "Post & Print with Job Queue"; Boolean)
        {
            Caption = 'Post & Print with Job Queue';
            ToolTip = 'Specifies if you use job queues to post and print sales documents in the background.';

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
                    Error(JobQueuePriorityErr);
            end;
        }
        field(43; "Notify On Success"; Boolean)
        {
            Caption = 'Notify On Success';
            ToolTip = 'Specifies a setting that has no effect. Legacy field.';
        }
        field(44; "VAT Bus. Posting Gr. (Price)"; Code[20])
        {
            Caption = 'VAT Bus. Posting Gr. (Price)';
            TableRelation = "VAT Business Posting Group";
            ToolTip = 'Specifies a VAT business posting group for customers for whom you want the item price including VAT to apply.';
        }
        field(45; "Direct Debit Mandate Nos."; Code[20])
        {
            Caption = 'Direct Debit Mandate Nos.';
            TableRelation = "No. Series";
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to direct-debit mandates.';
        }
        field(46; "Allow Document Deletion Before"; Date)
        {
            Caption = 'Allow Document Deletion Before';
            ToolTip = 'Specifies if and when posted sales invoices and credit memos can be deleted. If you enter a date, posted sales documents with a posting date on or after this date cannot be deleted.';
        }
        field(47; "Report Output Type"; Enum "Setup Report Output Type")
        {
            Caption = 'Report Output Type';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the output of the report that will be scheduled with a job queue entry when the Post and Print with Job Queue check box is selected.';

            trigger OnValidate()
            var
                EnvironmentInformation: Codeunit "Environment Information";
            begin
                if "Report Output Type" = "Report Output Type"::Print then
                    if EnvironmentInformation.IsSaaS() then
                        TestField("Report Output Type", "Report Output Type"::PDF);
            end;
        }
        field(49; "Document Default Line Type"; Enum "Sales Line Type")
        {
            Caption = 'Document Default Line Type';
            ToolTip = 'Specifies the default value for the Type field on the first line in new sales documents. If needed, you can change the value on the line.';
        }
        field(50; "Default Item Quantity"; Boolean)
        {
            Caption = 'Default Item Quantity';
            ToolTip = 'Specifies that the Quantity field is set to 1 when you fill in the Item No. field.';
        }
        field(51; "Create Item from Description"; Boolean)
        {
            Caption = 'Create Item from Description';
            ToolTip = 'Specifies if the system will suggest to create a new item when no item matches the description that you enter in the Description field on sales lines.';
        }
        field(52; "Archive Quotes"; Option)
        {
            Caption = 'Archive Quotes';
            OptionCaption = 'Never,Question,Always';
            OptionMembers = Never,Question,Always;
            ToolTip = 'Specifies if you want to automatically archive sales quotes when: deleted, processed or printed.';
        }
        field(53; "Archive Orders"; Boolean)
        {
            Caption = 'Archive Orders';
            ToolTip = 'Specifies if you want to automatically archive sales orders when: deleted, posted or printed.';

            trigger OnValidate()
            var
                CRMConnectionSetup: Record "CRM Connection Setup";
            begin
                if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then
                    Error(CRMBidirectionalSalesOrderIntEnabledErr);
            end;
        }
        field(54; "Archive Blanket Orders"; Boolean)
        {
            Caption = 'Archive Blanket Orders';
            ToolTip = 'Specifies if you want to automatically archive sales blanket orders when: deleted, processed or printed.';
        }
        field(55; "Archive Return Orders"; Boolean)
        {
            Caption = 'Archive Return Orders';
            ToolTip = 'Specifies if you want to automatically archive sales return orders when deleted or posted.';
        }
        field(56; "Default G/L Account Quantity"; Boolean)
        {
            Caption = 'Default G/L Account Quantity';
            ToolTip = 'Specifies that Quantity is set to 1 on lines of type G/L Account.';
        }
#if not CLEANSCHEMA29        
        field(57; "Create Item from Item No."; Boolean)
        {
            Caption = 'Create Item from Item No.';
            ToolTip = 'Specifies if the system will suggest to create a new item when no item matches the number that you enter in the No. Field on sales lines.';
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
        field(58; "Copy Customer Name to Entries"; Boolean)
        {
            Caption = 'Copy Customer Name to Entries';
            ToolTip = 'Specifies if you want the name on customer cards to be copied to customer ledger entries during posting.';

            trigger OnValidate()
            var
                UpdateNameInLedgerEntries: Codeunit "Update Name In Ledger Entries";
            begin
                if "Copy Customer Name to Entries" then
                    UpdateNameInLedgerEntries.NotifyAboutBlankNamesInLedgerEntries(RecordId);
            end;
        }
        field(61; "Ignore Updated Addresses"; Boolean)
        {
            Caption = 'Ignore Updated Addresses';
            ToolTip = 'Specifies if changes to addresses made on sales documents are copied to the customer card. By default, changes are copied to the customer card.';
        }
        field(65; "Skip Manual Reservation"; Boolean)
        {
            Caption = 'Skip Manual Reservation';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies that the reservation confirmation message is not shown on sales lines. This is useful to avoid noise when you are processing many lines.';
        }
        field(160; "Disable Search by Name"; Boolean)
        {
            Caption = 'Disable Search by Name';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies that you can change the names of customers on open sales documents. The change applies only to the documents.';
        }
        field(175; "Allow Multiple Posting Groups"; Boolean)
        {
            Caption = 'Allow Multiple Posting Groups';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies if multiple posting groups can be used for the same customer in sales documents.';
        }
        field(176; "Check Multiple Posting Groups"; enum "Posting Group Change Method")
        {
            Caption = 'Check Multiple Posting Groups';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies implementation method of checking which posting groups can be used for the customer.';
        }
        field(200; "Quote Validity Calculation"; DateFormula)
        {
            Caption = 'Quote Validity Calculation';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies a formula that determines how to calculate the quote expiration date based on the document date.';
        }
        field(201; "S. Invoice Template Name"; Code[10])
        {
            Caption = 'Sales Invoice Journal Template';
            TableRelation = "Gen. Journal Template" where(Type = filter(Sales));
            ToolTip = 'Specifies the journal template to use for posting sales invoices.';
        }
        field(202; "S. Cr. Memo Template Name"; Code[10])
        {
            Caption = 'Sales Cr. Memo Journal Template';
            TableRelation = "Gen. Journal Template" where(Type = filter(Sales));
            ToolTip = 'Specifies the journal template to use for posting sales credit memos.';
        }
        field(203; "S. Prep. Inv. Template Name"; Code[10])
        {
            Caption = 'Sales Prep. Invoice Template Name';
            TableRelation = "Gen. Journal Template" where(Type = filter(Sales));
            ToolTip = 'Specifies which general journal template to use for sales invoices.';
        }
        field(204; "S. Prep. Cr.Memo Template Name"; Code[10])
        {
            Caption = 'Sales Prep. Cr. Memo Template Name';
            TableRelation = "Gen. Journal Template" where(Type = filter(Sales));
            ToolTip = 'Specifies which general journal template to use for sales credit memos.';
        }
        field(205; "IC Sales Invoice Template Name"; Code[10])
        {
            Caption = 'IC Sales Invoice Template Name';
            TableRelation = "Gen. Journal Template" where(Type = filter(Intercompany));
            ToolTip = 'Specifies the intercompany journal template to use for sales invoices.';
        }
        field(206; "IC Sales Cr. Memo Templ. Name"; Code[10])
        {
            Caption = 'IC Sales Cr. Memo Template Name';
            TableRelation = "Gen. Journal Template" where(Type = filter(Intercompany));
            ToolTip = 'Specifies the intercompany journal template to use for sales credit memos.';
        }
        field(207; "Fin. Charge Jnl. Template Name"; Code[10])
        {
            Caption = 'Finance Charge Journal Template Name';
            TableRelation = "Gen. Journal Template" where(Type = filter(Sales));
            ToolTip = 'Specifies which general journal template to use for finance charges.';
        }
        field(208; "Reminder Journal Template Name"; Code[10])
        {
            Caption = 'Reminder Journal Template Name';
            TableRelation = "Gen. Journal Template" where(Type = filter(Sales));
            ToolTip = 'Specifies which general journal template to use for reminders.';
        }
        field(209; "Reminder Journal Batch Name"; Code[10])
        {
            Caption = 'Reminder Journal Batch Name';
            TableRelation = if ("Reminder Journal Template Name" = filter(<> '')) "Gen. Journal Batch".Name where("Journal Template Name" = field("Reminder Journal Template Name"));
            ToolTip = 'Specifies which general journal batch to use for reminders.';

            trigger OnValidate()
            begin
                TestField("Reminder Journal Template Name");
            end;
        }
        field(210; "Copy Line Descr. to G/L Entry"; Boolean)
        {
            Caption = 'Copy Line Descr. to G/L Entry';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies that the description on document lines of type G/L Account will be carried to the resulting general ledger entries.';
        }
        field(211; "Fin. Charge Jnl. Batch Name"; Code[10])
        {
            Caption = 'Finance Charge Journal Batch Name';
            TableRelation = if ("Fin. Charge Jnl. Template Name" = filter(<> '')) "Gen. Journal Batch".Name where("Journal Template Name" = field("Fin. Charge Jnl. Template Name"));
            ToolTip = 'Specifies which general journal batch to use for finance charges.';

            trigger OnValidate()
            begin
                TestField("Fin. Charge Jnl. Template Name");
            end;
        }
        field(393; "Canceled Issued Reminder Nos."; Code[20])
        {
            Caption = 'Canceled Issued Reminder Nos.';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to canceled issued reminders.';
        }
        field(395; "Canc. Iss. Fin. Ch. Mem. Nos."; Code[20])
        {
            Caption = 'Canceled Issued Fin. Charge Memo Nos.';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to canceled issued finance charge memos.';
        }
        field(5329; "Write-in Product Type"; Option)
        {
            Caption = 'Write-in Product Type';
            OptionCaption = 'Item,Resource';
            OptionMembers = Item,Resource;
            ToolTip = 'Specifies the sales line type that will be used for write-in products in Dynamics 365 Sales.';
        }
        field(5330; "Write-in Product No."; Code[20])
        {
            Caption = 'Write-in Product No.';
            TableRelation = if ("Write-in Product Type" = const(Item)) Item."No." where(Type = filter(Service | "Non-Inventory"))
            else
            if ("Write-in Product Type" = const(Resource)) Resource."No.";
            ToolTip = 'Specifies the number of the item or resource depending on the write-in product type that will be used for Dynamics 365 Sales.';

            trigger OnValidate()
            var
                Item: Record Item;
                Resource: Record Resource;
                CRMIntegrationRecord: Record "CRM Integration Record";
                CRMProductName: Codeunit "CRM Product Name";
                RecId: RecordId;
            begin
                case "Write-in Product Type" of
                    "Write-in Product Type"::Item:
                        begin
                            if not Item.Get("Write-in Product No.") then
                                exit;
                            RecId := Item.RecordId();
                        end;
                    "Write-in Product Type"::Resource:
                        begin
                            if not Resource.Get("Write-in Product No.") then
                                exit;
                            RecId := Resource.RecordId();
                        end;
                end;
                if CRMIntegrationRecord.FindByRecordID(RecId) then
                    Error(ProductCoupledErr, CRMProductName.Short());
            end;
        }
        field(5775; "Auto Post Non-Invt. via Whse."; Enum "Non-Invt. Item Whse. Policy")
        {
            Caption = 'Auto Post Non-Invt. via Whse.';
            ToolTip = 'Specifies if non-inventory item lines in a sales document will be posted automatically when the document is posted via warehouse. None: Do not automatically post non-inventory item lines. Attached/Assigned: Post item charges and other non-inventory item lines assigned or attached to regular items. All: Post all non-inventory item lines.';
        }
        field(5800; "Posted Return Receipt Nos."; Code[20])
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            Caption = 'Posted Return Receipt Nos.';
            TableRelation = "No. Series";
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to posted return receipts.';
        }
        field(5801; "Copy Cmts Ret.Ord. to Ret.Rcpt"; Boolean)
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            Caption = 'Copy Cmts Ret.Ord. to Ret.Rcpt';
            InitValue = true;
            ToolTip = 'Specifies that comments are copied from the sales return order to the posted return receipt.';
        }
        field(5802; "Copy Cmts Ret.Ord. to Cr. Memo"; Boolean)
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            Caption = 'Copy Cmts Ret.Ord. to Cr. Memo';
            InitValue = true;
            ToolTip = 'Specifies whether to copy comments from sales return orders to sales credit memos.';
        }
        field(6600; "Return Order Nos."; Code[20])
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            Caption = 'Return Order Nos.';
            TableRelation = "No. Series";
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to new sales return orders.';
        }
        field(6601; "Return Receipt on Credit Memo"; Boolean)
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            Caption = 'Return Receipt on Credit Memo';
            ToolTip = 'Specifies that a posted return receipt and a posted sales credit memo are automatically created when you post a credit memo.';
        }
        field(6602; "Exact Cost Reversing Mandatory"; Boolean)
        {
            Caption = 'Exact Cost Reversing Mandatory';
            ToolTip = 'Specifies that a return transaction cannot be posted unless the Appl.-from Item Entry field on the sales order line specifies an entry.';
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
            InitValue = "Lowest Price";
            ToolTip = 'Specifies the price calculation method that will be default for sales transactions.';

            trigger OnValidate()
            var
                PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
                PriceType: Enum "Price Type";
            begin
                PriceCalculationMgt.VerifyMethodImplemented("Price Calculation Method", PriceType::Sale);
            end;
        }
        field(7001; "Price List Nos."; Code[20])
        {
            Caption = 'Price List Nos.';
            TableRelation = "No. Series";
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to sales price lists.';
        }
        field(7002; "Allow Editing Active Price"; Boolean)
        {
            Caption = 'Allow Editing Active Price';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies it the existing active sales price line can be modified or removed, or a new price line can be added to the active price list.';
        }
        field(7003; "Default Price List Code"; Code[20])
        {
            Caption = 'Default Price List Code';
            TableRelation = "Price List Header" where("Price Type" = const(Sale), "Source Group" = const(Customer), "Allow Updating Defaults" = const(true));
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the code of the existing sales price list that stores all new price lines created in the price worksheet page.';

            trigger OnLookup()
            var
                PriceListHeader: Record "Price List Header";
            begin
                if Page.RunModal(Page::"Sales Price Lists", PriceListHeader) = Action::LookupOK then begin
                    PriceListHeader.TestField("Allow Updating Defaults");
                    Validate("Default Price List Code", PriceListHeader.Code);
                end;
            end;
        }
        field(7005; "Use Customized Lookup"; Boolean)
        {
            Caption = 'Use Your Custom Lookup';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether the Assign-to Parent No., Assign-to No., and Product No. fields on price list pages use standard lookups to find records. If you have customized these fields and prefer your implementation, turn on this toggle.';
        }
        field(7101; "Customer Group Dimension Code"; Code[20])
        {
            Caption = 'Customer Group Dimension Code';
            TableRelation = Dimension;
            ToolTip = 'Specifies the dimension code for customer groups in your analysis report.';
        }
        field(7102; "Salesperson Dimension Code"; Code[20])
        {
            Caption = 'Salesperson Dimension Code';
            TableRelation = Dimension;
            ToolTip = 'Specifies the dimension code for salespeople in your analysis report';
        }
        field(7103; "Freight G/L Acc. No."; Code[20])
        {
            Caption = 'Freight G/L Account No.';
            TableRelation = "G/L Account";
            ToolTip = 'Specifies the general ledger account that must be used to handle freight charges from Dynamics 365 Sales.';

            trigger OnValidate()
            begin
                CheckGLAccPostingTypeBlockedAndGenProdPostingType("Freight G/L Acc. No.");
            end;
        }
        field(7104; "Link Doc. Date To Posting Date"; Boolean)
        {
            Caption = 'Link Doc. Date to Posting Date';
            DataClassification = SystemMetadata;
            InitValue = true;
            ToolTip = 'Specifies whether the document date changes when the posting date is modified.';
        }
        field(10500; "Posting Date Check on Posting"; Boolean)
        {
            Caption = 'Posting Date Check on Posting';
        }
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
        JobQueuePriorityErr: Label 'Job Queue Priority must be zero or positive.';
        ProductCoupledErr: Label 'You must choose a record that is not coupled to a product in %1.', Comment = '%1 - Dynamics 365 Sales product name';
        RecordHasBeenRead: Boolean;
        CRMBidirectionalSalesOrderIntEnabledErr: Label 'You cannot disable Archive Orders when Dynamics 365 Sales connection and Bidirectional Sales Order Integration are enabled.';

    procedure GetRecordOnce()
    begin
        if RecordHasBeenRead then
            exit;
        Get();
        RecordHasBeenRead := true;
    end;

    procedure GetLegalStatement(): Text
    begin
        exit('');
    end;

    procedure JobQueueActive(): Boolean
    begin
        Get();
        exit("Post with Job Queue" or "Post & Print with Job Queue");
    end;

    local procedure CheckGLAccPostingTypeBlockedAndGenProdPostingType(AccNo: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        if AccNo <> '' then begin
            GLAccount.Get(AccNo);
            GLAccount.CheckGLAcc();
            GLAccount.TestField("Gen. Prod. Posting Group");
        end;
    end;
}
