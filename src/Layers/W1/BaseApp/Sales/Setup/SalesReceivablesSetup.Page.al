// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Setup;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Integration.Dataverse;
using Microsoft.Pricing.Calculation;
using Microsoft.Sales.Customer;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Reminder;
using Microsoft.Utilities;

page 459 "Sales & Receivables Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Sales & Receivables Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Sales & Receivables Setup";
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
                field("Credit Warnings"; Rec."Credit Warnings")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Stockout Warning"; Rec."Stockout Warning")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Shipment on Invoice"; Rec."Shipment on Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Return Receipt on Credit Memo"; Rec."Return Receipt on Credit Memo")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Invoice Rounding"; Rec."Invoice Rounding")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(DefaultItemQuantity; Rec."Default Item Quantity")
                {
                    ApplicationArea = Basic, Suite;
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
                field("Create Item from Description"; Rec."Create Item from Description")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Copy Customer Name to Entries"; Rec."Copy Customer Name to Entries")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Ext. Doc. No. Mandatory"; Rec."Ext. Doc. No. Mandatory")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Appln. between Currencies"; Rec."Appln. between Currencies")
                {
                    ApplicationArea = Suite;
                }
                field("Logo Position on Documents"; Rec."Logo Position on Documents")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Default Posting Date"; Rec."Default Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Default Quantity to Ship"; Rec."Default Quantity to Ship")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Auto Post Non-Invt. via Whse."; Rec."Auto Post Non-Invt. via Whse.")
                {
                    ApplicationArea = Warehouse;
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
                field("Copy Comments Order to Shpt."; Rec."Copy Comments Order to Shpt.")
                {
                    ApplicationArea = Comments;
                    Importance = Additional;
                }
                field("Copy Cmts Ret.Ord. to Cr. Memo"; Rec."Copy Cmts Ret.Ord. to Cr. Memo")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Copy Cmts Ret.Ord. to Ret.Rcpt"; Rec."Copy Cmts Ret.Ord. to Ret.Rcpt")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
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
                    Visible = false;
                }
                field("VAT Bus. Posting Gr. (Price)"; Rec."VAT Bus. Posting Gr. (Price)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Exact Cost Reversing Mandatory"; Rec."Exact Cost Reversing Mandatory")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
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
                field("Posting Date Check on Posting"; Rec."Posting Date Check on Posting")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want the program to warn you when you post a sales document with a posting date that is different from the Work Date.';
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
                field("Skip Manual Reservation"; Rec."Skip Manual Reservation")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Quote Validity Calculation"; Rec."Quote Validity Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Copy Line Descr. to G/L Entry"; Rec."Copy Line Descr. to G/L Entry")
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
                field("Update Document Date When Posting Date Is Modified"; Rec."Link Doc. Date To Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
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
                field("Use Customized Lookup"; Rec."Use Customized Lookup")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Dimensions)
            {
                Caption = 'Dimensions';
                field("Customer Group Dimension Code"; Rec."Customer Group Dimension Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Salesperson Dimension Code"; Rec."Salesperson Dimension Code")
                {
                    ApplicationArea = Dimensions;
                }
            }
            group("Number Series")
            {
                Caption = 'Number Series';
                field("Customer Nos."; Rec."Customer Nos.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Quote Nos."; Rec."Quote Nos.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Blanket Order Nos."; Rec."Blanket Order Nos.")
                {
                    ApplicationArea = Suite;
                }
                field("Order Nos."; Rec."Order Nos.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Return Order Nos."; Rec."Return Order Nos.")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("Invoice Nos."; Rec."Invoice Nos.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posted Invoice Nos."; Rec."Posted Invoice Nos.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Credit Memo Nos."; Rec."Credit Memo Nos.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posted Credit Memo Nos."; Rec."Posted Credit Memo Nos.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posted Shipment Nos."; Rec."Posted Shipment Nos.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posted Return Receipt Nos."; Rec."Posted Return Receipt Nos.")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("Reminder Nos."; Rec."Reminder Nos.")
                {
                    ApplicationArea = Suite;
                }
                field("Issued Reminder Nos."; Rec."Issued Reminder Nos.")
                {
                    ApplicationArea = Suite;
                }
                field("Canceled Issued Reminder Nos."; Rec."Canceled Issued Reminder Nos.")
                {
                    ApplicationArea = Suite;
                }
                field("Fin. Chrg. Memo Nos."; Rec."Fin. Chrg. Memo Nos.")
                {
                    ApplicationArea = Suite;
                }
                field("Issued Fin. Chrg. M. Nos."; Rec."Issued Fin. Chrg. M. Nos.")
                {
                    ApplicationArea = Suite;
                }
                field("Canc. Iss. Fin. Ch. Mem. Nos."; Rec."Canc. Iss. Fin. Ch. Mem. Nos.")
                {
                    ApplicationArea = Suite;
                }
                field("Posted Prepmt. Inv. Nos."; Rec."Posted Prepmt. Inv. Nos.")
                {
                    ApplicationArea = Prepayments;
                }
                field("Posted Prepmt. Cr. Memo Nos."; Rec."Posted Prepmt. Cr. Memo Nos.")
                {
                    ApplicationArea = Prepayments;
                }
                field("Direct Debit Mandate Nos."; Rec."Direct Debit Mandate Nos.")
                {
                    ApplicationArea = Basic, Suite;
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
                    ApplicationArea = Basic, Suite;
                }
                field("Post & Print with Job Queue"; Rec."Post & Print with Job Queue")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Job Queue Category Code"; Rec."Job Queue Category Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Notify On Success"; Rec."Notify On Success")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Report Output Type"; Rec."Report Output Type")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Archiving)
            {
                Caption = 'Archiving';
                field("Archive Quotes"; Rec."Archive Quotes")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Archive Blanket Orders"; Rec."Archive Blanket Orders")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Archive Orders"; Rec."Archive Orders")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Archive Return Orders"; Rec."Archive Return Orders")
                {
                    ApplicationArea = SalesReturnOrder;
                }
            }
            group("Journal Templates")
            {
                Caption = 'Journal Templates';
                Visible = JnlTemplateNameVisible;

                field("S. Invoice Template Name"; Rec."S. Invoice Template Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("S. Cr. Memo Template Name"; Rec."S. Cr. Memo Template Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("S. Prep. Inv. Template Name"; Rec."S. Prep. Inv. Template Name")
                {
                    ApplicationArea = Prepayments;
                }
                field("S. Prep. Cr.Memo Template Name"; Rec."S. Prep. Cr.Memo Template Name")
                {
                    ApplicationArea = Prepayments;
                }
                field("IC Sales Invoice Template Name"; Rec."IC Sales Invoice Template Name")
                {
                    ApplicationArea = Intercompany;
                }
                field("IC Sales Cr. Memo Templ. Name"; Rec."IC Sales Cr. Memo Templ. Name")
                {
                    ApplicationArea = Intercompany;
                }
                field("Fin. Charge Jnl. Template Name"; Rec."Fin. Charge Jnl. Template Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Fin. Charge Jnl. Batch Name"; Rec."Fin. Charge Jnl. Batch Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Reminder Journal Template Name"; Rec."Reminder Journal Template Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Reminder Journal Batch Name"; Rec."Reminder Journal Batch Name")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group("Dynamics 365 Sales")
            {
                Caption = 'Dynamics 365 Sales';
                Visible = CRMIntegrationEnabled;
                field("Write-in Product Type"; Rec."Write-in Product Type")
                {
                    ApplicationArea = Suite;
                }
                field("Write-in Product No."; Rec."Write-in Product No.")
                {
                    ApplicationArea = Suite;
                }
                field("Freight G/L Acc. No."; Rec."Freight G/L Acc. No.")
                {
                    ApplicationArea = Suite;
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
            action("Customer Posting Groups")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer Posting Groups';
                Image = CustomerGroup;
                RunObject = Page "Customer Posting Groups";
                ToolTip = 'Set up the posting groups to select from when you set up customer cards to link business transactions made for the customer with the appropriate account in the general ledger.';
            }
            action("Customer Price Groups")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer Price Groups';
                Image = Price;
                RunObject = Page "Customer Price Groups";
                ToolTip = 'Set up the posting groups to select from when you set up customer cards to link business transactions made for the customer with the appropriate account in the general ledger.';
            }
            action("Customer Disc. Groups")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer Disc. Groups';
                Image = Discount;
                RunObject = Page "Customer Disc. Groups";
                ToolTip = 'Set up discount group codes that you can use as criteria when you define special discounts on a customer, vendor, or item card.';
            }
            group(Payment)
            {
                Caption = 'Payment';
                action("Payment Registration Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Registration Setup';
                    Image = PaymentJournal;
                    RunObject = Page "Payment Registration Setup";
                    ToolTip = 'Set up the payment journal template and the balancing account that is used to post received customer payments. Define how you prefer to process customer payments in the Payment Registration window.';
                }
                action("Payment Methods")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Methods';
                    Image = Payment;
                    RunObject = Page "Payment Methods";
                    ToolTip = 'Set up the payment methods that you select from the customer card to define how the customer must pay, for example by bank transfer.';
                }
                action("Payment Terms")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Terms';
                    Image = Payment;
                    RunObject = Page "Payment Terms";
                    ToolTip = 'Set up the payment terms that you select from on customer cards to define when the customer must pay, such as within 14 days.';
                }
                action("Finance Charge Terms")
                {
                    ApplicationArea = Suite;
                    Caption = 'Finance Charge Terms';
                    Image = FinChargeMemo;
                    RunObject = Page "Finance Charge Terms";
                    ToolTip = 'Set up the finance charge terms that you select from on customer cards to define how to calculate interest in case the customer''s payment is late.';
                }
                action("Reminder Terms")
                {
                    ApplicationArea = Suite;
                    Caption = 'Reminder Terms';
                    Image = ReminderTerms;
                    RunObject = Page "Reminder Terms";
                    ToolTip = 'Set up reminder terms that you select from on customer cards to define when and how to remind the customer of late payments.';
                }
                action("Rounding Methods")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Rounding Methods';
                    Image = Calculate;
                    RunObject = Page "Rounding Methods";
                    ToolTip = 'Define how amounts are rounded when you use functions to adjust or suggest item prices or standard costs.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Customer Groups', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("Customer Posting Groups_Promoted"; "Customer Posting Groups")
                {
                }
                actionref("Customer Price Groups_Promoted"; "Customer Price Groups")
                {
                }
                actionref("Customer Disc. Groups_Promoted"; "Customer Disc. Groups")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Payments', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref("Payment Registration Setup_Promoted"; "Payment Registration Setup")
                {
                }
                actionref("Payment Methods_Promoted"; "Payment Methods")
                {
                }
                actionref("Payment Terms_Promoted"; "Payment Terms")
                {
                }
                actionref("Finance Charge Terms_Promoted"; "Finance Charge Terms")
                {
                }
                actionref("Reminder Terms_Promoted"; "Reminder Terms")
                {
                }
                actionref("Rounding Methods_Promoted"; "Rounding Methods")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
        if ExtendedPriceEnabled then
            PriceCalculationMgt.FeatureCustomizedLookupDiscovered();
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled();
        GeneralLedgerSetup.Get();
        JnlTemplateNameVisible := GeneralLedgerSetup."Journal Templ. Name Mandatory";
    end;

    var
        ExtendedPriceEnabled: Boolean;
        CRMIntegrationEnabled: Boolean;
        JnlTemplateNameVisible: Boolean;
}

