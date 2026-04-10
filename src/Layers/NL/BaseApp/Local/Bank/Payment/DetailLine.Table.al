// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Foundation.Company;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

table 11000003 "Detail Line"
{
    Caption = 'Detail Line';
    DrillDownPageID = "Detail Lines";
    LookupPageID = "Detail Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Account Type"; Option)
        {
            Caption = 'Account Type';
            Editable = false;
            OptionCaption = 'Customer,Vendor,Employee';
            OptionMembers = Customer,Vendor,Employee;
        }
        field(2; "Serial No. (Entry)"; Integer)
        {
            Caption = 'Serial No. (Entry)';
            Editable = true;
            NotBlank = true;
            TableRelation = if ("Account Type" = const(Customer)) "Cust. Ledger Entry"."Entry No."
            else
            if ("Account Type" = const(Vendor)) "Vendor Ledger Entry"."Entry No.";

            trigger OnLookup()
            begin
                SerialnoPostingLookup();
            end;

            trigger OnValidate()
            var
                TrMode: Record "Transaction Mode";
                CompanyInfo: Record "Company Information";
                Cust: Record Customer;
                Vend: Record Vendor;
                Empl: Record Employee;
                IsHandled: Boolean;
            begin
                TrMode.Get("Account Type", "Transaction Mode");
                case "Account Type" of
                    "Account Type"::Customer:
                        begin
                            GetCustomerEntries();
                            CustLedgEntry.TestField(Open, true);
                            CustLedgEntry.TestField("Customer No.", "Account No.");
                            "Currency Code (Entry)" := CustLedgEntry."Currency Code";
                            Cust.Get(CustLedgEntry."Customer No.");
                            if Cust."Our Account No." <> '' then
                                Description :=
                                  CopyStr(
                                    StrSubstNo(
                                      Text1000001,
                                      CustLedgEntry."Document Type",
                                      CustLedgEntry."Document No.",
                                      Cust."Our Account No."), 1, MaxStrLen(Description))
                            else begin
                                CompanyInfo.Get();
                                Description :=
                                  CopyStr(
                                    StrSubstNo(
                                      '%1 %2 %3',
                                      CustLedgEntry."Document Type",
                                      CustLedgEntry."Document No.",
                                      CompanyInfo.Name), 1, MaxStrLen(Description));
                            end;

                            IsHandled := false;
                            OnValidateSerialNoEntryOnBeforeValidateAmountFromCustLedgEntry(Rec, TrMode, CustLedgEntry, IsHandled);
                            if not IsHandled then
                                if TrMode."Pmt. Disc. Possible" and
                                (CustLedgEntry."Remaining Pmt. Disc. Possible" <> 0) and
                                (CustLedgEntry."Pmt. Discount Date" >= Date)
                                then
                                    Validate("Amount (Entry)", -(CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible") -
                                    CalculateTotalAmount("Currency Code (Entry)"))
                                else
                                    Validate("Amount (Entry)", -CustLedgEntry."Remaining Amount" - CalculateTotalAmount("Currency Code (Entry)"));
                        end;
                    "Account Type"::Vendor:
                        begin
                            GetVendorEntries();
                            OnValidateSerialNoEntryOnOnAfterGetVendorEntries(Rec, VendLedgEntry, CurrFieldNo);
                            VendLedgEntry.TestField(Open, true);
                            VendLedgEntry.TestField("Vendor No.", "Account No.");
                            "Currency Code (Entry)" := VendLedgEntry."Currency Code";
                            Vend.Get(VendLedgEntry."Vendor No.");
                            FillVendorDescription(CompanyInfo, Vend);

                            IsHandled := false;
                            OnValidateSerialNoEntryOnBeforeValidateAmountFromVendLedgEntry(Rec, TrMode, VendLedgEntry, CurrFieldNo, IsHandled);
                            if not IsHandled then
                                if TrMode."Pmt. Disc. Possible" and
                                (VendLedgEntry."Remaining Pmt. Disc. Possible" <> 0) and
                                (VendLedgEntry."Pmt. Discount Date" >= Date)
                                then
                                    Validate("Amount (Entry)", -(VendLedgEntry."Remaining Amount" - VendLedgEntry."Remaining Pmt. Disc. Possible") -
                                    CalculateTotalAmount("Currency Code (Entry)"))
                                else
                                    Validate("Amount (Entry)", -VendLedgEntry."Remaining Amount" - CalculateTotalAmount("Currency Code (Entry)"));
                        end;
                    "Account Type"::Employee:
                        begin
                            GetEmployeeEntries();
                            EmployeeLedgerEntry.TestField(Open, true);
                            EmployeeLedgerEntry.TestField("Employee No.", "Account No.");
                            "Currency Code (Entry)" := EmployeeLedgerEntry."Currency Code";
                            Empl.Get(EmployeeLedgerEntry."Employee No.");
                            CompanyInfo.Get();
                            Description :=
                              CopyStr(
                                StrSubstNo(
                                  '%1 %2 %3',
                                  EmployeeLedgerEntry."Document Type",
                                  EmployeeLedgerEntry."Document No.",
                                  CompanyInfo.Name), 1, MaxStrLen(Description));

                            IsHandled := false;
                            OnValidateSerialNoEntryOnBeforeValidateAmountFromEmplLedgEntry(Rec, TrMode, EmployeeLedgerEntry, IsHandled);
                            if not IsHandled then
                                Validate("Amount (Entry)", -EmployeeLedgerEntry."Remaining Amount" - CalculateTotalAmount("Currency Code (Entry)"));
                        end;
                end;
            end;
        }
        field(3; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            Editable = false;
            TableRelation = if ("Account Type" = const(Customer)) Customer."No."
            else
            if ("Account Type" = const(Vendor)) Vendor."No.";
        }
        field(4; Date; Date)
        {
            Caption = 'Date';
            Editable = false;
        }
        field(5; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Proposal,In process,Posted,Correction';
            OptionMembers = Proposal,"In process",Posted,Correction;
        }
        field(6; Bank; Code[20])
        {
            Caption = 'Bank';
            Editable = false;
            TableRelation = if ("Account Type" = const(Customer)) "Customer Bank Account".Code where("Customer No." = field("Account No."))
            else
            if ("Account Type" = const(Vendor)) "Vendor Bank Account".Code where("Vendor No." = field("Account No."));
        }
        field(7; "Our Bank"; Code[20])
        {
            Caption = 'Our Bank';
            Editable = false;
            TableRelation = "Bank Account"."No.";
        }
        field(8; "Transaction Mode"; Code[20])
        {
            Caption = 'Transaction Mode';
            Editable = false;
            TableRelation = "Transaction Mode".Code where("Account Type" = field("Account Type"));
        }
        field(9; "Order"; Option)
        {
            Caption = 'Order';
            Editable = false;
            OptionCaption = 'Both,Debit,Credit';
            OptionMembers = Both,Debit,Credit;
        }
        field(10; Amount; Decimal)
        {
            AutoFormatExpression = "Currency Code (Entry)";
            AutoFormatType = 1;
            Caption = 'Amount';

            trigger OnValidate()
            begin
                if not AmountValidate then begin
                    AmountValidate := true;
                    Validate("Amount (Entry)", CurrencyExchangeRate.ExchangeAmtFCYToFCY(Date, "Currency Code", "Currency Code (Entry)", Amount));
                    AmountValidate := false;
                end;

                GetCurrency();
                Amount := Round(Amount, BankCur."Amount Rounding Precision");
            end;
        }
        field(11; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            Editable = false;
        }
        field(12; "Connect Lines"; Integer)
        {
            Caption = 'Connect Lines';
            Editable = false;
            TableRelation = if (Status = const(Proposal)) "Proposal Line"."Line No." where("Our Bank No." = field("Our Bank"))
            else
            if (Status = const("In process")) "Payment History Line"."Line No." where("Our Bank" = field("Our Bank"),
                                                                                                          "Run No." = field("Connect Batches"));
        }
        field(13; "Connect Batches"; Code[20])
        {
            Caption = 'Connect Batches';
            Editable = false;
            TableRelation = if (Status = const("In process")) "Payment History"."Run No.";
        }
        field(14; Description; Text[32])
        {
            Caption = 'Description';
            Editable = true;
        }
        field(15; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency.Code;
        }
        field(16; "Amount (Entry)"; Decimal)
        {
            AutoFormatExpression = "Currency Code (Entry)";
            AutoFormatType = 1;
            Caption = 'Amount (Entry)';

            trigger OnValidate()
            var
                Difference: Decimal;
                "Remaining Amount": Decimal;
                ShowExceedMessage: Boolean;
            begin
                case "Account Type" of
                    "Account Type"::Customer:
                        begin
                            if GetCustomerEntries() then
                                "Remaining Amount" := -CustLedgEntry."Remaining Amount"
                            else
                                "Remaining Amount" := 0;

                            if IsDifferentSign("Remaining Amount", "Amount (Entry)") then
                                Error(AmountSignErr, CustLedgEntry.TableCaption(), CustLedgEntry.FieldCaption("Entry No."), CustLedgEntry."Entry No.");
                        end;
                    "Account Type"::Vendor:
                        begin
                            if GetVendorEntries() then
                                "Remaining Amount" := -VendLedgEntry."Remaining Amount"
                            else
                                "Remaining Amount" := 0;

                            if IsDifferentSign("Remaining Amount", "Amount (Entry)") then
                                Error(AmountSignErr, VendLedgEntry.TableCaption(), VendLedgEntry.FieldCaption("Entry No."), VendLedgEntry."Entry No.");
                        end;
                    "Account Type"::Employee:
                        begin
                            if GetEmployeeEntries() then
                                "Remaining Amount" := -EmployeeLedgerEntry."Remaining Amount"
                            else
                                "Remaining Amount" := 0;

                            if IsDifferentSign("Remaining Amount", "Amount (Entry)") then
                                Error(AmountSignErr, EmployeeLedgerEntry.TableCaption(), EmployeeLedgerEntry.FieldCaption("Entry No."), EmployeeLedgerEntry."Entry No.");
                        end;
                end;

                Difference := "Remaining Amount" - (CalculateTotalAmount("Currency Code (Entry)") + "Amount (Entry)");
                ShowExceedMessage := (Abs(Difference) > Abs(CalculateVariation())) and IsDifferentSign("Remaining Amount", Difference);
                OnValidateAmountEntryOnAfterCalcShowExceedMessage(Rec, Difference, "Remaining Amount", ShowExceedMessage);
                if ShowExceedMessage then
                    Message(Text1000004, DelChr(Format(Abs(Difference)) + ' ' + "Currency Code (Entry)", '<>', ' '));

                if not AmountValidate then begin
                    AmountValidate := true;
                    Validate(Amount, CurrencyExchangeRate.ExchangeAmtFCYToFCY(Date, "Currency Code (Entry)", "Currency Code", "Amount (Entry)"));
                    AmountValidate := false;
                end;

                GetCurrency();
                "Amount (Entry)" := Round("Amount (Entry)", EntryCurrency."Amount Rounding Precision");
            end;
        }
        field(17; "Currency Code (Entry)"; Code[10])
        {
            Caption = 'Currency Code (Entry)';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Transaction No.")
        {
            Clustered = true;
        }
        key(Key2; "Account Type", "Serial No. (Entry)", Status, Date, "Connect Batches", "Connect Lines", "Our Bank")
        {
            SumIndexFields = Amount, "Amount (Entry)";
        }
        key(Key3; "Account Type", "Account No.", Bank, "Transaction Mode", "Currency Code", Date)
        {
        }
        key(Key4; "Our Bank", Status, "Connect Batches", "Connect Lines", Date)
        {
            SumIndexFields = Amount, "Amount (Entry)";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        Date := 0D;
        Amount := 0;
        if Count > 1 then
            UpdateConnection();
    end;

    trigger OnInsert()
    var
        "Detail line": Record "Detail Line";
    begin
        if "Detail line".FindLast() then
            "Transaction No." := "Detail line"."Transaction No." + 1
        else
            "Transaction No." := 1;

        UpdateConnection();
    end;

    trigger OnModify()
    begin
        UpdateConnection();
    end;

    trigger OnRename()
    begin
        Error(Text1000000, TableCaption);
    end;

    var
        Text1000000: Label '%1 cannot be renamed';
        Text1000001: Label '%1 %2 vendor no. %3';
        Text1000002: Label '%1 %2 customer no. %3';
        Text1000004: Label 'The outstanding amount is exceeded by %1.';
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        AmountValidate: Boolean;
        EntryCurrency: Record Currency;
        BankCur: Record Currency;
        AmountSignErr: Label 'The sign does not correspond with the outstanding %1 %2 %3.', Comment = '%1 - table caption, %2 - field caption, %3 - field value';

    protected var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";

    procedure CalculateBalance(UseCurrency: Code[10]) Balance: Decimal
    begin
        // always in currency of the entry (Entry currency)
        if "Serial No. (Entry)" <> 0 then
            case "Account Type" of
                "Account Type"::Customer:
                    begin
                        GetCustomerEntries();
                        Balance := -CustLedgEntry."Remaining Amount";
                    end;
                "Account Type"::Vendor:
                    begin
                        GetVendorEntries();
                        VendLedgEntry.CalcFields("Remaining Amount");
                        Balance := -VendLedgEntry."Remaining Amount";
                    end;
                "Account Type"::Employee:
                    begin
                        GetEmployeeEntries();
                        EmployeeLedgerEntry.CalcFields("Remaining Amount");
                        Balance := -EmployeeLedgerEntry."Remaining Amount";
                    end;
            end;

        OnCalculateBalanceOnBeforeConvertToCurrency(Rec, VendLedgEntry, CustLedgEntry, Balance);
        if UseCurrency <> "Currency Code (Entry)" then
            Balance := CurrencyExchangeRate.ExchangeAmtFCYToFCY(Date, "Currency Code (Entry)", UseCurrency, Balance);

        OnAfterCalculateBalance(Rec, Balance);
    end;

    procedure CalculateTotalAmount(UseCurrency: Code[10]) Total: Decimal
    var
        DetailLine: Record "Detail Line";
    begin
        SetKeyForCalculateTotalAmount(DetailLine);
        DetailLine.SetRange("Account Type", "Account Type");
        DetailLine.SetRange("Serial No. (Entry)", "Serial No. (Entry)");
        DetailLine.SetFilter(Status, '%1|%2', Status::Proposal, Status::"In process");
        DetailLine.SetFilter("Transaction No.", '<>%1', "Transaction No.");
        OnCalculateTotalAmountOnBeforeCalcSums(Rec, DetailLine, VendLedgEntry, CustLedgEntry);
        DetailLine.CalcSums("Amount (Entry)");
        if UseCurrency <> "Currency Code (Entry)" then
            Total := CurrencyExchangeRate.ExchangeAmtFCYToFCY(Date, "Currency Code (Entry)", UseCurrency, "Amount (Entry)")
        else
            Total := DetailLine."Amount (Entry)";
    end;

    local procedure FillVendorDescription(var CompanyInformation: Record "Company Information"; var Vendor: Record Vendor)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFillVendorDescription(Rec, Vendor, VendLedgEntry, IsHandled);
        if IsHandled then
            exit;

        if Vendor."Our Account No." <> '' then
            Description :=
              CopyStr(
                StrSubstNo(
                  Text1000002,
                  VendLedgEntry."Document Type",
                  VendLedgEntry."External Document No.",
                  Vendor."Our Account No."), 1, MaxStrLen(Description))
        else begin
            CompanyInformation.Get();
            Description :=
              CopyStr(
                StrSubstNo(
                  '%1 %2 %3',
                  VendLedgEntry."Document Type",
                  VendLedgEntry."External Document No.",
                  CompanyInformation.Name), 1, MaxStrLen(Description));
        end;
    end;

    local procedure SetKeyForCalculateTotalAmount(var DetailLine: Record "Detail Line")
    begin
        DetailLine.SetCurrentKey("Account Type", "Serial No. (Entry)");
        OnAfterSetKeyForCalculateTotalAmount(DetailLine);
    end;

    procedure CalculatePartOfBalance() Percent: Decimal
    var
        Totamount: Decimal;
    begin
        Totamount := CalculateBalance("Currency Code (Entry)");
        if Abs("Amount (Entry)" - Totamount) < CalculateVariation() then
            Percent := 1
        else
            if Totamount <> 0 then
                Percent := "Amount (Entry)" / Totamount
            else
                Percent := 0;

        OnAfterCalculatePartOfBalance(Rec, Percent);
    end;

    procedure GetCustomerEntries() OK: Boolean
    begin
        if "Serial No. (Entry)" <> CustLedgEntry."Entry No." then begin
            OK := CustLedgEntry.Get("Serial No. (Entry)");
            CustLedgEntry.CalcFields("Remaining Amount");
        end else
            OK := true;
    end;

    procedure GetVendorEntries() OK: Boolean
    begin
        if "Serial No. (Entry)" <> VendLedgEntry."Entry No." then begin
            OK := VendLedgEntry.Get("Serial No. (Entry)");
            VendLedgEntry.CalcFields("Remaining Amount");
        end else
            OK := true;
    end;

    procedure GetEmployeeEntries() OK: Boolean
    begin
        if "Serial No. (Entry)" <> EmployeeLedgerEntry."Entry No." then begin
            OK := EmployeeLedgerEntry.Get("Serial No. (Entry)");
            EmployeeLedgerEntry.CalcFields("Remaining Amount");
        end else
            OK := true;
    end;

    procedure UpdateConnection()
    var
        Prop: Record "Proposal Line";
        "Detail line": Record "Detail Line";
    begin
        case Status of
            Status::Proposal:
                if "Connect Lines" <> 0 then begin
                    "Detail line".SetCurrentKey("Our Bank", Status, "Connect Batches", "Connect Lines", Date);
                    "Detail line".SetRange("Our Bank", "Our Bank");
                    "Detail line".SetRange(Status, Status);
                    "Detail line".SetRange("Connect Batches", '');
                    "Detail line".SetRange("Connect Lines", "Connect Lines");
                    "Detail line".SetFilter("Transaction No.", '<>%1', "Transaction No.");
                    "Detail line".CalcSums(Amount);

                    Prop.Get("Our Bank", "Connect Lines");
                    Prop.Validate(Amount, "Detail line".Amount + Amount);
                    if Prop."Foreign Currency" <> '' then
                        Prop.Validate("Foreign Amount", GetAmountInDocumentCurrency(Prop));
                    if "Detail line".FindFirst() then begin
                        if (Date < "Detail line".Date) and (Date <> 0D) then
                            Prop."Transaction Date" := Date
                        else
                            Prop."Transaction Date" := "Detail line".Date;
                    end else
                        Prop."Transaction Date" := Date;
                    Prop.Modify();
                end;
        end;
    end;

    procedure InitRecord()
    var
        TrMode: Record "Transaction Mode";
        BankAcc: Record "Bank Account";
    begin
        TestField("Account No.");
        TestField(Date);
        TestField("Transaction Mode");

        TrMode.Get("Account Type", "Transaction Mode");
        Order := TrMode.Order;
        if "Our Bank" = '' then
            "Our Bank" := TrMode."Our Bank";

        BankAcc.Get("Our Bank");
        "Currency Code" := BankAcc."Currency Code";
    end;

    local procedure GetCurrency()
    begin
        if "Currency Code" = '' then
            BankCur.InitRoundingPrecision()
        else
            if "Currency Code" <> BankCur.Code then begin
                BankCur.Get("Currency Code");
                BankCur.TestField("Amount Rounding Precision");
            end;

        if "Currency Code (Entry)" = '' then
            EntryCurrency.InitRoundingPrecision()
        else
            if "Currency Code (Entry)" <> EntryCurrency.Code then begin
                EntryCurrency.Get("Currency Code (Entry)");
                EntryCurrency.TestField("Amount Rounding Precision");
            end;
    end;

    procedure CalculateVariation() Variation: Decimal
    begin
        GetCurrency();
        if BankCur."Appln. Rounding Precision" <> 0 then
            Variation := CurrencyExchangeRate.ExchangeAmtFCYToFCY(Date,
                "Currency Code",
                "Currency Code (Entry)",
                BankCur."Appln. Rounding Precision");
    end;

    local procedure SerialnoPostingLookup()
    var
        CustEntry: Page "Customer Ledger Entries";
        VenEntry: Page "Vendor Ledger Entries";
        EmployeeLedgerEntries2: Page "Employee Ledger Entries";
    begin
        OnBeforeSerialnoPostingLookup(Rec);
        case "Account Type" of
            "Account Type"::Customer:
                begin
                    if "Serial No. (Entry)" <> 0 then
                        GetCustomerEntries();
                    CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive);
                    CustLedgEntry.SetRange("Customer No.", "Account No.");
                    if Status = Status::Proposal then
                        CustLedgEntry.SetRange(Open, true);
                    CustEntry.SetRecord(CustLedgEntry);
                    CustEntry.SetTableView(CustLedgEntry);
                    CustEntry.LookupMode(true);
                    if CustEntry.RunModal() = ACTION::LookupOK then begin
                        CustEntry.GetRecord(CustLedgEntry);
                        OnSerialnoPostingLookupOnAfterCustEntryGetRecord(Rec, CustLedgEntry);
                        Validate("Serial No. (Entry)", CustLedgEntry."Entry No.");
                    end;
                    CustLedgEntry.Reset();
                end;
            "Account Type"::Vendor:
                begin
                    if "Serial No. (Entry)" <> 0 then
                        GetVendorEntries();
                    VendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive);
                    VendLedgEntry.SetRange("Vendor No.", "Account No.");
                    if Status = Status::Proposal then
                        VendLedgEntry.SetRange(Open, true);
                    VenEntry.SetRecord(VendLedgEntry);
                    VenEntry.SetTableView(VendLedgEntry);
                    VenEntry.LookupMode(true);
                    OnSerialnoPostingLookupOnBeforeVenEntryRunModal(VendLedgEntry);
                    if VenEntry.RunModal() = ACTION::LookupOK then begin
                        VenEntry.GetRecord(VendLedgEntry);
                        OnSerialnoPostingLookupOnAfterGetVendLedgEntry(Rec, VendLedgEntry);
                        Validate("Serial No. (Entry)", VendLedgEntry."Entry No.");
                    end;
                    VendLedgEntry.Reset();
                end;
            "Account Type"::Employee:
                begin
                    if "Serial No. (Entry)" <> 0 then
                        GetEmployeeEntries();
                    EmployeeLedgerEntry.SetCurrentKey("Employee No.", Open, Positive);
                    EmployeeLedgerEntry.SetRange("Employee No.", "Account No.");
                    if Status = Status::Proposal then
                        EmployeeLedgerEntry.SetRange(Open, true);
                    EmployeeLedgerEntries2.SetRecord(EmployeeLedgerEntry);
                    EmployeeLedgerEntries2.SetTableView(EmployeeLedgerEntry);
                    EmployeeLedgerEntries2.LookupMode(true);
                    if EmployeeLedgerEntries2.RunModal() = ACTION::LookupOK then begin
                        EmployeeLedgerEntries2.GetRecord(EmployeeLedgerEntry);
                        Validate("Serial No. (Entry)", EmployeeLedgerEntry."Entry No.");
                    end;
                    EmployeeLedgerEntry.Reset();
                end;
        end;
    end;

    procedure IsDifferentSign(FirstAmount: Decimal; SecondAmount: Decimal): Boolean
    begin
        exit(((FirstAmount < 0) and (SecondAmount > 0)) or ((FirstAmount > 0) and (SecondAmount < 0)));
    end;

    local procedure GetCurrencyAmountRoundingPrecision(FCYCode: Code[10]): Decimal
    var
        Currency: Record Currency;
    begin
        Currency.Initialize(FCYCode);
        exit(Currency."Amount Rounding Precision");
    end;

    local procedure GetAmountInDocumentCurrency(ProposalLine: Record "Proposal Line"): Decimal
    begin
        if ProposalLine."Foreign Currency" = ProposalLine."Currency Code" then
            exit(ProposalLine.Amount);

        exit(Round(
            CurrencyExchangeRate.ExchangeAmtFCYToFCY(
                ProposalLine."Transaction Date", ProposalLine."Currency Code", ProposalLine."Foreign Currency", ProposalLine.Amount),
                GetCurrencyAmountRoundingPrecision(ProposalLine."Foreign Currency")))
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculatePartOfBalance(DetailLineRec: Record "Detail Line"; var Percent: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateBalance(DetailLine: Record "Detail Line"; var Balance: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetKeyForCalculateTotalAmount(var DetailLine: Record "Detail Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFillVendorDescription(var DetailLine: Record "Detail Line"; Vendor: Record Vendor; VendorLedgerEntry: Record "Vendor Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSerialnoPostingLookup(var DetailLine: Record "Detail Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateBalanceOnBeforeConvertToCurrency(var DetailLineRec: Record "Detail Line"; var VendLedgEntry: Record "Vendor Ledger Entry"; var CustLedgEntry: Record "Cust. Ledger Entry"; var Balance: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateTotalAmountOnBeforeCalcSums(var DetailLineRec: Record "Detail Line"; var DetailLine: Record "Detail Line"; var VendLedgEntry: Record "Vendor Ledger Entry"; var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSerialnoPostingLookupOnAfterGetVendLedgEntry(var DetailLineRec: Record "Detail Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSerialnoPostingLookupOnAfterCustEntryGetRecord(var DetailLine: Record "Detail Line"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSerialnoPostingLookupOnBeforeVenEntryRunModal(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateAmountEntryOnAfterCalcShowExceedMessage(var DetailLine: Record "Detail Line"; Difference: Decimal; RemainingAmount: Decimal; var ShowExceedMessage: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSerialNoEntryOnOnAfterGetVendorEntries(var DetailLine: Record "Detail Line"; VendorLedgerEntry: Record "Vendor Ledger Entry"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSerialNoEntryOnBeforeValidateAmountFromCustLedgEntry(var DetailLineRec: Record "Detail Line"; TrMode: Record "Transaction Mode"; CustLedgEntry: Record "Cust. Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSerialNoEntryOnBeforeValidateAmountFromVendLedgEntry(var DetailLineRec: Record "Detail Line"; TrMode: Record "Transaction Mode"; VendLedgEntry: Record "Vendor Ledger Entry"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSerialNoEntryOnBeforeValidateAmountFromEmplLedgEntry(var DetailLineRec: Record "Detail Line"; TrMode: Record "Transaction Mode"; EmplLedgEntry: Record "Employee Ledger Entry"; var IsHandled: Boolean)
    begin
    end;
}

