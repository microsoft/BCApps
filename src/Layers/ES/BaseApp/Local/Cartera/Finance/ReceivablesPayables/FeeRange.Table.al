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
            AutoFormatType = 0;
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
        Currency: Record Currency;
        OperationFee: Record "Operation Fee";
        TempDiscExpenses: Record "BG/PO Post. Buffer" temporary;
        TempCollExpenses: Record "BG/PO Post. Buffer" temporary;
        TempDiscInterests: Record "BG/PO Post. Buffer" temporary;
        TempRejExpenses: Record "BG/PO Post. Buffer" temporary;
        TempPmtOrdCollExpenses: Record "BG/PO Post. Buffer" temporary;
        TempRiskFactExpenses: Record "BG/PO Post. Buffer" temporary;
        TempUnriskFactExpenses: Record "BG/PO Post. Buffer" temporary;
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

        UntitledLbl: Label 'untitled';
        CollExpensesLbl: Label 'CollExpenses';
        OutOfRangeLbl: Label 'Out of Range';
        DiscExpensesLbl: Label 'DiscExpenses';
        DiscInterestsLbl: Label 'DiscInterests';
        RejExpensesLbl: Label 'RejExpenses';
        PmtOrdCollExpensesLbl: Label 'PmtOrdCollExpenses';
        RiskFactExpensesLbl: Label 'RiskFactExpenses';
        UnriskFactExpensesLbl: Label 'UnriskFactExpenses';

    procedure Caption(): Text
    var
        BankAcc: Record "Bank Account";
    begin
        if Code = '' then
            exit(UntitledLbl);
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

        TempCollExpenses.DeleteAll();
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
        if TempCollExpenses.Get(CollExpensesLbl, '', EntryNo) then begin
            TempCollExpenses.Amount := TempCollExpenses.Amount + Amount;
            TempCollExpenses.Modify();
        end else begin
            TempCollExpenses.Init();
            TempCollExpenses.Account := CollExpensesLbl;
            TempCollExpenses."Entry No." := EntryNo;
            // TempCollExpenses."Global Dimension 1 Code" := Dep;
            // TempCollExpenses."Global Dimension 2 Code" := Proj;
            TempCollExpenses.Amount := Amount;
            TempCollExpenses.Insert();
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
        TempDiscExpenses.DeleteAll();
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

        if TempDiscExpenses.Get(DiscExpensesLbl, '', EntryNo) then begin
            TempDiscExpenses.Amount := TempDiscExpenses.Amount + Amount;
            TempDiscExpenses.Modify();
        end else begin
            TempDiscExpenses.Init();
            TempDiscExpenses.Account := DiscExpensesLbl;
            TempDiscExpenses."Entry No." := EntryNo;
            // TempDiscExpenses."Global Dimension 1 Code" := Dep;
            // TempDiscExpenses."Global Dimension 2 Code" := Proj;
            TempDiscExpenses.Amount := Amount;
            TempDiscExpenses.Insert();
        end;
    end;

    procedure GetTotalDiscExpensesAmt(): Decimal
    begin
        exit(TotalDiscExpensesAmt);
    end;

    procedure NoRegsDiscExpenses(): Integer
    begin
        TempDiscExpenses.SetRange(Account, DiscExpensesLbl);
        if TempDiscExpenses.Find('-') and (InitDiscExpensesAmt <> 0) then begin
            Sum := 0;
            repeat
                Sum := Sum + TempDiscExpenses.Amount;
            until TempDiscExpenses.Next() <= 0;

            if Sum <> 0 then
                Factor := InitDiscExpensesAmt / Sum
            else
                Factor := 1;
            TempDiscExpenses.Find('-');
            repeat
                Sum := Round(TempDiscExpenses.Amount * Factor, Currency."Amount Rounding Precision");
                TempDiscExpenses.Amount := TempDiscExpenses.Amount + Sum;
                InitDiscExpensesAmt := InitDiscExpensesAmt - Sum;
                TempDiscExpenses.Modify();
            until TempDiscExpenses.Next() <= 0;
            if Round(InitDiscExpensesAmt, Currency."Amount Rounding Precision") <> 0 then begin
                TempDiscExpenses.Find('+');
                TempDiscExpenses.Amount := TempDiscExpenses.Amount + Round(InitDiscExpensesAmt, Currency."Amount Rounding Precision");
                InitDiscExpensesAmt := 0;
                TempDiscExpenses.Modify();
            end;
        end;
        exit(TempDiscExpenses.Count);
    end;

    procedure GetDiscExpensesAmt(var value: Record "BG/PO Post. Buffer"; Register: Integer)
    begin
        TempDiscExpenses.SetRange(Account, DiscExpensesLbl);
        TempDiscExpenses.Find('-');
        if Register <> TempDiscExpenses.Next(Register) then
            Error(OutOfRangeLbl);
        value := TempDiscExpenses;
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
        TempDiscInterests.DeleteAll();
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

        if TempDiscInterests.Get(DiscInterestsLbl, '', EntryNo) then begin
            TempDiscInterests.Amount := TempDiscInterests.Amount + Amount;
            TempDiscInterests.Modify();
        end else begin
            TempDiscInterests.Init();
            TempDiscInterests.Account := DiscInterestsLbl;
            TempDiscInterests."Entry No." := EntryNo;
            TempDiscInterests.Amount := Amount;
            TempDiscInterests.Insert();
        end;
    end;

    procedure GetTotalDiscInterestsAmt(): Decimal
    begin
        exit(TotalDiscInterestsAmt);
    end;

    procedure NoRegsDiscInterests(): Integer
    begin
        TempDiscInterests.SetRange(Account, DiscInterestsLbl);
        if TempDiscInterests.Find('-') and (InitDiscInterestsAmt <> 0) then begin
            Sum := 0;
            repeat
                Sum := Sum + TempDiscInterests.Amount;
            until TempDiscInterests.Next() <= 0;

            if Sum <> 0 then
                Factor := InitDiscInterestsAmt / Sum
            else
                Factor := 1;
            TempDiscInterests.Find('-');
            repeat
                Sum := Round(TempDiscInterests.Amount * Factor, Currency."Amount Rounding Precision");
                TempDiscInterests.Amount := TempDiscInterests.Amount + Sum;
                InitDiscInterestsAmt := InitDiscInterestsAmt - Sum;
                TempDiscInterests.Modify();
            until TempDiscInterests.Next() <= 0;
            if Round(InitDiscInterestsAmt, Currency."Amount Rounding Precision") <> 0 then begin
                TempDiscInterests.Find('+');
                TempDiscInterests.Amount := TempDiscInterests.Amount + Round(InitDiscInterestsAmt, Currency."Amount Rounding Precision");
                InitDiscInterestsAmt := 0;
                TempDiscInterests.Modify();
            end;
        end;
        exit(TempDiscInterests.Count);
    end;

    procedure GetDiscInterestsAmt(var value: Record "BG/PO Post. Buffer"; Register: Integer)
    begin
        TempDiscInterests.SetRange(Account, DiscInterestsLbl);
        TempDiscInterests.Find('-');
        if Register <> TempDiscInterests.Next(Register) then
            Error(OutOfRangeLbl);
        value := TempDiscInterests;
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
        TempRejExpenses.DeleteAll();
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

        if TempRejExpenses.Get(RejExpensesLbl, '', EntryNo) then begin
            TempRejExpenses.Amount := TempRejExpenses.Amount + Amount;
            TempRejExpenses.Modify();
        end else begin
            TempRejExpenses.Init();
            TempRejExpenses.Account := RejExpensesLbl;
            TempRejExpenses."Entry No." := EntryNo;
            TempRejExpenses.Amount := Amount;
            TempRejExpenses.Insert();
        end;
    end;

    procedure GetTotalRejExpensesAmt(): Decimal
    begin
        exit(TotalRejExpensesAmt);
    end;

    procedure NoRegRejExpenses(): Integer
    begin
        TempRejExpenses.SetRange(Account, RejExpensesLbl);
        if TempRejExpenses.Find('-') and (InitRejExpensesAmt <> 0) then begin
            Sum := 0;
            repeat
                Sum := Sum + TempRejExpenses.Amount;
            until TempRejExpenses.Next() <= 0;

            if Sum <> 0 then
                Factor := InitRejExpensesAmt / Sum
            else
                Factor := 1;
            TempRejExpenses.Find('-');
            repeat
                Sum := Round(TempRejExpenses.Amount * Factor, Currency."Amount Rounding Precision");
                TempRejExpenses.Amount := TempRejExpenses.Amount + Sum;
                InitRejExpensesAmt := InitRejExpensesAmt - Sum;
                TempRejExpenses.Modify();
            until TempRejExpenses.Next() <= 0;
            if Round(InitRejExpensesAmt, Currency."Amount Rounding Precision") <> 0 then begin
                TempRejExpenses.Find('+');
                TempRejExpenses.Amount := TempRejExpenses.Amount + Round(InitRejExpensesAmt, Currency."Amount Rounding Precision");
                InitRejExpensesAmt := 0;
                TempRejExpenses.Modify();
            end;
        end;
        exit(TempRejExpenses.Count);
    end;

    procedure GetRejExpensesAmt(var value: Record "BG/PO Post. Buffer"; Register: Integer)
    begin
        TempRejExpenses.SetRange(Account, RejExpensesLbl);
        TempRejExpenses.Find('-');
        if Register <> TempRejExpenses.Next(Register) then
            Error(OutOfRangeLbl);
        value := TempRejExpenses;
    end;

    procedure InitPmtOrdCollExpenses(Code2: Code[20]; CurrencyCode2: Code[10])
    begin
        "Currency Code" := CurrencyCode2;
        InitCurrency();
        TotalPmtOrdCollExpensesAmt := 0;
        if OperationFee.Get(Code2, CurrencyCode2, "Type of Fee"::"Payment Order Expenses") then
            TotalPmtOrdCollExpensesAmt :=
              Round(OperationFee."Charge Amt. per Operation", Currency."Amount Rounding Precision");

        TempPmtOrdCollExpenses.DeleteAll();
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

        if TempPmtOrdCollExpenses.Get(PmtOrdCollExpensesLbl, '', EntryNo) then begin
            TempPmtOrdCollExpenses.Amount := TempPmtOrdCollExpenses.Amount + Amount;
            TempPmtOrdCollExpenses.Modify();
        end else begin
            TempPmtOrdCollExpenses.Init();
            TempPmtOrdCollExpenses.Account := PmtOrdCollExpensesLbl;
            TempPmtOrdCollExpenses."Entry No." := EntryNo;
            TempPmtOrdCollExpenses.Amount := Amount;
            TempPmtOrdCollExpenses.Insert();
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
        TempRiskFactExpenses.DeleteAll();
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

        if TempRiskFactExpenses.Get(RiskFactExpensesLbl, '', EntryNo) then begin
            TempRiskFactExpenses.Amount := TempRiskFactExpenses.Amount + Amount;
            TempRiskFactExpenses.Modify();
        end else begin
            TempRiskFactExpenses.Init();
            TempRiskFactExpenses.Account := RiskFactExpensesLbl;
            TempRiskFactExpenses."Entry No." := EntryNo;
            TempRiskFactExpenses.Amount := Amount;
            TempRiskFactExpenses.Insert();
        end;
    end;

    procedure GetTotalRiskFactExpensesAmt(): Decimal
    begin
        exit(TotalRiskFactExpensesAmt);
    end;

    procedure NoRegRiskFactExpenses(): Integer
    begin
        TempRiskFactExpenses.SetRange(Account, RiskFactExpensesLbl);
        if TempRiskFactExpenses.Find('-') and (InitRiskFactExpensesAmt <> 0) then begin
            Sum := 0;
            repeat
                Sum := Sum + TempRiskFactExpenses.Amount;
            until TempRiskFactExpenses.Next() <= 0;

            if Sum <> 0 then
                Factor := InitRiskFactExpensesAmt / Sum
            else
                Factor := 1;
            TempRiskFactExpenses.Find('-');
            repeat
                Sum := Round(TempRiskFactExpenses.Amount * Factor, Currency."Amount Rounding Precision");
                TempRiskFactExpenses.Amount := TempRiskFactExpenses.Amount + Sum;
                InitRiskFactExpensesAmt := InitRiskFactExpensesAmt - Sum;
                TempRiskFactExpenses.Modify();
            until TempRiskFactExpenses.Next() <= 0;
            if Round(InitRiskFactExpensesAmt, Currency."Amount Rounding Precision") <> 0 then begin
                TempRiskFactExpenses.Find('+');
                TempRiskFactExpenses.Amount := TempRiskFactExpenses.Amount + Round(InitRiskFactExpensesAmt, Currency."Amount Rounding Precision");
                InitRiskFactExpensesAmt := 0;
                TempRiskFactExpenses.Modify();
            end;
        end;
        exit(TempRiskFactExpenses.Count);
    end;

    procedure GetRiskFactExpenses(var value: Record "BG/PO Post. Buffer"; Register: Integer)
    begin
        TempRiskFactExpenses.SetRange(Account, RiskFactExpensesLbl);
        TempRiskFactExpenses.Find('-');
        if Register <> TempRiskFactExpenses.Next(Register) then
            Error(OutOfRangeLbl);
        value := TempRiskFactExpenses;
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
        TempUnriskFactExpenses.DeleteAll();
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

        if TempUnriskFactExpenses.Get(UnriskFactExpensesLbl, '', EntryNo) then begin
            TempUnriskFactExpenses.Amount := TempUnriskFactExpenses.Amount + Amount;
            TempUnriskFactExpenses.Modify();
        end else begin
            TempUnriskFactExpenses.Init();
            TempUnriskFactExpenses.Account := UnriskFactExpensesLbl;
            TempUnriskFactExpenses."Entry No." := EntryNo;
            TempUnriskFactExpenses.Amount := Amount;
            TempUnriskFactExpenses.Insert();
        end;
    end;

    procedure GetTotalUnriskFactExpensesAmt(): Decimal
    begin
        exit(TotalUnriskFactExpensesAmt);
    end;

    procedure NoRegUnriskFactExpenses(): Integer
    begin
        TempUnriskFactExpenses.SetRange(Account, UnriskFactExpensesLbl);
        if TempUnriskFactExpenses.Find('-') and (InitUnriskFactExpensesAmt <> 0) then begin
            Sum := 0;
            repeat
                Sum := Sum + TempUnriskFactExpenses.Amount;
            until TempUnriskFactExpenses.Next() <= 0;

            if Sum <> 0 then
                Factor := InitUnriskFactExpensesAmt / Sum
            else
                Factor := 1;
            TempUnriskFactExpenses.Find('-');
            repeat
                Sum := Round(TempUnriskFactExpenses.Amount * Factor, Currency."Amount Rounding Precision");
                TempUnriskFactExpenses.Amount := TempUnriskFactExpenses.Amount + Sum;
                InitUnriskFactExpensesAmt := InitUnriskFactExpensesAmt - Sum;
                TempUnriskFactExpenses.Modify();
            until TempUnriskFactExpenses.Next() <= 0;
            if Round(InitUnriskFactExpensesAmt, Currency."Amount Rounding Precision") <> 0 then begin
                TempUnriskFactExpenses.Find('+');
                TempUnriskFactExpenses.Amount := TempUnriskFactExpenses.Amount +
                  Round(InitUnriskFactExpensesAmt, Currency."Amount Rounding Precision");
                InitUnriskFactExpensesAmt := 0;
                TempUnriskFactExpenses.Modify();
            end;
        end;
        exit(TempUnriskFactExpenses.Count);
    end;

    procedure GetUnriskFactExpenses(var value: Record "BG/PO Post. Buffer"; Register: Integer)
    begin
        TempUnriskFactExpenses.SetRange(Account, UnriskFactExpensesLbl);
        TempUnriskFactExpenses.Find('-');
        if Register <> TempUnriskFactExpenses.Next(Register) then
            Error(OutOfRangeLbl);
        value := TempUnriskFactExpenses;
    end;
}

