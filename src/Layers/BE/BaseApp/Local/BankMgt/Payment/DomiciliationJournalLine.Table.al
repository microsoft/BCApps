// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.DirectDebit;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

table 2000022 "Domiciliation Journal Line"
{
    Caption = 'Domiciliation Journal Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Domiciliation Journal Template";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;
            ValidateTableRelation = true;

            trigger OnValidate()
            begin
                if "Customer No." = '' then begin
                    CreateDim(
                      DATABASE::Customer, "Customer No.",
                      DATABASE::"Bank Account", "Bank Account No.");
                    exit;
                end;
                Cust.Get("Customer No.");

                // test on customer
                InitCompanyInformation();
                if Cust."Domiciliation No." <> '' then
                    if not DomiciliationJnlMgt.CheckDomiciliationNo(Cust."Domiciliation No.") then
                        Error(Text001, Cust.FieldCaption("Domiciliation No."));
                if "Applies-to Doc. Type" = "Applies-to Doc. Type"::" " then
                    "Applies-to Doc. Type" := "Applies-to Doc. Type"::Invoice;

                if "Customer No." <> xRec."Customer No." then begin
                    xRec."Customer No." := "Customer No.";
                    xRec."Posting Date" := "Posting Date";
                    xRec.Amount := Amount;
                    xRec."Amount (LCY)" := "Amount (LCY)";
                    xRec."Bank Account No." := "Bank Account No.";
                    Init();
                    "Customer No." := xRec."Customer No.";
                    Validate("Posting Date", xRec."Posting Date");
                    Amount := xRec.Amount;
                    "Amount (LCY)" := xRec."Amount (LCY)";
                    "Bank Account No." := xRec."Bank Account No.";
                end;

                CreateDim(
                  DATABASE::Customer, "Customer No.",
                  DATABASE::"Bank Account", "Bank Account No.");
            end;
        }
        field(4; "Posting Date"; Date)
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
        field(5; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';

            trigger OnValidate()
            begin
                GetCurrencyCode();
                Amount := Round(Amount, Currency."Amount Rounding Precision");

                if "Currency Code" = '' then
                    "Amount (LCY)" := Amount
                else
                    "Amount (LCY)" := Round(
                        CurrencyExchRate.ExchangeAmtFCYToLCY(
                          "Posting Date", "Currency Code",
                          Amount, "Currency Factor"));
            end;
        }
        field(6; "Pmt. Disc. Possible"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Pmt. Disc. Possible';

            trigger OnValidate()
            begin
                if "Pmt. Disc. Possible" * Amount < 0 then
                    FieldError("Pmt. Disc. Possible", StrSubstNo(Text004, FieldCaption(Amount)));

                if CurrFieldNo = FieldNo("Pmt. Disc. Possible") then begin
                    Validate(Amount, Amount + xRec."Pmt. Disc. Possible" - "Pmt. Disc. Possible");
                    "Pmt. Discount possible (LCY)" := "Pmt. Disc. Possible";
                end;
            end;
        }
        field(7; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';
        }
        field(8; "Message 1"; Text[15])
        {
            Caption = 'Message 1';
        }
        field(9; "Message 2"; Text[15])
        {
            Caption = 'Message 2';
        }
#pragma warning disable AS0086
        field(10; Reference; Text[16])
