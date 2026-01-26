// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Team;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Intercompany.Partner;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Remittance;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;
using System.Security.AccessControl;
using System.Utilities;

table 25 "Vendor Ledger Entry"
{
    Caption = 'Vendor Ledger Entry';
    DrillDownPageID = "Vendor Ledger Entries";
    LookupPageID = "Vendor Ledger Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(3; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(5; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';

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
        }
        field(8; "Vendor Name"; Text[100])
        {
            Caption = 'Vendor Name';
        }
        field(11; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(13; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Detailed Vendor Ledg. Entry".Amount where("Ledger Entry Amount" = const(true),
                                                                          "Vendor Ledger Entry No." = field("Entry No."),
                                                                          "Posting Date" = field("Date Filter")));
            Caption = 'Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Detailed Vendor Ledg. Entry".Amount where("Vendor Ledger Entry No." = field("Entry No."),
                                                                          "Posting Date" = field("Date Filter")));
            Caption = 'Remaining Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(15; "Original Amt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Detailed Vendor Ledg. Entry"."Amount (LCY)" where("Vendor Ledger Entry No." = field("Entry No."),
                                                                                  "Entry Type" = filter("Initial Entry"),
                                                                                  "Posting Date" = field("Date Filter")));
            Caption = 'Original Amt. (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "Remaining Amt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Detailed Vendor Ledg. Entry"."Amount (LCY)" where("Vendor Ledger Entry No." = field("Entry No."),
                                                                                  "Posting Date" = field("Date Filter")));
            Caption = 'Remaining Amt. (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Detailed Vendor Ledg. Entry"."Amount (LCY)" where("Ledger Entry Amount" = const(true),
                                                                                  "Vendor Ledger Entry No." = field("Entry No."),
                                                                                  "Posting Date" = field("Date Filter")));
            Caption = 'Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(18; "Purchase (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Purchase (LCY)';
        }
        field(20; "Inv. Discount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Inv. Discount (LCY)';
        }
        field(21; "Buy-from Vendor No."; Code[20])
        {
            Caption = 'Buy-from Vendor No.';
            TableRelation = Vendor;
        }
        field(22; "Vendor Posting Group"; Code[20])
        {
            Caption = 'Vendor Posting Group';
            TableRelation = "Vendor Posting Group";
        }
        field(23; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(24; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(25; "Purchaser Code"; Code[20])
        {
            Caption = 'Purchaser Code';
            TableRelation = "Salesperson/Purchaser";
        }
        field(27; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(28; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(33; "On Hold"; Code[3])
        {
            Caption = 'On Hold';

            trigger OnValidate()
            var
                GenJournalLine: Record "Gen. Journal Line";
            begin
                if "On Hold" = xRec."On Hold" then
                    exit;
                GenJournalLine.Reset();
                GenJournalLine.SetLoadFields("On Hold");
                GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Vendor);
                GenJournalLine.SetRange("Account No.", "Vendor No.");
                GenJournalLine.SetRange("Applies-to Doc. Type", "Document Type");
                GenJournalLine.SetRange("Applies-to Doc. No.", "Document No.");
                GenJournalLine.SetRange("On Hold", xRec."On Hold");
                if GenJournalLine.FindFirst() then
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
        }
        field(37; "Due Date"; Date)
        {
            Caption = 'Due Date';

            trigger OnValidate()
            begin
                TestField(Open, true);
            end;
        }
        field(38; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';

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
        }
        field(40; "Pmt. Disc. Rcd.(LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Pmt. Disc. Rcd.(LCY)';
        }
        field(42; "Orig. Pmt. Disc. Possible(LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Org. Pmt. Disc. Possible (LCY)';
            Editable = false;
        }
        field(43; Positive; Boolean)
        {
            Caption = 'Positive';
        }
        field(44; "Closed by Entry No."; Integer)
        {
            Caption = 'Closed by Entry No.';
            TableRelation = "Vendor Ledger Entry";
        }
        field(45; "Closed at Date"; Date)
        {
            Caption = 'Closed at Date';
        }
        field(46; "Closed by Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Closed by Amount';
        }
        field(47; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';

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
        }
        field(51; "Bal. Account Type"; enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';
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
            CalcFormula = sum("Detailed Vendor Ledg. Entry"."Debit Amount" where("Ledger Entry Amount" = const(true),
                                                                                  "Vendor Ledger Entry No." = field("Entry No."),
                                                                                  "Posting Date" = field("Date Filter")));
            Caption = 'Debit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(59; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Detailed Vendor Ledg. Entry"."Credit Amount" where("Ledger Entry Amount" = const(true),
                                                                                   "Vendor Ledger Entry No." = field("Entry No."),
                                                                                   "Posting Date" = field("Date Filter")));
            Caption = 'Credit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(60; "Debit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Detailed Vendor Ledg. Entry"."Debit Amount (LCY)" where("Ledger Entry Amount" = const(true),
                                                                                        "Vendor Ledger Entry No." = field("Entry No."),
                                                                                        "Posting Date" = field("Date Filter")));
            Caption = 'Debit Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(61; "Credit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Detailed Vendor Ledg. Entry"."Credit Amount (LCY)" where("Ledger Entry Amount" = const(true),
                                                                                         "Vendor Ledger Entry No." = field("Entry No."),
                                                                                         "Posting Date" = field("Date Filter")));
            Caption = 'Credit Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(62; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(63; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(64; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(65; "Closed by Currency Code"; Code[10])
        {
            Caption = 'Closed by Currency Code';
            TableRelation = Currency;
        }
        field(66; "Closed by Currency Amount"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatExpression = "Closed by Currency Code";
            AutoFormatType = 1;
            Caption = 'Closed by Currency Amount';
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
            CalcFormula = sum("Detailed Vendor Ledg. Entry".Amount where("Vendor Ledger Entry No." = field("Entry No."),
                                                                          "Entry Type" = filter("Initial Entry"),
                                                                          "Posting Date" = field("Date Filter")));
            Caption = 'Original Amount';
            Editable = false;
            FieldClass = FlowField;
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

            trigger OnValidate()
            begin
                TestField(Open, true);
                CalcFields(Amount, "Original Amount");

                if "Remaining Pmt. Disc. Possible" * Amount < 0 then
                    FieldError("Remaining Pmt. Disc. Possible", StrSubstNo(MustHaveSameSignErr, FieldCaption(Amount)));

                if Abs("Remaining Pmt. Disc. Possible") > Abs("Original Amount") then
                    FieldError("Remaining Pmt. Disc. Possible", StrSubstNo(MustNotBeLargerErr, FieldCaption("Original Amount")));
            end;
        }
        field(78; "Pmt. Disc. Tolerance Date"; Date)
        {
            Caption = 'Pmt. Disc. Tolerance Date';

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

            trigger OnValidate()
            begin
                TestField(Open, true);
                CalcFields(Amount, "Remaining Amount");
                OnValidateMaxPaymentToleranceBeforeError(Rec);

                if "Max. Payment Tolerance" * Amount < 0 then
                    FieldError("Max. Payment Tolerance", StrSubstNo(MustHaveSameSignErr, FieldCaption(Amount)));

                if Abs("Max. Payment Tolerance") > Abs("Remaining Amount") then
                    FieldError("Max. Payment Tolerance", StrSubstNo(MustNotBeLargerErr, FieldCaption("Remaining Amount")));
            end;
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

            trigger OnValidate()
            begin
                TestField(Open, true);
                CalcFields("Remaining Amount");

                if AreOppositeSign("Amount to Apply", "Remaining Amount") then
                    FieldError("Amount to Apply", StrSubstNo(MustHaveSameSignErr, FieldCaption("Remaining Amount")));

                if Abs("Amount to Apply") > Abs("Remaining Amount") then
                    FieldError("Amount to Apply", StrSubstNo(MustNotBeLargerErr, FieldCaption("Remaining Amount")));
            end;
        }
        field(85; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            TableRelation = "IC Partner";
        }
        field(86; "Applying Entry"; Boolean)
        {
            Caption = 'Applying Entry';
        }
        field(87; Reversed; Boolean)
        {
            Caption = 'Reversed';
        }
        field(88; "Reversed by Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed by Entry No.';
            TableRelation = "Vendor Ledger Entry";
        }
        field(89; "Reversed Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed Entry No.';
            TableRelation = "Vendor Ledger Entry";
        }
        field(90; Prepayment; Boolean)
        {
            Caption = 'Prepayment';
        }
        field(170; "Creditor No."; Code[20])
        {
            Caption = 'Creditor No.';
        }
        field(171; "Payment Reference"; Code[50])
        {
            Caption = 'Payment Reference';
        }
        field(172; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";

            trigger OnValidate()
            begin
                TestField(Open, true);
            end;
        }
        field(173; "Applies-to Ext. Doc. No."; Code[35])
        {
            Caption = 'Applies-to Ext. Doc. No.';
        }
        field(175; "Invoice Received Date"; Date)
        {

        }
        field(288; "Recipient Bank Account"; Code[20])
        {
            Caption = 'Recipient Bank Account';
            TableRelation = "Vendor Bank Account".Code where("Vendor No." = field("Vendor No."));
        }
        field(289; "Message to Recipient"; Text[140])
        {
            Caption = 'Message to Recipient';

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
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

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
        }
        field(482; "Shortcut Dimension 4 Code"; Code[20])
        {
            CaptionClass = '1,2,4';
            Caption = 'Shortcut Dimension 4 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(4)));
        }
        field(483; "Shortcut Dimension 5 Code"; Code[20])
        {
            CaptionClass = '1,2,5';
            Caption = 'Shortcut Dimension 5 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(5)));
        }
        field(484; "Shortcut Dimension 6 Code"; Code[20])
        {
            CaptionClass = '1,2,6';
            Caption = 'Shortcut Dimension 6 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(6)));
        }
        field(485; "Shortcut Dimension 7 Code"; Code[20])
        {
            CaptionClass = '1,2,7';
            Caption = 'Shortcut Dimension 7 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(7)));
        }
        field(486; "Shortcut Dimension 8 Code"; Code[20])
        {
            CaptionClass = '1,2,8';
            Caption = 'Shortcut Dimension 8 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(8)));
        }
        field(1000; "Remit-to Code"; Code[20])
        {
            Caption = 'Remit-to Code';
            TableRelation = "Remit Address".Code where("Vendor No." = field("Vendor No."));
        }
