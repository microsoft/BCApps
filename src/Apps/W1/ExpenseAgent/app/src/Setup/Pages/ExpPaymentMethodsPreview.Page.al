// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6971 "Exp. Payment Methods Preview"
{
    Caption = 'Expense payment methods';
    PageType = List;
    ApplicationArea = Basic, Suite;
    SourceTable = "Expense Payment Method";
    SourceTableTemporary = true;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    RefreshOnActivate = true;
    Extensible = false;
    InstructionalText = 'Lists existing expense payment methods together with the defaults that will be created when you apply the setup.';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Code"; Rec."Code")
                {
                    ToolTip = 'Specifies the payment method code.';
                    StyleExpr = StyleExpr;
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies a short description of the payment method.';
                }
                field("Reimbursement Type"; Rec."Reimbursement Type")
                {
                    ToolTip = 'Specifies the reimbursement type for this payment method.';
                }
                field(Status; StatusText)
                {
                    Caption = 'Status';
                    ToolTip = 'Specifies whether the row is a new default that will be added or already exists.';
                    StyleExpr = StyleExpr;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        ReloadPreview();
    end;

    trigger OnAfterGetRecord()
    var
        ExpensePaymentMethod: Record "Expense Payment Method";
    begin
        if ExpensePaymentMethod.Get(Rec."Code") then begin
            StatusText := ExistingLbl;
            StyleExpr := '';
        end else begin
            StatusText := NewLbl;
            StyleExpr := 'Favorable';
        end;
    end;

    local procedure ReloadPreview()
    var
        TempExpensePaymentMethod: Record "Expense Payment Method" temporary;
        CreateExpenseAgentSetup: Codeunit "Create Expense Agent Setup";
    begin
        CreateExpenseAgentSetup.LoadPaymentMethodsPreview(TempExpensePaymentMethod);

        Rec.Reset();
        Rec.DeleteAll();

        if TempExpensePaymentMethod.FindSet() then
            repeat
                Rec := TempExpensePaymentMethod;
                Rec.Insert();
            until TempExpensePaymentMethod.Next() = 0;

        if Rec.FindFirst() then;
    end;

    var
        StatusText: Text;
        StyleExpr: Text;
        NewLbl: Label 'New';
        ExistingLbl: Label 'Existing';
}