#pragma warning restore AS0086
        {
            Caption = 'Reference';
        }
        field(12; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;

            trigger OnValidate()
            begin
                GetCurrencyCode();
                if "Currency Code" <> '' then begin
                    if ("Currency Code" <> xRec."Currency Code") or
                       ("Posting Date" <> xRec."Posting Date") or
                       (CurrFieldNo = FieldNo("Currency Code")) or
                       ("Currency Factor" = 0)
                    then
                        "Currency Factor" := CurrencyExchRate.ExchangeRate("Posting Date", "Currency Code");
                end else
                    "Currency Factor" := 0;
                Validate("Currency Factor");
                "ISO Currency Code" := Currency."ISO Code";
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
                    FieldError("Currency Factor", StrSubstNo(Text002, FieldCaption("Currency Code")));
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
        field(17; "Pmt. Discount possible (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Pmt. Discount possible (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                if "Currency Code" = '' then begin
                    "Pmt. Disc. Possible" := "Pmt. Discount possible (LCY)";
                    Validate("Pmt. Disc. Possible");
                end else begin
                    TestField("Currency Factor");
                    Validate("Pmt. Disc. Possible", ("Pmt. Discount possible (LCY)" / "Currency Factor"));
                end;
            end;
        }
        field(22; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account";

            trigger OnValidate()
            begin
                if "Bank Account No." = '' then
                    Status := Status::" "
                else
                    Status := Status::Marked;

                CreateDim(
                  DATABASE::"Bank Account", "Bank Account No.",
                  DATABASE::Customer, "Customer No.");
            end;
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
            begin
                AccNo := "Customer No.";

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
                ApplyCustLedgEntries.SetTableView(CustLedgEntry);
                ApplyCustLedgEntries.SetRecord(CustLedgEntry);
                ApplyCustLedgEntries.LookupMode(true);
                if ApplyCustLedgEntries.RunModal() = ACTION::LookupOK then begin
                    ApplyCustLedgEntries.GetRecord(CustLedgEntry);
                    CustUpdatePayment();
                end;
                Clear(ApplyCustLedgEntries);
            end;

            trigger OnValidate()
            begin
                // Empty Applies-to Doc for payment without invoice
                if "Applies-to Doc. No." <> '' then begin
                    CustLedgEntry.SetCurrentKey("Document No.");
                    CustLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
                    CustLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                    CustLedgEntry.SetRange("Customer No.", "Customer No.");
                    if not CustLedgEntry.FindFirst() then
                        Error(Text003, "Applies-to Doc. Type", "Applies-to Doc. No.");
                    CustUpdatePayment();
                end;
            end;
        }
        field(51; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Domiciliation Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));
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
            InitValue = " ";
            OptionCaption = ' ,Marked,Processed,Posted';
            OptionMembers = " ",Marked,Processed,Posted;
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
        field(1200; "Direct Debit Mandate ID"; Code[35])
        {
            Caption = 'Direct Debit Mandate ID';
            TableRelation = "SEPA Direct Debit Mandate" where("Customer No." = field("Customer No."));
        }
        field(1201; "Applies-to Entry No."; Integer)
        {
            Caption = 'Applies-to Entry No.';
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "Journal Batch Name", "Line No.")
        {
            Clustered = true;
            SumIndexFields = Amount, "Amount (LCY)";
        }
        key(Key2; "Customer No.", "Applies-to Doc. Type", "Applies-to Doc. No.")
        {
            SumIndexFields = Amount, "Amount (LCY)";
        }
        key(Key3; "Bank Account No.", "Customer No.", "Posting Date")
        {
            SumIndexFields = Amount, "Amount (LCY)";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine."Journal Template Name" := "Journal Template Name";
        GenJnlLine."Journal Batch Name" := "Journal Batch Name";
        GenJnlLine."Line No." := "Line No.";
        GenJnlLine.DeletePaymentFileErrors();
    end;

    trigger OnInsert()
    begin
        LockTable();
        DomiciliationJnlTemplate.Get("Journal Template Name");
        "Source Code" := DomiciliationJnlTemplate."Source Code";
        DomiciliationJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        "Reason Code" := DomiciliationJnlBatch."Reason Code";
    end;

    trigger OnModify()
    begin
        if not Processing then
            if Status = Status::Posted then
                Error(Text000);
        Processing := (Status = Status::Processed);
    end;

    var
        Text000: Label 'Payment has been posted, changes are not allowed.';
        Text001: Label 'There is no valid %1 for the Customer.';
        Text002: Label 'cannot be specified without %1.';
        Text003: Label '%1 %2 is not a Customer Ledger Entry.', Comment = 'First parameter is a sales document type, second one - document number.';
        GLSetup: Record "General Ledger Setup";
        Cust: Record Customer;
        Currency: Record Currency;
        DomiciliationJnlTemplate: Record "Domiciliation Journal Template";
        DomiciliationJnlBatch: Record "Domiciliation Journal Batch";
        CustLedgEntry: Record "Cust. Ledger Entry";
        CurrencyExchRate: Record "Currency Exchange Rate";
        DomiciliationJnlMgt: Codeunit DomiciliationJnlManagement;
        DimMgt: Codeunit DimensionManagement;
        ApplyCustLedgEntries: Page "Apply Customer Entries";
        AccNo: Code[20];
        Text004: Label 'must have the same sign as %1.';

    local procedure InitCompanyInformation()
    begin
        GLSetup.Get();
    end;

    [Scope('OnPrem')]
    procedure CustUpdatePayment()
    begin
        CustLedgEntry.TestField("On Hold", '');
        CustLedgEntry.TestField(Open);
        CustLedgEntry.CalcFields("Remaining Amount");
        if ("Pmt. Discount Date" <> 0D) and
           ("Pmt. Discount Date" <= CustLedgEntry."Pmt. Discount Date")
        then begin
            Amount := -(CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible");
            "Pmt. Disc. Possible" := -CustLedgEntry."Remaining Pmt. Disc. Possible";
        end else begin
            Amount := -CustLedgEntry."Remaining Amount";
            "Pmt. Disc. Possible" := 0;
        end;
        Validate("Currency Code", CustLedgEntry."Currency Code");
        Validate(Amount);
        Validate("Pmt. Disc. Possible");

        "Applies-to Doc. Type" := CustLedgEntry."Document Type";
        "Applies-to Doc. No." := CustLedgEntry."Document No.";
        "Message 1" := CopyStr(CustLedgEntry."Document No.", 1, MaxStrLen("Message 1"));
        "Message 2" := CopyStr(CustLedgEntry.Description, 1, MaxStrLen("Message 2"));
        Reference := DomiciliationJnlMgt.CreateReference(CustLedgEntry);
        "Direct Debit Mandate ID" := CustLedgEntry."Direct Debit Mandate ID";
        "Applies-to Entry No." := CustLedgEntry."Entry No.";
        "Dimension Set ID" := CustLedgEntry."Dimension Set ID";
    end;

    [Scope('OnPrem')]
    procedure GetCurrencyCode()
    begin
        InitCompanyInformation();
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

    [Scope('OnPrem')]
    procedure CreateDim(Type1: Integer; No1: Code[20]; Type2: Integer; No2: Code[20])
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';

        DimMgt.AddDimSource(DefaultDimSource, Type1, No1);
        DimMgt.AddDimSource(DefaultDimSource, Type2, No2);

        "Dimension Set ID" :=
            DimMgt.GetRecDefaultDimID(
                Rec, CurrFieldNo, DefaultDimSource, "Source Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
    end;

    [Scope('OnPrem')]
    procedure ValidateShortcutDimCode(FieldNo: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateShortcutDimValues(FieldNo, ShortcutDimCode, "Dimension Set ID");
    end;

    [Scope('OnPrem')]
    procedure LookupShortcutDimCode(FieldNo: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNo, ShortcutDimCode);
        DimMgt.ValidateShortcutDimValues(FieldNo, ShortcutDimCode, "Dimension Set ID");
    end;

    [Scope('OnPrem')]
    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    [Scope('OnPrem')]
    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            "Dimension Set ID", StrSubstNo('%1 %2 %3', "Journal Template Name", "Journal Batch Name", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    [Scope('OnPrem')]
    procedure ExportToFile()
    var
        DomJnlTemp: Record "Domiciliation Journal Template";
        DomJnlBatch: Record "Domiciliation Journal Batch";
        BankAccount: Record "Bank Account";
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
    begin
        DomJnlTemp.Get("Journal Template Name");
        DomJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        BankAccount.Get(DomJnlTemp."Bank Account No.");

        DirectDebitCollection.CreateRecord("Journal Template Name", DomJnlTemp."Bank Account No.", DomJnlBatch."Partner Type");
        DirectDebitCollection."Domiciliation Batch Name" := "Journal Batch Name";
        DirectDebitCollection.Modify();
        Commit();

        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", DirectDebitCollection."No.");
        RunFileExportCodeunit(BankAccount.GetDDExportCodeunitID(), DirectDebitCollection."No.", DirectDebitCollectionEntry);
        DeleteDirectDebitCollection(DirectDebitCollection."No.");
    end;

    [Scope('OnPrem')]
    procedure RunFileExportCodeunit(CodeunitID: Integer; DirectDebitCollectionNo: Integer; var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry")
    var
        LastError: Text;
    begin
        SetRange("Journal Template Name", "Journal Template Name");
        SetRange("Journal Batch Name", "Journal Batch Name");
        if CODEUNIT.Run(CodeunitID, DirectDebitCollectionEntry) then begin
            if DirectDebitCollectionEntry."Entry No." <> CodeunitID then begin
                FindSet();
                DeleteDirectDebitCollection(DirectDebitCollectionNo);
                Commit();
                REPORT.Run(REPORT::"Create Gen. Jnl. Lines", true, true, Rec);
                ModifyAll(Status, Status::Posted);
            end;
            exit;
        end;
        Reset();
        LastError := GetLastErrorText;
        DeleteDirectDebitCollection(DirectDebitCollectionNo);
        Commit();
        Error(LastError);
    end;

    [Scope('OnPrem')]
    procedure DeleteDirectDebitCollection(DirectDebitCollectionNo: Integer)
    var
        DirectDebitCollection: Record "Direct Debit Collection";
    begin
        if DirectDebitCollection.Get(DirectDebitCollectionNo) then
            DirectDebitCollection.Delete(true);
    end;
}