#if not CLEANSCHEMA26
        field(10500; "Invoice Receipt Date"; Date)
        {

            ObsoleteReason = 'Replaced by W1 field "Invoice Received Date".';
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
        }
#endif
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Vendor No.", "Posting Date", "Currency Code")
        {
            SumIndexFields = "Purchase (LCY)", "Inv. Discount (LCY)";
        }
        key(Key3; "Vendor No.", "Currency Code", "Posting Date")
        {
            Enabled = false;
        }
        key(Key4; "Document No.")
        {
        }
        key(Key5; "External Document No.")
        {
        }
        key(Key6; "Vendor No.", Open, Positive, "Due Date", "Currency Code")
        {
        }
        key(Key7; Open, "Due Date")
        {
        }
        key(Key8; "Document Type", "Vendor No.", "Posting Date", "Currency Code")
        {
            MaintainSIFTIndex = false;
            MaintainSQLIndex = false;
            SumIndexFields = "Purchase (LCY)", "Inv. Discount (LCY)";
        }
        key(Key9; "Closed by Entry No.")
        {
        }
        key(Key10; "Transaction No.")
        {
        }
        key(Key11; "Vendor No.", "Global Dimension 1 Code", "Global Dimension 2 Code", "Posting Date", "Currency Code")
        {
            Enabled = false;
            SumIndexFields = "Purchase (LCY)", "Inv. Discount (LCY)";
        }
        key(Key12; "Vendor No.", Open, "Global Dimension 1 Code", "Global Dimension 2 Code", Positive, "Due Date", "Currency Code")
        {
            Enabled = false;
        }
        key(Key13; Open, "Global Dimension 1 Code", "Global Dimension 2 Code", "Due Date")
        {
            Enabled = false;
        }
        key(Key14; "Document Type", "Vendor No.", "Global Dimension 1 Code", "Global Dimension 2 Code", "Posting Date", "Currency Code")
        {
            Enabled = false;
            MaintainSIFTIndex = false;
            MaintainSQLIndex = false;
        }
        key(Key15; "Vendor No.", "Applies-to ID", Open, Positive, "Due Date")
        {
        }
        key(Key16; "Vendor Posting Group")
        {
        }
        key(Key17; "Pmt. Discount Date")
        {
        }
        key(Key18; "Document Type", "Due Date", Open)
        {
        }
        key(Key25; "Vendor No.", "Posting Date", "Applies-to ID")
        {
            IncludedFields = "Currency Code", "Amount to Apply", Open;
        }
        key(Key26; "Applies-to ID")
        {
            IncludedFields = "Accepted Payment Tolerance";
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", Description, "Vendor No.", "Posting Date", "Document Type", "Document No.")
        {
        }
        fieldgroup(Brick; "Document No.", Description, "Remaining Amt. (LCY)", "Due Date")
        {
        }
    }

    var
