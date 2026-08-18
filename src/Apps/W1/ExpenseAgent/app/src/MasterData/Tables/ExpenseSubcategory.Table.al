// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.VAT.Setup;

table 6929 "Expense Subcategory"
{
    Access = Internal;
    Caption = 'Expense Subcategory';
    DataClassification = CustomerContent;
    LookupPageId = "Expense Subcategories";
    DrillDownPageId = "Expense Subcategories";
    ReplicateData = false;

    fields
    {
        field(1; "Expense Category Code"; Code[20])
        {
            Caption = 'Expense Category Code';
            TableRelation = "Expense Category".Code;
            NotBlank = true;
        }
        field(2; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
            ToolTip = 'Specifies the subcategory code.';
        }
        field(3; "Description"; Text[250])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the expense subcategory that identifies its purpose or usage.';
        }
        field(4; "Inactive"; Boolean)
        {
            Caption = 'Inactive';
            ToolTip = 'Specifies that the expense subcategory is inactive and can''t be selected for new transactions.';
        }
        field(5; "Refundable"; Boolean)
        {
            Caption = 'Refundable';
            ToolTip = 'Specifies whether the subcategory is refundable by default when itemization is used. This value can be changed on the expense report.';
        }
        field(6; "Expense Description Mandatory"; Boolean)
        {
            Caption = 'Expense Description Mandatory';
            ToolTip = 'Specifies whether a description must be entered for expenses using this subcategory before they can be released.';
        }
        field(15; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group".Code;
            ToolTip = 'Specifies the VAT product posting group to link the expense subcategory to the correct VAT code on the expense report.';
        }
        field(16; "Default VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Default VAT %';
            MinValue = 0;
            MaxValue = 100;
            ToolTip = 'Specifies the default VAT percentage for the expense subcategory. This value is used to calculate the VAT amount on the expense report when the subcategory is selected, and can be changed on the expense report if needed.';
        }
        field(17; "Default VAT Reclaim %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Default VAT Reclaim %';
            MinValue = 0;
            MaxValue = 100;
            ToolTip = 'Specifies the default VAT reclaim percentage for the expense subcategory. This value is used to calculate the VAT reclaim amount on the expense report when the subcategory is selected, and can be changed on the expense report if needed.';
        }
        field(20; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
            ToolTip = 'Specifies the posting description of the expense subcategory that identifies its purpose or usage.';
        }
    }

    keys
    {
        key(Key1; "Expense Category Code", "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description, Refundable)
        {
        }
    }

    trigger OnInsert()
    begin
        TestField("Expense Category Code");
    end;

    trigger OnDelete()
    begin
        CheckExpenseSubcategoryIsInUse(Rec."Expense Category Code", Rec.Code);
    end;

    trigger OnRename()
    begin
        CheckExpenseSubcategoryIsInUse(xRec."Expense Category Code", xRec.Code);
    end;

    var
        CannotDeleteOrRenameExpenseSubcategoryErr: Label 'You cannot delete or rename %1 %2 because it is used on at least one %3 or %4.', Comment = '%1 = Expense Subcategory table caption, %2 = Expense Subcategory Code, %3 = Expense Itemization table caption, %4 = Expense Report Line Itemization table caption';

    local procedure CheckExpenseSubcategoryIsInUse(ExpenseCategoryCode: Code[20]; SubcategoryCode: Code[20])
    var
        ExpenseItemization: Record "Expense Itemization";
        ExpenseReportLineItem: Record "Expense Report Line Item";
    begin
        ExpenseItemization.SetRange("Expense Category Code", ExpenseCategoryCode);
        ExpenseItemization.SetRange("Expense Subcategory Code", SubcategoryCode);
        if not ExpenseItemization.IsEmpty() then
            Error(CannotDeleteOrRenameExpenseSubcategoryErr, Rec.TableCaption(), SubcategoryCode, ExpenseItemization.TableCaption(), ExpenseReportLineItem.TableCaption());

        ExpenseReportLineItem.SetRange("Expense Category Code", ExpenseCategoryCode);
        ExpenseReportLineItem.SetRange("Expense Subcategory Code", SubcategoryCode);
        if not ExpenseReportLineItem.IsEmpty() then
            Error(CannotDeleteOrRenameExpenseSubcategoryErr, Rec.TableCaption(), SubcategoryCode, ExpenseItemization.TableCaption(), ExpenseReportLineItem.TableCaption());
    end;
}