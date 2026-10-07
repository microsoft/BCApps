// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Defines expense payment methods and their processing characteristics for transactions.
/// </summary>
table 6913 "Expense Payment Method"
{
    Caption = 'Expense Payment Method';
    DataCaptionFields = "Code", Description;
    DrillDownPageID = "Expense Payment Methods";
    LookupPageID = "Expense Payment Methods";
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        /// <summary>
        /// Unique identifier for the payment method.
        /// </summary>
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        /// <summary>
        /// Descriptive name of the payment method for user identification.
        /// </summary>
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Type of balancing account for automatic posting (G/L Account or Bank Account).
        /// </summary>
        field(3; "Reimbursement Type"; Enum "Expense Reimbursement Type")
        {
            Caption = 'Reimbursement Type';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if xRec."Reimbursement Type" <> Rec."Reimbursement Type" then
                    if Rec."Reimbursement Type" <> Rec."Reimbursement Type"::" " then
                        CheckForSameReimbursementType();
            end;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description)
        {
        }
        fieldgroup(Brick; "Code", Description)
        {
        }
    }

    trigger OnDelete()
    var
        ExpenseCategory: Record "Expense Category";
    begin
        ExpenseCategory.SetRange("Default Payment Method", Rec.Code);
        if ExpenseCategory.FindFirst() then
            Error(CannotDeletePaymentMethodInUseErr, Rec.TableCaption(), Rec.Code, ExpenseCategory.FieldCaption("Default Payment Method"), ExpenseCategory.TableCaption(), ExpenseCategory.Code);
    end;

    var
        SameExpensePaymentMethodForReimbursementExistErr: Label '%1 %2 with the same %3 "%4" already exists. %3 must be unique for expense report payment methods.', Comment = '%1 = Table Caption, %2 = Expense Payment Method Code, %3 = Reimbursement Type, %4 = Reimbursement Type Value';
        CannotDeletePaymentMethodInUseErr: Label 'You cannot delete %1 %2 because it is used as the %3 for %4 %5.', Comment = '%1 = Table Caption, %2 = Payment Method Code, %3 = Default Payment Method Field Caption, %4 = Expense Category Table Caption, %5 = Expense Category Code';

    local procedure CheckForSameReimbursementType()
    var
        ExpensePaymentMethod: Record "Expense Payment Method";
    begin
        ExpensePaymentMethod.SetFilter(Code, '<>%1', Rec.Code);
        ExpensePaymentMethod.SetRange("Reimbursement Type", Rec."Reimbursement Type");
        if ExpensePaymentMethod.FindFirst() then
            Error(
                SameExpensePaymentMethodForReimbursementExistErr,
                ExpensePaymentMethod.TableCaption(),
                ExpensePaymentMethod.Code,
                ExpensePaymentMethod.FieldCaption("Reimbursement Type"),
                Rec."Reimbursement Type");
    end;
}