#pragma warning disable AA0470
        MustHaveSameSignErr: Label 'must have the same sign as %1';
        MustNotBeLargerErr: Label 'must not be larger than %1';
#pragma warning restore AA0470
        NetBalanceOnHoldErr: Label 'General journal line number %3 on template name %1 batch name %2 is applied. Do you want to change On Hold value anyway?', Comment = '%1 - template name, %2 - batch name, %3 - line number';

    [InherentPermissions(PermissionObjectType::TableData, Database::"Vendor Ledger Entry", 'r')]
    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure ShowDoc() Result: Boolean
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowDoc(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        case "Document Type" of
            "Document Type"::Invoice:
                if PurchInvHeader.Get("Document No.") then begin
                    PAGE.Run(PAGE::"Posted Purchase Invoice", PurchInvHeader);
                    exit(true);
                end;
            "Document Type"::"Credit Memo":
                if PurchCrMemoHdr.Get("Document No.") then begin
                    PAGE.Run(PAGE::"Posted Purchase Credit Memo", PurchCrMemoHdr);
                    exit(true);
                end
        end;

        OnAfterShowDoc(Rec);
    end;

    procedure ShowPostedDocAttachment()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        case "Document Type" of
            "Document Type"::Invoice:
                if PurchInvHeader.Get("Document No.") then
                    OpenDocumentAttachmentDetails(PurchInvHeader);
            "Document Type"::"Credit Memo":
                if PurchCrMemoHdr.Get("Document No.") then
                    OpenDocumentAttachmentDetails(PurchCrMemoHdr);
        end;

        OnAfterShowPostedDocAttachment(Rec);
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
        PurchInvHeader: Record "Purch. Inv. Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        DocumentAttachment: Record "Document Attachment";
        HasPostedDocumentAttachment: Boolean;
    begin
        case "Document Type" of
            "Document Type"::Invoice:
                if PurchInvHeader.Get("Document No.") then
                    exit(DocumentAttachment.HasPostedDocumentAttachment(PurchInvHeader));
            "Document Type"::"Credit Memo":
                if PurchCrMemoHdr.Get("Document No.") then
                    exit(DocumentAttachment.HasPostedDocumentAttachment(PurchCrMemoHdr));
        end;

        OnAfterHasPostedDocAttachment(Rec, HasPostedDocumentAttachment);
        exit(HasPostedDocumentAttachment);
    end;

    procedure DrillDownOnEntries(var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry")
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        DrillDownPageID: Integer;
    begin
        VendLedgEntry.Reset();
        DtldVendLedgEntry.CopyFilter("Vendor No.", VendLedgEntry."Vendor No.");
        DtldVendLedgEntry.CopyFilter("Currency Code", VendLedgEntry."Currency Code");
        DtldVendLedgEntry.CopyFilter("Initial Entry Global Dim. 1", VendLedgEntry."Global Dimension 1 Code");
        DtldVendLedgEntry.CopyFilter("Initial Entry Global Dim. 2", VendLedgEntry."Global Dimension 2 Code");
        DtldVendLedgEntry.CopyFilter("Initial Entry Due Date", VendLedgEntry."Due Date");
        VendLedgEntry.SetCurrentKey("Vendor No.", "Posting Date");
        VendLedgEntry.SetRange(Open, true);
        OnBeforeDrillDownEntries(VendLedgEntry, DtldVendLedgEntry, DrillDownPageID);
        PAGE.Run(DrillDownPageID, VendLedgEntry);
    end;

    procedure DrillDownOnOverdueEntries(var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry")
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        DrillDownPageID: Integer;
    begin
        VendLedgEntry.Reset();
        DtldVendLedgEntry.CopyFilter("Vendor No.", VendLedgEntry."Vendor No.");
        DtldVendLedgEntry.CopyFilter("Currency Code", VendLedgEntry."Currency Code");
        DtldVendLedgEntry.CopyFilter("Initial Entry Global Dim. 1", VendLedgEntry."Global Dimension 1 Code");
        DtldVendLedgEntry.CopyFilter("Initial Entry Global Dim. 2", VendLedgEntry."Global Dimension 2 Code");
        VendLedgEntry.SetCurrentKey("Vendor No.", "Posting Date");
        VendLedgEntry.SetFilter("Date Filter", '..%1', WorkDate());
        VendLedgEntry.SetFilter("Due Date", '<%1', WorkDate());
        VendLedgEntry.SetFilter("Remaining Amount", '<>%1', 0);
        OnBeforeDrillDownOnOverdueEntries(VendLedgEntry, DtldVendLedgEntry, DrillDownPageID);
        PAGE.Run(DrillDownPageID, VendLedgEntry);
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

    procedure SetStyle() Result: Text
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetStyle(Result, IsHandled);
        if IsHandled then
            exit(Result);

        if Open then begin
            if WorkDate() > "Due Date" then
                exit('Unfavorable')
        end else
            if "Closed at Date" > "Due Date" then
                exit('Attention');
        exit('');
    end;

    procedure CopyFromGenJnlLine(GenJnlLine: Record "Gen. Journal Line")
    begin
        "Vendor No." := GenJnlLine."Account No.";
        "Posting Date" := GenJnlLine."Posting Date";
        "Document Date" := GenJnlLine."Document Date";
        "Invoice Received Date" := GenJnlLine."Invoice Received Date";
        "Document Type" := GenJnlLine."Document Type";
        "Document No." := GenJnlLine."Document No.";
        "External Document No." := GenJnlLine."External Document No.";
        Description := GenJnlLine.Description;
        "Currency Code" := GenJnlLine."Currency Code";
        "Purchase (LCY)" := GenJnlLine."Sales/Purch. (LCY)";
        "Inv. Discount (LCY)" := GenJnlLine."Inv. Discount (LCY)";
        "Buy-from Vendor No." := GenJnlLine."Sell-to/Buy-from No.";
        "Vendor Posting Group" := GenJnlLine."Posting Group";
        "Global Dimension 1 Code" := GenJnlLine."Shortcut Dimension 1 Code";
        "Global Dimension 2 Code" := GenJnlLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := GenJnlLine."Dimension Set ID";
        "Purchaser Code" := GenJnlLine."Salespers./Purch. Code";
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
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        "Bal. Account Type" := GenJnlLine."Bal. Account Type";
        "Bal. Account No." := GenJnlLine."Bal. Account No.";
        "No. Series" := GenJnlLine."Posting No. Series";
        "IC Partner Code" := GenJnlLine."IC Partner Code";
        Prepayment := GenJnlLine.Prepayment;
        "Recipient Bank Account" := GenJnlLine."Recipient Bank Account";
        "Message to Recipient" := GenJnlLine."Message to Recipient";
        "Applies-to Ext. Doc. No." := GenJnlLine."Applies-to Ext. Doc. No.";
        "Creditor No." := GenJnlLine."Creditor No.";
        "Payment Reference" := GenJnlLine."Payment Reference";
        "Payment Method Code" := GenJnlLine."Payment Method Code";
        "Exported to Payment File" := GenJnlLine."Exported to Payment File";
        if (GenJnlLine."Remit-to Code" <> '') then
            "Remit-to Code" := GenJnlLine."Remit-to Code";

        OnAfterCopyVendLedgerEntryFromGenJnlLine(Rec, GenJnlLine);
    end;

    procedure CopyFromCVLedgEntryBuffer(var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
        "Entry No." := CVLedgerEntryBuffer."Entry No.";
        "Vendor No." := CVLedgerEntryBuffer."CV No.";
        "Posting Date" := CVLedgerEntryBuffer."Posting Date";
        "Document Type" := CVLedgerEntryBuffer."Document Type";
        "Document No." := CVLedgerEntryBuffer."Document No.";
        Description := CVLedgerEntryBuffer.Description;
        "Currency Code" := CVLedgerEntryBuffer."Currency Code";
        Amount := CVLedgerEntryBuffer.Amount;
        "Remaining Amount" := CVLedgerEntryBuffer."Remaining Amount";
        "Original Amount" := CVLedgerEntryBuffer."Original Amount";
        "Original Amt. (LCY)" := CVLedgerEntryBuffer."Original Amt. (LCY)";
        "Remaining Amt. (LCY)" := CVLedgerEntryBuffer."Remaining Amt. (LCY)";
        "Amount (LCY)" := CVLedgerEntryBuffer."Amount (LCY)";
        "Purchase (LCY)" := CVLedgerEntryBuffer."Sales/Purchase (LCY)";
        "Inv. Discount (LCY)" := CVLedgerEntryBuffer."Inv. Discount (LCY)";
        "Buy-from Vendor No." := CVLedgerEntryBuffer."Bill-to/Pay-to CV No.";
        "Vendor Posting Group" := CVLedgerEntryBuffer."CV Posting Group";
        "Global Dimension 1 Code" := CVLedgerEntryBuffer."Global Dimension 1 Code";
        "Global Dimension 2 Code" := CVLedgerEntryBuffer."Global Dimension 2 Code";
        "Dimension Set ID" := CVLedgerEntryBuffer."Dimension Set ID";
        "Purchaser Code" := CVLedgerEntryBuffer."Salesperson Code";
        "User ID" := CVLedgerEntryBuffer."User ID";
        "Source Code" := CVLedgerEntryBuffer."Source Code";
        "On Hold" := CVLedgerEntryBuffer."On Hold";
        "Applies-to Doc. Type" := CVLedgerEntryBuffer."Applies-to Doc. Type";
        "Applies-to Doc. No." := CVLedgerEntryBuffer."Applies-to Doc. No.";
        Open := CVLedgerEntryBuffer.Open;
        "Due Date" := CVLedgerEntryBuffer."Due Date";
        "Pmt. Discount Date" := CVLedgerEntryBuffer."Pmt. Discount Date";
        "Original Pmt. Disc. Possible" := CVLedgerEntryBuffer."Original Pmt. Disc. Possible";
        "Orig. Pmt. Disc. Possible(LCY)" := CVLedgerEntryBuffer."Orig. Pmt. Disc. Possible(LCY)";
        "Remaining Pmt. Disc. Possible" := CVLedgerEntryBuffer."Remaining Pmt. Disc. Possible";
        "Pmt. Disc. Rcd.(LCY)" := CVLedgerEntryBuffer."Pmt. Disc. Given (LCY)";
        Positive := CVLedgerEntryBuffer.Positive;
        "Closed by Entry No." := CVLedgerEntryBuffer."Closed by Entry No.";
        "Closed at Date" := CVLedgerEntryBuffer."Closed at Date";
        "Closed by Amount" := CVLedgerEntryBuffer."Closed by Amount";
        "Applies-to ID" := CVLedgerEntryBuffer."Applies-to ID";
        "Journal Templ. Name" := CVLedgerEntryBuffer."Journal Templ. Name";
        "Journal Batch Name" := CVLedgerEntryBuffer."Journal Batch Name";
        "Reason Code" := CVLedgerEntryBuffer."Reason Code";
        "Bal. Account Type" := CVLedgerEntryBuffer."Bal. Account Type";
        "Bal. Account No." := CVLedgerEntryBuffer."Bal. Account No.";
        "Transaction No." := CVLedgerEntryBuffer."Transaction No.";
        "Closed by Amount (LCY)" := CVLedgerEntryBuffer."Closed by Amount (LCY)";
        "Debit Amount" := CVLedgerEntryBuffer."Debit Amount";
        "Credit Amount" := CVLedgerEntryBuffer."Credit Amount";
        "Debit Amount (LCY)" := CVLedgerEntryBuffer."Debit Amount (LCY)";
        "Credit Amount (LCY)" := CVLedgerEntryBuffer."Credit Amount (LCY)";
        "Document Date" := CVLedgerEntryBuffer."Document Date";
        "External Document No." := CVLedgerEntryBuffer."External Document No.";
        "No. Series" := CVLedgerEntryBuffer."No. Series";
        "Closed by Currency Code" := CVLedgerEntryBuffer."Closed by Currency Code";
        "Closed by Currency Amount" := CVLedgerEntryBuffer."Closed by Currency Amount";
        "Adjusted Currency Factor" := CVLedgerEntryBuffer."Adjusted Currency Factor";
        "Original Currency Factor" := CVLedgerEntryBuffer."Original Currency Factor";
        "Pmt. Disc. Tolerance Date" := CVLedgerEntryBuffer."Pmt. Disc. Tolerance Date";
        "Max. Payment Tolerance" := CVLedgerEntryBuffer."Max. Payment Tolerance";
        "Accepted Payment Tolerance" := CVLedgerEntryBuffer."Accepted Payment Tolerance";
        "Accepted Pmt. Disc. Tolerance" := CVLedgerEntryBuffer."Accepted Pmt. Disc. Tolerance";
        "Pmt. Tolerance (LCY)" := CVLedgerEntryBuffer."Pmt. Tolerance (LCY)";
        "Amount to Apply" := CVLedgerEntryBuffer."Amount to Apply";
        Prepayment := CVLedgerEntryBuffer.Prepayment;

        OnAfterCopyVendLedgerEntryFromCVLedgEntryBuffer(Rec, CVLedgerEntryBuffer);
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
                if UpdateMaxPaymentTolerance then
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
    local procedure OnAfterCopyVendLedgerEntryFromGenJnlLine(var VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyVendLedgerEntryFromCVLedgEntryBuffer(var VendorLedgerEntry: Record "Vendor Ledger Entry"; CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecalculateAmounts(var VendorLedgerEntry: Record "Vendor Ledger Entry"; FromCurrencyCode: Code[10]; ToCurrencyCode: Code[10]; PostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateMaxPaymentToleranceBeforeError(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDoc(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowPostedDocAttachment(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHasPostedDocAttachment(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var HasPostedDocumentAttachment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDrillDownEntries(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; var DrillDownPageID: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeDrillDownOnOverdueEntries(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; var DrillDownPageID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateMessagetoRecipient(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDoc(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSetStyle(var Result: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAmountsForApplication(var VendorLedgerEntry: Record "Vendor Ledger Entry"; ApplnDate: Date; ApplnCurrencyCode: Code[10]; RoundAmounts: Boolean; UpdateMaxPaymentTolerance: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRemainingPmtDiscPossible(VendorLedgerEntry: Record "Vendor Ledger Entry"; ReferenceDate: Date; var RemainingPmtDiscPossible: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecalculateAmounts(var VendorLedgerEntry: Record "Vendor Ledger Entry"; FromCurrencyCode: Code[10]; ToCurrencyCode: Code[10]; PostingDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAmountsForApplication(var VendorLedgerEntry: Record "Vendor Ledger Entry"; ApplnDate: Date; ApplnCurrencyCode: Code[10]; RoundAmounts: Boolean; UpdateMaxPaymentTolerance: Boolean; var IsHandled: Boolean)
    begin
    end;
}

