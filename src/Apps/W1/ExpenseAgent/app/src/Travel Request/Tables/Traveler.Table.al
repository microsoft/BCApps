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
    end;

    var
        DuplicateTravelerErr: Label 'Traveler %1 is already on this travel request. Each traveler can be added only once. Choose a different traveler or remove the existing line.', Comment = '%1 = Traveler No.';

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