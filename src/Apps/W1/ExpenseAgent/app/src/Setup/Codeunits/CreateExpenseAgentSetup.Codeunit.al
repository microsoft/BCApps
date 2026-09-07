// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.UOM;

codeunit 6970 "Create Expense Agent Setup"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions =
        tabledata "Expense Agent Setup" = rim,
        tabledata "Source Code Setup" = rim;

    trigger OnRun()
    begin
        CreateSetupTable();
        UpdateSourceCodeSetup();
    end;

    local procedure CreateSetupTable()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        CreateExpenseNoSeries: Codeunit "Create Expense No. Series";
    begin
        if not ExpenseAgentSetup.Get() then begin
            ExpenseAgentSetup.Init();
            ExpenseAgentSetup.Insert();
        end;

        GeneralLedgerSetup.Get();

        if ExpenseAgentSetup."Expense Nos." = '' then
            ExpenseAgentSetup."Expense Nos." := CreateExpenseNoSeries.ExpenseNoSeries();
        if ExpenseAgentSetup."Expense User Nos." = '' then
            ExpenseAgentSetup."Expense User Nos." := CreateExpenseNoSeries.ExpenseUserSeries();
        if ExpenseAgentSetup."Expense Reports Nos." = '' then
            ExpenseAgentSetup."Expense Reports Nos." := CreateExpenseNoSeries.ExpenseReportNoSeries();
        if ExpenseAgentSetup."Posted Expense Reports Nos." = '' then
            ExpenseAgentSetup."Posted Expense Reports Nos." := CreateExpenseNoSeries.PostedExpenseReportNoSeries();
        if ExpenseAgentSetup."Expense Vendor Nos." = '' then
            ExpenseAgentSetup."Expense Vendor Nos." := CreateExpenseNoSeries.ExpenseVendorNoSeries();

        // Update Expense Payment Methods.
        CreateExpensePaymentMethod(CardTok, XCARDTxt, "Expense Reimbursement Type"::"Credit Card");
        CreateExpensePaymentMethod(CashTok, XCASHTxt, "Expense Reimbursement Type"::"Employee Paid");
        CreateExpensePaymentMethod(BankTok, XBANKTxt, "Expense Reimbursement Type"::"Company Paid");

        if Format(ExpenseAgentSetup."Do Not Allow Exp. Older Than") = '' then
            Evaluate(ExpenseAgentSetup."Do Not Allow Exp. Older Than", '<3M>');
        if not ExpenseAgentSetup."Allow Grp. of Trans. in Report" then
            ExpenseAgentSetup."Allow Grp. of Trans. in Report" := true;
        if not ExpenseAgentSetup."Check Category/SubCat. Usage" then
            ExpenseAgentSetup."Check Category/SubCat. Usage" := true;
        if ExpenseAgentSetup."Standard Rate of Mileage" = 0 then
            ExpenseAgentSetup."Standard Rate of Mileage" := 1.20;
        if ExpenseAgentSetup."Full Per-Diem Calculation" = ExpenseAgentSetup."Full Per-Diem Calculation"::None then
            ExpenseAgentSetup."Full Per-Diem Calculation" := ExpenseAgentSetup."Full Per-Diem Calculation"::"24-hour Rolling Period";
        if ExpenseAgentSetup."Minimum Hours for Per Diem" = 0 then
            ExpenseAgentSetup."Minimum Hours for Per Diem" := 12;
        if ExpenseAgentSetup."Reduction for Lunch %" = 0 then
            ExpenseAgentSetup."Reduction for Lunch %" := 30;
        if ExpenseAgentSetup."Reduction for Dinner %" = 0 then
            ExpenseAgentSetup."Reduction for Dinner %" := 20;
        if not ExpenseAgentSetup."Enable Anti-Corp. Statement" then
            ExpenseAgentSetup."Enable Anti-Corp. Statement" := true;
        if ExpenseAgentSetup."Default Mileage UOM" = '' then
            ExpenseAgentSetup."Default Mileage UOM" := GetDefaultMileageUOM();
        ExpenseAgentSetup.Modify(false);
    end;

    local procedure UpdateSourceCodeSetup()
    var
        SourceCode: Record "Source Code";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        if not SourceCode.Get(ExpenseTok) then begin
            SourceCode.Init();
            SourceCode.Code := ExpenseTok;
            SourceCode.Description := ExpenseDescriptionLbl;
            SourceCode.Insert();
        end;

        SourceCodeSetup.Get();
        SourceCodeSetup.Expense := ExpenseTok;
        SourceCodeSetup.Modify(false);
    end;

    internal procedure CreateDefaultPaymentMethods()
    var
        TempPaymentMethodSeed: Record "Expense Payment Method" temporary;
    begin
        BuildPaymentMethodSeeds(TempPaymentMethodSeed);
        if TempPaymentMethodSeed.FindSet() then
            repeat
                CreateExpensePaymentMethod(TempPaymentMethodSeed.Code, TempPaymentMethodSeed.Description, TempPaymentMethodSeed."Reimbursement Type");
            until TempPaymentMethodSeed.Next() = 0;
    end;

    /// <summary>
    /// Returns the catalogue of default expense payment methods without writing anything to the database.
    /// </summary>
    internal procedure BuildPaymentMethodSeeds(var TempExpensePaymentMethod: Record "Expense Payment Method" temporary)
    begin
        TempExpensePaymentMethod.Reset();
        TempExpensePaymentMethod.DeleteAll();

        AddPaymentMethodSeed(TempExpensePaymentMethod, CardTok, XCARDTxt, "Expense Reimbursement Type"::"Credit Card");
        AddPaymentMethodSeed(TempExpensePaymentMethod, CashTok, XCASHTxt, "Expense Reimbursement Type"::"Employee Paid");
        AddPaymentMethodSeed(TempExpensePaymentMethod, BankTok, XBANKTxt, "Expense Reimbursement Type"::"Company Paid");
    end;

    /// <summary>
    /// Builds the preview record set for expense payment methods: existing rows plus seeds that
    /// do not yet exist. A seed is skipped if an existing payment method already owns the same
    /// Reimbursement Type (the table enforces uniqueness of Reimbursement Type via OnValidate,
    /// so apply will skip it too). No database writes are performed.
    /// </summary>
    internal procedure LoadPaymentMethodsPreview(var TempExpensePaymentMethod: Record "Expense Payment Method" temporary)
    var
        ExistingPaymentMethod: Record "Expense Payment Method";
        TempSeed: Record "Expense Payment Method" temporary;
        ReimbursementOwners: Dictionary of [Integer, Code[10]];
    begin
        TempExpensePaymentMethod.Reset();
        TempExpensePaymentMethod.DeleteAll();

        if ExistingPaymentMethod.FindSet() then
            repeat
                TempExpensePaymentMethod := ExistingPaymentMethod;
                TempExpensePaymentMethod.Insert();

                // Track which Reimbursement Types are already owned by an existing code.
                if ExistingPaymentMethod."Reimbursement Type" <> ExistingPaymentMethod."Reimbursement Type"::" " then
                    if not ReimbursementOwners.ContainsKey(ExistingPaymentMethod."Reimbursement Type".AsInteger()) then
                        ReimbursementOwners.Add(ExistingPaymentMethod."Reimbursement Type".AsInteger(), ExistingPaymentMethod.Code);
            until ExistingPaymentMethod.Next() = 0;

        BuildPaymentMethodSeeds(TempSeed);
        if TempSeed.FindSet() then
            repeat
                if not TempExpensePaymentMethod.Get(TempSeed.Code) then
                    if not ReimbursementOwners.ContainsKey(TempSeed."Reimbursement Type".AsInteger()) then begin
                        TempExpensePaymentMethod := TempSeed;
                        TempExpensePaymentMethod.Insert();
                    end;
            until TempSeed.Next() = 0;
    end;

    local procedure AddPaymentMethodSeed(var TempExpensePaymentMethod: Record "Expense Payment Method" temporary; PaymentMethodCode: Code[10]; Description: Text[100]; ReimbursementType: Enum "Expense Reimbursement Type")
    begin
        TempExpensePaymentMethod.Init();
        TempExpensePaymentMethod.Code := PaymentMethodCode;
        TempExpensePaymentMethod.Description := Description;
        TempExpensePaymentMethod."Reimbursement Type" := ReimbursementType;
        TempExpensePaymentMethod.Insert();
    end;

    internal procedure GetMileageUOMStandardCodeFilter(): Text
    begin
        exit('SMI|MI|KMT|KM|1A');
    end;

    local procedure CreateExpensePaymentMethod(PaymentMethodCode: Code[10]; Description: Text[100]; ReimbursementType: Enum "Expense Reimbursement Type")
    var
        ExpensePaymentMethod: Record "Expense Payment Method";
    begin
        if ExpensePaymentMethod.Get(PaymentMethodCode) then
            exit;

        // The table's OnValidate on "Reimbursement Type" errors out on a duplicate, which would
        // abort the defaults run. Pre-check to decide skip vs. insert; once we've committed to
        // inserting, use Validate so the table's business logic is the source of truth.
        if ReimbursementType <> ReimbursementType::" " then begin
            ExpensePaymentMethod.SetRange("Reimbursement Type", ReimbursementType);
            if not ExpensePaymentMethod.IsEmpty() then
                exit;
            ExpensePaymentMethod.Reset();
        end;

        ExpensePaymentMethod.Init();
        ExpensePaymentMethod.Code := PaymentMethodCode;
        ExpensePaymentMethod.Description := Description;
        ExpensePaymentMethod.Validate("Reimbursement Type", ReimbursementType);
        ExpensePaymentMethod.Insert(true);
    end;

    internal procedure GetDefaultMileageUOM(): Code[10]
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        UnitOfMeasure.SetFilter("International Standard Code", 'SMI|MI');
        if UnitOfMeasure.FindFirst() then
            exit(UnitOfMeasure.Code);
        UnitOfMeasure.SetFilter("International Standard Code", 'KMT|KM');
        if UnitOfMeasure.FindFirst() then
            exit(UnitOfMeasure.Code);
        UnitOfMeasure.SetRange("International Standard Code");
        if UnitOfMeasure.Get(MilesCodeTxt) then
            exit(UnitOfMeasure.Code);
        if not UnitOfMeasure.WritePermission then
            exit('');

        UnitOfMeasure.Code := CopyStr(MilesCodeTxt, 1, MaxStrLen(UnitOfMeasure.Code));
        UnitOfMeasure.Description := CopyStr(MilesTxt, 1, MaxStrLen(UnitOfMeasure.Description));
        UnitOfMeasure."International Standard Code" := 'SMI';
        UnitOfMeasure.Symbol := 'mi';
        if UnitOfMeasure.Insert() then
            exit(UnitOfMeasure.Code);
        exit('');
    end;

    var
        ExpenseTok: Label 'EXPENSE', MaxLength = 10, Locked = true;
        ExpenseDescriptionLbl: Label 'Expenses', MaxLength = 100;
        CardTok: Label 'Card', Locked = true;
        CashTok: Label 'Cash', Locked = true;
        BankTok: Label 'Bank', Locked = true;
        XCARDTxt: Label 'Company credit card', MaxLength = 100;
        XCASHTxt: Label 'Cash paid by employee', MaxLength = 100;
        XBANKTxt: Label 'Company paid by bank transfer', MaxLength = 100;
        MilesTxt: Label 'Miles';
        MilesCodeTxt: Label 'MILES';
}
