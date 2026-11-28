// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

table 6944 "Expense Spend Limit"
{
    Access = Internal;
    Caption = 'Expense Spend Limit';
    DataClassification = CustomerContent;
    LookupPageId = "Expense Spend Limits";
    DrillDownPageId = "Expense Spend Limits";
    ReplicateData = false;

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
            AutoIncrement = true;
            ToolTip = 'Specifies the unique number of the spend limit.';
        }
        field(2; "Period Type"; Enum "Exp. Spend Limit Period")
        {
            Caption = 'Period Type';
            ToolTip = 'Specifies the period used to determine the start and end dates.';

            trigger OnValidate()
            begin
                if (xRec."Period Type" <> Rec."Period Type") and (Rec."Start Date" <> 0D) then
                    UpdatePeriodDates();
            end;
        }
        field(3; "Start Date"; Date)
        {
            Caption = 'Start Date';
            ToolTip = 'Specifies the first date of the spend-limit period.';

            trigger OnValidate()
            begin
                if Rec."Start Date" <> 0D then
                    UpdatePeriodDates();
            end;
        }
        field(4; "End Date"; Date)
        {
            Caption = 'End Date';
            ToolTip = 'Specifies the last date of the spend-limit period.';

            trigger OnValidate()
            begin
                ValidateDateRange();
            end;
        }
        field(5; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            ToolTip = 'Specifies the payment method to which this spend limit applies. Leave blank for all payment methods.';
            TableRelation = "Expense Payment Method".Code;
        }
        field(6; "Spend Limit Type"; Enum "Exp. Spend Limit Type")
        {
            Caption = 'Spend Limit Type';
            ToolTip = 'Specifies whether the limit applies to an Expense User, Expense Team, or the company.';

            trigger OnValidate()
            begin
                if xRec."Spend Limit Type" <> Rec."Spend Limit Type" then
                    Rec.Validate("Limit For", '');
            end;
        }
        field(7; "Limit For"; Code[20])
        {
            Caption = 'Limit For';
            ToolTip = 'Specifies the Expense User or Expense Team for this limit. Leave blank for a company limit.';
            TableRelation =
            if ("Spend Limit Type" = const(User)) "Expense User"."No."
            else
            if ("Spend Limit Type" = const(Team)) "Expense Team".Code;
        }
        field(8; "Amount (LCY)"; Decimal)
        {
            Caption = 'Amount (LCY)';
            BlankZero = true;
            AutoFormatType = 1;
            AutoFormatExpression = '';
            ToolTip = 'Specifies the spending limit in local currency.';

            trigger OnValidate()
            begin
                if Rec."Amount (LCY)" < 0 then
                    Error(AmountMustNotBeNegativeErr, FieldCaption("Amount (LCY)"));
            end;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(ScopeAndPeriod; "Spend Limit Type", "Limit For", "Start Date", "End Date")
        {
        }
    }

    var
        AmountMustNotBeNegativeErr: Label '%1 must not be negative.', Comment = '%1 = Amount field caption';
        OverlappingSpendLimitErr: Label 'Spend limit %1 for the period %2..%3 already exists with the same %4 and %5. Only one spend limit can apply on a given date. Change the existing spend limit or choose a period that does not overlap.', Comment = '%1 = existing spend limit No., %2 = start date, %3 = end date, %4 = Spend Limit Type caption, %5 = Limit For caption';

    trigger OnInsert()
    begin
        ValidateRequiredFields();
    end;

    trigger OnModify()
    begin
        ValidateRequiredFields();
    end;

    local procedure UpdatePeriodDates()
    var
        ExpenseSpendLimitMgt: Codeunit "Expense Spend Limit Mgt.";
    begin
        ExpenseSpendLimitMgt.UpdatePeriodDates(Rec);
    end;

    local procedure ValidateDateRange()
    begin
        if (Rec."Start Date" <> 0D) and (Rec."End Date" <> 0D) and (Rec."End Date" < Rec."Start Date") then
            Rec.FieldError("End Date");
    end;

    local procedure ValidateRequiredFields()
    begin
        Rec.TestField("Start Date");
        Rec.TestField("End Date");
        Rec.TestField("Amount (LCY)");
        if Rec."Spend Limit Type" in [Enum::"Exp. Spend Limit Type"::User, Enum::"Exp. Spend Limit Type"::Team] then
            Rec.TestField("Limit For")
        else
            Rec.TestField("Limit For", '');

        ValidateDateRange();
        CheckOverlappingSpendLimit();
    end;

    local procedure CheckOverlappingSpendLimit()
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
    begin
        ExpenseSpendLimit.SetLoadFields("No.", "Start Date", "End Date");
        ExpenseSpendLimit.SetFilter("No.", '<>%1', Rec."No.");
        ExpenseSpendLimit.SetRange("Spend Limit Type", Rec."Spend Limit Type");
        ExpenseSpendLimit.SetRange("Limit For", Rec."Limit For");
        ExpenseSpendLimit.SetFilter("Start Date", '..%1', Rec."End Date");
        ExpenseSpendLimit.SetFilter("End Date", '%1..', Rec."Start Date");
        if ExpenseSpendLimit.FindFirst() then
            Error(
                OverlappingSpendLimitErr,
                ExpenseSpendLimit."No.", ExpenseSpendLimit."Start Date", ExpenseSpendLimit."End Date",
                Rec.FieldCaption("Spend Limit Type"), Rec.FieldCaption("Limit For"));
    end;
}