// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;

table 7000019 "Fee Range"
{
    Caption = 'Fee Range';
    DrillDownPageID = "Fee Ranges";
    LookupPageID = "Fee Ranges";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(3; "Type of Fee"; Option)
        {
            Caption = 'Type of Fee';
            OptionCaption = 'Collection Expenses,Discount Expenses,Discount Interests,Rejection Expenses,Payment Order Expenses,Unrisked Factoring Expenses,Risked Factoring Expenses ';
            OptionMembers = "Collection Expenses","Discount Expenses","Discount Interests","Rejection Expenses","Payment Order Expenses","Unrisked Factoring Expenses","Risked Factoring Expenses ";
        }
        field(4; "From No. of Days"; Integer)
        {
            Caption = 'From No. of Days';
            MinValue = 0;

            trigger OnValidate()
            begin
                if "From No. of Days" <> 0 then
                    TestField("Type of Fee", "Type of Fee"::"Discount Interests");
            end;
        }
        field(5; "Charge Amount per Doc."; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Charge Amount per Doc.';
            MinValue = 0;
        }
        field(6; "Charge % per Doc."; Decimal)
        {
            Caption = 'Charge % per Doc.';
            DecimalPlaces = 2 : 6;
            MaxValue = 100;
            MinValue = 0;
        }
        field(7; "Minimum Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Minimum Amount';
        }
    }

    keys
    {
        key(Key1; "Code", "Currency Code", "Type of Fee", "From No. of Days")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Text1100000: Label 'untitled';
        Text1100001: Label 'CollExpenses';
        Text1100002: Label 'Out of Range';
        Text1100003: Label 'DiscExpenses';
        Text1100004: Label 'DiscInterests';
        Text1100005: Label 'RejExpenses';
        Text1100006: Label 'PmtOrdCollExpenses';
        Text1100007: Label 'RiskFactExpenses';
        Text1100008: Label 'UnriskFactExpenses';
        Currency: Record Currency;
        OperationFee: Record "Operation Fee";
        DiscExpenses: Record "BG/PO Post. Buffer" temporary;
        CollExpenses: Record "BG/PO Post. Buffer" temporary;
        DiscInterests: Record "BG/PO Post. Buffer" temporary;
        RejExpenses: Record "BG/PO Post. Buffer" temporary;
        PmtOrdCollExpenses: Record "BG/PO Post. Buffer" temporary;
        RiskFactExpenses: Record "BG/PO Post. Buffer" temporary;
        UnriskFactExpenses: Record "BG/PO Post. Buffer" temporary;
        Initialized: Boolean;
        TotalDiscExpensesAmt: Decimal;
        InitDiscExpensesAmt: Decimal;
        TotalCollExpensesAmt: Decimal;
        TotalDiscInterestsAmt: Decimal;
        InitDiscInterestsAmt: Decimal;
        TotalRejExpensesAmt: Decimal;
        InitRejExpensesAmt: Decimal;
        TotalPmtOrdCollExpensesAmt: Decimal;
        TotalRiskFactExpensesAmt: Decimal;
        InitRiskFactExpensesAmt: Decimal;
        TotalUnriskFactExpensesAmt: Decimal;
        InitUnriskFactExpensesAmt: Decimal;
        "Sum": Decimal;
        Factor: Decimal;

    procedure Caption(): Text
    var
        BankAcc: Record "Bank Account";
    begin
        if Code = '' then
            exit(Text1100000);
        BankAcc.Get(Code);
        exit(StrSubstNo('%1 %2 %3 %4', BankAcc."No.", BankAcc.Name, "Currency Code", "Type of Fee"));
    end;

    local procedure InitCurrency()
    begin
        if Initialized then
            exit;

        if "Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else begin
            Currency.Get("Currency Code");
            Currency.TestField("Amount Rounding Precision");
        end;
        Initialized := true;
    end;

    procedure InitCollExpenses(Code2: Code[20]; CurrencyCode2: Code[10])
    begin
        "Currency Code" := CurrencyCode2;
        InitCurrency();
        TotalCollExpensesAmt := 0;
        if OperationFee.Get(Code2, CurrencyCode2, "Type of Fee"::"Collection Expenses") then
            TotalCollExpensesAmt :=
              Round(OperationFee."Charge Amt. per Operation", Currency."Amount Rounding Precision");

        CollExpenses.DeleteAll();
    end;

    procedure CalcCollExpensesAmt(Code2: Code[20]; CurrencyCode2: Code[10]; Amount: Decimal; EntryNo: Integer)
    begin
        "Currency Code" := CurrencyCode2;
        InitCurrency();
        SetRange(Code, Code2);
        SetRange("Currency Code", CurrencyCode2);
        SetRange("Type of Fee", "Type of Fee"::"Collection Expenses");
        if Find('=><') then begin
            Amount := Round(
                "Charge Amount per Doc." + Amount * "Charge % per Doc." / 100,
                Currency."Amount Rounding Precision");
            if Amount < "Minimum Amount" then
                Amount := "Minimum Amount";
            TotalCollExpensesAmt := TotalCollExpensesAmt + Amount;
        end;
        if CollExpenses.Get(Text1100001, '', EntryNo) then begin
            CollExpenses.Amount := CollExpenses.Amount + Amount;
            CollExpenses.Modify();
        end else begin
            CollExpenses.Init();
            CollExpenses.Account := Text1100001;
            CollExpenses."Entry No." := EntryNo;
            // CollExpenses."Global Dimension 1 Code" := Dep;
            // CollExpenses."Global Dimension 2 Code" := Proj;
            CollExpenses.Amount := Amount;
            CollExpenses.Insert();
        end;
    end;

    procedure GetTotalCollExpensesAmt(): Decimal
    begin
        exit(TotalCollExpensesAmt);
    end;

    procedure InitDiscExpenses(Code2: Code[20]; CurrencyCode2: Code[10])
    begin
        "Currency Code" := CurrencyCode2;
        InitCurrency();
        TotalDiscExpensesAmt := 0;
        if OperationFee.Get(Code2, CurrencyCode2, "Type of Fee"::"Discount Expenses") then
            TotalDiscExpensesAmt :=
              Round(OperationFee."Charge Amt. per Operation", Currency."Amount Rounding Precision");

        InitDiscExpensesAmt := TotalDiscExpensesAmt;
        DiscExpenses.DeleteAll();
    end;

    procedure CalcDiscExpensesAmt(Code2: Code[20]; CurrencyCode2: Code[10]; Amount: Decimal; EntryNo: Integer)
    begin
        "Currency Code" := CurrencyCode2;
        InitCurrency();
        SetRange(Code, Code2);
        SetRange("Currency Code", CurrencyCode2);
        SetRange("Type of Fee", "Type of Fee"::"Discount Expenses");
        if Find('=><') then begin
            Amount := Round(
                "Charge Amount per Doc." + Amount * "Charge % per Doc." / 100,
                Currency."Amount Rounding Precision");
            if Amount < "Minimum Amount" then
                Amount := "Minimum Amount";
            TotalDiscExpensesAmt := TotalDiscExpensesAmt + Amount;
        end else
            Amount := 0;

        if DiscExpenses.Get(Text1100003, '', EntryNo) then begin
            DiscExpenses.Amount := DiscExpenses.Amount + Amount;
            DiscExpenses.Modify();
        end else begin
            DiscExpenses.Init();
            DiscExpenses.Account := Text1100003;
            DiscExpenses."Entry No." := EntryNo;
            // DiscExpenses."Global Dimension 1 Code" := Dep;
            // DiscExpenses."Global Dimension 2 Code" := Proj;
            DiscExpenses.Amount := Amount;
            DiscExpenses.Insert();
        end;
    end;

    procedure GetTotalDiscExpensesAmt(): Decimal
    begin
        exit(TotalDiscExpensesAmt);
    end;

    procedure NoRegsDiscExpenses(): Integer
    begin
        DiscExpenses.SetRange(Account, Text1100003);
        if DiscExpenses.Find('-') and (InitDiscExpensesAmt <> 0) then begin
            Sum := 0;
            repeat
                Sum := Sum + DiscExpenses.Amount;
            until DiscExpenses.Next() <= 0;

            if Sum <> 0 then
                Factor := InitDiscExpensesAmt / Sum
            else
                Factor := 1;
            DiscExpenses.Find('-');
            repeat
                Sum := Round(DiscExpenses.Amount * Factor, Currency."Amount Rounding Precision");
                DiscExpenses.Amount := DiscExpenses.Amount + Sum;
                InitDiscExpensesAmt := InitDiscExpensesAmt - Sum;
                DiscExpenses.Modify();
            until DiscExpenses.Next() <= 0;
            if Round(InitDiscExpensesAmt, Currency."Amount Rounding Precision") <> 0 then begin
                DiscExpenses.Find('+');
                DiscExpenses.Amount := DiscExpenses.Amount + Round(InitDiscExpensesAmt, Currency."Amount Rounding Precision");
                InitDiscExpensesAmt := 0;
                DiscExpenses.Modify();
            end;
        end;
        exit(DiscExpenses.Count);
    end;

    procedure GetDiscExpensesAmt(var value: Record "BG/PO Post. Buffer"; Register: Integer)
    begin
        DiscExpenses.SetRange(Account, Text1100003);
        DiscExpenses.Find('-');
        if Register <> DiscExpenses.Next(Register) then
            Error(Text1100002);
        value := DiscExpenses;
    end;

    procedure InitDiscInterests(Code2: Code[20]; CurrencyCode2: Code[10])
    begin
        "Currency Code" := CurrencyCode2;
        InitCurrency();
        TotalDiscInterestsAmt := 0;
        if OperationFee.Get(Code2, CurrencyCode2, "Type of Fee"::"Discount Interests") then
            TotalDiscInterestsAmt :=
              Round(OperationFee."Charge Amt. per Operation", Currency."Amount Rounding Precision");

        InitDiscInterestsAmt := TotalDiscInterestsAmt;
        DiscInterests.DeleteAll();
    end;

    procedure CalcDiscInterestsAmt(Code2: Code[20]; CurrencyCode2: Code[10]; NoOfDays: Integer; Amount: Decimal; EntryNo: Integer)
    begin
        "Currency Code" := CurrencyCode2;
        InitCurrency();
        if NoOfDays <= 0 then
            exit;
        SetRange(Code, Code2);
        SetRange("Currency Code", CurrencyCode2);
        SetFilter("From No. of Days", '<=%1', NoOfDays);
        SetRange("Type of Fee", "Type of Fee"::"Discount Interests");
        if Find('+') then begin
            Amount := Round(
                "Charge Amount per Doc." + Amount * "Charge % per Doc." * NoOfDays / 36000,
                Currency."Amount Rounding Precision");
            if Amount < "Minimum Amount" then
                Amount := "Minimum Amount";
            TotalDiscInterestsAmt := TotalDiscInterestsAmt + Amount;
        end else
            Amount := 0;

        SetRange("Type of Fee");

        if DiscInterests.Get(Text1100004, '', EntryNo) then begin
            DiscInterests.Amount := DiscInterests.Amount + Amount;
            DiscInterests.Modify();
        end else begin
            DiscInterests.Init();
            DiscInterests.Account := Text1100004;
            DiscInterests."Entry No." := EntryNo;
            DiscInterests.Amount := Amount;
            DiscInterests.Insert();
        end;
    end;

    procedure GetTotalDiscInterestsAmt(): Decimal
    begin
        exit(TotalDiscInterestsAmt);
    end;

    procedure NoRegsDiscInterests(): Integer
    begin
        DiscInterests.SetRange(Account, Text1100004);
        if DiscInterests.Find('-') and (InitDiscInterestsAmt <> 0) then begin
            Sum := 0;
            repeat
                Sum := Sum + DiscInterests.Amount;
            until DiscInterests.Next() <= 0;

            if Sum <> 0 then
                Factor := InitDiscInterestsAmt / Sum
            else
                Factor := 1;
            DiscInterests.Find('-');
            repeat
                Sum := Round(DiscInterests.Amount * Factor, Currency."Amount Rounding Precision");
                DiscInterests.Amount := DiscInterests.Amount + Sum;
                InitDiscInterestsAmt := InitDiscInterestsAmt - Sum;
                DiscInterests.Modify();
            until DiscInterests.Next() <= 0;
            if Round(InitDiscInterestsAmt, Currency."Amount Rounding Precision") <> 0 then begin
                DiscInterests.Find('+');
                DiscInterests.Amount := DiscInterests.Amount + Round(InitDiscInterestsAmt, Currency."Amount Rounding Precision");
                InitDiscInterestsAmt := 0;
                DiscInterests.Modify();
            end;
        end;
        exit(DiscInterests.Count);
    end;

    procedure GetDiscInterestsAmt(var value: Record "BG/PO Post. Buffer"; Register: Integer)
    begin
        DiscInterests.SetRange(Account, Text1100004);
        DiscInterests.Find('-');
        if Register <> DiscInterests.Next(Register) then
            Error(Text1100002);
        value := DiscInterests;
    end;

    procedure InitRejExpenses(Code2: Code[20]; CurrencyCode2: Code[10])
    begin
        "Currency Code" := CurrencyCode2;
        InitCurrency();
        TotalRejExpensesAmt := 0;
        if OperationFee.Get(Code2, CurrencyCode2, "Type of Fee"::"Rejection Expenses") then
            TotalRejExpensesAmt :=
              Round(OperationFee."Charge Amt. per Operation", Currency."Amount Rounding Precision");

        InitRejExpensesAmt := TotalRejExpensesAmt;
        RejExpenses.DeleteAll();
    end;

    procedure CalcRejExpensesAmt(Code2: Code[20]; CurrencyCode2: Code[10]; Amount: Decimal; EntryNo: Integer)
    begin
        "Currency Code" := CurrencyCode2;
        InitCurrency();
        SetRange(Code, Code2);
        SetRange("Currency Code", CurrencyCode2);
        SetRange("Type of Fee", "Type of Fee"::"Rejection Expenses");
        if Find('=><') then begin
            Amount := Round(
                "Charge Amount per Doc." + Amount * "Charge % per Doc." / 100,
                Currency."Amount Rounding Precision");
            if Amount < "Minimum Amount" then
                Amount := "Minimum Amount";
            TotalRejExpensesAmt := TotalRejExpensesAmt + Amount;
        end;
        SetRange("Type of Fee");

        if RejExpenses.Get(Text1100005, '', EntryNo) then begin
            RejExpenses.Amount := RejExpenses.Amount + Amount;
            RejExpenses.Modify();
        end else begin
            RejExpenses.Init();
            RejExpenses.Account := Text1100005;
            RejExpenses."Entry No." := EntryNo;
            RejExpenses.Amount := Amount;
            RejExpenses.Insert();
        end;
    end;

    procedure GetTotalRejExpensesAmt(): Decimal
    begin
        exit(TotalRejExpensesAmt);
    end;

    procedure NoRegRejExpenses(): Integer
    begin
        RejExpenses.SetRange(Account, Text1100005);
        if RejExpenses.Find('-') and (InitRejExpensesAmt <> 0) then begin
            Sum := 0;
            repeat
                Sum := Sum + RejExpenses.Amount;
            until RejExpenses.Next() <= 0;

            if Sum <> 0 then
                Factor := InitRejExpensesAmt / Sum
            else
                Factor := 1;
            RejExpenses.Find('-');
            repeat
                Sum := Round(RejExpenses.Amount * Factor, Currency."Amount Rounding Precision");
                RejExpenses.Amount := RejExpenses.Amount + Sum;
                InitRejExpensesAmt := InitRejExpensesAmt - Sum;
                RejExpenses.Modify();
            until RejExpenses.Next() <= 0;
            if Round(InitRejExpensesAmt, Currency."Amount Rounding Precision") <> 0 then begin
                RejExpenses.Find('+');
                RejExpenses.Amount := RejExpenses.Amount + Round(InitRejExpensesAmt, Currency."Amount Rounding Precision");
                InitRejExpensesAmt := 0;
                RejExpenses.Modify();
            end;
        end;
        exit(RejExpenses.Count);
    end;

    procedure GetRejExpensesAmt(var value: Record "BG/PO Post. Buffer"; Register: Integer)
    begin
        RejExpenses.SetRange(Account, Text1100005);
        RejExpenses.Find('-');
        if Register <> RejExpenses.Next(Register) then
            Error(Text1100002);
        value := RejExpenses;
    end;

    procedure InitPmtOrdCollExpenses(Code2: Code[20]; CurrencyCode2: Code[10])
    begin
        "Currency Code" := CurrencyCode2;
        InitCurrency();
        TotalPmtOrdCollExpensesAmt := 0;
        if OperationFee.Get(Code2, CurrencyCode2, "Type of Fee"::"Payment Order Expenses") then
            TotalPmtOrdCollExpensesAmt :=
              Round(OperationFee."Charge Amt. per Operation", Currency."Amount Rounding Precision");

        PmtOrdCollExpenses.DeleteAll();
    end;

    procedure CalcPmtOrdCollExpensesAmt(Code2: Code[20]; CurrencyCode2: Code[10]; Amount: Decimal; EntryNo: Integer)
    begin
        "Currency Code" := CurrencyCode2;
        InitCurrency();
        SetRange(Code, Code2);
        SetRange("Currency Code", CurrencyCode2);
        SetRange("Type of Fee", "Type of Fee"::"Payment Order Expenses");
        if Find('=><') then begin
            Amount := Round(
                "Charge Amount per Doc." + Amount * "Charge % per Doc." / 100,
                Currency."Amount Rounding Precision");
            if Amount < "Minimum Amount" then
                Amount := "Minimum Amount";
            TotalPmtOrdCollExpensesAmt := TotalPmtOrdCollExpensesAmt + Amount;
        end;

        if PmtOrdCollExpenses.Get(Text1100006, '', EntryNo) then begin
            PmtOrdCollExpenses.Amount := PmtOrdCollExpenses.Amount + Amount;
            PmtOrdCollExpenses.Modify();
        end else begin
            PmtOrdCollExpenses.Init();
            PmtOrdCollExpenses.Account := Text1100006;
            PmtOrdCollExpenses."Entry No." := EntryNo;
            PmtOrdCollExpenses.Amount := Amount;
            PmtOrdCollExpenses.Insert();
        end;
    end;

    procedure GetTotalPmtOrdCollExpensesAmt(): Decimal
    begin
        exit(TotalPmtOrdCollExpensesAmt);
    end;

    procedure InitRiskFactExpenses(Code2: Code[20]; CurrencyCode2: Code[10])
    begin
        "Currency Code" := CurrencyCode2;
        InitCurrency();
        TotalRiskFactExpensesAmt := 0;
        if OperationFee.Get(Code2, CurrencyCode2, "Type of Fee"::"Risked Factoring Expenses ") then
            TotalRiskFactExpensesAmt :=
              Round(OperationFee."Charge Amt. per Operation", Currency."Amount Rounding Precision");

        InitRiskFactExpensesAmt := TotalRiskFactExpensesAmt;
        RiskFactExpenses.DeleteAll();
    end;

    procedure CalcRiskFactExpensesAmt(Code2: Code[20]; CurrencyCode2: Code[10]; Amount: Decimal; EntryNo: Integer)
    begin
        "Currency Code" := CurrencyCode2;
        InitCurrency();
        SetRange(Code, Code2);
        SetRange("Currency Code", CurrencyCode2);
        SetRange("Type of Fee", "Type of Fee"::"Risked Factoring Expenses ");
        if Find('=><') then begin
            Amount := Round(
                "Charge Amount per Doc." + Amount * "Charge % per Doc." / 100,
                Currency."Amount Rounding Precision");
            if Amount < "Minimum Amount" then
                Amount := "Minimum Amount";
            TotalRiskFactExpensesAmt := TotalRiskFactExpensesAmt + Amount;
        end;

        if RiskFactExpenses.Get(Text1100007, '', EntryNo) then begin
            RiskFactExpenses.Amount := RiskFactExpenses.Amount + Amount;
            RiskFactExpenses.Modify();
        end else begin
            RiskFactExpenses.Init();
            RiskFactExpenses.Account := Text1100007;
            RiskFactExpenses."Entry No." := EntryNo;
            RiskFactExpenses.Amount := Amount;
            RiskFactExpenses.Insert();
        end;
    end;

    procedure GetTotalRiskFactExpensesAmt(): Decimal
    begin
        exit(TotalRiskFactExpensesAmt);
    end;

    procedure NoRegRiskFactExpenses(): Integer
    begin
        RiskFactExpenses.SetRange(Account, Text1100007);
        if RiskFactExpenses.Find('-') and (InitRiskFactExpensesAmt <> 0) then begin
            Sum := 0;
            repeat
                Sum := Sum + RiskFactExpenses.Amount;
            until RiskFactExpenses.Next() <= 0;

            if Sum <> 0 then
                Factor := InitRiskFactExpensesAmt / Sum
            else
                Factor := 1;
            RiskFactExpenses.Find('-');
            repeat
                Sum := Round(RiskFactExpenses.Amount * Factor, Currency."Amount Rounding Precision");
                RiskFactExpenses.Amount := RiskFactExpenses.Amount + Sum;
                InitRiskFactExpensesAmt := InitRiskFactExpensesAmt - Sum;
                RiskFactExpenses.Modify();
            until RiskFactExpenses.Next() <= 0;
            if Round(InitRiskFactExpensesAmt, Currency."Amount Rounding Precision") <> 0 then begin
                RiskFactExpenses.Find('+');
                RiskFactExpenses.Amount := RiskFactExpenses.Amount + Round(InitRiskFactExpensesAmt, Currency."Amount Rounding Precision");
                InitRiskFactExpensesAmt := 0;
                RiskFactExpenses.Modify();
            end;
        end;
        exit(RiskFactExpenses.Count);
    end;

    procedure GetRiskFactExpenses(var value: Record "BG/PO Post. Buffer"; Register: Integer)
    begin
        RiskFactExpenses.SetRange(Account, Text1100007);
        RiskFactExpenses.Find('-');
        if Register <> RiskFactExpenses.Next(Register) then
            Error(Text1100002);
        value := RiskFactExpenses;
    end;

    procedure InitUnriskFactExpenses(Code2: Code[20]; CurrencyCode2: Code[10])
    begin
        "Currency Code" := CurrencyCode2;
        InitCurrency();
        TotalUnriskFactExpensesAmt := 0;
        if OperationFee.Get(Code2, CurrencyCode2, "Type of Fee"::"Unrisked Factoring Expenses") then
            TotalUnriskFactExpensesAmt :=
              Round(OperationFee."Charge Amt. per Operation", Currency."Amount Rounding Precision");

        InitUnriskFactExpensesAmt := TotalUnriskFactExpensesAmt;
        UnriskFactExpenses.DeleteAll();
    end;

    procedure CalcUnriskFactExpensesAmt(Code2: Code[20]; CurrencyCode2: Code[10]; Amount: Decimal; EntryNo: Integer)
    begin
        "Currency Code" := CurrencyCode2;
        InitCurrency();
        SetRange(Code, Code2);
        SetRange("Currency Code", CurrencyCode2);
        SetRange("Type of Fee", "Type of Fee"::"Unrisked Factoring Expenses");
        if Find('=><') then begin
            Amount := Round(
                "Charge Amount per Doc." + Amount * "Charge % per Doc." / 100,
                Currency."Amount Rounding Precision");
            if Amount < "Minimum Amount" then
                Amount := "Minimum Amount";
            TotalUnriskFactExpensesAmt := TotalUnriskFactExpensesAmt + Amount;
        end;

        if UnriskFactExpenses.Get(Text1100008, '', EntryNo) then begin
            UnriskFactExpenses.Amount := UnriskFactExpenses.Amount + Amount;
            UnriskFactExpenses.Modify();
        end else begin
            UnriskFactExpenses.Init();
            UnriskFactExpenses.Account := Text1100008;
            UnriskFactExpenses."Entry No." := EntryNo;
            UnriskFactExpenses.Amount := Amount;
            UnriskFactExpenses.Insert();
        end;
    end;

    procedure GetTotalUnriskFactExpensesAmt(): Decimal
    begin
        exit(TotalUnriskFactExpensesAmt);
    end;

    procedure NoRegUnriskFactExpenses(): Integer
    begin
        UnriskFactExpenses.SetRange(Account, Text1100008);
        if UnriskFactExpenses.Find('-') and (InitUnriskFactExpensesAmt <> 0) then begin
            Sum := 0;
            repeat
                Sum := Sum + UnriskFactExpenses.Amount;
            until UnriskFactExpenses.Next() <= 0;

            if Sum <> 0 then
                Factor := InitUnriskFactExpensesAmt / Sum
            else
                Factor := 1;
            UnriskFactExpenses.Find('-');
            repeat
                Sum := Round(UnriskFactExpenses.Amount * Factor, Currency."Amount Rounding Precision");
                UnriskFactExpenses.Amount := UnriskFactExpenses.Amount + Sum;
                InitUnriskFactExpensesAmt := InitUnriskFactExpensesAmt - Sum;
                UnriskFactExpenses.Modify();
            until UnriskFactExpenses.Next() <= 0;
            if Round(InitUnriskFactExpensesAmt, Currency."Amount Rounding Precision") <> 0 then begin
                UnriskFactExpenses.Find('+');
                UnriskFactExpenses.Amount := UnriskFactExpenses.Amount +
                  Round(InitUnriskFactExpensesAmt, Currency."Amount Rounding Precision");
                InitUnriskFactExpensesAmt := 0;
                UnriskFactExpenses.Modify();
            end;
        end;
        exit(UnriskFactExpenses.Count);
    end;

    procedure GetUnriskFactExpenses(var value: Record "BG/PO Post. Buffer"; Register: Integer)
    begin
        UnriskFactExpenses.SetRange(Account, Text1100008);
        UnriskFactExpenses.Find('-');
        if Register <> UnriskFactExpenses.Next(Register) then
            Error(Text1100002);
        value := UnriskFactExpenses;
    end;
}

