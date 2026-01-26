// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

table 2000001 "Payment Journal Line"
{
    Caption = 'Payment Journal Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Payment Journal Template";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Account Type"; Option)
        {
            Caption = 'Account Type';
            InitValue = Vendor;
            OptionCaption = ',Customer,Vendor';
            OptionMembers = ,Customer,Vendor;

            trigger OnValidate()
            begin
                "Account No." := '';
                Validate("Account No.");
            end;
        }
        field(4; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = if ("Account Type" = const(Customer)) Customer
            else
            if ("Account Type" = const(Vendor)) Vendor;

            trigger OnValidate()
            begin
                if "Account No." <> xRec."Account No." then begin
                    xRec."Account Type" := "Account Type";
                    xRec."Account No." := "Account No.";
                    xRec."Posting Date" := "Posting Date";
                    xRec."Bank Account" := "Bank Account";
                    Init();
                    "Account Type" := xRec."Account Type";
                    "Account No." := xRec."Account No.";
                    Validate("Posting Date", xRec."Posting Date");
                    Validate("Bank Account", xRec."Bank Account");
                end;
                if "Account No." = '' then begin
                    CreateDim(
                      TypeToTableID2000001("Account Type"), "Account No.",
                      DATABASE::"Bank Account", "Bank Account",
                      DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code");
                    exit;
                end;
                case "Account Type" of
                    "Account Type"::Customer:
                        begin
                            Cust.Get("Account No.");
                            if ("Applies-to Doc. No." = '') and ("Applies-to ID" = '') then
                                Validate("Currency Code", Cust."Currency Code");
                            Validate("Bank Country/Region Code", Cust."Country/Region Code");
                            Validate("Beneficiary Bank Account", Cust."Preferred Bank Account Code");
                            "Payment Method Code" := Cust."Payment Method Code";
                            "Salespers./Purch. Code" := Cust."Salesperson Code";
                            if "Applies-to Doc. Type" = "Applies-to Doc. Type"::" " then
                                "Applies-to Doc. Type" := "Applies-to Doc. Type"::"Credit Memo";
                            Description := Cust.Name;
                        end;
                    "Account Type"::Vendor:
                        begin
                            Vend.Get("Account No.");
                            if ("Applies-to Doc. No." = '') and ("Applies-to ID" = '') then
                                Validate("Currency Code", Vend."Currency Code");
                            Validate("Bank Country/Region Code", Vend."Country/Region Code");
                            Validate("Beneficiary Bank Account", Vend."Preferred Bank Account Code");
                            "Payment Method Code" := Vend."Payment Method Code";
                            "Salespers./Purch. Code" := Vend."Purchaser Code";
                            if "Applies-to Doc. Type" = "Applies-to Doc. Type"::" " then
                                "Applies-to Doc. Type" := "Applies-to Doc. Type"::Invoice;
                            Description := Vend.Name;
                        end;
                end;

                CreateDim(
                  TypeToTableID2000001("Account Type"), "Account No.",
                  DATABASE::"Bank Account", "Bank Account",
                  DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code");
            end;
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';

            trigger OnValidate()
            begin
                if ("Pmt. Discount Date" = 0D) or
                   ("Pmt. Discount Date" = xRec."Posting Date")
                then
                    "Pmt. Discount Date" := "Posting Date";
            end;
        }
        field(7; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(8; "Payment Message"; Text[100])
        {
            Caption = 'Payment Message';

            trigger OnValidate()
            var
                PmtJrnlMgt: Codeunit PmtJrnlManagement;
            begin
                "Standard Format Message" := PmtJrnlMgt.Mod97Test("Payment Message");
                Validate("Separate Line");
            end;
        }
        field(9; "Standard Format Message"; Boolean)
        {
            Caption = 'Standard Format Message';
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(12; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;

            trigger OnValidate()
            begin
                InitCurrencyCode();
                if "Currency Code" <> '' then begin
                    if ("Currency Code" <> xRec."Currency Code") or
                       ("Posting Date" <> xRec."Posting Date") or
                       (CurrFieldNo = FieldNo("Currency Code")) or
                       ("Currency Factor" = 0)
                    then
                        "Currency Factor" :=
                          CurrencyExchRate.ExchangeRate("Posting Date", "Currency Code");
                end else
                    "Currency Factor" := 0;

                Validate("Currency Factor");
                "ISO Currency Code" := GetISOCurrencyCode();
            end;
        }
        field(13; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            MinValue = 0;

            trigger OnValidate()
            begin
                if ("Currency Code" = '') and ("Currency Factor" <> 0) then
                    FieldError("Currency Factor", StrSubstNo(Text001, FieldCaption("Currency Code")));
                Validate(Amount);
            end;
        }
        field(14; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';

            trigger OnValidate()
            begin
                InitCurrencyCode();
                Amount := Round(Amount, Currency."Amount Rounding Precision");

                if "Currency Code" = '' then
                    "Amount (LCY)" := Amount
                else
                    "Amount (LCY)" := Round(
                        CurrencyExchRate.ExchangeAmtFCYToLCY(
                          "Posting Date", "Currency Code",
                          Amount, "Currency Factor"));

                "Partial Payment" := ("Original Remaining Amount" - "Pmt. Disc. Possible") <> Amount;
                Validate("Separate Line");
            end;
        }
        field(15; "Pmt. Disc. Possible"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Pmt. Disc. Possible';

            trigger OnValidate()
            begin
                if "Pmt. Disc. Possible" * Amount < 0 then
                    FieldError("Pmt. Disc. Possible", StrSubstNo(Text002, FieldCaption(Amount)));

                InitCurrencyCode();
                "Pmt. Disc. Possible" := Round("Pmt. Disc. Possible", Currency."Amount Rounding Precision");

                if "Currency Code" <> '' then
                    "Pmt. Disc. Possible (LCY)" := Round(
                        CurrencyExchRate.ExchangeAmtFCYToLCY(
                          "Posting Date", "Currency Code",
                          "Pmt. Disc. Possible", "Currency Factor"))
                else
                    "Pmt. Disc. Possible (LCY)" := "Pmt. Disc. Possible";

                if CurrFieldNo = FieldNo("Pmt. Disc. Possible") then
                    Validate(Amount, Amount + xRec."Pmt. Disc. Possible" - "Pmt. Disc. Possible")
                else
                    Validate(Amount);
            end;
        }
        field(16; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                if "Currency Code" = '' then begin
                    Amount := "Amount (LCY)";
                    Validate(Amount);
                end else begin
                    TestField(Amount);
                    "Currency Factor" := Amount / "Amount (LCY)";
                end;
            end;
        }
        field(17; "Pmt. Disc. Possible (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Pmt. Disc. Possible (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                if "Currency Code" = '' then begin
                    "Pmt. Disc. Possible" := "Pmt. Disc. Possible (LCY)";
                    Validate("Pmt. Disc. Possible");
                end else begin
                    TestField("Currency Factor");
                    Validate("Pmt. Disc. Possible", ("Pmt. Disc. Possible (LCY)" / "Currency Factor"));
                end;
            end;
        }
        field(18; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';
            Editable = true;

            trigger OnValidate()
            begin
                if "Applies-to Doc. No." <> '' then
                    Validate("Applies-to Doc. No.");
            end;
        }
        field(19; "Beneficiary Bank Account"; Code[20])
        {
            Caption = 'Beneficiary Bank Account';
            TableRelation = if ("Account Type" = filter(Customer)) "Customer Bank Account".Code where("Customer No." = field("Account No."))
            else
            if ("Account Type" = filter(Vendor)) "Vendor Bank Account".Code where("Vendor No." = field("Account No."));

            trigger OnValidate()
            begin
                if "Beneficiary Bank Account" <> '' then
                    case "Account Type" of
                        "Account Type"::Customer:
                            begin
                                CustBankAcc.Get("Account No.", "Beneficiary Bank Account");
                                Validate("Bank Country/Region Code", CustBankAcc."Country/Region Code");
                                Validate("SWIFT Code", CustBankAcc."SWIFT Code");
                                "Beneficiary Bank Account No." := CustBankAcc."Bank Account No.";
                                "Beneficiary IBAN" := CustBankAcc.IBAN;
                                Validate("Export Protocol Code", CustBankAcc."Export Protocol Code");
                            end;
                        "Account Type"::Vendor:
                            begin
                                VendBankAcc.Get("Account No.", "Beneficiary Bank Account");
                                Validate("Bank Country/Region Code", VendBankAcc."Country/Region Code");
                                Validate("SWIFT Code", VendBankAcc."SWIFT Code");
                                "Beneficiary Bank Account No." := VendBankAcc."Bank Account No.";
                                "Beneficiary IBAN" := VendBankAcc.IBAN;
                                Validate("Export Protocol Code", VendBankAcc."Export Protocol Code");
                            end;
                    end
                else begin
                    Validate("Beneficiary Bank Account No.", '');
                    "Beneficiary IBAN" := '';
                    Validate("SWIFT Code", '');
                    Validate("Bank Country/Region Code", '')
                end;
            end;
        }
        field(20; "Beneficiary Bank Account No."; Text[50])
        {
            Caption = 'Beneficiary Bank Account No.';
            Editable = false;
        }
        field(22; "Bank Account"; Code[20])
        {
            Caption = 'Bank Account';
            TableRelation = "Bank Account";

            trigger OnValidate()
            var
                BankAcc: Record "Bank Account";
            begin
                CreateDim(
                  DATABASE::"Bank Account", "Bank Account",
                  TypeToTableID2000001("Account Type"), "Account No.",
                  DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code");

                if "Bank Account" <> '' then begin
                    BankAcc.Get("Bank Account");
                    if BankAcc."Interbank Clearing Code" = BankAcc."Interbank Clearing Code"::Urgent then
                        "Instruction Priority" := "Instruction Priority"::High;
                end;
            end;
        }
        field(23; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";
        }
        field(24; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(25; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(29; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            Editable = false;
            TableRelation = "Source Code";
        }
        field(35; "Applies-to Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-to Doc. Type';
        }
        field(36; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';

            trigger OnLookup()
            var
                GenJnlLine: Record "Gen. Journal Line";
            begin
                AccNo := "Account No.";
                AccType := "Account Type";

                case AccType of
                    AccType::Customer:
                        begin
                            CustLedgEntry.Reset();
                            CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive, "Due Date");
                            CustLedgEntry.SetRange("Customer No.", AccNo);
                            CustLedgEntry.SetRange(Open, true);
                            if "Applies-to Doc. No." <> '' then begin
                                CustLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
                                CustLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                                if CustLedgEntry.FindFirst() then;
                                CustLedgEntry.SetRange("Document Type");
                                CustLedgEntry.SetRange("Document No.");
                            end else
                                if "Applies-to ID" <> '' then begin
                                    CustLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
                                    if CustLedgEntry.FindFirst() then;
                                    CustLedgEntry.SetRange("Applies-to ID");
                                end else
                                    if "Applies-to Doc. Type" <> "Applies-to Doc. Type"::" " then begin
                                        CustLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
                                        if CustLedgEntry.FindFirst() then;
                                        CustLedgEntry.SetRange("Document Type");
                                    end else
                                        if Amount <> 0 then begin
                                            CustLedgEntry.SetRange(Positive, Amount < 0);
                                            if CustLedgEntry.FindFirst() then;
                                            CustLedgEntry.SetRange(Positive);
                                        end;
                            if CustLedgEntry.IsEmpty() then begin
                                CustLedgEntry.Init();
                                CustLedgEntry."Customer No." := AccNo;
                            end;
                            InitGenJnlLine(GenJnlLine);
                            Clear(ApplyCustLedgEntries);
                            ApplyCustLedgEntries.SetGenJnlLine(GenJnlLine, FieldNo("Applies-to Doc. No."));
                            ApplyCustLedgEntries.SetTableView(CustLedgEntry);
                            ApplyCustLedgEntries.SetRecord(CustLedgEntry);
                            ApplyCustLedgEntries.LookupMode(true);
                            if ApplyCustLedgEntries.RunModal() = ACTION::LookupOK then begin
                                ApplyCustLedgEntries.GetRecord(CustLedgEntry);
                                CustUpdatePayment();
                            end;
                        end;
                    AccType::Vendor:
                        begin
                            VendLedgEntry.Reset();
                            VendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive, "Due Date");
                            VendLedgEntry.SetRange("Vendor No.", AccNo);
                            VendLedgEntry.SetRange(Open, true);
                            if "Applies-to Doc. No." <> '' then begin
                                VendLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
                                VendLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                                if VendLedgEntry.FindFirst() then;
                                VendLedgEntry.SetRange("Document Type");
                                VendLedgEntry.SetRange("Document No.");
                            end else
                                if "Applies-to ID" <> '' then begin
                                    VendLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
                                    if VendLedgEntry.FindFirst() then;
                                    VendLedgEntry.SetRange("Applies-to ID");
                                end else
                                    if "Applies-to Doc. Type" <> "Applies-to Doc. Type"::" " then begin
                                        VendLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
                                        if VendLedgEntry.FindFirst() then;
                                        VendLedgEntry.SetRange("Document Type");
                                    end else
                                        if Amount <> 0 then begin
                                            VendLedgEntry.SetRange(Positive, Amount < 0);
                                            if VendLedgEntry.FindFirst() then;
                                            VendLedgEntry.SetRange(Positive);
                                        end;
                            if VendLedgEntry.IsEmpty() then begin
                                VendLedgEntry.Init();
                                VendLedgEntry."Vendor No." := AccNo;
                            end;
                            InitGenJnlLine(GenJnlLine);
                            Clear(ApplyVendLedgEntries);
                            ApplyVendLedgEntries.SetGenJnlLine(GenJnlLine, FieldNo("Applies-to Doc. No."));
                            ApplyVendLedgEntries.SetTableView(VendLedgEntry);
                            ApplyVendLedgEntries.SetRecord(VendLedgEntry);
                            ApplyVendLedgEntries.LookupMode(true);
                            if ApplyVendLedgEntries.RunModal() = ACTION::LookupOK then begin
                                ApplyVendLedgEntries.GetRecord(VendLedgEntry);
                                VendUpdatePayment();
                            end;
                        end;
                end;
            end;

            trigger OnValidate()
            begin
                // Empty Applies-to Doc for payment without invoice
                if "Applies-to Doc. No." <> '' then
                    case "Account Type" of
                        "Account Type"::Customer:
                            begin
                                CustLedgEntry.Reset();
                                CustLedgEntry.SetCurrentKey("Document No.");
                                CustLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
                                CustLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                                CustLedgEntry.SetRange("Customer No.", "Account No.");
                                if not CustLedgEntry.FindFirst() then
                                    Error(Text003, "Applies-to Doc. Type", "Applies-to Doc. No.");
                                CustUpdatePayment();
                            end;
                        "Account Type"::Vendor:
                            begin
                                VendLedgEntry.Reset();
                                VendLedgEntry.SetCurrentKey("Document No.");
                                VendLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
                                VendLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                                VendLedgEntry.SetRange("Vendor No.", "Account No.");
                                if not VendLedgEntry.FindFirst() then
                                    Error(Text004, "Applies-to Doc. Type", "Applies-to Doc. No.");
                                VendUpdatePayment();
                            end;
                    end;
            end;
        }
        field(37; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';
        }
        field(39; "Code Payment Method"; Option)
        {
            Caption = 'Code Payment Method';
            InitValue = " ";
            OptionCaption = ' ,TLX,CDC,CDD,CHC,CHD,MAN,EUR';
            OptionMembers = " ",TLX,CDC,CDD,CHC,CHD,MAN,EUR;
        }
        field(40; "Code Expenses"; Option)
        {
            Caption = 'Code Expenses';
            OptionCaption = ' ,SHA,BEN,OUR';
            OptionMembers = " ",SHA,BEN,OUR;
        }
        field(45; "IBLC/BLWI Code"; Code[3])
        {
            Caption = 'IBLC/BLWI Code';
            Numeric = true;
            TableRelation = "IBLC/BLWI Transaction Code";
        }
        field(46; "IBLC/BLWI Justification"; Text[50])
        {
            Caption = 'IBLC/BLWI Justification';
        }
        field(51; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Paym. Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));
        }
        field(52; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(53; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Created,,Processed,Posted';
            OptionMembers = Created,,Processed,Posted;
        }
        field(54; Processing; Boolean)
        {
            Caption = 'Processing';
            Editable = false;
        }
        field(55; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            Editable = false;
            InitValue = false;
        }
        field(60; "ISO Currency Code"; Code[3])
        {
            Caption = 'ISO Currency Code';
            Editable = false;
        }
        field(61; "Bank Country/Region Code"; Code[10])
        {
            Caption = 'Bank Country/Region Code';
            Editable = false;
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                if "Bank Country/Region Code" = '' then
                    "Bank ISO Country/Region Code" := Text005
                else
                    if Country.Get("Bank Country/Region Code") then begin
                        Country.TestField("ISO Code");
                        "Bank ISO Country/Region Code" := Country."ISO Code";
                    end;
            end;
        }
        field(62; "Bank ISO Country/Region Code"; Code[2])
        {
            Caption = 'Bank ISO Country/Region Code';
            Editable = false;
        }
        field(63; "Original Remaining Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Original Remaining Amount';
            Editable = false;
        }
        field(64; "Ledger Entry No."; Integer)
        {
            Caption = 'Ledger Entry No.';
            TableRelation = if ("Account Type" = const(Vendor)) "Vendor Ledger Entry" where("Entry No." = field("Ledger Entry No."))
            else
            if ("Account Type" = const(Customer)) "Cust. Ledger Entry" where("Entry No." = field("Ledger Entry No."));
        }
        field(65; "Partial Payment"; Boolean)
        {
            Caption = 'Partial Payment';
        }
        field(66; "Separate Line"; Boolean)
        {
            Caption = 'Separate Line';

            trigger OnValidate()
            begin
                "Separate Line" := ("Standard Format Message" or "Partial Payment") and (Amount > 0);
            end;
        }
        field(67; "SWIFT Code"; Code[20])
        {
            Caption = 'SWIFT Code';
            Editable = false;
        }
        field(69; "Salespers./Purch. Code"; Code[20])
        {
            Caption = 'Salespers./Purch. Code';
        }
        field(75; "Export Protocol Code"; Code[20])
        {
            Caption = 'Export Protocol Code';
            TableRelation = "Export Protocol".Code;

            trigger OnValidate()
            begin
                GetExportProtocol();
                "Code Expenses" := ExportProtocol."Code Expenses";
            end;
        }
        field(80; "Instruction Priority"; Option)
        {
            Caption = 'Instruction Priority';
            OptionCaption = 'Normal,High';
            OptionMembers = Normal,High;
        }
        field(81; "Beneficiary IBAN"; Code[50])
        {
            Caption = 'Beneficiary IBAN';

            trigger OnValidate()
            var
                CompanyInfo: Record "Company Information";
            begin
                CompanyInfo.CheckIBAN("Beneficiary IBAN");
            end;
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

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(500; "Exported To File"; Boolean)
        {
            Caption = 'Exported To File';
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "Journal Batch Name", "Line No.")
        {
            Clustered = true;
            SumIndexFields = Amount, "Amount (LCY)";
        }
        key(Key2; "Account Type", "Account No.", "Currency Code", "Applies-to ID", "Separate Line", "Applies-to Doc. Type", "Applies-to Doc. No.")
        {
            SumIndexFields = Amount, "Amount (LCY)";
        }
        key(Key3; "ISO Currency Code")
        {
            SumIndexFields = Amount, "Amount (LCY)";
        }
        key(Key4; "Bank Account", "Beneficiary Bank Account No.", Status, "Account Type", "Account No.", "Currency Code", "Posting Date", "Instruction Priority", "Code Expenses")
        {
        }
        key(Key5; "Journal Template Name", "Journal Batch Name", "Account Type", "Account No.", "Export Protocol Code", "Bank Account")
        {
            MaintainSIFTIndex = false;
            MaintainSQLIndex = false;
            SumIndexFields = Amount, "Amount (LCY)";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        DeletePaymentFileErrors();
    end;

    trigger OnInsert()
    begin
        LockTable();
        PaymentJnlTemplate.Get("Journal Template Name");
        "Source Code" := PaymentJnlTemplate."Source Code";
        PaymJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        "Reason Code" := PaymJnlBatch."Reason Code";
    end;

    trigger OnModify()
    begin
        if not Processing then
            if xRec.Status = Status::Posted then
                Error(Text000);
        Processing := (Status = Status::Processed);
    end;

    var
        Text000: Label 'Payment has been posted, changes are not allowed.';
        Text001: Label 'cannot be specified without %1.';
        Text002: Label 'must have the same sign as %1.';
        Text003: Label '%1 %2 is not a Customer Ledger Entry.', Comment = 'First parameter is a sales document type, second one - document number.';
        Text004: Label '%1 %2 is not a Vendor Ledger Entry.', Comment = 'First parameter is a purchase document type, second one - document number.';
        Cust: Record Customer;
        Vend: Record Vendor;
        Currency: Record Currency;
        CurrencyExchRate: Record "Currency Exchange Rate";
        PaymentJnlTemplate: Record "Payment Journal Template";
        PaymJnlBatch: Record "Paym. Journal Batch";
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustBankAcc: Record "Customer Bank Account";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendBankAcc: Record "Vendor Bank Account";
        Country: Record "Country/Region";
        ExportProtocol: Record "Export Protocol";
        DimMgt: Codeunit DimensionManagement;
        ApplyCustLedgEntries: Page "Apply Customer Entries";
        ApplyVendLedgEntries: Page "Apply Vendor Entries";
        AccNo: Code[20];
        AccType: Option "G/L Account",Customer,Vendor;
        Text005: Label 'BE';
        Text008: Label 'This document is already fully paid.';
        Text009: Label 'There are already payments for this document.';
        Text010: Label 'There is already a payment line for this document.';
        Text011: Label 'This vendor ledger entry was already partially paid.';
        Text012: Label 'This customer ledger entry was already partially paid.';

    procedure InitCurrencyCode()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        if "Currency Code" = '' then begin
            Clear(Currency);
            Currency.InitRoundingPrecision();
            Currency."ISO Code" := GLSetup."LCY Code"
        end else
            if "Currency Code" <> Currency.Code then begin
                Currency.Get("Currency Code");
                Currency.TestField("Amount Rounding Precision");
                Currency.TestField("ISO Code")
            end;
    end;

    procedure GetISOCurrencyCode(): Code[3]
    begin
        if "Currency Code" <> Currency.Code then
            InitCurrencyCode();
        exit(Currency."ISO Code");
    end;

    procedure VendUpdatePayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJnlLine: Record "Payment Journal Line";
    begin
        VendLedgEntry.TestField("On Hold", '');
        VendLedgEntry.CalcFields("Remaining Amount");

        if (VendLedgEntry."Document Type" in [VendLedgEntry."Document Type"::Invoice, VendLedgEntry."Document Type"::"Credit Memo"]) and
           ("Pmt. Discount Date" <> 0D) and
           ("Pmt. Discount Date" <= VendLedgEntry."Pmt. Discount Date")
        then begin
            "Original Remaining Amount" := -VendLedgEntry."Remaining Amount";
            Amount := -(VendLedgEntry."Remaining Amount" - VendLedgEntry."Remaining Pmt. Disc. Possible");
            "Pmt. Disc. Possible" := -VendLedgEntry."Remaining Pmt. Disc. Possible";
        end else begin
            "Original Remaining Amount" := -VendLedgEntry."Remaining Amount";
            Amount := -VendLedgEntry."Remaining Amount";
            "Pmt. Disc. Possible" := 0;
        end;

        if CurrFieldNo = FieldNo("Applies-to Doc. No.") then begin
            if Amount = 0 then
                Message(Text008);

            if VendLedgEntry."Applies-to ID" <> '' then begin
                Message(Text009);
                Amount := 0;
            end;

            PaymentJnlLine.Reset();
            PaymentJnlLine.SetCurrentKey("Account Type", "Account No.");
            PaymentJnlLine.SetRange("Account Type", PaymentJnlLine."Account Type"::Vendor);
            PaymentJnlLine.SetRange("Account No.", VendLedgEntry."Vendor No.");
            PaymentJnlLine.SetRange("Applies-to Doc. Type", VendLedgEntry."Document Type");
            PaymentJnlLine.SetRange("Applies-to Doc. No.", VendLedgEntry."Document No.");
            PaymentJnlLine.SetFilter(Status, '<>%1', PaymentJnlLine.Status::Posted);
            if not PaymentJnlLine.IsEmpty() then begin
                Amount := 0;
                Error(Text010);
            end;
        end;

        GenJournalLine.SetCurrentKey("Account Type", "Account No.", "Applies-to Doc. Type", "Applies-to Doc. No.");
        SetFilterToLedgerEntry(
          "Gen. Journal Account Type".FromInteger(PaymentJnlLine."Account Type"::Vendor), VendLedgEntry."Vendor No.", VendLedgEntry."Document Type", VendLedgEntry."Document No.",
          GenJournalLine);

        if not PopulateAmountFromGenJournalLine(GenJournalLine) then
            Message(Text011);

        Validate("Currency Code", VendLedgEntry."Currency Code");
        Validate(Amount);
        Validate("Pmt. Disc. Possible");

        if VendLedgEntry."Payment Reference" <> '' then
            "Payment Message" := VendLedgEntry."Payment Reference"
        else
            if VendLedgEntry."External Document No." <> '' then
                "Payment Message" := VendLedgEntry."External Document No."
            else
                "Payment Message" := VendLedgEntry.Description;
        Validate("Payment Message");

        "External Document No." := VendLedgEntry."External Document No.";
        "Applies-to Doc. Type" := VendLedgEntry."Document Type";
        "Applies-to Doc. No." := VendLedgEntry."Document No.";
        "Applies-to ID" := '';

        "Dimension Set ID" := VendLedgEntry."Dimension Set ID";
        "Ledger Entry No." := VendLedgEntry."Entry No.";

        OnAfterVendUpdatePayment(Rec, VendLedgEntry);
    end;

    procedure CustUpdatePayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJnlLine: Record "Payment Journal Line";
    begin
        CustLedgEntry.TestField("On Hold", '');
        CustLedgEntry.CalcFields("Remaining Amount");

        if (CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::"Credit Memo") and
           ("Pmt. Discount Date" <> 0D) and
           ("Pmt. Discount Date" <= CustLedgEntry."Pmt. Discount Date")
        then begin
            "Original Remaining Amount" := -CustLedgEntry."Remaining Amount";
            Amount := -(CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible");
            "Pmt. Disc. Possible" := -CustLedgEntry."Remaining Pmt. Disc. Possible";
        end else begin
            "Original Remaining Amount" := -CustLedgEntry."Remaining Amount";
            Amount := -CustLedgEntry."Remaining Amount";
            "Pmt. Disc. Possible" := 0;
        end;

        if CurrFieldNo = FieldNo("Applies-to Doc. No.") then begin
            if Amount = 0 then
                Message(Text008);
            if CustLedgEntry."Applies-to ID" <> '' then begin
                Message(Text009);
                Amount := 0;
            end;

            PaymentJnlLine.Reset();
            PaymentJnlLine.SetCurrentKey("Account Type", "Account No.");
            PaymentJnlLine.SetRange("Account Type", PaymentJnlLine."Account Type"::Customer);
            PaymentJnlLine.SetRange("Account No.", CustLedgEntry."Customer No.");
            PaymentJnlLine.SetRange("Applies-to Doc. Type", CustLedgEntry."Document Type");
            PaymentJnlLine.SetRange("Applies-to Doc. No.", CustLedgEntry."Document No.");
            PaymentJnlLine.SetFilter(Status, '<>%1', PaymentJnlLine.Status::Posted);
            if not PaymentJnlLine.IsEmpty() then begin
                Amount := 0;
                Error(Text010);
            end;
        end;

        GenJournalLine.SetCurrentKey("Account Type", "Account No.", "Applies-to Doc. Type", "Applies-to Doc. No.");
        SetFilterToLedgerEntry(
          "Gen. Journal Account Type".FromInteger("Account Type"::Customer), CustLedgEntry."Customer No.", CustLedgEntry."Document Type", CustLedgEntry."Document No.",
          GenJournalLine);

        if not PopulateAmountFromGenJournalLine(GenJournalLine) then
            Message(Text012);

        Validate("Currency Code", CustLedgEntry."Currency Code");
        Validate(Amount);
        Validate("Pmt. Disc. Possible");

        "Payment Message" := CustLedgEntry."Document No.";
        "External Document No." := CustLedgEntry."Document No.";
        "Applies-to Doc. Type" := CustLedgEntry."Document Type";
        "Applies-to Doc. No." := CustLedgEntry."Document No.";
        "Applies-to ID" := '';

        "Dimension Set ID" := CustLedgEntry."Dimension Set ID";
        "Ledger Entry No." := CustLedgEntry."Entry No.";

        OnAfterCustUpdatePayment(Rec, CustLedgEntry);
    end;

    procedure CreateDim(Type1: Integer; No1: Code[20]; Type2: Integer; No2: Code[20]; Type3: Integer; No3: Code[20])
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';

        DimMgt.AddDimSource(DefaultDimSource, Type1, No1);
        DimMgt.AddDimSource(DefaultDimSource, Type2, No2);
        DimMgt.AddDimSource(DefaultDimSource, Type3, No3);

        "Dimension Set ID" :=
            DimMgt.GetRecDefaultDimID(
                Rec, CurrFieldNo, DefaultDimSource, "Source Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
    end;

    procedure ValidateShortcutDimCode(FieldNo: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateShortcutDimValues(FieldNo, ShortcutDimCode, "Dimension Set ID");
    end;

    procedure LookupShortcutDimCode(FieldNo: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNo, ShortcutDimCode);
        DimMgt.ValidateShortcutDimValues(FieldNo, ShortcutDimCode, "Dimension Set ID");
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            "Dimension Set ID", StrSubstNo('%1 %2 %3', "Journal Template Name", "Journal Batch Name", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    procedure TypeToTableID2000001(Type: Option " ",Customer,Vendor): Integer
    begin
        case Type of
            Type::" ":
                exit(0);
            Type::Customer:
                exit(Database::Customer);
            Type::Vendor:
                exit(Database::Vendor);
        end;
    end;

    local procedure GetExportProtocol()
    begin
        if "Export Protocol Code" <> '' then begin
            if "Export Protocol Code" <> ExportProtocol.Code then
                ExportProtocol.Get("Export Protocol Code");
        end else
            Clear(ExportProtocol);
    end;

    local procedure InitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        case "Account Type" of
            "Account Type"::Customer:
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
            "Account Type"::Vendor:
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
        end;
        GenJnlLine.Amount := Amount;
        GenJnlLine."Posting Date" := "Posting Date";
        GenJnlLine."Currency Code" := "Currency Code";
    end;

    procedure DeletePaymentFileErrors()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine."Journal Template Name" := "Journal Template Name";
        GenJnlLine."Journal Batch Name" := "Journal Batch Name";
        GenJnlLine."Document No." := "Applies-to Doc. No.";
        GenJnlLine."Line No." := "Line No.";
        GenJnlLine.DeletePaymentFileErrors();
    end;

    local procedure PopulateAmountFromGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"): Boolean
    begin
        if GenJournalLine.FindSet() then begin
            if CurrFieldNo = FieldNo("Applies-to Doc. No.") then
                exit(false);
            repeat
                Amount := Amount - GenJournalLine.Amount;
            until GenJournalLine.Next() = 0;
        end;
        exit(true);
    end;

    local procedure SetFilterToLedgerEntry(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[21]; AppliestoDocType: Enum "Gen. Journal Document Type"; AppliestoDocNo: Code[21]; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.SetRange("Account Type", AccountType);
        GenJournalLine.SetRange("Account No.", AccountNo);
        GenJournalLine.SetRange("Applies-to Doc. Type", AppliestoDocType);
        GenJournalLine.SetRange("Applies-to Doc. No.", AppliestoDocNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCustUpdatePayment(var PaymentJournalLine: Record "Payment Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterVendUpdatePayment(var PaymentJournalLine: Record "Payment Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;
}

