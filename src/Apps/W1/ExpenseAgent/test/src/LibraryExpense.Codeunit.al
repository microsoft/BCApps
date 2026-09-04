// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SpendRequest;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Setup;
using System.Agents;
using System.Security.User;

codeunit 148300 "Library - Expense"
{
    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        FirstNameTxt: Label 'First Name';
        NameTxt: Label 'Name';

    /// <summary>
    /// Creates or reuses the Expense Agent and ensures that it is enabled for the current company.
    /// </summary>
    /// <returns>The user security ID of the enabled Expense Agent.</returns>
    internal procedure EnsureExpenseAgentEnabled(): Guid
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        Agent: Record Agent;
        TempAgentSetupBuffer: Record "Agent Setup Buffer" temporary;
        AgentSetup: Codeunit "Agent Setup";
        AgentUserSecurityId: Guid;
    begin
        if ExpenseAgentSetup.Get() then
            AgentUserSecurityId := ExpenseAgentSetup."User Security ID";

        if not IsNullGuid(AgentUserSecurityId) then
            if Agent.Get(AgentUserSecurityId) then begin
                AgentSetup.GetSetupRecord(
                    TempAgentSetupBuffer,
                    AgentUserSecurityId,
                    "Agent Metadata Provider"::"Expense Agent",
                    '',
                    '',
                    '');
                if TempAgentSetupBuffer.State <> TempAgentSetupBuffer.State::Enabled then begin
                    TempAgentSetupBuffer.Validate(State, TempAgentSetupBuffer.State::Enabled);
                    AgentUserSecurityId := AgentSetup.SaveChanges(TempAgentSetupBuffer);
                end;
                EnableExpenseAgentSetup(ExpenseAgentSetup, AgentUserSecurityId);
                exit(AgentUserSecurityId);
            end;

        Clear(AgentUserSecurityId);
        AgentSetup.GetSetupRecord(
            TempAgentSetupBuffer,
            AgentUserSecurityId,
            "Agent Metadata Provider"::"Expense Agent",
            CopyStr('Expense Agent - ' + CompanyName(), 1, MaxStrLen(TempAgentSetupBuffer."User Name")),
            CopyStr('Expense Agent - ' + CompanyName(), 1, MaxStrLen(TempAgentSetupBuffer."Display Name")),
            'Processes employee expenses for the current company.');
        TempAgentSetupBuffer.Validate(State, TempAgentSetupBuffer.State::Enabled);
        AgentUserSecurityId := AgentSetup.SaveChanges(TempAgentSetupBuffer);

        EnableExpenseAgentSetup(ExpenseAgentSetup, AgentUserSecurityId);
        exit(AgentUserSecurityId);
    end;

    internal procedure CreateExpenseUser(var ExpenseUser: Record "Expense User")
    begin
        ExpenseUser.Init();
        ExpenseUser.Validate("No.", LibraryUtility.GenerateRandomCode(ExpenseUser.FieldNo("No."), Database::"Expense User"));
        ExpenseUser.Validate("Employee No.", LibraryHumanResource.CreateEmployeeNo());
        ExpenseUser.Insert(true);
    end;

    procedure CreateEmployee(EmployeeNo: Code[20]): Code[20]
    var
        Employee: Record Employee;
    begin
        Employee.Init();
        Employee.Validate("No.", EmployeeNo);
        Employee.Validate("Employee Posting Group", LibraryHumanResource.FindEmployeePostingGroup());
        Employee.Insert(true);
        UpdateEmployeeName(Employee);
        Employee.Modify(true);

        exit(Employee."No.");
    end;

    procedure UpdateEmployeeName(var Employee: Record Employee)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(Employee);
        if LibraryUtility.CheckFieldExistenceInTable(Database::Employee, NameTxt) then
            FieldRef := RecRef.Field(LibraryUtility.FindFieldNoInTable(Database::Employee, NameTxt))
        else
            FieldRef := RecRef.Field(LibraryUtility.FindFieldNoInTable(Database::Employee, FirstNameTxt));
        FieldRef.Validate(Employee."No.");  // Validating Name as No. because value is not important.
        RecRef.SetTable(Employee);
    end;

    internal procedure CreateExpenseCategoryWithSubCategory(var ExpenseCategory: Record "Expense Category"; ReimbursementType: Enum "Expense Reimbursement Type"; ExpenseDetailRequired: Enum "Expense Detail Needed"; Refundable: Boolean)
    var
        ExpenseSubCategory: Record "Expense Subcategory";
    begin
        CreateExpenseCategory(ExpenseCategory, ReimbursementType, ExpenseDetailRequired);
        CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, Refundable);
    end;

    internal procedure CreateExpenseCategory(var ExpenseCategory: Record "Expense Category"; ReimbursementType: Enum "Expense Reimbursement Type"; ExpenseDetailRequired: Enum "Expense Detail Needed")
    begin
        CreateExpenseCategory(ExpenseCategory, ReimbursementType, ExpenseDetailRequired, '');
    end;

    internal procedure CreateExpenseCategory(var ExpenseCategory: Record "Expense Category"; ReimbursementType: Enum "Expense Reimbursement Type"; ExpenseDetailRequired: Enum "Expense Detail Needed"; PaymentMethodCode: Code[10])
    begin
        ExpenseCategory.Init();
        ExpenseCategory.Validate(Code, LibraryUtility.GenerateRandomCode(ExpenseCategory.FieldNo(Code), Database::"Expense Category"));
        ExpenseCategory.Validate(Description, LibraryUtility.GenerateRandomCode(ExpenseCategory.FieldNo(Description), Database::"Expense Category"));
        ExpenseCategory.Validate("Posting Description", LibraryUtility.GenerateRandomCode(ExpenseCategory.FieldNo("Posting Description"), Database::"Expense Category"));
        ExpenseCategory.Validate("Posting Group", FindExpensePostingGroup());
        ExpenseCategory.Validate("Expense Group", FindExpenseGroup());
        ExpenseCategory.Validate("Reimbursement Type", ReimbursementType);
        ExpenseCategory.Validate("Expense Detail Required", ExpenseDetailRequired);

        if PaymentMethodCode <> '' then
            ExpenseCategory.Validate("Default Payment Method", PaymentMethodCode);

        ExpenseCategory.Insert(true);
    end;

    internal procedure CreateExpenseSubCategory(var ExpenseSubCategory: Record "Expense Subcategory"; ExpenseCategoryCode: Code[20]; Refundable: Boolean)
    begin
        ExpenseSubCategory.Init();
        ExpenseSubCategory.Validate("Expense Category Code", ExpenseCategoryCode);
        ExpenseSubCategory.Validate(Code, LibraryUtility.GenerateRandomCode(ExpenseSubCategory.FieldNo(Code), Database::"Expense SubCategory"));
        ExpenseSubCategory.Validate(Description, LibraryUtility.GenerateRandomCode(ExpenseSubCategory.FieldNo(Description), Database::"Expense SubCategory"));
        ExpenseSubCategory.Validate("Posting Description", LibraryUtility.GenerateRandomCode(ExpenseSubCategory.FieldNo("Posting Description"), Database::"Expense SubCategory"));
        ExpenseSubCategory.Validate(Refundable, Refundable);
        ExpenseSubCategory.Insert(true);
    end;

    internal procedure CreateExpenseGroup(var ExpenseGroup: Record "Expense Group")
    begin
        ExpenseGroup.Init();
        ExpenseGroup.Validate(Code, LibraryUtility.GenerateRandomCode(ExpenseGroup.FieldNo(Code), Database::"Expense Group"));
        ExpenseGroup.Validate(Description, LibraryUtility.GenerateRandomCode(ExpenseGroup.FieldNo(Description), Database::"Expense Group"));
        ExpenseGroup.Insert(true);
    end;

    internal procedure CreateExpensePostingGroup(var ExpensePostingGroup: Record "Expense Posting Group")
    begin
        ExpensePostingGroup.Init();
        ExpensePostingGroup.Validate(Code, LibraryUtility.GenerateRandomCode(ExpensePostingGroup.FieldNo(Code), Database::"Expense Posting Group"));
        ExpensePostingGroup.Validate("Prepayment Credit Account", CreateExpenseCategoryGLAccountNo());
        ExpensePostingGroup.Validate("Refundable Debit Account", CreateExpenseCategoryGLAccountNo());
        ExpensePostingGroup.Validate("Non-Refundable Debit Account", CreateExpenseCategoryGLAccountNo());
        ExpensePostingGroup.Validate("Credit Rounding Account", CreateExpenseCategoryGLAccountNo());
        ExpensePostingGroup.Validate("Debit Rounding Account", CreateExpenseCategoryGLAccountNo());
        ExpensePostingGroup.Insert(true);
    end;

    internal procedure FindExpensePostingGroup(): Code[20]
    var
        ExpensePostingGroup: Record "Expense Posting Group";
    begin
        if not ExpensePostingGroup.FindFirst() then
            CreateExpensePostingGroup(ExpensePostingGroup);

        exit(ExpensePostingGroup.Code);
    end;

    internal procedure FindExpenseGroup(): Code[20]
    var
        ExpenseGroup: Record "Expense Group";
    begin
        if not ExpenseGroup.FindFirst() then
            CreateExpenseGroup(ExpenseGroup);

        exit(ExpenseGroup.Code);
    end;

    internal procedure CreateExpenseLocation(var ExpenseLocation: Record "Expense Location"; CountryRegionCode: Code[10]; City: Text[30])
    begin
        ExpenseLocation.Init();
        ExpenseLocation.Validate("No.", LibraryUtility.GenerateRandomCode(ExpenseLocation.FieldNo("No."), Database::"Expense Location"));
        ExpenseLocation.Validate(Description, LibraryUtility.GenerateRandomCode(ExpenseLocation.FieldNo(Description), Database::"Expense Location"));
        ExpenseLocation.Validate("Country/Region Code", CountryRegionCode);
        ExpenseLocation.Validate(City, City);
        ExpenseLocation.Insert(true);
    end;

    internal procedure CreateExpenseWithZeroVATPostingSetup(var Expense: Record Expense; ExpenseUserNo: Code[20]; ExpenseCategory: Code[20]; ExpenseSubCategory: Code[20]; LocationCode: Code[30]; Refundable: Boolean; CurrencyCode: Code[10]; Amount: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateExpense(Expense, ExpenseUserNo, ExpenseCategory, ExpenseSubCategory, LocationCode, Refundable, CurrencyCode, Amount);

        LibraryERM.FindZeroVATPostingSetup(VATPostingSetup, "Tax Calculation Type"::"Normal VAT");
        Expense.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Expense.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Expense.Modify();
    end;

    internal procedure CreateExpense(var Expense: Record Expense; ExpenseUserNo: Code[20]; ExpenseCategory: Code[20]; ExpenseSubCategory: Code[20]; LocationCode: Code[30]; Refundable: Boolean; CurrencyCode: Code[10]; Amount: Decimal)
    begin
        Expense.Init();
        Expense.Validate(Description, LibraryUtility.GenerateRandomCode(Expense.FieldNo(Description), Database::"Expense"));
        Expense.Validate("Expense Ext. Doc. No.", LibraryUtility.GenerateRandomCode(Expense.FieldNo("Expense Ext. Doc. No."), Database::"Expense"));
        Expense.Validate("Merchant Name", LibraryUtility.GenerateRandomCode(Expense.FieldNo("Merchant Name"), Database::"Expense"));
        Expense.Validate("Expense User No.", ExpenseUserNo);
        Expense.Validate("Expense Category", ExpenseCategory);
        Expense.Validate("Expense Subcategory", ExpenseSubCategory);
        Expense.Validate("Expense Date", WorkDate());
        Expense.Insert(true);

        if LocationCode <> '' then
            Expense.Validate("Expense Location", LocationCode);
        Expense.Validate("Currency Code", CurrencyCode);
        Expense.Validate(Amount, Amount);
        Expense.Validate(Refundable, Refundable);
        Expense.Modify();
    end;

    internal procedure FindExpensePaymentMethod(var ExpensePaymentMethod: Record "Expense Payment Method"; ReimbursementType: Enum "Expense Reimbursement Type")
    begin
        ExpensePaymentMethod.SetRange("Reimbursement Type", ReimbursementType);
        if not ExpensePaymentMethod.FindFirst() then
            CreateExpensePaymentMethod(ExpensePaymentMethod, ReimbursementType);
    end;

    internal procedure CreateExpensePaymentMethod(var ExpensePaymentMethod: Record "Expense Payment Method"; ReimbursementType: Enum "Expense Reimbursement Type")
    begin
        ExpensePaymentMethod.Init();
        ExpensePaymentMethod.Validate(
          Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(ExpensePaymentMethod.FieldNo(Code), Database::"Expense Payment Method"), 1,
            LibraryUtility.GetFieldLength(Database::"Expense Payment Method", ExpensePaymentMethod.FieldNo(Code))));
        ExpensePaymentMethod.Validate(Description, LibraryUtility.GenerateGUID());
        ExpensePaymentMethod.Validate("Reimbursement Type", ReimbursementType);
        ExpensePaymentMethod.Insert(true);
    end;

    internal procedure CreateExpenseReport(var ExpenseReportHeader: Record "Expense Report Header"; ExpenseUserNo: Code[20]; CurrencyCode: Code[10]; VATBusPostingGroup: Code[20])
    begin
        ExpenseReportHeader.Init();
        ExpenseReportHeader.Validate(Description, LibraryUtility.GenerateRandomCode(ExpenseReportHeader.FieldNo(Description), Database::"Expense Report Header"));
        ExpenseReportHeader.Validate("Expense User No.", ExpenseUserNo);
        ExpenseReportHeader.Validate("Reimbursement Currency Code", CurrencyCode);
        ExpenseReportHeader.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        ExpenseReportHeader.Insert(true);
    end;

    internal procedure CreateExpenseReportLine(var ExpenseReportLine: Record "Expense Report Line"; ExpenseReportHeader: Record "Expense Report Header"; ExpenseUserNo: Code[20]; ExpenseCategory: Code[20]; PaymentMethodCode: Code[10]; Refundable: Boolean; CurrencyCode: Code[10]; Amount: Decimal)
    var
        RecordRef: RecordRef;
    begin
        ExpenseReportLine.Init();
        ExpenseReportLine.Validate("Document No.", ExpenseReportHeader."No.");

        RecordRef.GetTable(ExpenseReportLine);
        ExpenseReportLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecordRef, ExpenseReportLine.FieldNo("Line No.")));
        ExpenseReportLine.Validate(Description, LibraryUtility.GenerateRandomCode(ExpenseReportLine.FieldNo(Description), Database::"Expense Report Line"));
        ExpenseReportLine.Validate("Expense Ext. Doc. No.", LibraryUtility.GenerateRandomCode(ExpenseReportLine.FieldNo("Expense Ext. Doc. No."), Database::"Expense Report Line"));
        ExpenseReportLine.Validate("Merchant Name", LibraryUtility.GenerateRandomCode(ExpenseReportLine.FieldNo("Merchant Name"), Database::"Expense Report Line"));
        ExpenseReportLine.Validate("Expense User No.", ExpenseUserNo);
        ExpenseReportLine.Validate("Expense Category", ExpenseCategory);
        ExpenseReportLine.Validate("Payment Method Code", PaymentMethodCode);
        ExpenseReportLine.Validate("Refundable", Refundable);
        ExpenseReportLine.Validate("Amount", Amount);
        ExpenseReportLine.Validate("Expense Currency Code", CurrencyCode);
        ExpenseReportLine.Insert(true);
    end;

    internal procedure CreateExpenseReportLine(var ExpenseReportLine: Record "Expense Report Line"; ExpenseReportHeader: Record "Expense Report Header"; ExpenseCategory: Code[20]; Billable: Boolean; BillableToCustomer: Code[20]; AccountType: Enum "Expense Line Type"; AccountNo: Code[20])
    var
        RecordRef: RecordRef;
    begin
        ExpenseReportLine.Init();
        ExpenseReportLine.Validate("Document No.", ExpenseReportHeader."No.");

        RecordRef.GetTable(ExpenseReportLine);
        ExpenseReportLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecordRef, ExpenseReportLine.FieldNo("Line No.")));
        ExpenseReportLine.Validate(Description, LibraryUtility.GenerateRandomCode(ExpenseReportLine.FieldNo(Description), Database::"Expense Report Line"));
        ExpenseReportLine.Validate("Expense Ext. Doc. No.", LibraryUtility.GenerateRandomCode(ExpenseReportLine.FieldNo("Expense Ext. Doc. No."), Database::"Expense Report Line"));
        ExpenseReportLine.Validate("Merchant Name", LibraryUtility.GenerateRandomCode(ExpenseReportLine.FieldNo("Merchant Name"), Database::"Expense Report Line"));
        ExpenseReportLine.Validate("Expense Category", ExpenseCategory);
        ExpenseReportLine.Validate(Billable, Billable);
        ExpenseReportLine.Validate("Billable to Customer", BillableToCustomer);
        ExpenseReportLine.Validate("Account Type", AccountType);
        ExpenseReportLine.Validate("Account No.", AccountNo);
        ExpenseReportLine.Insert(true);
    end;

    internal procedure CreateSpendRequest(var SpendRequest: Record "Spend Request")
    begin
        SpendRequest.Init();
        SpendRequest."Document Type" := SpendRequest."Document Type"::"Travel Request";
        SpendRequest.Insert(true);
    end;

    internal procedure CreateSpendRequestDetail(SpendRequestNo: Code[20]; ExpectedAmount: Decimal)
    var
        SpendRequestDetail: Record "Spend Request Detail";
        RecordRef: RecordRef;
    begin
        SpendRequestDetail.Init();
        SpendRequestDetail.Validate("Spend Request No.", SpendRequestNo);

        RecordRef.GetTable(SpendRequestDetail);
        SpendRequestDetail.Validate("Line No.", LibraryUtility.GetNewLineNo(RecordRef, SpendRequestDetail.FieldNo("Line No.")));
        SpendRequestDetail.Insert(true);
        SpendRequestDetail.Validate("Expected Amount", ExpectedAmount);
        SpendRequestDetail.Modify(true);
    end;

    internal procedure CreateTraveler(SpendRequestNo: Code[20]; ExpenseUserNo: Code[20])
    var
        Traveler: Record Traveler;
        RecordRef: RecordRef;
    begin
        Traveler.Init();
        Traveler.Validate("Spend Request No.", SpendRequestNo);

        RecordRef.GetTable(Traveler);
        Traveler.Validate("Line No.", LibraryUtility.GetNewLineNo(RecordRef, Traveler.FieldNo("Line No.")));
        Traveler.Insert(true);
        Traveler.Validate("Expense User No.", ExpenseUserNo);
        Traveler.Modify(true);
    end;

    internal procedure SetSpendRequestStatus(var SpendRequest: Record "Spend Request"; NewStatus: Enum "Spend Request Status")
    begin
        SpendRequest.Status := NewStatus;
        SpendRequest.Modify();
    end;

    procedure InitializeExpenseSourceCode()
    var
        SourceCode: Record "Source Code";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        if SourceCodeSetup.Expense <> '' then
            exit;

        LibraryERM.CreateSourceCode(SourceCode);
        SourceCodeSetup.Validate(Expense, SourceCode.Code);
        SourceCodeSetup.Modify();
    end;

    procedure SetupNumberSeriesInExpenseMgmt()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        HumanResourcesSetup: Record "Human Resources Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        ExpenseAgentSetup.Get();
        // Always assign fresh no. series so tests never inherit a partially-consumed series from a previous run.
        ExpenseAgentSetup.Validate("Expense Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        ExpenseAgentSetup.Validate("Expense User Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        ExpenseAgentSetup.Validate("Expense Vendor Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        ExpenseAgentSetup.Validate("Expense Reports Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        ExpenseAgentSetup.Validate("Posted Expense Reports Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        ExpenseAgentSetup.Modify(true);

        // Use fresh no. series so tests that create employees never consume the its entire no. series.
        HumanResourcesSetup.Get();
        HumanResourcesSetup.Validate("Employee Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        HumanResourcesSetup.Modify(true);

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Spend Request No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        GeneralLedgerSetup.Modify(true);
    end;

    procedure UpdateEnableApprovalWorkflowInAgentSetup(EnableApprovalWorkflow: Boolean)
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Enable Approval Workflow", EnableApprovalWorkflow);
        ExpenseAgentSetup.Modify(true);
    end;

    internal procedure UpdateExpenseRateForExpensesInAgentSetup(ExpenseRateForExpenses: Enum "Expense Exchange Rate")
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Exchange Rate for Expenses", ExpenseRateForExpenses);
        ExpenseAgentSetup.Modify(true);
    end;

    internal procedure UpdateUseRulesInAgentSetup(UseRules: Boolean)
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Use Rules", UseRules);
        ExpenseAgentSetup.Modify(true);
    end;

    internal procedure UpdateCreateEmpForExpenseUsersInAgentSetup(CreateEmpForExpenseUsers: Boolean)
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup."Create Emp. for Expense Users" := CreateEmpForExpenseUsers;
        ExpenseAgentSetup.Modify(true);
    end;

    internal procedure UpdateDefaultUnitOfMeasureInAgentSetup()
    var
        UnitOfMeasure: Record "Unit of Measure";
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Default Mileage UOM", UnitOfMeasure.Code);
        ExpenseAgentSetup.Modify(true);
    end;

    procedure UpdateReductionInAgentSetup(BreakfastReduction: Decimal; LunchReduction: Decimal; DinnerReduction: Decimal)
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Reduction for Breakfast %", BreakfastReduction);
        ExpenseAgentSetup.Validate("Reduction for Lunch %", LunchReduction);
        ExpenseAgentSetup.Validate("Reduction for Dinner %", DinnerReduction);
        ExpenseAgentSetup.Modify(true);
    end;

    internal procedure UpdatePerDiemInAgentSetup(FullPerDiemCalculation: Enum "Exp. Full Per Diem Calculation"; PartialDayRules: Enum "Expense Partial Day Rules"; PercentageForPartialDay: Decimal; MinimumHoursForPerDiem: Decimal; MinimumHoursForPartialPerDiem: Decimal)
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Full Per-Diem Calculation", FullPerDiemCalculation);
        ExpenseAgentSetup.Validate("Partial Day Rules", PartialDayRules);
        ExpenseAgentSetup.Validate("Percentage For Partial Day", PercentageForPartialDay);
        ExpenseAgentSetup.Validate("Minimum Hours for Per Diem", MinimumHoursForPerDiem);
        ExpenseAgentSetup.Validate("Min Hours for Partial Per Diem", MinimumHoursForPartialPerDiem);
        ExpenseAgentSetup.Modify(true);
    end;

    procedure UpdateExpenseAccountInEmployeePostingGroup(EmployeePostingGroupCode: Code[20])
    var
        EmployeePostingGroup: Record "Employee Posting Group";
    begin
        EmployeePostingGroup.Get(EmployeePostingGroupCode);
        if EmployeePostingGroup."Payables Account" = '' then
            EmployeePostingGroup.Validate("Payables Account", LibraryERM.CreateGLAccountNo());
        if EmployeePostingGroup."Expense Report Payable Account" = '' then
            EmployeePostingGroup.Validate("Expense Report Payable Account", LibraryERM.CreateGLAccountNo());
        if EmployeePostingGroup."Expense Payable Bank Paid Acc." = '' then
            EmployeePostingGroup.Validate("Expense Payable Bank Paid Acc.", LibraryERM.CreateGLAccountNo());
        if EmployeePostingGroup."Expense Payable Card Paid Acc." = '' then
            EmployeePostingGroup.Validate("Expense Payable Card Paid Acc.", LibraryERM.CreateGLAccountNo());
        if EmployeePostingGroup."Exp. Report Prepayment Account" = '' then
            EmployeePostingGroup.Validate("Exp. Report Prepayment Account", LibraryERM.CreateGLAccountNo());
        EmployeePostingGroup.Modify(true);
    end;

    internal procedure CreateExpenseRuleWithCondition(var ExpenseRuleHeader: Record "Expense Rule Header"; var ExpenseRuleCondition: Record "Expense Rule Condition"; ExpenseCategoryCode: Code[20]; ExpenseLocationCode: Code[20]; EffectiveDate: Date; JustificationRequired: Enum "Expense Justification"; CurrencyCode: Code[10]; UnitOfMeasureCode: Code[10]; ConditionType: Enum "Expense Rule Condition Type"; Value: Decimal)
    begin
        ExpenseRuleHeader.Init();
        ExpenseRuleHeader.Validate("Expense Category Code", ExpenseCategoryCode);
        ExpenseRuleHeader.Validate("Expense Location", ExpenseLocationCode);
        ExpenseRuleHeader.Validate("Effective Date", EffectiveDate);
        ExpenseRuleHeader.Validate("Justification Required", JustificationRequired);
        ExpenseRuleHeader.Validate("Currency Code", CurrencyCode);
        ExpenseRuleHeader.Validate("Unit of Measure Code", UnitOfMeasureCode);
        ExpenseRuleHeader.Insert(true);

        CreateExpenseRuleCondition(ExpenseRuleCondition, ExpenseRuleHeader, ConditionType, Value);
    end;

    internal procedure CreateExpenseRuleCondition(var ExpenseRuleCondition: Record "Expense Rule Condition"; ExpenseRuleHeader: Record "Expense Rule Header"; ConditionType: Enum "Expense Rule Condition Type"; Value: Decimal)
    var
        RecordRef: RecordRef;
    begin
        ExpenseRuleCondition.Init();
        ExpenseRuleCondition.Validate("Expense Category Code", ExpenseRuleHeader."Expense Category Code");
        ExpenseRuleCondition.Validate("Expense Location", ExpenseRuleHeader."Expense Location");
        ExpenseRuleCondition.Validate("Effective Date", ExpenseRuleHeader."Effective Date");
        RecordRef.GetTable(ExpenseRuleCondition);
        ExpenseRuleCondition.Validate("Line No.", LibraryUtility.GetNewLineNo(RecordRef, ExpenseRuleCondition.FieldNo("Line No.")));
        ExpenseRuleCondition.Validate("Condition Type", ConditionType);
        ExpenseRuleCondition.Validate(Value, Value);
        ExpenseRuleCondition.Insert(true);
    end;

    internal procedure CreateExpenseItemization(var ExpenseItemization: Record "Expense Itemization"; Expense: Record Expense; ExpenseCategoryCode: Code[20]; ExpenseSubcategoryCode: Code[20]; StartDate: Date; DailyRate: Decimal; Quantity: Decimal)
    var
        RecordRef: RecordRef;
    begin
        ExpenseItemization.Init();
        ExpenseItemization.Validate("Expense No.", Expense."No.");
        ExpenseItemization.Validate(Description, LibraryUtility.GenerateRandomCode(ExpenseItemization.FieldNo(Description), Database::"Expense Itemization"));
        RecordRef.GetTable(ExpenseItemization);
        ExpenseItemization.Validate("Line No.", LibraryUtility.GetNewLineNo(RecordRef, ExpenseItemization.FieldNo("Line No.")));
        ExpenseItemization.Validate("Expense Category Code", ExpenseCategoryCode);
        ExpenseItemization.Validate("Expense Subcategory Code", ExpenseSubcategoryCode);
        ExpenseItemization.Validate("Start Date", StartDate);
        ExpenseItemization.Validate("Quantity", Quantity);
        ExpenseItemization.Validate("Daily Rate", DailyRate);
        ExpenseItemization.Insert(true);
    end;

    internal procedure CreateExpenseReportLineItemization(var ExpenseReportLineItemization: Record "Expense Report Line Item"; ExpenseReportLine: Record "Expense Report Line"; ExpenseCategoryCode: Code[20]; ExpenseSubcategoryCode: Code[20]; StartDate: Date; DailyRate: Decimal; Quantity: Decimal)
    var
        RecordRef: RecordRef;
    begin
        ExpenseReportLineItemization.Init();
        ExpenseReportLineItemization.Validate("Expense Report No.", ExpenseReportLine."Document No.");
        ExpenseReportLineItemization.Validate("Expense Report Line No.", ExpenseReportLine."Line No.");
        ExpenseReportLineItemization.Validate(Description, LibraryUtility.GenerateRandomCode(ExpenseReportLineItemization.FieldNo(Description), Database::"Expense Report Line Item"));
        RecordRef.GetTable(ExpenseReportLineItemization);
        ExpenseReportLineItemization.Validate("Line No.", LibraryUtility.GetNewLineNo(RecordRef, ExpenseReportLineItemization.FieldNo("Line No.")));
        ExpenseReportLineItemization.Validate("Expense Category Code", ExpenseCategoryCode);
        ExpenseReportLineItemization.Validate("Expense Subcategory Code", ExpenseSubcategoryCode);
        ExpenseReportLineItemization.Validate("Start Date", StartDate);
        ExpenseReportLineItemization.Validate("Quantity", Quantity);
        ExpenseReportLineItemization.Validate("Daily Rate", DailyRate);
        ExpenseReportLineItemization.Insert(true);
    end;

    internal procedure CreateExpensePerDiem(var ExpensePerDiem: Record "Expense Per Diem"; Expense: Record Expense; ExpenseCategoryCode: Code[20]; ExpenseSubcategoryCode: Code[20]; ExpenseLocation: Code[30]; Date: Date; Breakfast: Boolean; Lunch: Boolean; Dinner: Boolean; PerDiemAmount: Decimal)
    var
        RecordRef: RecordRef;
    begin
        ExpensePerDiem.Init();
        ExpensePerDiem.Validate("Expense No.", Expense."No.");
        ExpensePerDiem.Validate(Description, LibraryUtility.GenerateRandomCode(ExpensePerDiem.FieldNo(Description), Database::"Expense Per Diem"));
        RecordRef.GetTable(ExpensePerDiem);
        ExpensePerDiem.Validate("Line No.", LibraryUtility.GetNewLineNo(RecordRef, ExpensePerDiem.FieldNo("Line No.")));
        ExpensePerDiem.Validate("Expense Category Code", ExpenseCategoryCode);
        ExpensePerDiem.Validate("Expense Subcategory Code", ExpenseSubcategoryCode);
        ExpensePerDiem.Validate("Expense Location", ExpenseLocation);
        ExpensePerDiem.Validate(Date, Date);
        ExpensePerDiem.Validate(Breakfast, Breakfast);
        ExpensePerDiem.Validate(Lunch, Lunch);
        ExpensePerDiem.Validate(Dinner, Dinner);
        ExpensePerDiem.Validate("Per Diem Amount", PerDiemAmount);
        ExpensePerDiem.Insert(true);
    end;

    internal procedure CreateExpenseReportLinePerDiem(var ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem"; ExpenseReportLine: Record "Expense Report Line"; ExpenseCategoryCode: Code[20]; ExpenseSubcategoryCode: Code[20]; ExpenseLocation: Code[30]; Date: Date; Breakfast: Boolean; Lunch: Boolean; Dinner: Boolean; PerDiemAmount: Decimal)
    var
        RecordRef: RecordRef;
    begin
        ExpenseReportLinePerDiem.Init();
        ExpenseReportLinePerDiem.Validate("Expense Report No.", ExpenseReportLine."Document No.");
        ExpenseReportLinePerDiem.Validate("Expense Report Line No.", ExpenseReportLine."Line No.");
        ExpenseReportLinePerDiem.Validate(Description, LibraryUtility.GenerateRandomCode(ExpenseReportLinePerDiem.FieldNo(Description), Database::"Expense Report Line Per Diem"));
        RecordRef.GetTable(ExpenseReportLinePerDiem);
        ExpenseReportLinePerDiem.Validate("Line No.", LibraryUtility.GetNewLineNo(RecordRef, ExpenseReportLinePerDiem.FieldNo("Line No.")));
        ExpenseReportLinePerDiem.Validate("Expense Category Code", ExpenseCategoryCode);
        ExpenseReportLinePerDiem.Validate("Expense Subcategory Code", ExpenseSubcategoryCode);
        ExpenseReportLinePerDiem.Validate("Expense Location", ExpenseLocation);
        ExpenseReportLinePerDiem.Validate(Date, Date);
        ExpenseReportLinePerDiem.Validate(Breakfast, Breakfast);
        ExpenseReportLinePerDiem.Validate(Lunch, Lunch);
        ExpenseReportLinePerDiem.Validate(Dinner, Dinner);
        ExpenseReportLinePerDiem.Validate("Per Diem Amount", PerDiemAmount);
        ExpenseReportLinePerDiem.Insert(true);
    end;

    internal procedure CreateExpenseParticipant(var ExpenseParticipant: Record "Expense Participant"; Expense: Record "Expense")
    var
        RecordRef: RecordRef;
    begin
        ExpenseParticipant.Init();
        ExpenseParticipant.Validate("Expense No.", Expense."No.");

        RecordRef.GetTable(ExpenseParticipant);
        ExpenseParticipant.Validate("Line No.", LibraryUtility.GetNewLineNo(RecordRef, ExpenseParticipant.FieldNo("Line No.")));
        ExpenseParticipant.Validate("Participant Type", ExpenseParticipant."Participant Type"::Employee);
        ExpenseParticipant.Validate("Participant Employee No.", LibraryHumanResource.CreateEmployeeNo());
        ExpenseParticipant.Insert(true);
    end;

    internal procedure CreateExpenseTeam(var ExpenseTeam: Record "Expense Team")
    begin
        ExpenseTeam.Init();
        ExpenseTeam.Validate(Code, LibraryUtility.GenerateRandomCode(ExpenseTeam.FieldNo(Code), Database::"Expense Team"));
        ExpenseTeam.Validate(Description, LibraryUtility.GenerateRandomCode(ExpenseTeam.FieldNo(Description), Database::"Expense Team"));
        ExpenseTeam.Insert(true);
    end;

    procedure SetExpenseAmountApprovalLimits(var UserSetup: Record "User Setup"; ExpenseApprovalLimit: Integer)
    begin
        UserSetup."Expense Amount Approval Limit" := ExpenseApprovalLimit;
        UserSetup.Modify(true);
    end;

    procedure SetLimitedExpenseApprovalLimits(var UserSetup: Record "User Setup")
    begin
        UserSetup."Unlimited Expense Approval" := false;
        UserSetup.Modify(true);
    end;

    procedure SetUnlimitedExpenseApprovalLimits(var UserSetup: Record "User Setup")
    begin
        UserSetup."Unlimited Expense Approval" := true;
        UserSetup.Modify(true);
    end;

    internal procedure CreateExpenseApprovalSetup(var ExpenseApprovalSetup: Record "Expense Approval Setup"; ExpenseUserNo: Code[20]; ApproverNo: Code[20])
    begin
        ExpenseApprovalSetup.Init();
        ExpenseApprovalSetup.Validate("Expense User No.", ExpenseUserNo);
        ExpenseApprovalSetup.Validate("Approver No.", ApproverNo);
        ExpenseApprovalSetup.Insert();
    end;

    internal procedure CreateExpensePolicy(var ExpensePolicy: Record "Expense Policy"; ExpenseCategoryCode: Code[20]; PolicyText: Text[2048])
    begin
        ExpensePolicy.Init();
        ExpensePolicy."Expense Category Code" := ExpenseCategoryCode;
        ExpensePolicy."Policy Text" := PolicyText;
        ExpensePolicy.Enabled := true;
        ExpensePolicy."Subject Type" := "Expense Policy Subject"::"Expense Report Line";
        ExpensePolicy.Insert(true);
    end;

    internal procedure CreateExpensePolicyEvaluation(var ExpensePolicyEvaluation: Record "Expense Policy Evaluation"; ExpenseReportLine: Record "Expense Report Line"; ExpensePolicy: Record "Expense Policy"; EvaluationReason: Text[2048]; Compliant: Boolean)
    begin
        ExpensePolicyEvaluation.Init();
        ExpensePolicyEvaluation."Subject System Id" := ExpenseReportLine.SystemId;
        ExpensePolicyEvaluation."Subject Type" := "Expense Policy Subject"::"Expense Report Line";
        ExpensePolicyEvaluation."Subject Version" := ExpenseReportLine."Policy Eval Version";
        ExpensePolicyEvaluation."Policy System Id" := ExpensePolicy.SystemId;
        ExpensePolicyEvaluation."Policy Version" := ExpensePolicy."Version";
        ExpensePolicyEvaluation.Reason := EvaluationReason;
        ExpensePolicyEvaluation.Compliant := Compliant;
        ExpensePolicyEvaluation.Insert(true);
    end;

    procedure CleanUpBeforeTesting()
    var
        ExpenseGroup: Record "Expense Group";
        ExpenseLocation: Record "Expense Location";
        ExpenseUser: Record "Expense User";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyEvaluation: Record "Expense Policy Evaluation";
    begin
        ExpenseGroup.DeleteAll();
        ExpenseUser.DeleteAll();
        ExpenseLocation.DeleteAll();

        // Codeunit test isolation keeps data written by earlier test methods, so shared policy
        // master data must be reset between tests. A leaked blank-category policy in particular
        // would otherwise apply to every report line and skew policy-status assertions.
        ExpensePolicyEvaluation.DeleteAll();
        ExpensePolicy.DeleteAll();

        // Ensure the agent is disabled so tests that toggle approval workflow don't fail
        // when the test environment was left with the agent enabled.
        if ExpenseAgentSetup.Get() then begin
            ExpenseAgentSetup."Enable Agent" := false;
            ExpenseAgentSetup."Default Approver No." := '';
            ExpenseAgentSetup.Modify();
        end;
    end;

    procedure CleanTransactionalData()
    var
        Expense: Record Expense;
        ExpenseItemization: Record "Expense Itemization";
        ExpenseParticipant: Record "Expense Participant";
        ExpensePerDiem: Record "Expense Per Diem";
        ExpenseVATSpecification: Record "Expense VAT Specification";
        ExpenseVendor: Record "Expense Vendor";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineItem: Record "Expense Report Line Item";
        ExpenseReportLineParticip: Record "Expense Report Line Particip.";
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
        ExpenseRuleViolation: Record "Expense Rule Violation";
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
    begin
        // First, clear expense report references to avoid "cannot delete attachment" validation.
        Expense.ModifyAll("Expense Report No.", '');

        DeleteExpenseAttachments();

        ExpenseReportLineItem.DeleteAll();
        ExpenseReportLineParticip.DeleteAll();
        ExpenseReportLinePerDiem.DeleteAll();
        ExpenseReportLine.DeleteAll();
        ExpenseActivityLogEntry.DeleteAll();
        ExpenseReportHeader.DeleteAll();
        ExpenseReportRuleViolation.DeleteAll();

        ExpenseParticipant.DeleteAll();
        ExpenseItemization.DeleteAll();
        ExpensePerDiem.DeleteAll();
        ExpenseVATSpecification.DeleteAll(false);

        Expense.DeleteAll();
        ExpenseRuleViolation.DeleteAll();
        ExpenseVendor.DeleteAll();
    end;

    local procedure EnableExpenseAgentSetup(
        var ExpenseAgentSetup: Record "Expense Agent Setup";
        AgentUserSecurityId: Guid)
    begin
        if not ExpenseAgentSetup.Get() then
            ExpenseAgentSetup.InitRecord();
        ExpenseAgentSetup."User Security ID" := AgentUserSecurityId;
        ExpenseAgentSetup.Validate("Enable Agent", true);
        ExpenseAgentSetup.Modify(false);
    end;

    local procedure DeleteExpenseAttachments()
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        DocumentAttachment.SetRange("Table ID", Database::Expense);
        DocumentAttachment.DeleteAll();

        DocumentAttachment.SetRange("Table ID", Database::"Expense Participant");
        DocumentAttachment.DeleteAll();

        DocumentAttachment.SetRange("Table ID", Database::"Expense Itemization");
        DocumentAttachment.DeleteAll();

        DocumentAttachment.SetRange("Table ID", Database::"Expense Per Diem");
        DocumentAttachment.DeleteAll();
    end;

    internal procedure UpdateDoNotAllowExpenseOlderThanInAgentSetup(DoNotAllowExpOlderThan: DateFormula)
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Do Not Allow Exp. Older Than", DoNotAllowExpOlderThan);
        ExpenseAgentSetup.Modify(true);
    end;

    internal procedure UpdateDoNotAllowExpenseOlderThanInAgentSetup(DoNotAllowExpOlderThanText: Text)
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        ExpenseAgentSetup.Get();

        RecRef.GetTable(ExpenseAgentSetup);
        FieldRef := RecRef.Field(ExpenseAgentSetup.FieldNo("Do Not Allow Exp. Older Than"));
        FieldRef.Validate(DoNotAllowExpOlderThanText);
        RecRef.SetTable(ExpenseAgentSetup);

        ExpenseAgentSetup.Modify(true);
    end;

    local procedure CreateExpenseCategoryGLAccountNo(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := LibraryERM.CreateGLAccountNo();
        GLAccount.Get(GLAccount."No.");
        GLAccount."Account Category" := GLAccount."Account Category"::Expense;
        GLAccount.Modify();
        exit(GLAccount."No.");
    end;

    internal procedure UpdateEnableAgentInAgentSetup(EnableAgent: Boolean)
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup."Enable Agent" := EnableAgent;
        ExpenseAgentSetup.Modify(true);
    end;
}