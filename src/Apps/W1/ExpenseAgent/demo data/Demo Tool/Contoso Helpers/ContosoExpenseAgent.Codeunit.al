// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.HumanResources.Employee;

codeunit 8205 "Contoso Expense Agent"
{
    InherentPermissions = X;
    InherentEntitlements = X;
    Permissions =
        tabledata "Expense" = rim,
        tabledata "Expense User" = rim,
        tabledata "Expense Payment Method" = rim,
        tabledata "Expense Group" = rim,
        tabledata "Expense Team" = rim,
        tabledata "Expense Location" = rim,
        tabledata "Expense Posting Group" = rim,
        tabledata "Expense Category" = rim,
        tabledata "Expense Subcategory" = rim,
        tabledata "Expense Rule Header" = rim,
        tabledata "Expense Rule Condition" = rim,
        tabledata "Expense Participant" = rim,
        tabledata "Expense Itemization" = rim,
        tabledata "Employee Posting Group" = rim,
        tabledata "Expense Report Header" = rim,
        tabledata "Expense Report Line" = rimd,
        tabledata "Expense Agent Setup" = r;

    var
        OverwriteData: Boolean;

    procedure SetOverwriteData(Overwrite: Boolean)
    begin
        OverwriteData := Overwrite;
    end;

    internal procedure InsertExpenseCategory(Code: Code[20]; Description: Text[250]; PostingDescription: Text[100]; PostingGroup: Code[20]; AttachmentEnforcement: Enum "Expense Attachment Enforcement"; DefaultPaymentMethodCode: Code[10]; IsPrepaymentCashAdvance: Boolean; Inactive: Boolean; ExpenseGroupCode: Code[20]; Refundable: Boolean; ReimbursementType: Enum "Expense Reimbursement Type"; ExpenseDetailRequired: Enum "Expense Detail Needed")
    var
        ExpenseCategory: Record "Expense Category";
        Exists: Boolean;
    begin
        if ExpenseCategory.Get(Code) then begin
            Exists := true;

            if not OverwriteData then
                exit;
        end;

        ExpenseCategory.Validate(Code, Code);
        ExpenseCategory.Validate(Description, Description);
        ExpenseCategory.Validate("Posting Description", PostingDescription);
        ExpenseCategory.Validate("Posting Group", PostingGroup);
        ExpenseCategory.Validate("Attachment Enforcement", AttachmentEnforcement);
        ExpenseCategory.Validate("Default Payment Method", DefaultPaymentMethodCode);
        ExpenseCategory.Validate("Prepayment-Cash Advance", IsPrepaymentCashAdvance);
        ExpenseCategory.Validate(Inactive, Inactive);
        ExpenseCategory.Validate("Expense Group", ExpenseGroupCode);
        ExpenseCategory.Validate(Refundable, Refundable);
        ExpenseCategory.Validate("Reimbursement Type", ReimbursementType);
        ExpenseCategory.Validate("Expense Detail Required", ExpenseDetailRequired);

        if Exists then
            ExpenseCategory.Modify(true)
        else
            ExpenseCategory.Insert(true);
    end;

    internal procedure InsertExpenseSubcategory(SubcategoryCode: Code[20]; CategoryCode: Code[20]; Description: Text[250]; PostingDescription: Text[100]; Inactive: Boolean; Refundable: Boolean; ExpenseDescriptionMandatory: Boolean)
    var
        ExpenseSubcategory: Record "Expense Subcategory";
        Exists: Boolean;
    begin
        if ExpenseSubcategory.Get(CategoryCode, SubcategoryCode) then begin
            Exists := true;

            if not OverwriteData then
                exit;
        end;

        ExpenseSubcategory.Validate(Code, SubcategoryCode);
        ExpenseSubcategory.Validate("Expense Category Code", CategoryCode);
        ExpenseSubcategory.Validate(Description, Description);
        ExpenseSubcategory.Validate("Posting Description", PostingDescription);
        ExpenseSubcategory.Validate(Inactive, Inactive);
        ExpenseSubcategory.Validate(Refundable, Refundable);
        ExpenseSubcategory.Validate("Expense Description Mandatory", ExpenseDescriptionMandatory);

        if Exists then
            ExpenseSubcategory.Modify(true)
        else
            ExpenseSubcategory.Insert(true);
    end;

    internal procedure InsertExpensePostingGroup(Code: Code[20]; Description: Text[100])
    var
        ExpensePostingGroup: Record "Expense Posting Group";
        Exists: Boolean;
    begin
        if ExpensePostingGroup.Get(Code) then begin
            Exists := true;

            if not OverwriteData then
                exit;
        end;

        ExpensePostingGroup.Validate(Code, Code);
        ExpensePostingGroup.Validate(Description, Description);

        if Exists then
            ExpensePostingGroup.Modify(true)
        else
            ExpensePostingGroup.Insert(true);
    end;

    internal procedure InsertExpensePaymentMethod(Code: Code[10]; Description: Text[100]; ReimbursementType: Enum "Expense Reimbursement Type")
    var
        ExpensePaymentMethod: Record "Expense Payment Method";
        Exists: Boolean;
    begin
        if ExpensePaymentMethod.Get(Code) then begin
            Exists := true;

            if not OverwriteData then
                exit;
        end;

        ExpensePaymentMethod.Validate(Code, Code);
        ExpensePaymentMethod.Validate(Description, Description);
        ExpensePaymentMethod.Validate("Reimbursement Type", ReimbursementType);

        if Exists then
            ExpensePaymentMethod.Modify(true)
        else
            ExpensePaymentMethod.Insert(true);
    end;

    internal procedure InsertExpenseGroup(Code: Code[20]; Description: Text[50])
    var
        ExpenseGroup: Record "Expense Group";
        Exists: Boolean;
    begin
        if ExpenseGroup.Get(Code) then begin
            Exists := true;

            if not OverwriteData then
                exit;
        end;

        ExpenseGroup.Validate(Code, Code);
        ExpenseGroup.Validate(Description, Description);

        if Exists then
            ExpenseGroup.Modify(true)
        else
            ExpenseGroup.Insert(true);
    end;

    internal procedure InsertExpenseLocation(Code: Code[20]; Description: Text[100]; CountryRegionCode: Code[10]; City: Text[30]; County: Text[30])
    var
        ExpenseLocation: Record "Expense Location";
        Exists: Boolean;
    begin
        if ExpenseLocation.Get(Code) then begin
            Exists := true;

            if not OverwriteData then
                exit;
        end;

        ExpenseLocation.Validate("No.", Code);
        ExpenseLocation.Validate(Description, Description);
        ExpenseLocation.Validate("Country/Region Code", CountryRegionCode);
        ExpenseLocation.Validate("City", City);
        ExpenseLocation.Validate("County", County);

        if Exists then
            ExpenseLocation.Modify(true)
        else
            ExpenseLocation.Insert(true);
    end;

    internal procedure InsertExpenseTeam(Code: Code[20]; Description: Text[100])
    var
        ExpenseTeam: Record "Expense Team";
        Exists: Boolean;
    begin
        if ExpenseTeam.Get(Code) then begin
            Exists := true;

            if not OverwriteData then
                exit;
        end;

        ExpenseTeam.Validate(Code, Code);
        ExpenseTeam.Validate(Description, Description);

        if Exists then
            ExpenseTeam.Modify(true)
        else
            ExpenseTeam.Insert(true);
    end;

    internal procedure InsertExpenseRuleHeader(ExpenseCategoryCode: Code[20]; ExpenseLocationCode: Code[20]; EffectiveDate: Date; JustificationRequired: Enum "Expense Justification"; RequiredSpecificMerchant: Boolean; SpecificMerchantName: Text[100]; CurrencyCode: Code[10]; UnitOfMeasureCode: Code[10])
    var
        ExpenseRuleHeader: Record "Expense Rule Header";
        Exists: Boolean;
    begin
        if ExpenseRuleHeader.Get(ExpenseCategoryCode, ExpenseLocationCode, EffectiveDate) then begin
            Exists := true;

            if not OverwriteData then
                exit;
        end;

        ExpenseRuleHeader.Validate("Expense Category Code", ExpenseCategoryCode);
        ExpenseRuleHeader.Validate("Expense Location", ExpenseLocationCode);
        ExpenseRuleHeader.Validate("Effective Date", EffectiveDate);
        ExpenseRuleHeader.Validate("Justification Required", JustificationRequired);
        ExpenseRuleHeader.Validate("Required Specific Merchant", RequiredSpecificMerchant);
        ExpenseRuleHeader.Validate("Specific Merchant Name", SpecificMerchantName);
        ExpenseRuleHeader.Validate("Currency Code", CurrencyCode);
        ExpenseRuleHeader.Validate("Unit of Measure Code", UnitOfMeasureCode);

        if Exists then
            ExpenseRuleHeader.Modify(true)
        else
            ExpenseRuleHeader.Insert(true);
    end;

    internal procedure InsertExpenseRuleCondition(ExpenseCategoryCode: Code[20]; ExpenseLocationCode: Code[20]; EffectiveDate: Date; LineNo: Integer; ConditionType: Enum "Expense Rule Condition Type"; Value: Decimal)
    var
        ExpenseRuleCondition: Record "Expense Rule Condition";
        Exists: Boolean;
    begin
        if ExpenseRuleCondition.Get(ExpenseCategoryCode, ExpenseLocationCode, EffectiveDate, LineNo) then begin
            Exists := true;

            if not OverwriteData then
                exit;
        end;

        ExpenseRuleCondition.Validate("Expense Category Code", ExpenseCategoryCode);
        ExpenseRuleCondition.Validate("Expense Location", ExpenseLocationCode);
        ExpenseRuleCondition.Validate("Effective Date", EffectiveDate);
        ExpenseRuleCondition.Validate("Line No.", LineNo);
        ExpenseRuleCondition.Validate("Condition Type", ConditionType);
        ExpenseRuleCondition.Validate(Value, Value);

        if Exists then
            ExpenseRuleCondition.Modify(true)
        else
            ExpenseRuleCondition.Insert(true);
    end;

    internal procedure InsertExpenseUser(Code: Code[20]; EmployeeNo: Code[20]; ExpenseTeamCode: Code[20]; TeamManager: Boolean)
    var
        ExpenseUser: Record "Expense User";
        Exists: Boolean;
    begin
        if ExpenseUser.Get(Code) then begin
            Exists := true;

            if not OverwriteData then
                exit;
        end;

        ExpenseUser.Validate("No.", Code);
        ExpenseUser.Validate("Employee No.", EmployeeNo);
        ExpenseUser.Validate("Expense Team Code", ExpenseTeamCode);
        ExpenseUser.Validate("Team Manager", TeamManager);

        if Exists then
            ExpenseUser.Modify(true)
        else
            ExpenseUser.Insert(true);
    end;

    internal procedure InsertExpense(ExpenseUserNo: Code[20]; ExpenseCategoryCode: Code[20]; ExpenseLocationCode: Code[30]; Description: Text[100]; Justification: Text[250]; ExpenseDate: Date; CurrencyCode: Code[10]; Amount: Decimal; MerchantName: Text[100]; PaymentMethodCode: Code[20]; Refundable: Boolean; Billable: Boolean; BillableToCustomer: Code[20]; StartingDateTime: DateTime; EndingDateTime: DateTime; NonRefundableAmount: Decimal; Mileage: Decimal; StartingPoint: Text[100]; EndingPoint: Text[100]; ExpenseExtDocNo: Text[30]; JobNo: Code[20]; JobTaskNo: Code[20]): Record Expense
    var
        Expense: Record Expense;
    begin
        Expense.Validate("Expense User No.", ExpenseUserNo);
        Expense.Validate("Expense Category", ExpenseCategoryCode);
        Expense.Validate("Expense Location", ExpenseLocationCode);
        Expense.Validate("Description", Description);
        Expense.Validate("Justification", Justification);
        Expense.Validate("Expense Date", ExpenseDate);

        ValidateCurrencyCodeInExpense(Expense, CurrencyCode);

        if Amount <> 0 then
            Expense.Validate("Amount", Amount);
        Expense.Validate("Merchant Name", MerchantName);
        Expense.Validate("Payment Method Code", PaymentMethodCode);
        Expense.Validate(Refundable, Refundable);
        Expense.Validate(Billable, Billable);
        Expense.Validate("Billable to Customer", BillableToCustomer);
        Expense.Validate("Starting Date and Time", StartingDateTime);
        Expense.Validate("Ending Date and Time", EndingDateTime);
        Expense.Validate("Non-Refundable Amount", NonRefundableAmount);
        if Mileage <> 0 then
            Expense.Validate("Mileage", Mileage);
        Expense.Validate("Starting Point", StartingPoint);
        Expense.Validate("Ending Point", EndingPoint);
        Expense.Validate("Expense Ext. Doc. No.", ExpenseExtDocNo);
        Expense.Validate("Job No.", JobNo);
        Expense.Validate("Job Task No.", JobTaskNo);
        Expense.Insert(true);

        exit(Expense);
    end;

    local procedure ValidateCurrencyCodeInExpense(var Expense: Record Expense; CurrencyCode: Code[10])
    begin
        OnBeforeValidateCurrencyCodeInExpense(CurrencyCode);

        if CurrencyCode <> '' then
            Expense.Validate("Currency Code", CurrencyCode);
    end;

    internal procedure InsertExpenseParticipant(ExpenseNo: Code[20]; LineNo: Integer; ExpenseCategoryCode: Code[20]; ParticipantType: Enum "Expense Participant Type"; ParticipantEmployeeNo: Code[20]; ParticipantName: Text[100]; ParticipantOrganization: Text[100]; ParticipantCountryRegionCode: Code[10]; ParticipantTitle: Text[30]; ParticipantEmail: Text[80])
    var
        ExpenseParticipant: Record "Expense Participant";
    begin
        ExpenseParticipant.Validate("Expense No.", ExpenseNo);
        ExpenseParticipant.Validate("Line No.", LineNo);
        ExpenseParticipant.Validate("Expense Category Code", ExpenseCategoryCode);
        ExpenseParticipant.Validate("Participant Type", ParticipantType);
        ExpenseParticipant.Validate("Participant Employee No.", ParticipantEmployeeNo);

        if ParticipantType = ParticipantType::External then begin
            ExpenseParticipant.Validate("Participant Name", ParticipantName);
            ExpenseParticipant.Validate("Participant Organization", ParticipantOrganization);
            ExpenseParticipant.Validate("Participant Country/Region", ParticipantCountryRegionCode);
            ExpenseParticipant.Validate("Participant Title", ParticipantTitle);
            ExpenseParticipant.Validate("Participant Email", ParticipantEmail);
        end;

        ExpenseParticipant.Insert(true);
    end;

    internal procedure InsertExpenseItemization(ExpenseNo: Code[20]; LineNo: Integer; ExpenseCategoryCode: Code[20]; ExpenseSubcategoryCode: Code[20]; Description: Text[100]; StartDate: Date; DailyRate: Decimal)
    var
        ExpenseItemization: Record "Expense Itemization";
    begin
        ExpenseItemization.Validate("Expense No.", ExpenseNo);
        ExpenseItemization.Validate("Line No.", LineNo);
        ExpenseItemization.Validate("Expense Category Code", ExpenseCategoryCode);
        ExpenseItemization.Validate("Expense Subcategory Code", ExpenseSubcategoryCode);
        ExpenseItemization.Validate(Description, Description);
        ExpenseItemization.Validate("Start Date", StartDate);
        ExpenseItemization.Validate("Daily Rate", DailyRate);
        ExpenseItemization.Insert(true);
    end;

    internal procedure InsertExpenseReportHeader(ExpenseUserNo: Code[20]; ExpenseReportDate: Date; PostingDate: Date): Record "Expense Report Header"
    var
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        ExpenseReportHeader.Validate("Expense User No.", ExpenseUserNo);
        ExpenseReportHeader.Validate("Expense Report Date", ExpenseReportDate);
        ExpenseReportHeader.Validate("Posting Date", PostingDate);
        ExpenseReportHeader.Insert(true);

        exit(ExpenseReportHeader);
    end;

    procedure UpdateEmployeePostingGroup(EmployeePostingGroupCode: Code[20]; ExpenseReportPayableAccount: Code[20]; ExpReportPrepaymentAccount: Code[20]; ExpensePayableBankPaidAcc: Code[20]; ExpensePayableCardPaidAcc: Code[20])
    var
        EmployeePostingGroup: Record "Employee Posting Group";
    begin
        if not OverwriteData then
            exit;

        EmployeePostingGroup.Get(EmployeePostingGroupCode);

        EmployeePostingGroup.Validate("Expense Report Payable Account", ExpenseReportPayableAccount);
        EmployeePostingGroup.Validate("Exp. Report Prepayment Account", ExpReportPrepaymentAccount);
        EmployeePostingGroup.Validate("Expense Payable Bank Paid Acc.", ExpensePayableBankPaidAcc);
        EmployeePostingGroup.Validate("Expense Payable Card Paid Acc.", ExpensePayableCardPaidAcc);
        EmployeePostingGroup.Modify(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCurrencyCodeInExpense(var CurrencyCode: Code[10])
    begin
    end;
}