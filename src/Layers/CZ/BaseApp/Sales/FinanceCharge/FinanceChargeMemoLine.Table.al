// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Clause;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reminder;
using Microsoft.Utilities;
using System.Text;

table 303 "Finance Charge Memo Line"
{
    Caption = 'Finance Charge Memo Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Finance Charge Memo No."; Code[20])
        {
            Caption = 'Finance Charge Memo No.';
            TableRelation = "Finance Charge Memo Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            NotBlank = true;
        }
        field(3; "Attached to Line No."; Integer)
        {
            Caption = 'Attached to Line No.';
            Editable = false;
            TableRelation = "Finance Charge Memo Line"."Line No." where("Finance Charge Memo No." = field("Finance Charge Memo No."));
        }
        field(4; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,G/L Account,Customer Ledger Entry';
            OptionMembers = " ","G/L Account","Customer Ledger Entry";

            trigger OnValidate()
            begin
                if Type <> xRec.Type then begin
                    FinChrgMemoLine := Rec;
                    Init();
                    Type := FinChrgMemoLine.Type;
                    GetFinChrgMemoHeader();
                end;
            end;
        }
        field(5; "Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Entry No.';
            TableRelation = "Cust. Ledger Entry";

            trigger OnLookup()
            begin
                if Type <> Type::"Customer Ledger Entry" then
                    exit;
                SetCustLedgEntryView();
                if CustLedgEntry.Get("Entry No.") then;
                LookupCustLedgEntry();
            end;

            trigger OnValidate()
            begin
                TestField(Type, Type::"Customer Ledger Entry");
                TestField("Attached to Line No.", 0);
                GetFinChrgMemoHeader();
                CustLedgEntry.Get("Entry No.");
                case FinChrgTerms."Interest Calculation" of
                    FinChrgTerms."Interest Calculation"::"Open Entries":
                        CustLedgEntry.TestField(Open, true);
                    FinChrgTerms."Interest Calculation"::"Closed Entries":
                        CustLedgEntry.TestField(Open, false);
                end;
                CustLedgEntry.TestField("Customer No.", FinChrgMemoHeader."Customer No.");
                EnsureNotOnHold(CustLedgEntry);
                if CustLedgEntry."Currency Code" <> FinChrgMemoHeader."Currency Code" then
                    Error(
                      Text000,
                      FinChrgMemoHeader.FieldCaption("Currency Code"),
                      FinChrgMemoHeader.TableCaption(), CustLedgEntry.TableCaption());
                "Posting Date" := CustLedgEntry."Posting Date";
                "Document Date" := CustLedgEntry."Document Date";
                "Due Date" := CustLedgEntry."Due Date";
                "Document Type" := CustLedgEntry."Document Type";
                "Document No." := CustLedgEntry."Document No.";
                Description := CustLedgEntry.Description;
                CustLedgEntry.SetFilter("Date Filter", '..%1', FinChrgMemoHeader."Document Date");
                CustLedgEntry.CalcFields(Amount, "Remaining Amount");
                "Original Amount" := CustLedgEntry.Amount;
                "Remaining Amount" := CustLedgEntry."Remaining Amount";
                CalcFinChrg();
            end;
        }
        field(7; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
        }
        field(8; "Document Date"; Date)
        {
            Caption = 'Document Date';
            Editable = false;
        }
        field(9; "Due Date"; Date)
        {
            Caption = 'Due Date';
            Editable = false;
        }
        field(10; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';

            trigger OnValidate()
            begin
                TestField(Type, Type::"Customer Ledger Entry");
                Validate("Document No.");
            end;
        }
        field(11; "Document No."; Code[20])
        {
            Caption = 'Document No.';

            trigger OnLookup()
            begin
                LookupDocNo();
            end;

            trigger OnValidate()
            begin
                TestField(Type, Type::"Customer Ledger Entry");
                "Entry No." := 0;
                if "Document No." <> '' then begin
                    SetCustLedgEntryView();
                    if "Document Type" <> "Document Type"::" " then
                        CustLedgEntry.SetRange("Document Type", "Document Type");
                    CustLedgEntry.SetRange("Document No.", "Document No.");
                    if CustLedgEntry.FindFirst() then
                        Validate("Entry No.", CustLedgEntry."Entry No.")
                    else
                        Error(Text004, Format(Type), FieldCaption("Document No."), "Document No.");
                end;
            end;
        }
        field(12; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(13; "Original Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Original Amount';
            Editable = false;
        }
        field(14; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Remaining Amount';
            Editable = false;
        }
        field(15; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const(" ")) "Standard Text"
            else
            if (Type = const("G/L Account")) "G/L Account";

            trigger OnValidate()
            begin
                if "No." <> '' then
                    case Type of
                        Type::" ":
                            begin
                                StdTxt.Get("No.");
                                Description := StdTxt.Description;
                            end;
                        Type::"Customer Ledger Entry":
                            begin
                                FinChrgMemoLine.Type := FinChrgMemoLine.Type::" ";
                                FinChrgMemoLine2.Type := FinChrgMemoLine2.Type::"G/L Account";
                                Error(
                                  Text001,
                                  FieldCaption(Type), FinChrgMemoLine.Type, FinChrgMemoLine2.Type);
                            end;
                        Type::"G/L Account":
                            begin
                                GLAcc.Get("No.");
                                GLAcc.CheckGLAcc();
                                if not "System-Created Entry" then
                                    GLAcc.TestField("Direct Posting", true);
                                GLAcc.TestField("Gen. Prod. Posting Group");
                                Description := GLAcc.Name;
                                GetFinChrgMemoHeader();
                                "Tax Group Code" := GLAcc."Tax Group Code";
                                Validate("Gen. Prod. Posting Group", GLAcc."Gen. Prod. Posting Group");
                                Validate("VAT Prod. Posting Group", GLAcc."VAT Prod. Posting Group");
                                OnValidateNoOnAfterAssignGLAccountValues(Rec, FinChrgMemoHeader, GLAcc);
                            end;
                    end;
            end;
        }
        field(16; Amount; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Amount';

            trigger OnValidate()
            begin
                if Type = Type::" " then begin
                    FinChrgMemoLine.Type := Type::"G/L Account";
                    FinChrgMemoLine2.Type := Type::"Customer Ledger Entry";
                    Error(
                      Text001,
                      FieldCaption(Type), FinChrgMemoLine.Type, FinChrgMemoLine2.Type);
                end;
                if Type = Type::"Customer Ledger Entry" then
                    TestField("Attached to Line No.", 0);
                GetFinChrgMemoHeader();
                Amount := Round(Amount, Currency."Amount Rounding Precision");
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                    "VAT Calculation Type"::"Reverse Charge VAT",
                    "VAT Calculation Type"::"Full VAT":
                        "VAT Amount" :=
                          Round(Amount * "VAT %" / 100, Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
                    "VAT Calculation Type"::"Sales Tax":
                        begin
                            "VAT Amount" :=
                              SalesTaxCalculate.CalculateTax(
                                FinChrgMemoHeader."Tax Area Code", "Tax Group Code", FinChrgMemoHeader."Tax Liable",
                                FinChrgMemoHeader."Posting Date", Amount, 0, 0);
                            if Amount - "VAT Amount" <> 0 then
                                "VAT %" := Round(100 * "VAT Amount" / Amount, 0.00001)
                            else
                                "VAT %" := 0;
                            "VAT Amount" := Round("VAT Amount", Currency."Amount Rounding Precision");
                        end;
                end;
            end;
        }
        field(17; "Interest Rate"; Decimal)
        {
            Caption = 'Interest Rate';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestField(Type, Type::"Customer Ledger Entry");
                TestField("Entry No.");
                CalcFinChrg();
            end;
        }
        field(18; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            begin
                if xRec."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group" then
                    if GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp, "Gen. Prod. Posting Group") then
                        Validate("VAT Prod. Posting Group", GenProdPostingGrp."Def. VAT Prod. Posting Group");
            end;
        }
        field(19; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(20; "VAT Calculation Type"; enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            Editable = false;
        }
        field(21; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'VAT Amount';
            Editable = false;
        }
        field(22; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";

            trigger OnValidate()
            begin
                Validate("VAT Prod. Posting Group");
            end;
        }
        field(23; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                GetFinChrgMemoHeader();

                IsHandled := false;
                OnValidateVATProdPostingGroupOnBeforeVATPostingSetupGet(Rec, xRec, IsHandled);
                if not IsHandled then
                    VATPostingSetup.Get(FinChrgMemoHeader."VAT Bus. Posting Group", "VAT Prod. Posting Group");
                OnValidateVATProdPostingGroupOnAfterVATPostingSetupGet(VATPostingSetup, Rec);
                "VAT %" := VATPostingSetup."VAT %";
                "VAT Calculation Type" := VATPostingSetup."VAT Calculation Type";
                "VAT Identifier" := VATPostingSetup."VAT Identifier";
                "VAT Clause Code" := VATPostingSetup."VAT Clause Code";
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Reverse Charge VAT":
                        "VAT %" := 0;
                    "VAT Calculation Type"::"Full VAT":
                        begin
                            TestField(Type, Type::"G/L Account");
                            TestField("No.", VATPostingSetup.GetSalesAccount(false));
                        end;
                    "VAT Calculation Type"::"Sales Tax":
                        begin
                            "VAT Amount" :=
                              SalesTaxCalculate.CalculateTax(
                                FinChrgMemoHeader."Tax Area Code", "Tax Group Code", FinChrgMemoHeader."Tax Liable",
                                FinChrgMemoHeader."Posting Date", Amount, 0, 0);
                            if Amount - "VAT Amount" <> 0 then
                                "VAT %" := Round(100 * "VAT Amount" / Amount, 0.00001)
                            else
                                "VAT %" := 0;
                            "VAT Amount" := Round("VAT Amount", Currency."Amount Rounding Precision");
                        end;
                end;
                Validate(Amount);
            end;
        }
        field(24; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
            Editable = false;
        }
        field(25; "Line Type"; Option)
        {
            Caption = 'Line Type';
            OptionCaption = 'Finance Charge Memo Line,Beginning Text,Ending Text,Rounding';
            OptionMembers = "Finance Charge Memo Line","Beginning Text","Ending Text",Rounding;
        }
        field(26; "VAT Clause Code"; Code[20])
        {
            Caption = 'VAT Clause Code';
            TableRelation = "VAT Clause";
        }
        field(30; "Detailed Interest Rates Entry"; Boolean)
        {
            Caption = 'Detailed Interest Rates Entry';
        }
        field(101; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Finance Charge Memo No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Finance Charge Memo No.", Type, "Detailed Interest Rates Entry")
        {
            MaintainSIFTIndex = false;
            MaintainSQLIndex = false;
            SumIndexFields = Amount, "VAT Amount", "Remaining Amount";
        }
        key(Key3; "Finance Charge Memo No.", "Detailed Interest Rates Entry")
        {
            SumIndexFields = Amount, "VAT Amount", "Remaining Amount";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        FinChrgMemoLine.SetRange("Finance Charge Memo No.", "Finance Charge Memo No.");
        FinChrgMemoLine.SetRange("Attached to Line No.", "Line No.");
        FinChrgMemoLine.DeleteAll();
    end;

    trigger OnInsert()
    var
        FinChrgMemoHeader: Record "Finance Charge Memo Header";
    begin
        FinChrgMemoHeader.Get("Finance Charge Memo No.");
        if Type = Type::"Customer Ledger Entry" then
            TestField("Attached to Line No.", 0);
        "Attached to Line No." := 0;
    end;

    trigger OnModify()
    begin
        TestField("System-Created Entry", false);
    end;

    var
        CustLedgEntry2: Record "Cust. Ledger Entry";
        FinChrgTerms: Record "Finance Charge Terms";
        FinChrgMemoHeader: Record "Finance Charge Memo Header";
        FinChrgMemoLine: Record "Finance Charge Memo Line";
        FinChrgMemoLine2: Record "Finance Charge Memo Line";
        ReminderEntry: Record "Reminder/Fin. Charge Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        Currency: Record Currency;
        VATPostingSetup: Record "VAT Posting Setup";
        CustPostingGr: Record "Customer Posting Group";
        GLAcc: Record "G/L Account";
        StdTxt: Record "Standard Text";
        GenProdPostingGrp: Record "Gen. Product Posting Group";
        AutoFormat: Codeunit "Auto Format";
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        InterestCalcDate: Date;
        DocTypeText: Text[30];
        CalcInterest: Boolean;
        ClosedatDate: Date;
        Checking: Boolean;
        NrOfDays: Integer;
        NrOfLinesToInsert: Integer;
        NrOfLines: Integer;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'The %1 on the %2 and the %3 must be the same.';
        Text001: Label '%1 must be %2 or %3.';
#pragma warning restore AA0470
        Text002: Label 'Document';
#pragma warning disable AA0470
        Text004: Label 'There is no open %1 with %2 %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        NotEnoughSpaceToInsertErr: Label 'There is not enough space to insert lines with additional interest rates.';
        InvalidInterestRateDateErr: Label 'Create interest rate with start date prior to %1.', Comment = '%1 - date';

    local procedure CalcFinChrg()
    var
        FinanceChargeInterestRate: Record "Finance Charge Interest Rate";
        ExtraFinChrgMemoLine: Record "Finance Charge Memo Line";
        BaseAmount: Decimal;
        UseDueDate: Date;
        UseCalcDate: Date;
        UseInterestRate: Decimal;
        CumAmount: Decimal;
        InsertedLines: Boolean;
        IsHandled: Boolean;
        SkipBecauseEntryOnHold: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcFinChrgProcedure(Rec, FinChrgMemoHeader, IsHandled);
        if IsHandled then
            exit;

        GetFinChrgMemoHeader();
        Amount := 0;
        "VAT Amount" := 0;
        "VAT Calculation Type" := "VAT Calculation Type"::"Normal VAT";
        "Gen. Prod. Posting Group" := '';
        "VAT Prod. Posting Group" := '';
        "Interest Rate" := 0;
        FinChrgMemoLine := Rec;
        FinChrgMemoLine.SetRange("Finance Charge Memo No.", "Finance Charge Memo No.");
        FinChrgMemoLine.SetRange("Detailed Interest Rates Entry", true);
        FinChrgMemoLine.SetRange("Entry No.", "Entry No.");
        FinChrgMemoLine.DeleteAll();
        CustLedgEntry.Get("Entry No.");
        SkipBecauseEntryOnHold := CustLedgEntry."On Hold" <> '';
        OnCalcFinChrgOnAfterCalcSkipBecauseEntryOnHold(CustLedgEntry, FinChrgMemoHeader, SkipBecauseEntryOnHold);
        if SkipBecauseEntryOnHold then
            exit;

        CalcFinanceChargeInterestRate(FinanceChargeInterestRate, UseDueDate, UseInterestRate, UseCalcDate);

        IsHandled := false;
        OnCalcFinChargeOnAfterCalcFinanceChargeInterestRate(Rec, FinChrgMemoHeader, IsHandled);
        if IsHandled then
            exit;

        case FinChrgTerms."Interest Calculation Method" of
            FinChrgTerms."Interest Calculation Method"::"Average Daily Balance":
                begin
                    if NrOfLinesToInsert = 0 then
                        FinChrgTerms.TestField("Interest Period (Days)")
                    else
                        FinanceChargeInterestRate.TestField("Interest Period (Days)");
                    ReminderEntry.SetCurrentKey("Customer Entry No.");
                    ReminderEntry.SetRange("Customer Entry No.", "Entry No.");
                    ReminderEntry.SetRange(Type, ReminderEntry.Type::"Finance Charge Memo");
                    ReminderEntry.SetRange(Canceled, false);
                    InterestCalcDate := CustLedgEntry."Due Date";
                    if ReminderEntry.FindLast() then
                        InterestCalcDate := ReminderEntry."Document Date";
                    ReminderEntry.SetRange(Type, ReminderEntry.Type::Reminder);
                    ReminderEntry.SetRange("Interest Posted", true);
                    if ReminderEntry.FindLast() then
                        if ReminderEntry."Document Date" > InterestCalcDate then
                            InterestCalcDate := ReminderEntry."Document Date";
                    CalcInterest := false;
                    if CalcDate(FinChrgTerms."Grace Period", "Due Date") < FinChrgMemoHeader."Document Date" then
                        if NrOfLines = 0 then
                            CumulateDetailedEntries(Amount, UseDueDate, UseCalcDate,
                              UseInterestRate, FinChrgTerms."Interest Period (Days)", BaseAmount)
                        else
                            CumulateDetailedEntries(Amount, UseDueDate, UseCalcDate,
                              UseInterestRate, FinanceChargeInterestRate."Interest Period (Days)", BaseAmount);
                    NrOfDays := UseCalcDate - UseDueDate;

                    OnCalcFinChrgOnBeforeCheckNrOfLinesToInsert(FinChrgMemoLine, NrOfDays);
                    if (NrOfLinesToInsert > 0) and
                       (FinChrgTerms."Interest Calculation Method" = FinChrgTerms."Interest Calculation Method"::"Average Daily Balance")
                    then
                        InsertedLines :=
                          CreateMulitplyInterestRateEntries(
                            ExtraFinChrgMemoLine, FinanceChargeInterestRate, UseDueDate, UseCalcDate, UseInterestRate, BaseAmount, CumAmount);
                end;
            FinChrgTerms."Interest Calculation Method"::"Balance Due":
                if CalcDate(FinChrgTerms."Grace Period", "Due Date") < FinChrgMemoHeader."Document Date" then begin
                    Amount := "Remaining Amount" * "Interest Rate" / 100;
                    BaseAmount := "Remaining Amount";
                end;
        end;

        OnCalcFinChrgOnAfterFinChrgTermsInterestCalculationMethodCase(FinChrgMemoLine, FinChrgTerms, FinChrgMemoHeader, Rec);

        if InsertedLines then
            BuildMultiDescription(FinChrgTerms."Line Description", UseDueDate, NrOfDays);
        BuildDescription(Description, UseInterestRate, UseDueDate, NrOfDays, BaseAmount);

        if Amount <> 0 then begin
            CustPostingGr.Get(FinChrgMemoHeader."Customer Posting Group");
            GLAcc.Get(CustPostingGr.GetInterestAccount());
            GLAcc.TestField("Gen. Prod. Posting Group");
            Validate("Gen. Prod. Posting Group", GLAcc."Gen. Prod. Posting Group");
            Validate("VAT Prod. Posting Group", GLAcc."VAT Prod. Posting Group");
        end;

        OnAfterCalcFinCharge(Rec, FinChrgMemoHeader);
    end;

    procedure CheckAttachedLines(): Boolean
    var
        FinChrgMemoLine: Record "Finance Charge Memo Line";
    begin
        if "Line No." <> 0 then begin
            FinChrgMemoLine.SetRange("Finance Charge Memo No.", "Finance Charge Memo No.");
            FinChrgMemoLine.SetRange("Attached to Line No.", "Line No.");
            exit(not FinChrgMemoLine.IsEmpty);
        end;
        exit(false);
    end;

    procedure UpdateAttachedLines()
    var
        FinChrgMemoLine: Record "Finance Charge Memo Line";
    begin
        FinChrgMemoLine.SetRange("Finance Charge Memo No.", "Finance Charge Memo No.");
        FinChrgMemoLine.SetRange("Attached to Line No.", "Line No.");
        FinChrgMemoLine.DeleteAll();
    end;

    local procedure SetCustLedgEntryView()
    begin
        GetFinChrgMemoHeader();
        case FinChrgTerms."Interest Calculation" of
            FinChrgTerms."Interest Calculation"::"Open Entries":
                begin
                    CustLedgEntry.SetCurrentKey("Customer No.", Open);
                    CustLedgEntry.SetRange("Customer No.", FinChrgMemoHeader."Customer No.");
                    CustLedgEntry.SetRange(Open, true);
                end;
            FinChrgTerms."Interest Calculation"::"Closed Entries",
            FinChrgTerms."Interest Calculation"::"All Entries":
                begin
                    CustLedgEntry.SetCurrentKey("Customer No.");
                    CustLedgEntry.SetRange("Customer No.", FinChrgMemoHeader."Customer No.");
                end;
        end;

        OnAfterSetCustLedgEntryView(CustLedgEntry, FinChrgTerms, FinChrgMemoHeader);
    end;

    local procedure LookupCustLedgEntry()
    begin
        GetFinChrgMemoHeader();
        case FinChrgTerms."Interest Calculation" of
            FinChrgTerms."Interest Calculation"::"Open Entries":
                if PAGE.RunModal(0, CustLedgEntry) = ACTION::LookupOK then
                    Validate("Entry No.", CustLedgEntry."Entry No.");
            FinChrgTerms."Interest Calculation"::"Closed Entries",
          FinChrgTerms."Interest Calculation"::"All Entries":
                if PAGE.RunModal(PAGE::"Customer Ledger Entries", CustLedgEntry) = ACTION::LookupOK then
                    Validate("Entry No.", CustLedgEntry."Entry No.");
        end;
    end;

    local procedure GetFinChrgMemoHeader()
    begin
        if "Finance Charge Memo No." <> FinChrgMemoHeader."No." then begin
            FinChrgMemoHeader.Get("Finance Charge Memo No.");
            ProcessFinChrgMemoHeader();
        end;
    end;

    procedure SetFinChrgMemoHeader(var NewFinChrgMemoHeader: Record "Finance Charge Memo Header")
    begin
        FinChrgMemoHeader := NewFinChrgMemoHeader;
        ProcessFinChrgMemoHeader();
    end;

    local procedure ProcessFinChrgMemoHeader()
    begin
        FinChrgMemoHeader.TestField("Customer No.");
        FinChrgMemoHeader.TestField("Document Date");
        FinChrgMemoHeader.TestField("Customer Posting Group");
        FinChrgMemoHeader.TestField("Fin. Charge Terms Code");
        FinChrgTerms.Get(FinChrgMemoHeader."Fin. Charge Terms Code");
        OnProcessFinChrgMemoHeaderOnAfterFinChrgTermsGet(Rec, FinChrgTerms);
        if FinChrgMemoHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else begin
            Currency.Get(FinChrgMemoHeader."Currency Code");
            Currency.TestField("Amount Rounding Precision");
        end;
    end;

    procedure GetCurrencyCode(): Code[10]
    var
        FinChrgMemoHeader: Record "Finance Charge Memo Header";
    begin
        if "Finance Charge Memo No." = FinChrgMemoHeader."No." then
            exit(FinChrgMemoHeader."Currency Code");

        if FinChrgMemoHeader.Get("Finance Charge Memo No.") then
            exit(FinChrgMemoHeader."Currency Code");

        exit('');
    end;

    procedure CalcClosedatDate() ClosedatDate: Date
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcClosedatDate(CustLedgEntry, ClosedatDate, IsHandled);
        if IsHandled then
            exit;

        if CustLedgEntry2.Get(CustLedgEntry."Closed by Entry No.") then
            if CustLedgEntry2."Document Date" > CustLedgEntry."Closed at Date" then
                ClosedatDate := CustLedgEntry2."Document Date"
            else
                ClosedatDate := CustLedgEntry."Closed at Date";
        CustLedgEntry2.SetCurrentKey("Closed by Entry No.");
        CustLedgEntry2.SetRange("Closed by Entry No.", CustLedgEntry."Entry No.");
        if CustLedgEntry2.Find('-') then
            repeat
                if CustLedgEntry2."Document Date" > CustLedgEntry."Closed at Date" then
                    ClosedatDate := CustLedgEntry2."Document Date"
                else
                    ClosedatDate := CustLedgEntry."Closed at Date";
            until CustLedgEntry2.Next() = 0;
    end;

    procedure SetCheckingMode(DoChecking: Boolean)
    begin
        Checking := DoChecking;
    end;

    local procedure BuildDescription(var Descr: Text[100]; InterestRate: Decimal; DueDate: Date; NrOfDays: Integer; BaseAmount: Decimal)
    var
        AutoFormatType: Enum "Auto Format";
    begin
        DocTypeText := CopyStr(DelChr(Format("Document Type"), '<'), 1, 30);
        if DocTypeText = '' then
            DocTypeText := Text002;
        if FinChrgTerms."Line Description" = '' then
            Descr := CopyStr(CustLedgEntry.Description, 1, MaxStrLen(Description))
        else
            Descr :=
              CopyStr(
                StrSubstNo(
                  FinChrgTerms."Line Description",
                  CustLedgEntry.Description,
                  DocTypeText,
                  "Document No.",
                  InterestRate,
                  Format("Original Amount", 0, AutoFormat.ResolveAutoFormat(AutoFormatType::AmountFormat, FinChrgMemoHeader."Currency Code")),
                  Format(BaseAmount, 0, AutoFormat.ResolveAutoFormat(AutoFormatType::AmountFormat, FinChrgMemoHeader."Currency Code")),
                  DueDate,
                  FinChrgMemoHeader."Currency Code",
                  NrOfDays),
                1,
                MaxStrLen(Description));
    end;

    local procedure BuildMultiDescription(var Descr: Text[100]; DueDate: Date; NrOfDays: Integer)
    var
        AutoFormatType: Enum "Auto Format";
    begin
        DocTypeText := CopyStr(DelChr(Format("Document Type"), '<'), 1, 30);
        if DocTypeText = '' then
            DocTypeText := Text002;
        if FinChrgTerms.Description = '' then
            Descr := CopyStr(CustLedgEntry.Description, 1, MaxStrLen(Description))
        else
            Descr :=
              CopyStr(
                StrSubstNo(
                  FinChrgTerms."Detailed Lines Description",
                  CustLedgEntry.Description,
                  DocTypeText,
                  "Document No.",
                  Format("Original Amount", 0, AutoFormat.ResolveAutoFormat(AutoFormatType::AmountFormat, FinChrgMemoHeader."Currency Code")),
                  Format("Remaining Amount", 0, AutoFormat.ResolveAutoFormat(AutoFormatType::AmountFormat, FinChrgMemoHeader."Currency Code")),
                  DueDate,
                  FinChrgMemoHeader."Currency Code",
                  NrOfDays),
                1,
                MaxStrLen(Description));
    end;

    local procedure EnsureNotOnHold(var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeEnsureNotOnHold(CustLedgerEntry, FinChrgMemoHeader, IsHandled);
        if IsHandled then
            exit;

        CustLedgEntry.TestField("On Hold", '');
    end;

    local procedure CumulateDetailedEntries(var CumAmount: Decimal; UseDueDate: Date; UseCalcDate: Date; UseInterestRate: Decimal; UseInterestPeriod: Integer; var BaseAmount: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        IssuedReminderHeader: Record "Issued Reminder Header";
        InterestStartDate: Date;
        LineFee: Decimal;
    begin
        CalcInterest := true;
        if CustLedgEntry."Calculate Interest" then begin
            ClosedatDate := CalcClosedatDate();
            if ClosedatDate <= CalcDate(FinChrgTerms."Grace Period", "Due Date") then
                CalcInterest := false;
        end;
        DetailedCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type", "Posting Date");
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
        DetailedCustLedgEntry.SetFilter("Entry Type", '%1|%2|%3|%4|%5',
          DetailedCustLedgEntry."Entry Type"::"Initial Entry",
          DetailedCustLedgEntry."Entry Type"::Application,
          DetailedCustLedgEntry."Entry Type"::"Payment Tolerance",
          DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance (VAT Excl.)",
          DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance (VAT Adjustment)");
        DetailedCustLedgEntry.SetRange("Posting Date", 0D, FinChrgMemoHeader."Document Date");
        CumAmount := 0;
        if DetailedCustLedgEntry.FindSet() then
            repeat
                if DetailedCustLedgEntry."Entry Type" = DetailedCustLedgEntry."Entry Type"::"Initial Entry" then
                    InterestStartDate := UseDueDate
                else
                    if UseDueDate < DetailedCustLedgEntry."Posting Date" then
                        InterestStartDate := DetailedCustLedgEntry."Posting Date";
                if InterestCalcDate > InterestStartDate then
                    InterestStartDate := InterestCalcDate;
                if InterestStartDate < UseCalcDate then
                    CumAmount := CumAmount + (DetailedCustLedgEntry.Amount * (UseCalcDate - InterestStartDate));
            until DetailedCustLedgEntry.Next() = 0;

        if not FinChrgTerms."Add. Line Fee in Interest" then
            if CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::Reminder then
                if IssuedReminderHeader.Get(CustLedgEntry."Document No.") then begin
                    IssuedReminderHeader.CalcFields("Add. Fee per Line");
                    LineFee := IssuedReminderHeader."Add. Fee per Line" + IssuedReminderHeader.CalculateLineFeeVATAmount();
                    CumAmount := CumAmount - LineFee * (FinChrgMemoHeader."Document Date" - InterestStartDate);
                    if CumAmount < 0 then
                        CumAmount := 0;
                end;

        BaseAmount := CumAmount / UseInterestPeriod;
        if CalcInterest then
            CumAmount := Round(CumAmount / UseInterestPeriod * UseInterestRate / 100, Currency."Amount Rounding Precision")
        else
            CumAmount := 0;

        OnAfterCumulateDetailedEntries(Rec, FinChrgMemoHeader, ClosedatDate, CumAmount);
    end;

    procedure LookupDocNo()
    begin
        if Type <> Type::"Customer Ledger Entry" then
            exit;
        SetCustLedgEntryView();
        if "Document Type" <> "Document Type"::" " then
            CustLedgEntry.SetRange("Document Type", "Document Type");
        if "Document No." <> '' then
            CustLedgEntry.SetRange("Document No.", "Document No.");
        if CustLedgEntry.FindFirst() then;
        CustLedgEntry.SetRange("Document Type");
        CustLedgEntry.SetRange("Document No.");
        LookupCustLedgEntry();
    end;

    local procedure CalcFinanceChargeInterestRate(var FinanceChargeInterestRate: Record "Finance Charge Interest Rate"; var UseDueDate: Date; var UseInterestRate: Decimal; var UseCalcDate: Date)
    var
        LastRateFound: Boolean;
    begin
        UseDueDate := CustLedgEntry."Due Date";
        UseInterestRate := FinChrgTerms."Interest Rate";
        UseCalcDate := 0D;
        NrOfLinesToInsert := 0;

        FinanceChargeInterestRate.Init();
        FinanceChargeInterestRate.SetRange("Fin. Charge Terms Code", FinChrgMemoHeader."Fin. Charge Terms Code");
        FinanceChargeInterestRate."Fin. Charge Terms Code" := FinChrgMemoHeader."Fin. Charge Terms Code";
        if FinChrgTerms."Interest Calculation Method" = FinChrgTerms."Interest Calculation Method"::"Average Daily Balance" then
            FinanceChargeInterestRate."Start Date" := CalcDate('<+1D>', CustLedgEntry."Due Date")
        else
            FinanceChargeInterestRate."Start Date" := FinChrgMemoHeader."Document Date";
        NrOfLinesToInsert := 0;
        NrOfLines := 0;
        LastRateFound := false;
        if FinanceChargeInterestRate.Find('=<') then begin
            UseInterestRate := FinanceChargeInterestRate."Interest Rate";
            if FinChrgTerms."Interest Calculation Method" = FinChrgTerms."Interest Calculation Method"::"Average Daily Balance" then
                repeat
                    if FinanceChargeInterestRate."Start Date" <= FinChrgMemoHeader."Document Date" then begin
                        NrOfLines := NrOfLines + 1;
                        UseInterestRate := FinanceChargeInterestRate."Interest Rate";
                        if CalcDate(FinChrgTerms."Grace Period", "Due Date") < FinChrgMemoHeader."Document Date" then
                            NrOfLinesToInsert := NrOfLinesToInsert + 1
                    end else
                        LastRateFound := true;
                until LastRateFound or (FinanceChargeInterestRate.Next() = 0);
            if UseCalcDate = 0D then begin
                FinanceChargeInterestRate.Next(-1);
                UseCalcDate := FinanceChargeInterestRate."Start Date";
            end;
        end else
            if FinanceChargeInterestRate.Count > 0 then
                Error(InvalidInterestRateDateErr, FinanceChargeInterestRate."Start Date");
        if (UseCalcDate = 0D) or (UseCalcDate < FinChrgMemoHeader."Document Date") then
            UseCalcDate := FinChrgMemoHeader."Document Date";

        "Interest Rate" := UseInterestRate;

        OnAfterCalcFinanceChargeInterestRate(Rec, CustLedgEntry, FinChrgTerms, UseCalcDate);
    end;

    local procedure CreateMulitplyInterestRateEntries(var ExtraFinChrgMemoLine: Record "Finance Charge Memo Line"; var FinanceChargeInterestRate: Record "Finance Charge Interest Rate"; var UseDueDate: Date; var UseCalcDate: Date; var UseInterestRate: Decimal; var BaseAmount: Decimal; var CumAmount: Decimal) InsertedLines: Boolean
    var
        LineSpacing: Integer;
        NextLineNo: Integer;
        CurrInterestRateStartDate: Date;
        UseInterestPeriod: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateMulitplyInterestRateEntries(Rec, InsertedLines, IsHandled);
        if IsHandled then
            exit(InsertedLines);

        NrOfDays := 0;
        ExtraFinChrgMemoLine.Reset();
        ExtraFinChrgMemoLine.SetRange("Finance Charge Memo No.", "Finance Charge Memo No.");
        ExtraFinChrgMemoLine := Rec;
        if ExtraFinChrgMemoLine.Find('>') then begin
            LineSpacing :=
              (ExtraFinChrgMemoLine."Line No." - "Line No.") div (1 + NrOfLinesToInsert);
            if LineSpacing = 0 then
                Error(NotEnoughSpaceToInsertErr);
        end else
            LineSpacing := 10000;
        NextLineNo := "Line No." + LineSpacing;
        FinanceChargeInterestRate.Init();
        FinanceChargeInterestRate.SetRange("Fin. Charge Terms Code", FinChrgMemoHeader."Fin. Charge Terms Code");
        FinanceChargeInterestRate."Fin. Charge Terms Code" := FinChrgMemoHeader."Fin. Charge Terms Code";
        FinanceChargeInterestRate."Start Date" := CalcDate('<+1D>', CustLedgEntry."Due Date");
        if FinanceChargeInterestRate.Find('=<') then begin
            repeat
                CalcInterest := false;
                FinanceChargeInterestRate.TestField("Interest Period (Days)");
                UseDueDate := CalcDate('<-1D>', FinanceChargeInterestRate."Start Date");
                CurrInterestRateStartDate := FinanceChargeInterestRate."Start Date";
                UseInterestRate := FinanceChargeInterestRate."Interest Rate";
                UseInterestPeriod := FinanceChargeInterestRate."Interest Period (Days)";
                if FinanceChargeInterestRate.Next() <> 0 then begin
                    if FinanceChargeInterestRate."Start Date" <= FinChrgMemoHeader."Document Date" then
                        UseCalcDate := CalcDate('<-1D>', FinanceChargeInterestRate."Start Date")
                    else
                        UseCalcDate := FinChrgMemoHeader."Document Date";
                end else
                    UseCalcDate := FinChrgMemoHeader."Document Date";
                if (CustLedgEntry."Closed at Date" <> 0D) and (UseCalcDate > CustLedgEntry."Closed at Date") then
                    UseCalcDate := CustLedgEntry."Closed at Date";
                ExtraFinChrgMemoLine := Rec;
                ExtraFinChrgMemoLine."Line No." := NextLineNo;
                ExtraFinChrgMemoLine."Due Date" := CalcDate('<+1D>', InterestCalcDate);
                if CurrInterestRateStartDate > ExtraFinChrgMemoLine."Due Date" then
                    ExtraFinChrgMemoLine."Due Date" := CurrInterestRateStartDate;
                ExtraFinChrgMemoLine."Interest Rate" := UseInterestRate;
                if InterestCalcDate < UseCalcDate then begin
                    CumulateDetailedEntries(ExtraFinChrgMemoLine.Amount, UseDueDate, UseCalcDate,
                      UseInterestRate, UseInterestPeriod, BaseAmount);
                    if ExtraFinChrgMemoLine.Amount <> 0 then begin
                        NrOfDays := NrOfDays + (UseCalcDate - UseDueDate);
                        OnCreateMulitplyInterestRateEntriesOnBeforeBuildDescription(ExtraFinChrgMemoLine, UseCalcDate, UseDueDate);
                        BuildDescription(ExtraFinChrgMemoLine.Description, UseInterestRate, UseDueDate, UseCalcDate - UseDueDate, BaseAmount);
                        CumAmount := CumAmount + ExtraFinChrgMemoLine.Amount;
                        ExtraFinChrgMemoLine."Detailed Interest Rates Entry" := true;
                        if not Checking then
                            ExtraFinChrgMemoLine.Insert();
                        InsertedLines := true;
                        NextLineNo := ExtraFinChrgMemoLine."Line No." + LineSpacing;
                    end;
                end;
                NrOfLinesToInsert := NrOfLinesToInsert - 1;
            until NrOfLinesToInsert = 0;
            Validate(Amount, CumAmount);
        end;
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnAfterCalcFinCharge(var FinanceChargeMemoLine: Record "Finance Charge Memo Line"; var FinanceChargeMemoHeader: Record "Finance Charge Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcFinChrgProcedure(var FinanceChargeMemoLine: Record "Finance Charge Memo Line"; var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcFinanceChargeInterestRate(FinanceChargeMemoLine: Record "Finance Charge Memo Line"; CustLedgerEntry: Record "Cust. Ledger Entry"; FinanceChargeTerms: Record "Finance Charge Terms"; var UseCalcDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateMulitplyInterestRateEntries(var FinanceChargeMemoLine: Record "Finance Charge Memo Line"; var InsertedLines: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcClosedatDate(CustLedgerEntry: Record "Cust. Ledger Entry"; var ClosedAtDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcFinChrgOnAfterFinChrgTermsInterestCalculationMethodCase(var FinanceChargeMemoLine: Record "Finance Charge Memo Line"; FinanceChargeTerms: Record "Finance Charge Terms"; FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; var FinanceChargeMemoLineSender: Record "Finance Charge Memo Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcFinChrgOnAfterCalcSkipBecauseEntryOnHold(CustLedgerEntry: Record "Cust. Ledger Entry"; FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; var SkipBecauseEntryOnHold: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcFinChrgOnBeforeCheckNrOfLinesToInsert(var FinanceChargeMemoLine: Record "Finance Charge Memo Line"; NrOfDays: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEnsureNotOnHold(var CustLedgerEntry: Record "Cust. Ledger Entry"; var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVATProdPostingGroupOnAfterVATPostingSetupGet(var VATPostingSetup: Record "VAT Posting Setup"; FinanceChargeMemoLine: Record "Finance Charge Memo Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCustLedgEntryView(var CustLedgEntry: Record "Cust. Ledger Entry"; FinChrgTerms: Record "Finance Charge Terms"; FinChrgMemoHeader: Record "Finance Charge Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnAfterAssignGLAccountValues(var FinanceChargeMemoLine: Record "Finance Charge Memo Line"; FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVATProdPostingGroupOnBeforeVATPostingSetupGet(var FinanceChargeMemoLine: Record "Finance Charge Memo Line"; xFinanceChargeMemoLine: Record "Finance Charge Memo Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateMulitplyInterestRateEntriesOnBeforeBuildDescription(var FinanceChargeMemoLine: Record "Finance Charge Memo Line"; UseCalcDate: Date; UseDueDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCumulateDetailedEntries(var FinanceChargeMemoLine: Record "Finance Charge Memo Line"; var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; ClosedAtDate: Date; var CumAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessFinChrgMemoHeaderOnAfterFinChrgTermsGet(var FinanceChargeMemoLine: Record "Finance Charge Memo Line"; var FinanceChargeTerms: Record "Finance Charge Terms")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcFinChargeOnAfterCalcFinanceChargeInterestRate(var FinanceChargeMemoLine: Record "Finance Charge Memo Line"; var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; var IsHandled: Boolean)
    begin
    end;
}
