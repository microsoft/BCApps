// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

using Microsoft.Sales.Customer;

table 12173 "Deferring Due Dates"
{
    Caption = 'Deferring Due Dates';
    DrillDownPageID = "Stop Payment Periods";
    LookupPageID = "Stop Payment Periods";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = Customer;
        }
        field(2; "From-Date"; Date)
        {
            Caption = 'From-Date';
            NotBlank = true;
        }
        field(3; "To-Date"; Date)
        {
            Caption = 'To-Date';
            NotBlank = true;
        }
        field(4; "Due Date Calculation"; DateFormula)
        {
            Caption = 'Due Date Calculation';
        }
        field(5; Description; Text[50])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "No.", "From-Date")
        {
            Clustered = true;
        }
        key(Key2; "No.", "To-Date")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        DefDueDates.Reset();
        DefDueDates.SetRange("No.", "No.");

        if DefDueDates.FindSet() then
            repeat
                if ("From-Date" >= DefDueDates."From-Date") and
                   ("From-Date" <= DefDueDates."To-Date")
                then
                    FieldError("From-Date", PeriodConflictTxt);

                if ("To-Date" >= DefDueDates."From-Date") and
                   ("To-Date" <= DefDueDates."To-Date")
                then
                    FieldError("To-Date", PeriodConflictTxt);

                if (DefDueDates."From-Date" >= "From-Date") and
                   (DefDueDates."From-Date" <= "To-Date")
                then
                    Error(PeriodConflictErr);

                if (DefDueDates."To-Date" >= "From-Date") and
                   (DefDueDates."To-Date" <= "To-Date")
                then
                    Error(PeriodConflictErr);

            until DefDueDates.Next() = 0;
    end;

    var
        PeriodConflictTxt: Label 'conflicts with another period';
        PeriodConflictErr: Label 'Period conflicts with another period.';
        DefDueDates: Record "Deferring Due Dates";
}

