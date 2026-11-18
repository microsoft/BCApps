// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.SpendRequest;

table 6938 Traveler
{
    Access = Internal;
    Caption = 'Traveler';
    ReplicateData = false;
    LookupPageId = "Travelers";
    DrillDownPageId = "Travelers";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Spend Request No."; Code[20])
        {
            Caption = 'Travel Request No.';
            TableRelation = "Spend Request";
            ToolTip = 'Specifies the travel request to which the traveler is added.';
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Expense User No."; Code[20])
        {
            Caption = 'Expense User No.';
            TableRelation = "Expense User"."No.";
            NotBlank = true;
            ToolTip = 'Specifies the expense user who is traveling.';

            trigger OnValidate()
            var
                ExpenseUser: Record "Expense User";
            begin
                TestStatusOpenOfSpendRequest();

                if (xRec."Expense User No." <> '') and (xRec."Expense User No." <> Rec."Expense User No.") then
                    CheckNoLinkedExpenseReports(xRec."Expense User No.");

                if Rec."Expense User No." <> '' then begin
                    CheckDuplicateTraveler();

                    if ExpenseUser.Get(Rec."Expense User No.") then
                        Rec."Expense User Name" := ExpenseUser.Name;
                end;
            end;
        }
        field(5; "Expense User Name"; Text[100])
        {
            Caption = 'Expense User Name';
            ToolTip = 'Specifies the name of the traveler.';

            trigger OnValidate()
            begin
                TestStatusOpenOfSpendRequest();
            end;
        }
        field(6; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            FieldClass = FlowField;
            CalcFormula = lookup("Expense User"."Employee No." where("No." = field("Expense User No.")));
            ToolTip = 'Specifies the employee number linked to the expense user who is traveling.';
        }
    }

    keys
    {
        key(PK; "Spend Request No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Expense User No.", "Expense User Name")
        {
        }
    }

    trigger OnInsert()
    begin
        TestStatusOpenOfSpendRequest();
    end;

    trigger OnDelete()
    begin
        TestStatusOpenOfSpendRequest();
        CheckNoLinkedExpenseReports(Rec."Expense User No.");
    end;

    var
        DuplicateTravelerErr: Label 'Traveler %1 is already on this travel request. Each traveler can be added only once. Choose a different traveler or remove the existing line.', Comment = '%1 = Traveler No.';
        ExpenseUserNotFoundErr: Label 'No expense user is linked to employee %1.', Comment = '%1 = Employee No.';
        TravelerHasExpenseReportsErr: Label 'You cannot remove traveler %1 from travel request %2 because an expense report is linked to the traveler.', Comment = '%1 = Expense User No., %2 = Travel Request No.';

    /// <summary>
    /// Checks whether the travel request has more than one traveler.
    /// </summary>
    /// <param name="SpendRequestNo">The travel request number.</param>
    /// <returns>True if the travel request has more than one traveler.</returns>
    internal procedure HasMultipleTravelers(SpendRequestNo: Code[20]): Boolean
    var
        Traveler: Record Traveler;
    begin
        if SpendRequestNo = '' then
            exit(false);

        Traveler.SetRange("Spend Request No.", SpendRequestNo);
        exit(Traveler.Count() > 1);
    end;

    /// <summary>
    /// Checks whether an expense report, open or posted, is linked to the travel request for the traveler.
    /// </summary>
    /// <param name="SpendRequestNo">The travel request number.</param>
    /// <param name="TravelerExpenseUserNo">The expense user of the traveler.</param>
    /// <returns>True if the traveler has a linked expense report.</returns>
    internal procedure HasLinkedExpenseReports(SpendRequestNo: Code[20]; TravelerExpenseUserNo: Code[20]): Boolean
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
    begin
        if (SpendRequestNo = '') or (TravelerExpenseUserNo = '') then
            exit(false);

        ExpenseReportHeader.SetRange("Spend Request No.", SpendRequestNo);
        ExpenseReportHeader.SetRange("Expense User No.", TravelerExpenseUserNo);
        if not ExpenseReportHeader.IsEmpty() then
            exit(true);

        ExpenseReportLine.SetRange("Spend Request No.", SpendRequestNo);
        ExpenseReportLine.SetRange("Expense User No.", TravelerExpenseUserNo);
        if not ExpenseReportLine.IsEmpty() then
            exit(true);

        PostedExpenseReportHeader.SetRange("Spend Request No.", SpendRequestNo);
        PostedExpenseReportHeader.SetRange("Expense User No.", TravelerExpenseUserNo);
        if not PostedExpenseReportHeader.IsEmpty() then
            exit(true);

        PostedExpenseReportLine.SetRange("Spend Request No.", SpendRequestNo);
        PostedExpenseReportLine.SetRange("Expense User No.", TravelerExpenseUserNo);
        exit(not PostedExpenseReportLine.IsEmpty());
    end;

    local procedure CheckNoLinkedExpenseReports(TravelerExpenseUserNo: Code[20])
    begin
        if HasLinkedExpenseReports(Rec."Spend Request No.", TravelerExpenseUserNo) then
            Error(TravelerHasExpenseReportsErr, TravelerExpenseUserNo, Rec."Spend Request No.");
    end;

    internal procedure ValidateEmployeeNo(EmployeeNo: Code[20])
    var
        ExpenseUser: Record "Expense User";
    begin
        if EmployeeNo = '' then
            Error(ExpenseUserNotFoundErr, EmployeeNo);

        ExpenseUser.SetLoadFields("No.");
        ExpenseUser.SetRange("Employee No.", EmployeeNo);
        if not ExpenseUser.FindFirst() then
            Error(ExpenseUserNotFoundErr, EmployeeNo);

        Rec.Validate("Expense User No.", ExpenseUser."No.");
    end;

    local procedure TestStatusOpenOfSpendRequest()
    var
        SpendRequest: Record "Spend Request";
    begin
        SpendRequest.SetLoadFields(Status);
        SpendRequest.Get(Rec."Spend Request No.");

        SpendRequest.TestStatusOpen();
    end;

    local procedure CheckDuplicateTraveler()
    var
        ExistingTraveler: Record Traveler;
    begin
        ExistingTraveler.SetRange("Spend Request No.", Rec."Spend Request No.");
        ExistingTraveler.SetRange("Expense User No.", Rec."Expense User No.");
        ExistingTraveler.SetFilter("Line No.", '<>%1', Rec."Line No.");
        if not ExistingTraveler.IsEmpty() then
            Error(DuplicateTravelerErr, Rec."Expense User No.");
    end;
}