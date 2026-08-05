// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.VAT.Setup;

table 6921 "Expense Category"
{
    Access = Internal;
    Caption = 'Expense Category';
    LookupPageId = "Expense Categories";
    DrillDownPageId = "Expense Categories";
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Description"; Text[250])
        {
            Caption = 'Description';
        }
        field(3; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            TableRelation = "Expense Posting Group".Code;
        }
        field(4; "Attachment Enforcement"; Enum "Expense Attachment Enforcement")
        {
            Caption = 'Attachment Enforcement';

            trigger OnValidate()
            begin
                if Rec."Attachment Enforcement" <> xRec."Attachment Enforcement" then
                    CheckRuleViolationOnOpenExpenseReports(Rec);
            end;
        }
        field(5; "Default Payment Method"; Code[10])
        {
            Caption = 'Default Payment Method';
            TableRelation = "Expense Payment Method".Code;

            trigger OnValidate()
            var
                ExpensePaymentMethod: Record "Expense Payment Method";
            begin
                if ExpensePaymentMethod.Get(Rec."Default Payment Method") then
                    Rec."Reimbursement Type" := ExpensePaymentMethod."Reimbursement Type"
                else
                    Rec."Reimbursement Type" := Rec."Reimbursement Type"::" ";
            end;
        }
        field(6; "Prepayment-Cash Advance"; Boolean)
        {
            Caption = 'Prepayment-Cash Advance';
        }
        field(7; "Inactive"; Boolean)
        {
            Caption = 'Inactive';
        }
        field(8; "Expense Group"; Code[20])
        {
            Caption = 'Expense Group';
            TableRelation = "Expense Group".Code;
        }
        field(9; "Refundable"; Boolean)
        {
            Caption = 'Refundable';
        }
        field(10; "Reimbursement Type"; Enum "Expense Reimbursement Type")
        {
            Caption = 'Reimbursement Type';
            Editable = false;
        }
        field(11; "Expense Detail Required"; Enum "Expense Detail Needed")
        {
            Caption = 'Expense Detail Required';

            trigger OnValidate()
            begin
                if Rec."Expense Detail Required" <> xRec."Expense Detail Required" then
                    CheckExpenseDetailRequiredCannotBeChangeInExpenseCategoryWhenRuleExist(Rec.Code);
            end;
        }
        field(15; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group".Code;
            ToolTip = 'Specifies VAT product posting group will be used to calculate the VAT percentage when the expense report line is created with this expense category. If the VAT product posting group is left blank, the system will use the default VAT percentage defined in the "Default VAT %" field on this table. If both the VAT product posting group and the default VAT percentage are left blank, the system will calculate the VAT percentage based on the VAT business posting group and the country/region of the transaction.';
        }
        field(16; "Default VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Default VAT %';
            BlankZero = true;
            MinValue = 0;
            MaxValue = 100;
            ToolTip = 'Specifies default VAT percentage will be used when the expense report line is created with this expense category. If the default VAT percentage is left blank, the system will calculate the VAT percentage based on the VAT product posting group and the VAT business posting group.';
        }
        field(17; "Default VAT Reclaim %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Default VAT Reclaim %';
            BlankZero = true;
            MinValue = 0;
            MaxValue = 100;
            ToolTip = 'Specifies default VAT reclaim percentage will be used when the expense report line is created with this expense category. If the default VAT reclaim percentage is left blank, the system will calculate the VAT reclaim percentage based on the VAT product posting group and the VAT business posting group.';
        }
        field(20; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
            ToolTip = 'Specifies the posting description that will be used on the ledger entries when this expense category is used in an expense report line. If this field is left blank, the description from the expense report line will be used for the ledger entries.';
        }
    }
    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    begin
        CheckExpenseCategoryIsInUse(Rec.Code);
        DeleteRelatedRecords();
    end;

    trigger OnRename()
    var
        ExpenseRuleHeader: Record "Expense Rule Header";
    begin
        CheckExpenseCategoryIsInUse(xRec.Code);

        ExpenseRuleHeader.SetRange("Expense Category Code", xRec.Code);
        if not ExpenseRuleHeader.IsEmpty() then
            Error(CannotRenameExpenseCategoryWhenExpenseRuleExistErr, Rec.TableCaption(), xRec.Code, ExpenseRuleHeader.TableCaption());
    end;

    var
        ConfirmManagement: Codeunit System.Utilities."Confirm Management";
        ExpenseDetailRequiredCannotBeChangedWhenRuleExistErr: Label '%1 cannot be changed because there are existing Expense Rules for this Expense Category %2.', Comment = '%1 = Field Caption, %2 = Expense Category Code';
        CanModifyExpenseReportLinesQst: Label 'You have modified %1 which will also update the expense report lines.\\Do you want to continue?', Comment = '%1 - Field Caption';
        CannotDeleteOrRenameExpenseCategoryErr: Label 'You cannot delete or rename %1 %2 because it is used on at least one %3 or %4.', Comment = '%1 = Expense Category table caption, %2 = Expense Category Code, %3 = Expense table caption, %4 = Expense Report Line table caption';
        CannotRenameExpenseCategoryWhenExpenseRuleExistErr: Label 'You cannot rename %1 %2 because it is used on %3.', Comment = '%1 = Expense Category table caption, %2 = Expense Category Code, %3 = Expense Rule Header table caption';

    local procedure CheckExpenseCategoryIsInUse(ExpenseCategoryCode: Code[20])
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
    begin
        Expense.SetRange("Expense Category", ExpenseCategoryCode);
        if not Expense.IsEmpty() then
            Error(CannotDeleteOrRenameExpenseCategoryErr, Rec.TableCaption(), ExpenseCategoryCode, Expense.TableCaption(), ExpenseReportLine.TableCaption());

        ExpenseReportLine.SetRange("Expense Category", ExpenseCategoryCode);
        if not ExpenseReportLine.IsEmpty() then
            Error(CannotDeleteOrRenameExpenseCategoryErr, Rec.TableCaption(), ExpenseCategoryCode, Expense.TableCaption(), ExpenseReportLine.TableCaption());
    end;

    local procedure DeleteRelatedRecords()
    var
        ExpenseSubcategory: Record "Expense Subcategory";
        ExpenseRuleHeader: Record "Expense Rule Header";
    begin
        ExpenseSubcategory.SetRange("Expense Category Code", Rec.Code);
        ExpenseSubcategory.DeleteAll(true);

        ExpenseRuleHeader.SetRange("Expense Category Code", Rec.Code);
        ExpenseRuleHeader.DeleteAll(true);
    end;

    local procedure CheckExpenseDetailRequiredCannotBeChangeInExpenseCategoryWhenRuleExist(ExpenseCategoryCode: Code[20])
    var
        ExpenseRuleHeader: Record "Expense Rule Header";
    begin
        ExpenseRuleHeader.SetRange("Expense Category Code", ExpenseCategoryCode);
        if not ExpenseRuleHeader.IsEmpty() then
            Error(ExpenseDetailRequiredCannotBeChangedWhenRuleExistErr, Rec.FieldCaption("Expense Detail Required"), ExpenseCategoryCode);
    end;

    local procedure CheckRuleViolationOnOpenExpenseReports(var ExpenseCategory: Record "Expense Category")
    var
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // This is to ensure that if the record doesn't exists then there is no need to call this procedure as this procedure can also be called when is called from api / demo data calls validate at the time of insert.
        if not ExpenseCategoryExist(ExpenseCategory.Code) then
            exit;

        ExpenseReportHeader.SetRange(Status, ExpenseReportHeader.Status::Open);
        if ExpenseReportHeader.IsEmpty() then
            exit;

        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(CanModifyExpenseReportLinesQst, ExpenseCategory.FieldCaption("Attachment Enforcement")), true) then
            Error('');

        ExpenseCategory.Modify();

        if ExpenseReportHeader.FindSet() then
            repeat
                CheckRuleViolationOnExpenseReportLine(ExpenseReportHeader, ExpenseCategory);
            until ExpenseReportHeader.Next() = 0;
    end;

    local procedure ExpenseCategoryExist(ExpenseCategoryCode: Code[20]): Boolean
    var
        ExpenseCategory: Record "Expense Category";
    begin
        if ExpenseCategory.Get(ExpenseCategoryCode) then
            exit(true);
    end;

    local procedure CheckRuleViolationOnExpenseReportLine(ExpenseReportHeader: Record "Expense Report Header"; ExpenseCategory: Record "Expense Category")
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
    begin
        ExpenseReportLine.SetRange("Document No.", ExpenseReportHeader."No.");
        ExpenseReportLine.SetRange("Expense Category", ExpenseCategory.Code);
        if ExpenseReportLine.FindSet() then
            repeat
                ExpenseRuleValidation.ValidateExpenseReportLineAgainstRule(ExpenseReportLine);
            until ExpenseReportLine.Next() = 0;
    end;
}