// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.DirectDebit;
using Microsoft.CRM.Team;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.WithholdingTax;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Intercompany.Partner;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Reminder;
using Microsoft.Utilities;
using System.Security.AccessControl;
using System.Utilities;

table 21 "Cust. Ledger Entry"
{
    Caption = 'Cust. Ledger Entry';
    DrillDownPageID = "Customer Ledger Entries";
    LookupPageID = "Customer Ledger Entries";
    Permissions = tabledata "Reminder/Fin. Charge Entry" = R;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
        }
        field(3; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;
            ToolTip = 'Specifies the customer account number that the entry is linked to.';
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the customer entry''s posting date.';
        }
        field(5; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies the document type that the customer entry belongs to.';
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the entry''s document number.';

            trigger OnLookup()
            var
                IncomingDocument: Record "Incoming Document";
            begin
                IncomingDocument.HyperlinkToDocument("Document No.", "Posting Date");
            end;
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the customer entry.';
        }
        field(8; "Customer Name"; Text[100])
        {
            Caption = 'Customer Name';
            ToolTip = 'Specifies the customer name that the entry is linked to.';
        }
        field(10; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the customer''s reference.';
        }
        field(11; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
            ToolTip = 'Specifies the currency code for the amount on the line.';
        }
        field(13; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Detailed Cust. Ledg. Entry".Amount where("Ledger Entry Amount" = const(true),
                                                                         "Cust. Ledger Entry No." = field("Entry No."),
                                                                         "Posting Date" = field("Date Filter")));
            Caption = 'Amount';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the amount of the entry.';
        }
        field(14; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Detailed Cust. Ledg. Entry".Amount where("Cust. Ledger Entry No." = field("Entry No."),
                                                                         "Posting Date" = field("Date Filter")));
            Caption = 'Remaining Amount';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the amount that remains to be applied to before the entry has been completely applied.';
        }
        field(15; "Original Amt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Detailed Cust. Ledg. Entry"."Amount (LCY)" where("Cust. Ledger Entry No." = field("Entry No."),
                                                                                 "Entry Type" = filter("Initial Entry"),
                                                                                 "Posting Date" = field("Date Filter")));
            Caption = 'Original Amt. (LCY)';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the amount that the entry originally consisted of, in LCY.';
        }
        field(16; "Remaining Amt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Detailed Cust. Ledg. Entry"."Amount (LCY)" where("Cust. Ledger Entry No." = field("Entry No."),
                                                                                 "Posting Date" = field("Date Filter")));
            Caption = 'Remaining Amt. (LCY)';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the amount that remains to be applied to before the entry is totally applied to.';
        }
        field(17; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Detailed Cust. Ledg. Entry"."Amount (LCY)" where("Ledger Entry Amount" = const(true),
                                                                                 "Cust. Ledger Entry No." = field("Entry No."),
                                                                                 "Posting Date" = field("Date Filter")));
            Caption = 'Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the amount of the entry in LCY.';
        }
        field(18; "Sales (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Sales (LCY)';
            ToolTip = 'Specifies the total sales amount excl. VAT to the customer in LCY.';
        }
        field(19; "Profit (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Profit (LCY)';
        }
        field(20; "Inv. Discount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Inv. Discount (LCY)';
        }
        field(21; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            TableRelation = Customer;
        }
        field(22; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            TableRelation = "Customer Posting Group";
            ToolTip = 'Specifies the customer''s market type to link business transactions to.';
        }
        field(23; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
            ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
        }
        field(24; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
            ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
        }
        field(25; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = "Salesperson/Purchaser";
            ToolTip = 'Specifies the code for the salesperson whom the entry is linked to.';
        }
        field(27; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
            ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
        }
        field(28; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
            ToolTip = 'Specifies the source code that specifies where the entry was created.';
        }
        field(33; "On Hold"; Code[3])
        {
            Caption = 'On Hold';
            ToolTip = 'Specifies that the related entry represents an unpaid invoice for which either a payment suggestion, a reminder, or a finance charge memo exists.';

            trigger OnValidate()
            var
                GenJournalLine: Record "Gen. Journal Line";
            begin
                if "On Hold" = xRec."On Hold" then
                    exit;
                GenJournalLine.Reset();
                GenJournalLine.SetLoadFields("On Hold");
                GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Customer);
                GenJournalLine.SetRange("Account No.", "Customer No.");
                GenJournalLine.SetRange("Applies-to Doc. Type", "Document Type");
                GenJournalLine.SetRange("Applies-to Doc. No.", "Document No.");
                GenJournalLine.SetRange("On Hold", xRec."On Hold");
                if GenJournalLine.FIndFirst() then
                    if not Confirm(
                        StrSubstNo(
                            NetBalanceOnHoldErr,
                            GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No."))
                    then
                        Error('');
            end;
        }
        field(34; "Applies-to Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-to Doc. Type';
        }
        field(35; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';
        }
        field(36; Open; Boolean)
        {
            Caption = 'Open';
            ToolTip = 'Specifies whether the amount on the entry has been fully paid or there is still a remaining amount that must be applied to.';
        }
        field(37; "Due Date"; Date)
        {
            Caption = 'Due Date';
            ToolTip = 'Specifies the due date on the entry.';

            trigger OnValidate()
            var
                ReminderEntry: Record "Reminder/Fin. Charge Entry";
                ReminderIssue: Codeunit "Reminder-Issue";
            begin
                TestField(Open, true);
                if "Due Date" <> xRec."Due Date" then begin
                    ReminderEntry.SetCurrentKey("Customer Entry No.", Type);
                    ReminderEntry.SetRange("Customer Entry No.", "Entry No.");
                    ReminderEntry.SetRange(Type, ReminderEntry.Type::Reminder);
                    ReminderEntry.SetRange("Reminder Level", "Last Issued Reminder Level");
                    if ReminderEntry.FindLast() then
                        ReminderIssue.ChangeDueDate(ReminderEntry, "Due Date", xRec."Due Date");
                end;
            end;
        }
        field(38; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';
            ToolTip = 'Specifies the date on which the amount in the entry must be paid for a payment discount to be granted.';

            trigger OnValidate()
            begin
                TestField(Open, true);
            end;
        }
        field(39; "Original Pmt. Disc. Possible"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Original Pmt. Disc. Possible';
            Editable = false;
            ToolTip = 'Specifies the discount that the customer can obtain if the entry is applied to before the payment discount date.';
        }
        field(40; "Pmt. Disc. Given (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Pmt. Disc. Given (LCY)';
        }
        field(42; "Orig. Pmt. Disc. Possible(LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Orig. Pmt. Disc. Possible (LCY)';
            Editable = false;
        }
        field(43; Positive; Boolean)
        {
            Caption = 'Positive';
            ToolTip = 'Specifies if the entry to be applied is positive.';
        }
        field(44; "Closed by Entry No."; Integer)
        {
            Caption = 'Closed by Entry No.';
            TableRelation = "Cust. Ledger Entry";
        }
        field(45; "Closed at Date"; Date)
        {
            Caption = 'Closed at Date';
            ToolTip = 'Specifies when the entry was closed.';
        }
        field(46; "Closed by Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Closed by Amount';
            ToolTip = 'Specifies the amount that the entry was finally applied to (closed) with.';
        }
        field(47; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';
            ToolTip = 'Specifies the ID of entries that will be applied to when you choose the Apply Entries action.';

            trigger OnValidate()
            begin
                TestField(Open, true);
            end;
        }
        field(48; "Journal Templ. Name"; Code[10])
        {
            Caption = 'Journal Template Name';
        }
        field(49; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(50; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
            ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
        }
        field(51; "Bal. Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';
            ToolTip = 'Specifies the type of account that a balancing entry is posted to, such as BANK for a cash account.';
        }
        field(52; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = if ("Bal. Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Bal. Account Type" = const(Customer)) Customer
            else
            if ("Bal. Account Type" = const(Vendor)) Vendor
            else
            if ("Bal. Account Type" = const("Bank Account")) "Bank Account"
            else
            if ("Bal. Account Type" = const("Fixed Asset")) "Fixed Asset";
            ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account that the balancing entry is posted to, such as a cash account for cash purchases.';
        }
        field(53; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
        }
        field(54; "Closed by Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Closed by Amount (LCY)';
        }
        field(58; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Detailed Cust. Ledg. Entry"."Debit Amount" where("Ledger Entry Amount" = const(true),
                                                                                 "Cust. Ledger Entry No." = field("Entry No."),
                                                                                 "Posting Date" = field("Date Filter")));
            Caption = 'Debit Amount';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the total of the ledger entries that represent debits.';
        }
        field(59; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Detailed Cust. Ledg. Entry"."Credit Amount" where("Ledger Entry Amount" = const(true),
                                                                                  "Cust. Ledger Entry No." = field("Entry No."),
                                                                                  "Posting Date" = field("Date Filter")));
            Caption = 'Credit Amount';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the total of the ledger entries that represent credits.';
        }
        field(60; "Debit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Detailed Cust. Ledg. Entry"."Debit Amount (LCY)" where("Ledger Entry Amount" = const(true),
                                                                                       "Cust. Ledger Entry No." = field("Entry No."),
                                                                                       "Posting Date" = field("Date Filter")));
            Caption = 'Debit Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the total of the ledger entries that represent debits, expressed in LCY.';
        }
        field(61; "Credit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Detailed Cust. Ledg. Entry"."Credit Amount (LCY)" where("Ledger Entry Amount" = const(true),
                                                                                        "Cust. Ledger Entry No." = field("Entry No."),
                                                                                        "Posting Date" = field("Date Filter")));
            Caption = 'Credit Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the total of the ledger entries that represent credits, expressed in LCY.';
        }
        field(62; "Document Date"; Date)
        {
            Caption = 'Document Date';
            ToolTip = 'Specifies the customer entry''s document date.';
        }
        field(63; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
        }
        field(64; "Calculate Interest"; Boolean)
        {
            Caption = 'Calculate Interest';
        }
        field(65; "Closing Interest Calculated"; Boolean)
        {
            Caption = 'Closing Interest Calculated';
        }
        field(66; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(67; "Closed by Currency Code"; Code[10])
        {
            Caption = 'Closed by Currency Code';
            TableRelation = Currency;
            ToolTip = 'Specifies the code of the currency of the entry that was applied to (and closed) this customer ledger entry.';
        }
        field(68; "Closed by Currency Amount"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatExpression = "Closed by Currency Code";
            AutoFormatType = 1;
            Caption = 'Closed by Currency Amount';
            ToolTip = 'Specifies the amount that was finally applied to (and closed) this customer ledger entry.';
        }
        field(73; "Adjusted Currency Factor"; Decimal)
        {
            Caption = 'Adjusted Currency Factor';
            DecimalPlaces = 0 : 15;
        }
        field(74; "Original Currency Factor"; Decimal)
        {
            Caption = 'Original Currency Factor';
            DecimalPlaces = 0 : 15;
        }
        field(75; "Original Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Detailed Cust. Ledg. Entry".Amount where("Cust. Ledger Entry No." = field("Entry No."),
                                                                         "Entry Type" = filter("Initial Entry"),
                                                                         "Posting Date" = field("Date Filter")));
            Caption = 'Original Amount';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the amount of the original entry.';
        }
        field(76; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(77; "Remaining Pmt. Disc. Possible"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Remaining Pmt. Disc. Possible';
            ToolTip = 'Specifies the remaining payment discount which can be received if the payment is made before the payment discount date.';

            trigger OnValidate()
            begin
                TestField(Open, true);
                CalcFields(Amount, "Original Amount");

                if "Remaining Pmt. Disc. Possible" * Amount < 0 then
                    FieldError("Remaining Pmt. Disc. Possible", StrSubstNo(Text000, FieldCaption(Amount)));

                if Abs("Remaining Pmt. Disc. Possible") > Abs("Original Amount") then
                    FieldError("Remaining Pmt. Disc. Possible", StrSubstNo(Text001, FieldCaption("Original Amount")));
            end;
        }
        field(78; "Pmt. Disc. Tolerance Date"; Date)
        {
            Caption = 'Pmt. Disc. Tolerance Date';
            ToolTip = 'Specifies the latest date the amount in the entry must be paid in order for a payment discount tolerance to be granted.';

            trigger OnValidate()
            begin
                TestField(Open, true);
            end;
        }
        field(79; "Max. Payment Tolerance"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Max. Payment Tolerance';
            ToolTip = 'Specifies the maximum tolerated amount the entry can differ from the amount on the invoice or credit memo.';

            trigger OnValidate()
            begin
                TestField(Open, true);
                CalcFields(Amount, "Remaining Amount");
                OnValidateMaxPaymentToleranceOnBeforeFieldError(Rec);

                if "Max. Payment Tolerance" * Amount < 0 then
                    FieldError("Max. Payment Tolerance", StrSubstNo(Text000, FieldCaption(Amount)));

                if Abs("Max. Payment Tolerance") > Abs("Remaining Amount") then
                    FieldError("Max. Payment Tolerance", StrSubstNo(Text001, FieldCaption("Remaining Amount")));
            end;
        }
        field(80; "Last Issued Reminder Level"; Integer)
        {
            Caption = 'Last Issued Reminder Level';
        }
        field(81; "Accepted Payment Tolerance"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Accepted Payment Tolerance';
        }
        field(82; "Accepted Pmt. Disc. Tolerance"; Boolean)
        {
            Caption = 'Accepted Pmt. Disc. Tolerance';
        }
        field(83; "Pmt. Tolerance (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Pmt. Tolerance (LCY)';
        }
        field(84; "Amount to Apply"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount to Apply';
            ToolTip = 'Specifies the amount to apply.';

            trigger OnValidate()
            begin
                TestField(Open, true);
                CalcFields("Remaining Amount");
                OnValidateAmounttoApplyBeforeFieldError(Rec);

                if AreOppositeSign("Amount to Apply", "Remaining Amount") then
                    FieldError("Amount to Apply", StrSubstNo(Text000, FieldCaption("Remaining Amount")));

                if Abs("Amount to Apply") > Abs("Remaining Amount") then
                    FieldError("Amount to Apply", StrSubstNo(Text001, FieldCaption("Remaining Amount")));
            end;
        }
        field(85; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            TableRelation = "IC Partner";
            ToolTip = 'Specifies the code of the intercompany partner that the transaction is related to if the entry was created from an intercompany transaction.';
        }
        field(86; "Applying Entry"; Boolean)
        {
            Caption = 'Applying Entry';
        }
        field(87; Reversed; Boolean)
        {
            BlankZero = true;
            Caption = 'Reversed';
            ToolTip = 'Specifies if the entry has been part of a reverse transaction.';
        }
        field(88; "Reversed by Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed by Entry No.';
            TableRelation = "Cust. Ledger Entry";
            ToolTip = 'Specifies the number of the correcting entry that replaced the original entry in the reverse transaction.';
        }
        field(89; "Reversed Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed Entry No.';
            TableRelation = "Cust. Ledger Entry";
            ToolTip = 'Specifies the number of the original entry that was undone by the reverse transaction.';
        }
        field(90; Prepayment; Boolean)
        {
            Caption = 'Prepayment';
            ToolTip = 'Specifies if the related payment is a prepayment.';
        }
        field(171; "Payment Reference"; Code[50])
        {
            Caption = 'Payment Reference';
        }
        field(172; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";
            ToolTip = 'Specifies how to make payment, such as with bank transfer, cash, or check.';

            trigger OnValidate()
            begin
                TestField(Open, true);
            end;
        }
        field(173; "Applies-to Ext. Doc. No."; Code[35])
        {
            Caption = 'Applies-to Ext. Doc. No.';
        }
        field(288; "Recipient Bank Account"; Code[20])
        {
            Caption = 'Recipient Bank Account';
            TableRelation = "Customer Bank Account".Code where("Customer No." = field("Customer No."));
            ToolTip = 'Specifies the bank account to transfer the amount to.';
        }
        field(289; "Message to Recipient"; Text[140])
        {
            Caption = 'Message to Recipient';
            ToolTip = 'Specifies the message exported to the payment file when you use the Export Payments to File function in the Payment Journal window.';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateMessagetoRecipient(Rec, IsHandled);
                if IsHandled then
                    exit;

                TestField(Open, true);
            end;
        }
        field(290; "Exported to Payment File"; Boolean)
        {
            Caption = 'Exported to Payment File';
            Editable = false;
            ToolTip = 'Specifies that the entry was created as a result of exporting a payment journal line.';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";
            ToolTip = 'Specifies a reference to a combination of dimension values. The actual values are stored in the Dimension Set Entry table.';

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;
        }
        field(481; "Shortcut Dimension 3 Code"; Code[20])
        {
            CaptionClass = '1,2,3';
            Caption = 'Shortcut Dimension 3 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(3)));
            ToolTip = 'Specifies the code for Shortcut Dimension 3, which is one of dimension codes that you set up in the General Ledger Setup window.';
        }
        field(482; "Shortcut Dimension 4 Code"; Code[20])
        {
            CaptionClass = '1,2,4';
            Caption = 'Shortcut Dimension 4 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(4)));
            ToolTip = 'Specifies the code for Shortcut Dimension 4, which is one of dimension codes that you set up in the General Ledger Setup window.';
        }
        field(483; "Shortcut Dimension 5 Code"; Code[20])
        {
            CaptionClass = '1,2,5';
            Caption = 'Shortcut Dimension 5 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(5)));
            ToolTip = 'Specifies the code for Shortcut Dimension 5, which is one of dimension codes that you set up in the General Ledger Setup window.';
        }
        field(484; "Shortcut Dimension 6 Code"; Code[20])
        {
            CaptionClass = '1,2,6';
            Caption = 'Shortcut Dimension 6 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(6)));
            ToolTip = 'Specifies the code for Shortcut Dimension 6, which is one of dimension codes that you set up in the General Ledger Setup window.';
        }
        field(485; "Shortcut Dimension 7 Code"; Code[20])
        {
            CaptionClass = '1,2,7';
            Caption = 'Shortcut Dimension 7 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(7)));
            ToolTip = 'Specifies the code for Shortcut Dimension 7, which is one of dimension codes that you set up in the General Ledger Setup window.';
        }
        field(486; "Shortcut Dimension 8 Code"; Code[20])
        {
            CaptionClass = '1,2,8';
            Caption = 'Shortcut Dimension 8 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(8)));
            ToolTip = 'Specifies the code for Shortcut Dimension 8, which is one of dimension codes that you set up in the General Ledger Setup window.';
        }
        field(1200; "Direct Debit Mandate ID"; Code[35])
        {
            Caption = 'Direct Debit Mandate ID';
            TableRelation = "SEPA Direct Debit Mandate" where("Customer No." = field("Customer No."));
            ToolTip = 'Specifies the direct-debit mandate that the customer has signed to allow direct debit collection of payments.';
        }
        field(1340; "Dispute Status"; Code[10])
        {
            Caption = 'Dispute Status';
            TableRelation = "Dispute Status";
            DataClassification = CustomerContent;
            ToolTip = 'Specifies if there is an ongoing dispute for this Invoice';

            trigger OnValidate()
            var
                DisputeStatus: Record "Dispute Status";
                MarkedAsOnHoldLbl: label 'X', Locked = true;
            begin
                if Rec."Dispute Status" = '' then
                    exit;
                if DisputeStatus.get(Rec."Dispute Status") then
                    if DisputeStatus."Overwrite on hold" then
                        "On Hold" := MarkedAsOnHoldLbl;
            end;
        }
        field(1341; "Promised Pay Date"; Date)
        {
            Caption = 'Promised Pay Date';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the date on which the customer have promised to pay this invoice.';
        }
        field(11620; Adjustment; Boolean)
        {
            Caption = 'Adjustment';
        }
        field(11621; "BAS Adjustment"; Boolean)
        {
            Caption = 'BAS Adjustment';
        }
        field(11626; "Adjustment Applies-to"; Code[20])
        {
            Caption = 'Adjustment Applies-to';
        }
        field(11628; "Pre Adjmt. Reason Code"; Code[10])
        {
            Caption = 'Pre Adjmt. Reason Code';
            TableRelation = "Reason Code";
        }
        field(28040; "Rem. Amt for WHT"; Decimal)
        {
            Caption = 'Rem. Amt for WHT';
        }
        field(28041; "Rem. Amt"; Decimal)
        {
            Caption = 'Rem. Amt';
        }
        field(28042; "WHT Amount"; Decimal)
        {
            CalcFormula = sum("WHT Entry".Amount where("Bill-to/Pay-to No." = field("Customer No."),
                                                        "Transaction No." = field("Transaction No.")));
            Caption = 'WHT Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(28043; "WHT Amount (LCY)"; Decimal)
        {
            CalcFormula = sum("WHT Entry"."Amount (LCY)" where("Bill-to/Pay-to No." = field("Customer No."),
                                                                "Transaction No." = field("Transaction No.")));
            Caption = 'WHT Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(28044; "WHT Payment"; Boolean)
        {
            Caption = 'WHT Payment';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Customer No.", "Posting Date", "Currency Code")
        {
            SumIndexFields = "Sales (LCY)", "Profit (LCY)", "Inv. Discount (LCY)";
        }
        key(Key4; "Document No.")
        {
        }
        key(Key5; "External Document No.")
        {
        }
        key(Key6; "Customer No.", Open, Positive, "Due Date", "Currency Code")
        {
        }
        key(Key7; Open, "Due Date")
        {
        }
        key(Key8; "Document Type", "Customer No.", "Posting Date", "Currency Code")
        {
            SumIndexFields = "Sales (LCY)", "Profit (LCY)", "Inv. Discount (LCY)";
        }
        key(Key9; "Salesperson Code", "Posting Date")
        {
        }
        key(Key10; "Closed by Entry No.")
        {
        }
        key(Key11; "Transaction No.")
        {
        }
        key(Key17; "Customer No.", "Applies-to ID", Open, Positive, "Due Date")
        {
        }
        key(Key18; "Customer No.", "Document Date", "BAS Adjustment")
        {
        }
        key(Key19; "Customer No.", Positive, "Applies-to Doc. Type", "Applies-to Doc. No.", "Due Date")
        {
        }
        key(Key20; "Document No.", "Document Type", "Customer No.")
        {
        }
        key(Key21; "Document Type", "Posting Date")
        {
            SumIndexFields = "Sales (LCY)";
        }
        key(Key22; "Document Type", "Customer No.", Open, "Due Date")
        {
        }
        key(Key23; "Customer Posting Group")
        {
        }
        key(Key24; "Document Type", Open, "Posting Date", "Closed at Date")
        {
        }
        key(Key25; "Salesperson Code")
        {
        }
        key(Key26; SystemModifiedAt)
        {
        }
        key(Key35; "Customer No.", "Posting Date", "Applies-to ID")
        {
            IncludedFields = "Currency Code", "Amount to Apply", Open;
        }
        key(Key36; "Document Type", Reversed, "Posting Date")
        {
            IncludedFields = "Customer No.", Open, "Sales (LCY)";
        }
        key(Key37; "Applies-to ID")
        {
            IncludedFields = "Accepted Payment Tolerance";
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", Description, "Customer No.", "Posting Date", "Document Type", "Document No.")
        {
        }
        fieldgroup(Brick; "Document No.", Description, "Remaining Amt. (LCY)", "Due Date")
        {
        }
    }

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'must have the same sign as %1';
        Text001: Label 'must not be larger than %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        NetBalanceOnHoldErr: Label 'General journal line number %3 on template name %1 batch name %2 is applied. Do you want to change On Hold value anyway?', Comment = '%1 - template name, %2 - batch name, %3 - line number';

    [InherentPermissions(PermissionObjectType::TableData, Database::"Cust. Ledger Entry", 'r')]
    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure ShowDoc(): Boolean
    var
        SalesInvoiceHdr: Record "Sales Invoice Header";
        SalesCrMemoHdr: Record "Sales Cr.Memo Header";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        IssuedReminderHeader: Record "Issued Reminder Header";
        PageManagement: Codeunit "Page Management";
        IsHandled: Boolean;
        IsPageOpened: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowDoc(Rec, IsPageOpened, IsHandled);
        if IsHandled then
            exit(IsPageOpened);

        case "Document Type" of
            "Document Type"::Invoice:
                if SalesInvoiceHdr.Get("Document No.") then begin
                    PageManagement.PageRun(SalesInvoiceHdr);
                    exit(true);
                end;
            "Document Type"::"Credit Memo":
                if SalesCrMemoHdr.Get("Document No.") then begin
                    PageManagement.PageRun(SalesCrMemoHdr);
                    exit(true);
                end;
            "Document Type"::"Finance Charge Memo":
                if IssuedFinChargeMemoHeader.Get("Document No.") then begin
                    PAGE.Run(PAGE::"Issued Finance Charge Memo", IssuedFinChargeMemoHeader);
                    exit(true);
                end;
            "Document Type"::Reminder:
                if IssuedReminderHeader.Get("Document No.") then begin
                    PAGE.Run(PAGE::"Issued Reminder", IssuedReminderHeader);
                    exit(true);
                end;
        end;

        OnAfterShowDoc(Rec);
    end;

    procedure ShowPostedDocAttachment()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DocumentFound: Boolean;
    begin
        case "Document Type" of
            "Document Type"::Invoice:
                if SalesInvoiceHeader.Get("Document No.") then begin
                    OpenDocumentAttachmentDetails(SalesInvoiceHeader);
                    DocumentFound := true;
                end;
            "Document Type"::"Credit Memo":
                if SalesCrMemoHeader.Get("Document No.") then begin
                    OpenDocumentAttachmentDetails(SalesCrMemoHeader);
                    DocumentFound := true;
                end;
        end;

        OnAfterShowPostedDocAttachment(Rec, DocumentFound);
    end;

    local procedure OpenDocumentAttachmentDetails("Record": Variant)
    var
        DocumentAttachmentDetails: Page "Document Attachment Details";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Record);
        DocumentAttachmentDetails.OpenForRecRef(RecRef);
        DocumentAttachmentDetails.RunModal();
    end;

    procedure HasPostedDocAttachment(): Boolean
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        SalesInvoiceHeader: Record "Sales Invoice Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DocumentAttachment: Record "Document Attachment";
        HasPostedDocumentAttachment: Boolean;
    begin
        case "Document Type" of
            "Document Type"::Invoice:
                if SalesInvoiceHeader.Get("Document No.") then
                    exit(DocumentAttachment.HasPostedDocumentAttachment(SalesInvoiceHeader));
            "Document Type"::"Credit Memo":
                if SalesCrMemoHeader.Get("Document No.") then
                    exit(DocumentAttachment.HasPostedDocumentAttachment(SalesCrMemoHeader));
        end;

        OnAfterHasPostedDocAttachment(Rec, HasPostedDocumentAttachment);
        exit(HasPostedDocumentAttachment);
    end;

    procedure DrillDownOnEntries(var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        DrillDownPageID: Integer;
    begin
        CustLedgEntry.Reset();
        DtldCustLedgEntry.CopyFilter("Customer No.", CustLedgEntry."Customer No.");
        DtldCustLedgEntry.CopyFilter("Currency Code", CustLedgEntry."Currency Code");
        DtldCustLedgEntry.CopyFilter("Initial Entry Global Dim. 1", CustLedgEntry."Global Dimension 1 Code");
        DtldCustLedgEntry.CopyFilter("Initial Entry Global Dim. 2", CustLedgEntry."Global Dimension 2 Code");
        DtldCustLedgEntry.CopyFilter("Initial Entry Due Date", CustLedgEntry."Due Date");
        CustLedgEntry.SetCurrentKey("Customer No.", "Posting Date");
        CustLedgEntry.SetRange(Open, true);
        OnBeforeDrillDownEntries(CustLedgEntry, DtldCustLedgEntry, DrillDownPageID);
        PAGE.Run(DrillDownPageID, CustLedgEntry);
    end;

    procedure DrillDownOnOverdueEntries(var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        DrillDownPageID: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDrillDownOnOverdueEntriesBeforeCode(DtldCustLedgEntry, IsHandled);
        if IsHandled then
            exit;

        CustLedgEntry.Reset();
        DtldCustLedgEntry.CopyFilter("Customer No.", CustLedgEntry."Customer No.");
        DtldCustLedgEntry.CopyFilter("Currency Code", CustLedgEntry."Currency Code");
        DtldCustLedgEntry.CopyFilter("Initial Entry Global Dim. 1", CustLedgEntry."Global Dimension 1 Code");
        DtldCustLedgEntry.CopyFilter("Initial Entry Global Dim. 2", CustLedgEntry."Global Dimension 2 Code");
        CustLedgEntry.SetCurrentKey("Customer No.", "Posting Date");
        CustLedgEntry.SetFilter("Date Filter", '..%1', Today);
        CustLedgEntry.SetFilter("Due Date", '<%1', Today);
        CustLedgEntry.SetFilter("Remaining Amount", '<>%1', 0);
        OnBeforeDrillDownOnOverdueEntries(CustLedgEntry, DtldCustLedgEntry, DrillDownPageID);
        PAGE.Run(DrillDownPageID, CustLedgEntry);
    end;

    procedure GetOriginalCurrencyFactor(): Decimal
    begin
        if "Original Currency Factor" = 0 then
            exit(1);
        exit("Original Currency Factor");
    end;

    procedure GetAdjustedCurrencyFactor(): Decimal
    begin
        if "Adjusted Currency Factor" = 0 then
            exit(1);
        exit("Adjusted Currency Factor");
    end;

    procedure ShowDimensions()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "Entry No."));
    end;

    procedure SetStyle() Style: Text
    var
        IsHandled: Boolean;
    begin
        OnBeforeSetStyle(Style, IsHandled);
        if IsHandled then
            exit(Style);

        if Open then begin
            if WorkDate() > "Due Date" then
                exit('Unfavorable')
        end else
            if "Closed at Date" > "Due Date" then
                exit('Attention');
        exit('');
    end;

    procedure SetApplyToFilters(CustomerNo: Code[20]; ApplyDocType: Option; ApplyDocNo: Code[20]; ApplyAmount: Decimal)
    begin
        SetCurrentKey("Customer No.", Open, Positive, "Due Date");
        SetRange("Customer No.", CustomerNo);
        SetRange(Open, true);
        if ApplyDocNo <> '' then begin
            SetRange("Document Type", ApplyDocType);
            SetRange("Document No.", ApplyDocNo);
            if FindFirst() then;
            SetRange("Document Type");
            SetRange("Document No.");
        end else
            if ApplyDocType <> 0 then begin
                SetRange("Document Type", ApplyDocType);
                if FindFirst() then;
                SetRange("Document Type");
            end else
                if ApplyAmount <> 0 then begin
                    SetRange(Positive, ApplyAmount < 0);
                    if FindFirst() then;
                    SetRange(Positive);
                end;
    end;

    procedure SetAmountToApply(AppliesToDocNo: Code[20]; CustomerNo: Code[20])
    begin
        OnBeforeSetAmountToApply(Rec, AppliesToDocNo, CustomerNo);

        SetCurrentKey("Document No.");
        SetRange("Document No.", AppliesToDocNo);
        SetRange("Customer No.", CustomerNo);
        SetRange(Open, true);
        if FindFirst() then begin
            if "Amount to Apply" = 0 then begin
                CalcFields("Remaining Amount");
                OnSetAmountToApplyOnAfterCalcRemainingAmount(Rec);
                "Amount to Apply" := "Remaining Amount";
            end else
                "Amount to Apply" := 0;
            "Accepted Payment Tolerance" := 0;
            "Accepted Pmt. Disc. Tolerance" := false;
            CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", Rec);
        end;
    end;

    procedure CopyFromGenJnlLine(GenJnlLine: Record "Gen. Journal Line")
    begin
        "Customer No." := GenJnlLine."Account No.";
        "Posting Date" := GenJnlLine."Posting Date";
        "Document Date" := GenJnlLine."Document Date";
        "Document Type" := GenJnlLine."Document Type";
        "Document No." := GenJnlLine."Document No.";
        "External Document No." := GenJnlLine."External Document No.";
        "Your Reference" := GenJnlLine."Your Reference";
        Description := GenJnlLine.Description;
        "Currency Code" := GenJnlLine."Currency Code";
        "Sales (LCY)" := GenJnlLine."Sales/Purch. (LCY)";
        "Profit (LCY)" := GenJnlLine."Profit (LCY)";
        "Inv. Discount (LCY)" := GenJnlLine."Inv. Discount (LCY)";
        "Sell-to Customer No." := GenJnlLine."Sell-to/Buy-from No.";
        "Customer Posting Group" := GenJnlLine."Posting Group";
        "Global Dimension 1 Code" := GenJnlLine."Shortcut Dimension 1 Code";
        "Global Dimension 2 Code" := GenJnlLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := GenJnlLine."Dimension Set ID";
        "Salesperson Code" := GenJnlLine."Salespers./Purch. Code";
        "Source Code" := GenJnlLine."Source Code";
        "On Hold" := GenJnlLine."On Hold";
        "Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type";
        "Applies-to Doc. No." := GenJnlLine."Applies-to Doc. No.";
        "Due Date" := GenJnlLine."Due Date";
        "Pmt. Discount Date" := GenJnlLine."Pmt. Discount Date";
        "Applies-to ID" := GenJnlLine."Applies-to ID";
        "Journal Templ. Name" := GenJnlLine."Journal Template Name";
        "Journal Batch Name" := GenJnlLine."Journal Batch Name";
        "Reason Code" := GenJnlLine."Reason Code";
        "Direct Debit Mandate ID" := GenJnlLine."Direct Debit Mandate ID";
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        "Bal. Account Type" := GenJnlLine."Bal. Account Type";
        "Bal. Account No." := GenJnlLine."Bal. Account No.";
        "No. Series" := GenJnlLine."Posting No. Series";
        "IC Partner Code" := GenJnlLine."IC Partner Code";
        Prepayment := GenJnlLine.Prepayment;
        "Recipient Bank Account" := GenJnlLine."Recipient Bank Account";
        "Message to Recipient" := GenJnlLine."Message to Recipient";
        "Applies-to Ext. Doc. No." := GenJnlLine."Applies-to Ext. Doc. No.";
        "Payment Method Code" := GenJnlLine."Payment Method Code";
        "Payment Reference" := GenJnlLine."Payment Reference";
        "Exported to Payment File" := GenJnlLine."Exported to Payment File";
        Adjustment := GenJnlLine.Adjustment;
        "BAS Adjustment" := GenJnlLine."BAS Adjustment";
        "Adjustment Applies-to" := GenJnlLine."Adjustment Applies-to";
        "WHT Payment" := GenJnlLine."WHT Payment";

        OnAfterCopyCustLedgerEntryFromGenJnlLine(Rec, GenJnlLine);
    end;

    procedure CopyFromCVLedgEntryBuffer(var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
        TransferFields(CVLedgerEntryBuffer);
        Amount := CVLedgerEntryBuffer.Amount;
        "Amount (LCY)" := CVLedgerEntryBuffer."Amount (LCY)";
        "Remaining Amount" := CVLedgerEntryBuffer."Remaining Amount";
        "Remaining Amt. (LCY)" := CVLedgerEntryBuffer."Remaining Amt. (LCY)";
        "Original Amount" := CVLedgerEntryBuffer."Original Amount";
        "Original Amt. (LCY)" := CVLedgerEntryBuffer."Original Amt. (LCY)";

        OnAfterCopyCustLedgerEntryFromCVLedgEntryBuffer(Rec, CVLedgerEntryBuffer);
    end;

    procedure RecalculateAmounts(FromCurrencyCode: Code[10]; ToCurrencyCode: Code[10]; PostingDate: Date)
    var
        CurrExchRate: Record "Currency Exchange Rate";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRecalculateAmounts(Rec, FromCurrencyCode, ToCurrencyCode, PostingDate, IsHandled);
        if not IsHandled then begin
            if ToCurrencyCode = FromCurrencyCode then
                exit;

            "Remaining Amount" :=
              CurrExchRate.ExchangeAmount("Remaining Amount", FromCurrencyCode, ToCurrencyCode, PostingDate);
            "Remaining Pmt. Disc. Possible" :=
              CurrExchRate.ExchangeAmount("Remaining Pmt. Disc. Possible", FromCurrencyCode, ToCurrencyCode, PostingDate);
            "Accepted Payment Tolerance" :=
              CurrExchRate.ExchangeAmount("Accepted Payment Tolerance", FromCurrencyCode, ToCurrencyCode, PostingDate);
            "Amount to Apply" :=
              CurrExchRate.ExchangeAmount("Amount to Apply", FromCurrencyCode, ToCurrencyCode, PostingDate);
        end;
        OnAfterRecalculateAmounts(Rec, FromCurrencyCode, ToCurrencyCode, PostingDate);
    end;

    procedure UpdateAmountsForApplication(ApplnDate: Date; ApplnCurrencyCode: Code[10]; RoundAmounts: Boolean; UpdateMaxPaymentTolerance: Boolean)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAmountsForApplication(Rec, ApplnDate, ApplnCurrencyCode, RoundAmounts, UpdateMaxPaymentTolerance, IsHandled);
        if not IsHandled then begin
            //new
            if "Currency Code" = ApplnCurrencyCode then
                exit;
            if RoundAmounts then begin
                "Remaining Amount" :=
                    CurrencyExchangeRate.ExchangeAmount(
                        "Remaining Amount", "Currency Code", ApplnCurrencyCode, ApplnDate);
                "Remaining Pmt. Disc. Possible" :=
                    CurrencyExchangeRate.ExchangeAmount(
                        "Remaining Pmt. Disc. Possible", "Currency Code", ApplnCurrencyCode, ApplnDate);
                if UpdateMaxPaymentTolerance then
                    "Max. Payment Tolerance" :=
                        CurrencyExchangeRate.ExchangeAmount(
                            "Max. Payment Tolerance", "Currency Code", ApplnCurrencyCode, ApplnDate);
                "Amount to Apply" :=
                    CurrencyExchangeRate.ExchangeAmount(
                        "Amount to Apply", "Currency Code", ApplnCurrencyCode, ApplnDate);
            end else begin
                "Remaining Amount" :=
                    CurrencyExchangeRate.ExchangeAmtFCYToFCY(
                        ApplnDate, "Currency Code", ApplnCurrencyCode, "Remaining Amount");
                "Remaining Pmt. Disc. Possible" :=
                    CurrencyExchangeRate.ExchangeAmtFCYToFCY(
                        ApplnDate, "Currency Code", ApplnCurrencyCode, "Remaining Pmt. Disc. Possible");
                if UpdateMaxPaymentTolerance then // If it is not a problem that "Max. Payment Tolerance" is updated in procedure CalcApplnAmount() on the page "Apply Customer Entries", then maybe the argument UpdateMaxPaymentTolerance can be removed.
                    "Max. Payment Tolerance" :=
                        CurrencyExchangeRate.ExchangeAmtFCYToFCY(
                            ApplnDate, "Currency Code", ApplnCurrencyCode, "Max. Payment Tolerance");
                "Amount to Apply" :=
                    CurrencyExchangeRate.ExchangeAmtFCYToFCY(
                        ApplnDate, "Currency Code", ApplnCurrencyCode, "Amount to Apply");
            end;
        end;
        OnAfterUpdateAmountsForApplication(Rec, ApplnDate, ApplnCurrencyCode, RoundAmounts, UpdateMaxPaymentTolerance);
    end;

    procedure GetRemainingPmtDiscPossible(ReferenceDate: Date) RemainingPmtDiscPossible: Decimal
    begin
        RemainingPmtDiscPossible := "Remaining Pmt. Disc. Possible";

        OnAfterGetRemainingPmtDiscPossible(Rec, ReferenceDate, RemainingPmtDiscPossible);
    end;

    local procedure AreOppositeSign(Amount1: Decimal; Amount2: Decimal): Boolean
    var
        Math: Codeunit "Math";
    begin
        if (Amount1 = 0) or (Amount2 = 0) then
            exit(false);

        exit(Math.Sign(Amount1) <> Math.Sign(Amount2));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyCustLedgerEntryFromGenJnlLine(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyCustLedgerEntryFromCVLedgEntryBuffer(var CustLedgerEntry: Record "Cust. Ledger Entry"; CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecalculateAmounts(var CustLedgerEntry: Record "Cust. Ledger Entry"; FromCurrencyCode: Code[10]; ToCurrencyCode: Code[10]; PostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateAmounttoApplyBeforeFieldError(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDoc(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowPostedDocAttachment(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentFound: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHasPostedDocAttachment(var CustLedgerEntry: Record "Cust. Ledger Entry"; var HasPostedDocumentAttachment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDrillDownEntries(var CustLedgerEntry: Record "Cust. Ledger Entry"; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var DrillDownPageID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDrillDownOnOverdueEntries(var CustLedgerEntry: Record "Cust. Ledger Entry"; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var DrillDownPageID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetAmountToApply(var CustLedgerEntry: Record "Cust. Ledger Entry"; AppliesToDocNo: Code[20]; CustomerNo: Code[20])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSetStyle(var Style: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDoc(CustLedgerEntry: Record "Cust. Ledger Entry"; var IsPageOpened: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateMessagetoRecipient(var CustLedgerEntry: Record "Cust. Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAmountsForApplication(var CustLedgerEntry: Record "Cust. Ledger Entry"; ApplnDate: Date; ApplnCurrencyCode: Code[10]; RoundAmounts: Boolean; UpdateMaxPaymentTolerance: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRemainingPmtDiscPossible(CustLedgerEntry: Record "Cust. Ledger Entry"; ReferenceDate: Date; var RemainingPmtDiscPossible: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDrillDownOnOverdueEntriesBeforeCode(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecalculateAmounts(var CustLedgerEntry: Record "Cust. Ledger Entry"; FromCurrencyCode: Code[10]; ToCurrencyCode: Code[10]; PostingDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAmountsForApplication(var CustLedgerEntry: Record "Cust. Ledger Entry"; ApplnDate: Date; ApplnCurrencyCode: Code[10]; RoundAmounts: Boolean; UpdateMaxPaymentTolerance: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetAmountToApplyOnAfterCalcRemainingAmount(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateMaxPaymentToleranceOnBeforeFieldError(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;
}

