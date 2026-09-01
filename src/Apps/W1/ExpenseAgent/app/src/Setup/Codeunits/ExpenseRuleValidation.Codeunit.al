// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.Currency;
using Microsoft.Foundation.Attachment;

codeunit 6902 "Expense Rule Validation"
{
    Access = Internal;

    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseAutoPopulation: Codeunit "Expense Auto Population";
        JustificationRequiredErr: Label 'Justification is required for this expense based on your organization''s rule.';
        ItemizationRequiredErr: Label 'Itemization is required for this expense based on your organization''s rule.';
        MissingExpenseSubCategoryErr: Label 'Expense Subcategories is required in order to add Itemization detail(s) for expense category code %1.', Comment = '%1 = Expense Category Code';
        ParticipantsRequiredErr: Label 'Participants are required for this expense based on your organization''s rule.';
        PerDiemRequiredErr: Label 'Per Diem details are required for this expense based on your organization''s rule.';
        MileageRequiredErr: Label 'Mileage details are required for this expense based on your organization''s rule.';
        RuleRestrictOnlyItemizationErr: Label 'Your organization''s rule requires only Itemization details for this expense. Please remove the extra %1 and try again.', Comment = '%1 = Extra detail types found (e.g., Participants, Per Diem, Mileage)';
        RuleRestrictOnlyParticipantsErr: Label 'Your organization''s rule requires only Participants details for this expense. Please remove the extra %1 and try again.', Comment = '%1 = Extra detail types found (e.g., Itemization, Per Diem, Mileage)';
        RuleRestrictOnlyPerDiemErr: Label 'Your organization''s rule requires only Per Diem details for this expense. Please remove the extra %1 and try again.', Comment = '%1 = Extra detail types found (e.g., Itemization, Participants, Mileage)';
        RuleRestrictOnlyMileageErr: Label 'Your organization''s rule requires only Mileage details for this expense. Please remove the extra %1 and try again.', Comment = '%1 = Extra detail types found (e.g., Itemization, Participants, Per Diem)';
        ItemizationTotalMismatchErr: Label 'Itemization total %1 must be equal to expense amount %2.', Comment = '%1 = Itemization total amount, %2 = Expense amount';
        ItemizationTotalReductionMismatchErr: Label 'Itemization total reduction %1 must be equal to expense reduction amount %2.', Comment = '%1 = Itemization total reduction amount, %2 = Expense reduction amount';
        MileageCalculationMismatchErr: Label 'Mileage calculation (%1 x %2 = %3) must equal expense amount (%4).', Comment = '%1 = Effective distance (mileage doubled if round trip), %2 = Standard rate, %3 = Calculated amount, %4 = Expense amount';
        FixAmountErr: Label 'Amount must equal %1 as defined by rule.', Comment = '%1 = Required fixed amount';
        MinAmountErr: Label 'Amount must be at least %1 as defined by rule.', Comment = '%1 = Minimum required amount';
        MaxAmountErr: Label 'Amount must not exceed %1 as defined by rule.', Comment = '%1 = Maximum allowed amount';
        CurrencyCodeErr: Label 'Currency Code must be %1 as defined by rule.', Comment = '%1 = Required currency code';
        UnitOfMeasureErr: Label 'Unit of Measure Code must be %1 as defined by rule.', Comment = '%1 = Required unit of measure code';
        ParticipantsItemizationLbl: Label 'Participants/Itemization';
        PerDiemLbl: Label 'Per Diem';
        MileageLbl: Label 'Mileage';
        AndLbl: Label ' and ';
        AdditionalDetailsLbl: Label 'additional details';
        ParticipantEmployeeMustBeRequiredInExpenseErr: Label '%1 must be required in Expense No.=%2, Line No.=%3.', Comment = '%1 = Field Caption, %2 = Expense No., %3 = Line No.';
        ParticipantEmployeeMustBeRequiredInExpenseReportErr: Label '%1 must be required in Expense Report No.=%2,Expense Report No.=%3, Line No.=%4.', Comment = '%1 = Field Caption, %2 = Expense Report No.,  %3 = Expense Report Line No., %4 = Line No.';
        ExpenseReportLineAttachmentMissingMsg: Label 'Attachments are missing in Expense Report No. %1 Line No. %2.', Comment = '%1 = Expense Report No., %2 = Line No.';
        ExpenseAttachmentMissingMsg: Label 'Attachments are missing in Expense No. %1.', Comment = '%1 = Expense No.';
        ERLDocumentAttachmentMandatoryMsg: Label 'Document Attachment is mandatory on Expense Report No. %1 Line No. %2', Comment = '%1 = Expense Report No., %2 = Line No.';
        ExpenseDocumentAttachmentMandatoryMsg: Label 'Document Attachment is mandatory on Expense No. %1', Comment = '%1 = Expense No.';
        ReceiptNoMandatoryOnExpenseErr: Label 'Receipt No. is mandatory on Expense No. %1', Comment = '%1 = Expense No.';
        ReceiptNoMandatoryOnReportLineErr: Label 'Receipt No. is mandatory on Expense Report No. %1, Line No. %2', Comment = '%1 = Expense Report No., %2 = Line No.';
        MerchantNameMandatoryOnExpenseErr: Label 'Merchant Name is mandatory on Expense No. %1', Comment = '%1 = Expense No.';
        MerchantNameMandatoryOnReportLineErr: Label 'Merchant Name is mandatory on Expense Report No. %1, Line No. %2', Comment = '%1 = Expense Report No., %2 = Line No.';
        ExpenseAlreadyExistErr: Label 'An expense already exists with the same Receipt No. %1, Expense Date %2, Merchant Name %3 and Amount %4.', Comment = '%1 = Receipt No., %2 = Expense Date, %3 = Merchant Name, %4 = Amount';
        ExpenseReportAlreadyExistErr: Label 'An expense report already exists with the same Receipt No. %1, Expense Date %2, Merchant Name %3 and Amount %4.', Comment = '%1 = Receipt No., %2 = Expense Date, %3 = Merchant Name, %4 = Amount';

    procedure ValidateExpenseAgainstRule(var Expense: Record Expense)
    var
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleViolation: Record "Expense Rule Violation";
    begin
        ExpenseRuleViolation.ClearRuleViolations(Expense."No.");
        InitialExpenseValidation(Expense);
        if not ShouldApplyRule(Expense."Expense Detail Required") then
            exit;

        if not ExpenseRuleHeader.FindApplicableRule(Expense) then
            exit;

        ValidateJustificationRequirement(Expense, ExpenseRuleHeader);
        ValidateAmountsByDetailType(Expense, ExpenseRuleHeader);
        ValidateRuleFields(Expense, ExpenseRuleHeader);
    end;

    procedure ShouldApplyRule(ExpenseDetailRequired: Enum "Expense Detail Needed"): Boolean
    begin
        ExpenseAgentSetup.GetRecordOnce();

        exit(ExpenseAgentSetup."Use Rules" or (ExpenseDetailRequired = ExpenseDetailRequired::"Per Diem"));
    end;

    procedure ValidateItemizationAmount(ExpenseNo: Code[20]; JustWarning: Boolean)
    var
        Expense: Record Expense;
        ExpenseItemization: Record "Expense Itemization";
        ExpenseRuleViolation: Record "Expense Rule Violation";
        TotalReductionAmount: Decimal;
    begin
        Expense.Get(ExpenseNo);

        if not (Expense."Expense Detail Required" = Expense."Expense Detail Required"::Itemize) then
            exit;

        ExpenseItemization.SetRange("Expense No.", ExpenseNo);
        if not ExpenseItemization.IsEmpty() then
            ExpenseItemization.CalcSums(Amount);

        if Expense.Amount <> ExpenseItemization.Amount then
            if JustWarning then
                Message(ItemizationTotalMismatchErr, ExpenseItemization.Amount, Expense.Amount)
            else
                ExpenseRuleViolation.AddRuleViolation(ExpenseNo, StrSubstNo(ItemizationTotalMismatchErr, ExpenseItemization.Amount, Expense.Amount));

        if not JustWarning then begin
            ExpenseItemization.SetRange(Refundable, false);
            if not ExpenseItemization.IsEmpty() then begin
                ExpenseItemization.CalcSums(Amount);
                TotalReductionAmount := ExpenseItemization.Amount;
            end;

            if TotalReductionAmount <> Expense."Non-Refundable Amount" then
                ExpenseRuleViolation.AddRuleViolation(Expense."No.", StrSubstNo(ItemizationTotalReductionMismatchErr, TotalReductionAmount, Expense."Non-Refundable Amount"));
        end;
    end;

    local procedure InitialExpenseValidation(var Expense: Record Expense)
    var
        ExpenseRuleViolation: Record "Expense Rule Violation";
    begin
        ExpenseAgentSetup.GetRecordOnce();

        CheckAttachmentsOnExpense(Expense);
        CheckForDuplicateExpense(Expense);

        if ExpenseAgentSetup."Receipt No. Mandatory" then
            if (Expense."Expense Ext. Doc. No." = '') and (Expense."Expense Detail Required" <> Expense."Expense Detail Required"::Mileage) then
                ExpenseRuleViolation.AddRuleViolation(Expense."No.", StrSubstNo(ReceiptNoMandatoryOnExpenseErr, Expense."No."));

        if ExpenseAgentSetup."Merchant Name Mandatory" then
            if (Expense."Merchant Name" = '') and (Expense."Expense Detail Required" <> Expense."Expense Detail Required"::Mileage) then
                ExpenseRuleViolation.AddRuleViolation(Expense."No.", StrSubstNo(MerchantNameMandatoryOnExpenseErr, Expense."No."));

        ValidateExpenseDetailRequirement(Expense);
        ValidateAmountsByDetailType(Expense);
    end;

    local procedure InitialExpenseReportLineValidation(var ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
    begin
        ExpenseAgentSetup.GetRecordOnce();

        CheckAttachmentsOnExpenseReportLine(ExpenseReportLine);
        CheckForDuplicateExpenseReportLine(ExpenseReportLine);

        if ExpenseAgentSetup."Receipt No. Mandatory" then
            if (ExpenseReportLine."Expense Ext. Doc. No." = '') and (ExpenseReportLine."Expense Detail Required" <> ExpenseReportLine."Expense Detail Required"::Mileage) then
                ExpenseReportRuleViolation.AddRuleViolation(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", StrSubstNo(ReceiptNoMandatoryOnReportLineErr, ExpenseReportLine."Document No.", ExpenseReportLine."Line No."));

        if ExpenseAgentSetup."Merchant Name Mandatory" then
            if (ExpenseReportLine."Merchant Name" = '') and (ExpenseReportLine."Expense Detail Required" <> ExpenseReportLine."Expense Detail Required"::Mileage) then
                ExpenseReportRuleViolation.AddRuleViolation(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", StrSubstNo(MerchantNameMandatoryOnReportLineErr, ExpenseReportLine."Document No.", ExpenseReportLine."Line No."));

        ValidateExpenseDetailRequirementForReportLine(ExpenseReportLine);
        ValidateAmountsByDetailTypeForReportLine(ExpenseReportLine);
    end;

    local procedure ValidateJustificationRequirement(Expense: Record Expense; ExpenseRuleHeader: Record "Expense Rule Header")
    var
        ExpenseRuleViolation: Record "Expense Rule Violation";
        JustificationRequired: Boolean;
    begin
        case ExpenseRuleHeader."Justification Required" of
            ExpenseRuleHeader."Justification Required"::" ":
                exit;
            ExpenseRuleHeader."Justification Required"::Always:
                JustificationRequired := true;
            ExpenseRuleHeader."Justification Required"::"Against Conditions":
                JustificationRequired := CheckJustificationFromConditions(Expense, ExpenseRuleHeader);
        end;

        if JustificationRequired and (Expense.Justification = '') then
            ExpenseRuleViolation.AddRuleViolation(Expense."No.", JustificationRequiredErr);
    end;

    local procedure CheckJustificationFromConditions(Expense: Record Expense; ExpenseRuleHeader: Record "Expense Rule Header"): Boolean
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        Amount: Decimal;
        AmountLCY: Decimal;
        CurrencyFactor: Decimal;
    begin
        Amount := Expense.Amount - Expense."Non-Refundable Amount";
        AmountLCY := Expense."Amount (LCY)" - Expense."Non-Refundable Amount (LCY)";

        if Expense."Currency Code" <> ExpenseRuleHeader."Currency Code" then
            if ExpenseRuleHeader."Currency Code" <> '' then begin
                Currency.Get(ExpenseRuleHeader."Currency Code");
                CurrencyFactor := CurrencyExchangeRate.ExchangeRate(Expense."Expense Date", ExpenseRuleHeader."Currency Code");
                Amount :=
                    Round(
                        CurrencyExchangeRate.ExchangeAmtLCYToFCY(Expense."Expense Date", ExpenseRuleHeader."Currency Code", AmountLCY, CurrencyFactor),
                        Currency."Amount Rounding Precision");
            end else
                Amount := AmountLCY;

        ExpenseRuleCondition.SetRange("Expense Category Code", ExpenseRuleHeader."Expense Category Code");
        ExpenseRuleCondition.SetRange("Expense Location", ExpenseRuleHeader."Expense Location");
        ExpenseRuleCondition.SetRange("Effective Date", ExpenseRuleHeader."Effective Date");
        ExpenseRuleCondition.SetRange("Condition Type", ExpenseRuleCondition."Condition Type"::"At Least Justification Needed");

        if ExpenseRuleCondition.FindSet() then
            repeat
                if Amount >= ExpenseRuleCondition.Value then
                    exit(true);
            until ExpenseRuleCondition.Next() = 0;

        exit(false);
    end;

    local procedure CheckAttachmentsOnExpense(Expense: Record Expense)
    var
        ExpenseCategory: Record "Expense Category";
    begin
        if not ExpenseCategory.Get(Expense."Expense Category") then
            exit;

        CheckForAttachmentsByRuleOnExpense(ExpenseCategory."Attachment Enforcement", Expense);
    end;

    local procedure CheckAttachmentsOnExpenseReportLine(ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseCategory: Record "Expense Category";
    begin
        if not ExpenseCategory.Get(ExpenseReportLine."Expense Category") then
            exit;

        CheckForAttachmentsByRuleOnExpenseReportLine(ExpenseCategory."Attachment Enforcement", ExpenseReportLine);
    end;

    local procedure CheckForAttachmentsByRuleOnExpense(AttachmentEnforcement: Enum "Expense Attachment Enforcement"; Expense: Record Expense)
    var
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
        RecRef: RecordRef;
    begin
        RecallExpenseAttachmentNotification();
        RecRef.GetTable(Expense);

        case AttachmentEnforcement of
            Enum::"Expense Attachment Enforcement"::" ":
                exit;
            Enum::"Expense Attachment Enforcement"::Warning:
                if not DocumentAttachmentMgmt.AttachedDocumentsExist(RecRef) then
                    ShowMissingAttachmentNotification(Expense);
            Enum::"Expense Attachment Enforcement"::Error:
                if not DocumentAttachmentMgmt.AttachedDocumentsExist(RecRef) then
                    AddMissingAttachmentViolation(Expense);
        end;
    end;

    local procedure CheckForAttachmentsByRuleOnExpenseReportLine(AttachmentEnforcement: Enum "Expense Attachment Enforcement"; ExpenseReportLine: Record "Expense Report Line")
    var
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
        RecRef: RecordRef;
    begin
        RecallExpenseReportLineAttachmentNotification();
        RecRef.GetTable(ExpenseReportLine);

        case AttachmentEnforcement of
            Enum::"Expense Attachment Enforcement"::" ":
                exit;
            Enum::"Expense Attachment Enforcement"::Warning:
                if not DocumentAttachmentMgmt.AttachedDocumentsExist(RecRef) then
                    ShowMissingAttachmentNotification(ExpenseReportLine);
            Enum::"Expense Attachment Enforcement"::Error:
                if not DocumentAttachmentMgmt.AttachedDocumentsExist(RecRef) then
                    AddMissingAttachmentViolation(ExpenseReportLine);
        end;
    end;

    local procedure AddMissingAttachmentViolation(Expense: Record Expense)
    var
        ExpenseRuleViolation: Record "Expense Rule Violation";
    begin
        ExpenseRuleViolation.AddRuleViolation(Expense."No.", StrSubstNo(ExpenseDocumentAttachmentMandatoryMsg, Expense."No."));
    end;

    local procedure AddMissingAttachmentViolation(ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
    begin
        ExpenseReportRuleViolation.AddRuleViolation(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", StrSubstNo(ERLDocumentAttachmentMandatoryMsg, ExpenseReportLine."Document No.", ExpenseReportLine."Line No."));
    end;

    local procedure ShowMissingAttachmentNotification(Expense: Record Expense)
    var
        AttachmentMissingNotification: Notification;
    begin
        AttachmentMissingNotification.Id := GetExpenseAttachmentMissingNotificationGuid();
        AttachmentMissingNotification.Message(StrSubstNo(ExpenseAttachmentMissingMsg, Expense."No."));
        AttachmentMissingNotification.Scope := NotificationScope::LocalScope;
        AttachmentMissingNotification.Send();
    end;

    local procedure RecallExpenseAttachmentNotification()
    var
        AttachmentMissingNotification: Notification;
    begin
        AttachmentMissingNotification.Id := GetExpenseAttachmentMissingNotificationGuid();
        AttachmentMissingNotification.Recall();
    end;

    local procedure RecallExpenseReportLineAttachmentNotification()
    var
        AttachmentMissingNotification: Notification;
    begin
        AttachmentMissingNotification.Id := GetExpenseReportLineAttachmentMissingNotificationGuid();
        AttachmentMissingNotification.Recall();
    end;

    local procedure CheckForDuplicateExpense(Expense: Record Expense)
    var
        DuplicateExpense: Record Expense;
        ExpenseRuleViolation: Record "Expense Rule Violation";
    begin
        DuplicateExpense.SetRange("Expense Ext. Doc. No.", Expense."Expense Ext. Doc. No.");
        DuplicateExpense.SetRange("Expense Date", Expense."Expense Date");
        DuplicateExpense.SetRange("Merchant Name", Expense."Merchant Name");
        DuplicateExpense.SetRange(Amount, Expense.Amount);
        DuplicateExpense.SetFilter("No.", '<>%1', Expense."No.");
        if not DuplicateExpense.IsEmpty() then
            ExpenseRuleViolation.AddRuleViolation(Expense."No.", StrSubstNo(ExpenseAlreadyExistErr, Expense."Expense Ext. Doc. No.", Expense."Expense Date", Expense."Merchant Name", Expense.Amount));
    end;

    local procedure GetExpenseAttachmentMissingNotificationGuid(): Guid
    begin
        exit('8e4c044a-17f0-49ea-b7a7-5ad1ed31172b');
    end;

    local procedure GetExpenseReportLineAttachmentMissingNotificationGuid(): Guid
    begin
        exit('a0f1e8f4-153b-4787-b552-8b184af930dc');
    end;

    local procedure CheckForDuplicateExpenseReportLine(ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
        DuplicateFound: Boolean;
    begin
        DuplicateFound := ExistDuplicateInExpenseReportLine(ExpenseReportLine);

        if not DuplicateFound then
            DuplicateFound := ExistDuplicateInPostedExpenseReportLine(ExpenseReportLine);

        if DuplicateFound then
            ExpenseReportRuleViolation.AddRuleViolation(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", StrSubstNo(ExpenseReportAlreadyExistErr, ExpenseReportLine."Expense Ext. Doc. No.", ExpenseReportLine."Expense Date", ExpenseReportLine."Merchant Name", ExpenseReportLine.Amount));
    end;

    local procedure ExistDuplicateInExpenseReportLine(ExpenseReportLine: Record "Expense Report Line"): Boolean
    var
        DuplicateExpenseReportLine: Record "Expense Report Line";
    begin
        DuplicateExpenseReportLine.SetRange("Expense Ext. Doc. No.", ExpenseReportLine."Expense Ext. Doc. No.");
        DuplicateExpenseReportLine.SetRange("Expense Date", ExpenseReportLine."Expense Date");
        DuplicateExpenseReportLine.SetRange("Merchant Name", ExpenseReportLine."Merchant Name");
        DuplicateExpenseReportLine.SetRange(Amount, ExpenseReportLine.Amount);
        DuplicateExpenseReportLine.SetFilter(SystemId, '<>%1', ExpenseReportLine.SystemId); // Exclude current record to not consider it as duplicate of itself.
        if not DuplicateExpenseReportLine.IsEmpty() then
            exit(true);
    end;

    local procedure ExistDuplicateInPostedExpenseReportLine(ExpenseReportLine: Record "Expense Report Line"): Boolean
    var
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        NegativeExpenseDateFormula: DateFormula;
    begin
        PostedExpenseReportLine.SetRange("Expense Ext. Doc. No.", ExpenseReportLine."Expense Ext. Doc. No.");
        if TryGetNegativeExpenseDateFormula(NegativeExpenseDateFormula) then
            PostedExpenseReportLine.SetRange("Expense Date", CalcDate(NegativeExpenseDateFormula, Today()), Today())
        else
            PostedExpenseReportLine.SetRange("Expense Date", ExpenseReportLine."Expense Date");

        PostedExpenseReportLine.SetRange("Merchant Name", ExpenseReportLine."Merchant Name");
        PostedExpenseReportLine.SetRange(Amount, ExpenseReportLine.Amount);
        if not PostedExpenseReportLine.IsEmpty() then
            exit(true);
    end;

    local procedure TryGetNegativeExpenseDateFormula(var NegativeExpenseAgeFormula: DateFormula): Boolean
    var
        DateFormulaText: Text;
    begin
        DateFormulaText := DelChr(Format(ExpenseAgentSetup."Do Not Allow Exp. Older Than", 0, 9), '=', '<>');
        if DateFormulaText = '' then
            exit(false);

        if not DateFormulaText.StartsWith('-') then
            DateFormulaText := '-' + DateFormulaText;

        exit(Evaluate(NegativeExpenseAgeFormula, '<' + DateFormulaText + '>', 9));
    end;

    local procedure ShowMissingAttachmentNotification(ExpenseReportLine: Record "Expense Report Line")
    var
        AttachmentMissingNotification: Notification;
    begin
        AttachmentMissingNotification.Id := GetExpenseReportLineAttachmentMissingNotificationGuid();
        AttachmentMissingNotification.Message(StrSubstNo(ExpenseReportLineAttachmentMissingMsg, ExpenseReportLine."Document No.", ExpenseReportLine."Line No."));
        AttachmentMissingNotification.Scope := NotificationScope::LocalScope;
        AttachmentMissingNotification.Send();
    end;

    local procedure ValidateExpenseDetailRequirement(Expense: Record Expense)
    begin
        case Expense."Expense Detail Required" of
            Expense."Expense Detail Required"::" ":
                exit;
            Expense."Expense Detail Required"::Itemize:
                ValidateItemizationRequired(Expense);
            Expense."Expense Detail Required"::Participants:
                ValidateParticipantsRequired(Expense);
            Expense."Expense Detail Required"::"Per Diem":
                ValidatePerDiemRequired(Expense);
            Expense."Expense Detail Required"::Mileage:
                ValidateMileageRequired(Expense);
        end;

        ValidateRuleRestriction(Expense);
    end;

    local procedure ValidateItemizationRequired(Expense: Record Expense)
    var
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseItemization: Record "Expense Itemization";
        ExpenseRuleViolation: Record "Expense Rule Violation";
    begin
        ExpenseSubCategory.SetRange("Expense Category Code", Expense."Expense Category");
        if ExpenseSubCategory.IsEmpty() then begin
            ExpenseRuleViolation.AddRuleViolation(Expense."No.", StrSubstNo(MissingExpenseSubCategoryErr, Expense."Expense Category"));
            exit;
        end;

        ExpenseItemization.SetRange("Expense No.", Expense."No.");
        if ExpenseItemization.IsEmpty() then
            ExpenseRuleViolation.AddRuleViolation(Expense."No.", ItemizationRequiredErr);
    end;

    local procedure ValidateParticipantsRequired(Expense: Record Expense)
    var
        ExpenseParticipant: Record "Expense Participant";
        ExpenseRuleViolation: Record "Expense Rule Violation";
    begin
        ExpenseParticipant.SetRange("Expense No.", Expense."No.");
        if ExpenseParticipant.IsEmpty() then
            ExpenseRuleViolation.AddRuleViolation(Expense."No.", ParticipantsRequiredErr);

        if ExpenseParticipant.FindSet() then
            repeat
                if ExpenseParticipant."Participant Type" = ExpenseParticipant."Participant Type"::Employee then
                    if ExpenseParticipant."Participant Employee No." = '' then
                        ExpenseRuleViolation.AddRuleViolation(
                            Expense."No.",
                            StrSubstNo(ParticipantEmployeeMustBeRequiredInExpenseErr, ExpenseParticipant.FieldCaption("Participant Employee No."), ExpenseParticipant."Expense No.", ExpenseParticipant."Line No."));
            until ExpenseParticipant.Next() = 0;
    end;

    local procedure ValidatePerDiemRequired(Expense: Record Expense)
    var
        ExpensePerDiem: Record "Expense Per Diem";
        ExpenseRuleViolation: Record "Expense Rule Violation";
    begin
        ExpensePerDiem.SetRange("Expense No.", Expense."No.");
        if ExpensePerDiem.IsEmpty() then
            ExpenseRuleViolation.AddRuleViolation(Expense."No.", PerDiemRequiredErr);
    end;

    local procedure ValidateMileageRequired(Expense: Record Expense)
    var
        ExpenseRuleViolation: Record "Expense Rule Violation";
    begin
        if Expense.Mileage <= 0 then
            ExpenseRuleViolation.AddRuleViolation(Expense."No.", MileageRequiredErr);
    end;

    local procedure ValidateRuleRestriction(Expense: Record Expense)
    var
        ExpenseItemization: Record "Expense Itemization";
        ExpenseParticipant: Record "Expense Participant";
        ExpensePerDiem: Record "Expense Per Diem";
        ExpenseRuleViolation: Record "Expense Rule Violation";
        HasItemization: Boolean;
        HasParticipants: Boolean;
        HasPerDiem: Boolean;
        HasMileage: Boolean;
    begin
        ExpenseItemization.SetRange("Expense No.", Expense."No.");
        HasItemization := not ExpenseItemization.IsEmpty();

        ExpenseParticipant.SetRange("Expense No.", Expense."No.");
        HasParticipants := not ExpenseParticipant.IsEmpty();

        ExpensePerDiem.SetRange("Expense No.", Expense."No.");
        HasPerDiem := not ExpensePerDiem.IsEmpty();

        HasMileage := Expense.Mileage > 0;

        case Expense."Expense Detail Required" of
            Expense."Expense Detail Required"::Itemize:
                if HasParticipants or HasPerDiem or HasMileage then
                    ExpenseRuleViolation.AddRuleViolation(Expense."No.", StrSubstNo(RuleRestrictOnlyItemizationErr,
                        BuildExtraDetailsMessage(HasParticipants, HasPerDiem, HasMileage)));
            Expense."Expense Detail Required"::Participants:
                if HasItemization or HasPerDiem or HasMileage then
                    ExpenseRuleViolation.AddRuleViolation(Expense."No.", StrSubstNo(RuleRestrictOnlyParticipantsErr,
                        BuildExtraDetailsMessage(HasItemization, HasPerDiem, HasMileage)));
            Expense."Expense Detail Required"::"Per Diem":
                if HasItemization or HasParticipants or HasMileage then
                    ExpenseRuleViolation.AddRuleViolation(Expense."No.", StrSubstNo(RuleRestrictOnlyPerDiemErr,
                        BuildExtraDetailsMessage(HasItemization, HasParticipants, HasMileage)));
            Expense."Expense Detail Required"::Mileage:
                if HasItemization or HasParticipants or HasPerDiem then
                    ExpenseRuleViolation.AddRuleViolation(Expense."No.", StrSubstNo(RuleRestrictOnlyMileageErr,
                        BuildExtraDetailsMessage(HasItemization, HasParticipants, HasPerDiem)));
        end;
    end;

    local procedure ValidateAmountsByDetailType(Expense: Record Expense; ExpenseRuleHeader: Record "Expense Rule Header")
    begin
        case Expense."Expense Detail Required" of
            Expense."Expense Detail Required"::Itemize:
                ValidateItemizationAmounts(Expense, ExpenseRuleHeader);
            Expense."Expense Detail Required"::Participants:
                ValidateParticipantsAmounts(Expense, ExpenseRuleHeader);
            Expense."Expense Detail Required"::Mileage:
                ValidateMileageAmounts(Expense, ExpenseRuleHeader);
        end;
    end;

    local procedure ValidateItemizationAmounts(Expense: Record Expense; ExpenseRuleHeader: Record "Expense Rule Header")
    begin
        ValidateAmountConditions(Expense."No.", Expense.Amount - Expense."Non-Refundable Amount", Expense."Amount (LCY)" - Expense."Non-Refundable Amount (LCY)", Expense."Currency Code", Expense."Expense Date", ExpenseRuleHeader);
    end;

    local procedure ValidateParticipantsAmounts(Expense: Record Expense; ExpenseRuleHeader: Record "Expense Rule Header")
    begin
        ValidateAmountConditions(Expense."No.", Expense.Amount - Expense."Non-Refundable Amount", Expense."Amount (LCY)" - Expense."Non-Refundable Amount (LCY)", Expense."Currency Code", Expense."Expense Date", ExpenseRuleHeader);
    end;

    local procedure ValidateMileageAmounts(Expense: Record Expense; ExpenseRuleHeader: Record "Expense Rule Header")
    begin
        ValidateAmountConditions(Expense."No.", Expense.Amount - Expense."Non-Refundable Amount", Expense."Amount (LCY)" - Expense."Non-Refundable Amount (LCY)", Expense."Currency Code", Expense."Expense Date", ExpenseRuleHeader);
    end;

    local procedure ValidateAmountConditions(ExpenseNo: Code[20]; Amount: Decimal; AmountLCY: Decimal; ExpenseCurrencyCode: Code[10]; ExpenseDate: Date; ExpenseRuleHeader: Record "Expense Rule Header")
    var
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseRuleViolation: Record "Expense Rule Violation";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
        CurrencyFactor: Decimal;
    begin
        if ExpenseCurrencyCode <> ExpenseRuleHeader."Currency Code" then
            if ExpenseRuleHeader."Currency Code" <> '' then begin
                Currency.Get(ExpenseRuleHeader."Currency Code");
                CurrencyFactor := CurrencyExchangeRate.ExchangeRate(ExpenseDate, ExpenseRuleHeader."Currency Code");
                Amount :=
                    Round(
                        CurrencyExchangeRate.ExchangeAmtLCYToFCY(ExpenseDate, ExpenseRuleHeader."Currency Code", AmountLCY, CurrencyFactor),
                        Currency."Amount Rounding Precision");
            end else
                Amount := AmountLCY;

        ExpenseRuleCondition.SetRange("Expense Category Code", ExpenseRuleHeader."Expense Category Code");
        ExpenseRuleCondition.SetRange("Expense Location", ExpenseRuleHeader."Expense Location");
        ExpenseRuleCondition.SetRange("Effective Date", ExpenseRuleHeader."Effective Date");

        if ExpenseRuleCondition.FindSet() then
            repeat
                case ExpenseRuleCondition."Condition Type" of
                    ExpenseRuleCondition."Condition Type"::" ":
                        ;
                    ExpenseRuleCondition."Condition Type"::"Fix Amount":
                        if Amount <> ExpenseRuleCondition.Value then
                            ExpenseRuleViolation.AddRuleViolation(ExpenseNo, StrSubstNo(FixAmountErr, ExpenseRuleCondition.Value));
                    ExpenseRuleCondition."Condition Type"::"Min Amount":
                        if Amount < ExpenseRuleCondition.Value then
                            ExpenseRuleViolation.AddRuleViolation(ExpenseNo, StrSubstNo(MinAmountErr, ExpenseRuleCondition.Value));
                    ExpenseRuleCondition."Condition Type"::"Max Amount":
                        if Amount > ExpenseRuleCondition.Value then
                            ExpenseRuleViolation.AddRuleViolation(ExpenseNo, StrSubstNo(MaxAmountErr, ExpenseRuleCondition.Value));
                end;
            until ExpenseRuleCondition.Next() = 0;
    end;

    local procedure ValidateAmountsByDetailType(Expense: Record Expense)
    begin
        case Expense."Expense Detail Required" of
            Expense."Expense Detail Required"::Itemize:
                ValidateItemizationAmounts(Expense);
            Expense."Expense Detail Required"::Mileage:
                ValidateMileageAmounts(Expense);
        end;
    end;

    local procedure ValidateItemizationAmounts(Expense: Record Expense)
    var
        ExpenseItemization: Record "Expense Itemization";
        ExpenseRuleViolation: Record "Expense Rule Violation";
        TotalAmount: Decimal;
        TotalReductionAmount: Decimal;
    begin
        ExpenseItemization.SetRange("Expense No.", Expense."No.");
        ExpenseItemization.CalcSums(Amount);
        TotalAmount := ExpenseItemization.Amount;

        ExpenseItemization.SetRange(Refundable, false);
        ExpenseItemization.CalcSums(Amount);
        TotalReductionAmount := ExpenseItemization.Amount;

        if TotalAmount <> Expense.Amount then
            ExpenseRuleViolation.AddRuleViolation(Expense."No.", StrSubstNo(ItemizationTotalMismatchErr, TotalAmount, Expense.Amount));

        if TotalReductionAmount <> Expense."Non-Refundable Amount" then
            ExpenseRuleViolation.AddRuleViolation(Expense."No.", StrSubstNo(ItemizationTotalReductionMismatchErr, TotalReductionAmount, Expense."Non-Refundable Amount"));
    end;

    local procedure ValidateMileageAmounts(Expense: Record Expense)
    var
        ExpenseCurrency: Record Currency;
        ExpenseRuleViolation: Record "Expense Rule Violation";
        StandardRate: Decimal;
        CalculatedAmount: Decimal;
        EffectiveDistance: Decimal;
    begin
        if Expense."Currency Code" = '' then
            ExpenseCurrency.InitRoundingPrecision()
        else
            ExpenseCurrency.Get(Expense."Currency Code");

        StandardRate := ExpenseAutoPopulation.GetStandardRateOfMileage(Expense."Expense Date", Expense."Currency Code", Expense."Currency Factor", ExpenseAgentSetup."Standard Rate of Mileage", Expense."Vehicle Type");
        EffectiveDistance := ExpenseAutoPopulation.GetEffectiveDistance(Expense.Mileage, Expense."Round Trip");
        CalculatedAmount := Round(EffectiveDistance * StandardRate, ExpenseCurrency."Amount Rounding Precision");

        if CalculatedAmount <> Expense.Amount then
            ExpenseRuleViolation.AddRuleViolation(Expense."No.", StrSubstNo(MileageCalculationMismatchErr, EffectiveDistance, StandardRate, CalculatedAmount, Expense.Amount));
    end;

    local procedure BuildExtraDetailsMessage(HasFirst: Boolean; HasSecond: Boolean; HasThird: Boolean): Text
    var
        ExtraItems: Text;
    begin
        ExtraItems := '';

        if HasFirst then
            ExtraItems := ParticipantsItemizationLbl;

        if HasSecond then
            if ExtraItems <> '' then
                ExtraItems := ExtraItems + AndLbl + PerDiemLbl
            else
                ExtraItems := PerDiemLbl;

        if HasThird then
            if ExtraItems <> '' then
                ExtraItems := ExtraItems + AndLbl + MileageLbl
            else
                ExtraItems := MileageLbl;

        if ExtraItems = '' then
            ExtraItems := AdditionalDetailsLbl;

        exit(ExtraItems);
    end;

    procedure ValidateExpenseReportLineAgainstRule(var ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
    begin
        ExpenseReportRuleViolation.ClearRuleViolations(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        InitialExpenseReportLineValidation(ExpenseReportLine);
        if not ShouldApplyRule(ExpenseReportLine."Expense Detail Required") then
            exit;

        if not ExpenseRuleHeader.FindApplicableRule(ExpenseReportLine) then
            exit;

        ValidateJustificationRequirementForReportLine(ExpenseReportLine, ExpenseRuleHeader);
        ValidateAmountsByDetailTypeForReportLine(ExpenseReportLine, ExpenseRuleHeader);
        ValidateRuleFieldsForReportLine(ExpenseReportLine, ExpenseRuleHeader);
    end;

    procedure ValidateItemizationAmount(ExpenseReportLine: Record "Expense Report Line"; JustWarning: Boolean)
    var
        ExpenseReportLineItemization: Record "Expense Report Line Item";
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
        TotalReductionAmount: Decimal;
    begin
        if not (ExpenseReportLine."Expense Detail Required" = ExpenseReportLine."Expense Detail Required"::Itemize) then
            exit;

        ExpenseReportLineItemization.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        ExpenseReportLineItemization.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        if not ExpenseReportLineItemization.IsEmpty() then
            ExpenseReportLineItemization.CalcSums(Amount);

        if ExpenseReportLine.Amount <> ExpenseReportLineItemization.Amount then
            if JustWarning then
                Message(ItemizationTotalMismatchErr, ExpenseReportLineItemization.Amount, ExpenseReportLine.Amount)
            else
                ExpenseReportRuleViolation.AddRuleViolation(
                    ExpenseReportLine."Document No.",
                    ExpenseReportLine."Line No.",
                    StrSubstNo(ItemizationTotalMismatchErr, ExpenseReportLineItemization.Amount, ExpenseReportLine.Amount));

        if not JustWarning then begin
            ExpenseReportLineItemization.SetRange(Refundable, false);
            if not ExpenseReportLineItemization.IsEmpty() then begin
                ExpenseReportLineItemization.CalcSums(Amount);
                TotalReductionAmount := ExpenseReportLineItemization.Amount;
            end;

            if TotalReductionAmount <> ExpenseReportLine."Non-Refundable Amount" then
                ExpenseReportRuleViolation.AddRuleViolation(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", StrSubstNo(ItemizationTotalReductionMismatchErr, TotalReductionAmount, ExpenseReportLine."Non-Refundable Amount"));
        end;
    end;

    local procedure ValidateJustificationRequirementForReportLine(ExpenseReportLine: Record "Expense Report Line"; ExpenseRuleHeader: Record "Expense Rule Header")
    var
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
        JustificationRequired: Boolean;
    begin
        case ExpenseRuleHeader."Justification Required" of
            ExpenseRuleHeader."Justification Required"::" ":
                exit;
            ExpenseRuleHeader."Justification Required"::Always:
                JustificationRequired := true;
            ExpenseRuleHeader."Justification Required"::"Against Conditions":
                JustificationRequired := CheckJustificationFromConditionsForReportLine(ExpenseReportLine, ExpenseRuleHeader);
        end;

        if JustificationRequired and (ExpenseReportLine.Justification = '') then
            ExpenseReportRuleViolation.AddRuleViolation(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", JustificationRequiredErr);
    end;

    local procedure ValidateExpenseDetailRequirementForReportLine(ExpenseReportLine: Record "Expense Report Line")
    begin
        case ExpenseReportLine."Expense Detail Required" of
            ExpenseReportLine."Expense Detail Required"::" ":
                exit;
            ExpenseReportLine."Expense Detail Required"::Itemize:
                ValidateItemizationRequiredForReportLine(ExpenseReportLine);
            ExpenseReportLine."Expense Detail Required"::Participants:
                ValidateParticipantsRequiredForReportLine(ExpenseReportLine);
            ExpenseReportLine."Expense Detail Required"::"Per Diem":
                ValidatePerDiemRequiredForReportLine(ExpenseReportLine);
            ExpenseReportLine."Expense Detail Required"::Mileage:
                ValidateMileageRequiredForReportLine(ExpenseReportLine);
        end;

        ValidateRuleRestrictionForReportLine(ExpenseReportLine);
    end;

    local procedure ValidateItemizationRequiredForReportLine(ExpenseReportLine: Record "Expense Report Line")
    var
        ExpReportLineItemization: Record "Expense Report Line Item";
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
        ExpenseSubCategory: Record "Expense Subcategory";
    begin
        ExpenseSubCategory.SetRange("Expense Category Code", ExpenseReportLine."Expense Category");
        if ExpenseSubCategory.IsEmpty() then begin
            ExpenseReportRuleViolation.AddRuleViolation(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", StrSubstNo(MissingExpenseSubCategoryErr, ExpenseReportLine."Expense Category"));
            exit;
        end;

        ExpReportLineItemization.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        ExpReportLineItemization.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        if ExpReportLineItemization.IsEmpty() then
            ExpenseReportRuleViolation.AddRuleViolation(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", ItemizationRequiredErr);
    end;

    local procedure ValidateParticipantsRequiredForReportLine(ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseReportLineParticip: Record "Expense Report Line Particip.";
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
    begin
        ExpenseReportLineParticip.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        ExpenseReportLineParticip.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        if ExpenseReportLineParticip.IsEmpty() then
            ExpenseReportRuleViolation.AddRuleViolation(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", ParticipantsRequiredErr);

        if ExpenseReportLineParticip.FindSet() then
            repeat
                if ExpenseReportLineParticip."Participant Type" = ExpenseReportLineParticip."Participant Type"::Employee then
                    if ExpenseReportLineParticip."Participant Employee No." = '' then
                        ExpenseReportRuleViolation.AddRuleViolation(
                            ExpenseReportLine."Document No.",
                            ExpenseReportLine."Line No.",
                            StrSubstNo(
                                ParticipantEmployeeMustBeRequiredInExpenseReportErr,
                                ExpenseReportLineParticip.FieldCaption("Participant Employee No."),
                                ExpenseReportLineParticip."Expense Report No.",
                                ExpenseReportLineParticip."Expense Report Line No.",
                                ExpenseReportLineParticip."Line No."));
            until ExpenseReportLineParticip.Next() = 0;
    end;

    local procedure ValidatePerDiemRequiredForReportLine(ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
    begin
        ExpenseReportLinePerDiem.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        ExpenseReportLinePerDiem.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        if ExpenseReportLinePerDiem.IsEmpty() then
            ExpenseReportRuleViolation.AddRuleViolation(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", PerDiemRequiredErr);
    end;

    local procedure ValidateMileageRequiredForReportLine(ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
    begin
        if ExpenseReportLine.Mileage <= 0 then
            ExpenseReportRuleViolation.AddRuleViolation(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", MileageRequiredErr);
    end;

    local procedure ValidateRuleRestrictionForReportLine(ExpenseReportLine: Record "Expense Report Line")
    var
        ExpReportLineItemization: Record "Expense Report Line Item";
        ExpenseReportLineParticip: Record "Expense Report Line Particip.";
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
        HasItemization: Boolean;
        HasParticipants: Boolean;
        HasPerDiem: Boolean;
        HasMileage: Boolean;
    begin
        ExpReportLineItemization.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        ExpReportLineItemization.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        HasItemization := not ExpReportLineItemization.IsEmpty();

        ExpenseReportLineParticip.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        ExpenseReportLineParticip.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        HasParticipants := not ExpenseReportLineParticip.IsEmpty();

        ExpenseReportLinePerDiem.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        ExpenseReportLinePerDiem.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        HasPerDiem := not ExpenseReportLinePerDiem.IsEmpty();

        HasMileage := false;

        case ExpenseReportLine."Expense Detail Required" of
            ExpenseReportLine."Expense Detail Required"::Itemize:
                if HasParticipants or HasPerDiem or HasMileage then
                    ExpenseReportRuleViolation.AddRuleViolation(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", StrSubstNo(RuleRestrictOnlyItemizationErr,
                        BuildExtraDetailsMessage(HasParticipants, HasPerDiem, HasMileage)));
            ExpenseReportLine."Expense Detail Required"::Participants:
                if HasItemization or HasPerDiem or HasMileage then
                    ExpenseReportRuleViolation.AddRuleViolation(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", StrSubstNo(RuleRestrictOnlyParticipantsErr,
                        BuildExtraDetailsMessage(HasItemization, HasPerDiem, HasMileage)));
            ExpenseReportLine."Expense Detail Required"::"Per Diem":
                if HasItemization or HasParticipants or HasMileage then
                    ExpenseReportRuleViolation.AddRuleViolation(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", StrSubstNo(RuleRestrictOnlyPerDiemErr,
                        BuildExtraDetailsMessage(HasItemization, HasParticipants, HasMileage)));
            ExpenseReportLine."Expense Detail Required"::Mileage:
                if HasItemization or HasParticipants or HasPerDiem then
                    ExpenseReportRuleViolation.AddRuleViolation(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", StrSubstNo(RuleRestrictOnlyMileageErr,
                        BuildExtraDetailsMessage(HasItemization, HasParticipants, HasPerDiem)));
        end;
    end;

    local procedure ValidateAmountsByDetailTypeForReportLine(ExpenseReportLine: Record "Expense Report Line"; ExpenseRuleHeader: Record "Expense Rule Header")
    begin
        case ExpenseReportLine."Expense Detail Required" of
            ExpenseReportLine."Expense Detail Required"::Itemize:
                ValidateItemizationAmountsForReportLine(ExpenseReportLine, ExpenseRuleHeader);
            ExpenseReportLine."Expense Detail Required"::Participants:
                ValidateParticipantsAmountsForReportLine(ExpenseReportLine, ExpenseRuleHeader);
            ExpenseReportLine."Expense Detail Required"::Mileage:
                ValidateMileageAmountsForReportLine(ExpenseReportLine, ExpenseRuleHeader);
        end;
    end;

    local procedure ValidateItemizationAmountsForReportLine(ExpenseReportLine: Record "Expense Report Line"; ExpenseRuleHeader: Record "Expense Rule Header")
    begin
        ValidateAmountConditionsForReportLine(ExpenseReportLine, ExpenseRuleHeader);
    end;

    local procedure ValidateParticipantsAmountsForReportLine(ExpenseReportLine: Record "Expense Report Line"; ExpenseRuleHeader: Record "Expense Rule Header")
    begin
        ValidateAmountConditionsForReportLine(ExpenseReportLine, ExpenseRuleHeader);
    end;

    local procedure ValidateMileageAmountsForReportLine(ExpenseReportLine: Record "Expense Report Line"; ExpenseRuleHeader: Record "Expense Rule Header")
    begin
        ValidateAmountConditionsForReportLine(ExpenseReportLine, ExpenseRuleHeader);
    end;

    local procedure ValidateAmountsByDetailTypeForReportLine(ExpenseReportLine: Record "Expense Report Line")
    begin
        case ExpenseReportLine."Expense Detail Required" of
            ExpenseReportLine."Expense Detail Required"::Itemize:
                ValidateItemizationAmountsForReportLine(ExpenseReportLine);
            ExpenseReportLine."Expense Detail Required"::Mileage:
                ValidateMileageAmountsForReportLine(ExpenseReportLine);
        end;
    end;

    local procedure ValidateItemizationAmountsForReportLine(ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseReportItemLine: Record "Expense Report Line Item";
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
        TotalAmount: Decimal;
        TotalReductionAmount: Decimal;
    begin
        ExpenseReportItemLine.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        ExpenseReportItemLine.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        ExpenseReportItemLine.CalcSums(Amount);
        TotalAmount := ExpenseReportItemLine.Amount;

        if TotalAmount <> ExpenseReportLine.Amount then
            ExpenseReportRuleViolation.AddRuleViolation(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", StrSubstNo(ItemizationTotalMismatchErr, TotalAmount, ExpenseReportLine.Amount));

        ExpenseReportItemLine.SetRange(Refundable, false);
        ExpenseReportItemLine.CalcSums(Amount);
        TotalReductionAmount := ExpenseReportItemLine.Amount;
        if TotalReductionAmount <> ExpenseReportLine."Non-Refundable Amount" then
            ExpenseReportRuleViolation.AddRuleViolation(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", StrSubstNo(ItemizationTotalReductionMismatchErr, TotalReductionAmount, ExpenseReportLine."Non-Refundable Amount"));
    end;

    local procedure ValidateMileageAmountsForReportLine(ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseCurrency: Record Currency;
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
        StandardRate: Decimal;
        CalculatedAmount: Decimal;
        EffectiveDistance: Decimal;
    begin
        if ExpenseReportLine."Expense Currency Code" = '' then
            ExpenseCurrency.InitRoundingPrecision()
        else
            ExpenseCurrency.Get(ExpenseReportLine."Expense Currency Code");

        StandardRate := ExpenseAutoPopulation.GetStandardRateOfMileage(ExpenseReportLine."Expense Date", ExpenseReportLine."Expense Currency Code", ExpenseReportLine."Expense Currency Factor", ExpenseAgentSetup."Standard Rate of Mileage", ExpenseReportLine."Vehicle Type");
        EffectiveDistance := ExpenseAutoPopulation.GetEffectiveDistance(ExpenseReportLine.Mileage, ExpenseReportLine."Round Trip");
        CalculatedAmount := Round(EffectiveDistance * StandardRate, ExpenseCurrency."Amount Rounding Precision");

        if CalculatedAmount <> ExpenseReportLine.Amount then
            ExpenseReportRuleViolation.AddRuleViolation(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", StrSubstNo(MileageCalculationMismatchErr, EffectiveDistance, StandardRate, CalculatedAmount, ExpenseReportLine.Amount));
    end;

    local procedure CheckJustificationFromConditionsForReportLine(ExpenseReportLine: Record "Expense Report Line"; ExpenseRuleHeader: Record "Expense Rule Header"): Boolean
    var
        ExpenseRuleCondition: Record "Expense Rule Condition";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
        Amount: Decimal;
        AmountLCY: Decimal;
        CurrencyFactor: Decimal;
    begin
        Amount := ExpenseReportLine.Amount - ExpenseReportLine."Non-Refundable Amount";
        AmountLCY := ExpenseReportLine."Amount (LCY)" - ExpenseReportLine."Non-Refundable Amount (LCY)";

        if ExpenseReportLine."Expense Currency Code" <> ExpenseRuleHeader."Currency Code" then
            if ExpenseRuleHeader."Currency Code" <> '' then begin
                Currency.Get(ExpenseRuleHeader."Currency Code");

                CurrencyFactor := CurrencyExchangeRate.ExchangeRate(ExpenseReportLine."Expense Date", ExpenseRuleHeader."Currency Code");
                Amount :=
                    Round(
                        CurrencyExchangeRate.ExchangeAmtLCYToFCY(ExpenseReportLine."Expense Date", ExpenseRuleHeader."Currency Code", AmountLCY, CurrencyFactor),
                        Currency."Amount Rounding Precision");
            end else
                Amount := AmountLCY;

        ExpenseRuleCondition.SetRange("Expense Category Code", ExpenseRuleHeader."Expense Category Code");
        ExpenseRuleCondition.SetRange("Expense Location", ExpenseRuleHeader."Expense Location");
        ExpenseRuleCondition.SetRange("Effective Date", ExpenseRuleHeader."Effective Date");
        ExpenseRuleCondition.SetRange("Condition Type", ExpenseRuleCondition."Condition Type"::"At Least Justification Needed");

        if ExpenseRuleCondition.FindSet() then
            repeat
                if Amount >= ExpenseRuleCondition."Value" then
                    exit(true);
            until ExpenseRuleCondition.Next() = 0;

        exit(false);
    end;

    local procedure ValidateAmountConditionsForReportLine(ExpenseReportLine: Record "Expense Report Line"; ExpenseRuleHeader: Record "Expense Rule Header")
    var
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
        Amount: Decimal;
        AmountLCY: Decimal;
        CurrencyFactor: Decimal;
    begin
        Amount := ExpenseReportLine.Amount - ExpenseReportLine."Non-Refundable Amount";
        AmountLCY := ExpenseReportLine."Amount (LCY)" - ExpenseReportLine."Non-Refundable Amount (LCY)";

        if ExpenseReportLine."Expense Currency Code" <> ExpenseRuleHeader."Currency Code" then
            if ExpenseRuleHeader."Currency Code" <> '' then begin
                Currency.Get(ExpenseRuleHeader."Currency Code");

                CurrencyFactor := CurrencyExchangeRate.ExchangeRate(ExpenseReportLine."Expense Date", ExpenseRuleHeader."Currency Code");
                Amount :=
                    Round(
                        CurrencyExchangeRate.ExchangeAmtLCYToFCY(ExpenseReportLine."Expense Date", ExpenseRuleHeader."Currency Code", AmountLCY, CurrencyFactor),
                        Currency."Amount Rounding Precision");
            end else
                Amount := AmountLCY;

        ExpenseRuleCondition.SetRange("Expense Category Code", ExpenseRuleHeader."Expense Category Code");
        ExpenseRuleCondition.SetRange("Expense Location", ExpenseRuleHeader."Expense Location");
        ExpenseRuleCondition.SetRange("Effective Date", ExpenseRuleHeader."Effective Date");

        if ExpenseRuleCondition.FindSet() then
            repeat
                case ExpenseRuleCondition."Condition Type" of
                    ExpenseRuleCondition."Condition Type"::" ":
                        ;
                    ExpenseRuleCondition."Condition Type"::"Fix Amount":
                        if Amount <> ExpenseRuleCondition."Value" then
                            ExpenseReportRuleViolation.AddRuleViolation(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", StrSubstNo(FixAmountErr, ExpenseRuleCondition."Value"));
                    ExpenseRuleCondition."Condition Type"::"Min Amount":
                        if Amount < ExpenseRuleCondition."Value" then
                            ExpenseReportRuleViolation.AddRuleViolation(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", StrSubstNo(MinAmountErr, ExpenseRuleCondition."Value"));
                    ExpenseRuleCondition."Condition Type"::"Max Amount":
                        if Amount > ExpenseRuleCondition."Value" then
                            ExpenseReportRuleViolation.AddRuleViolation(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", StrSubstNo(MaxAmountErr, ExpenseRuleCondition."Value"));
                end;
            until ExpenseRuleCondition.Next() = 0;
    end;

    local procedure ValidateRuleFields(Expense: Record Expense; ExpenseRuleHeader: Record "Expense Rule Header")
    var
        ExpenseRuleViolation: Record "Expense Rule Violation";
    begin
        if Expense."Expense Detail Required" = Expense."Expense Detail Required"::"Per Diem" then
            if Expense."Currency Code" <> ExpenseRuleHeader."Currency Code" then
                ExpenseRuleViolation.AddRuleViolation(Expense."No.", StrSubstNo(CurrencyCodeErr, ExpenseRuleHeader."Currency Code"));

        if IsMileageRule(Expense."Expense Detail Required") then
            if ExpenseAgentSetup."Default Mileage UOM" <> Expense."Unit of Measure Code" then
                ExpenseRuleViolation.AddRuleViolation(Expense."No.", StrSubstNo(UnitOfMeasureErr, ExpenseAgentSetup."Default Mileage UOM"));
    end;

    local procedure ValidateRuleFieldsForReportLine(ExpenseReportLine: Record "Expense Report Line"; ExpenseRuleHeader: Record "Expense Rule Header")
    var
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
    begin
        if ExpenseReportLine."Expense Detail Required" = ExpenseReportLine."Expense Detail Required"::"Per Diem" then
            if ExpenseReportLine."Expense Currency Code" <> ExpenseRuleHeader."Currency Code" then
                ExpenseReportRuleViolation.AddRuleViolation(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", StrSubstNo(CurrencyCodeErr, ExpenseRuleHeader."Currency Code"));

        if IsMileageRule(ExpenseReportLine."Expense Detail Required") then
            if ExpenseReportLine."Unit of Measure Code" <> ExpenseAgentSetup."Default Mileage UOM" then
                ExpenseReportRuleViolation.AddRuleViolation(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", StrSubstNo(UnitOfMeasureErr, ExpenseAgentSetup."Default Mileage UOM"));
    end;

    local procedure IsMileageRule(ExpenseDetailNeeded: Enum "Expense Detail Needed"): Boolean
    begin
        exit(ExpenseDetailNeeded = ExpenseDetailNeeded::Mileage);
    end;
}