// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

table 6940 "Expense Alternate Approver"
{
    Access = Internal;
    Caption = 'Expense Alternate Approver';
    DataClassification = CustomerContent;
    LookupPageId = "Expense Alternate Approvers";
    DrillDownPageId = "Expense Alternate Approvers";
    ReplicateData = false;

    fields
    {
        field(1; "Primary Approver No."; Code[20])
        {
            Caption = 'Primary Approver No.';
            TableRelation = "Expense User"."No." where("Can Approve" = const(true));
        }
        field(2; "Alternate Approver No."; Code[20])
        {
            Caption = 'Alternate Approver No.';
            TableRelation = "Expense User"."No." where("Can Approve" = const(true));

            trigger OnValidate()
            begin
                if "Alternate Approver No." = "Primary Approver No." then
                    Error(ApproverCannotBeSameErr, FieldCaption("Alternate Approver No."), FieldCaption("Primary Approver No."));

                CheckApproverIsEligible("Alternate Approver No.");
            end;
        }
        field(3; "Effective Start Date"; Date)
        {
            Caption = 'Effective Start Date';

            trigger OnValidate()
            begin
                if ("Effective End Date" <> 0D) and ("Effective Start Date" > "Effective End Date") then
                    Error(EffectiveStartAfterEndErr, FieldCaption("Effective Start Date"), FieldCaption("Effective End Date"));
            end;
        }
        field(4; "Effective End Date"; Date)
        {
            Caption = 'Effective End Date';

            trigger OnValidate()
            begin
                if ("Effective End Date" <> 0D) and ("Effective Start Date" > "Effective End Date") then
                    Error(EffectiveStartAfterEndErr, FieldCaption("Effective Start Date"), FieldCaption("Effective End Date"));
            end;
        }
    }

    keys
    {
        key(PK; "Primary Approver No.", "Alternate Approver No.", "Effective Start Date")
        {
            Clustered = true;
        }
        key(AlternateApprover; "Alternate Approver No.")
        {
        }
    }

    trigger OnInsert()
    begin
        TestField("Primary Approver No.");
        TestField("Alternate Approver No.");
        TestField("Effective Start Date");
        CheckApproverIsEligible("Primary Approver No.");
        CheckOverlappingCoverage();
    end;

    trigger OnModify()
    begin
        CheckOverlappingCoverage();
    end;

    procedure IsActive(ReferenceDate: Date): Boolean
    begin
        exit(
            ("Effective Start Date" <= ReferenceDate) and
            (("Effective End Date" = 0D) or ("Effective End Date" >= ReferenceDate)));
    end;

    local procedure CheckApproverIsEligible(ApproverNo: Code[20])
    var
        ExpenseUser: Record "Expense User";
    begin
        if ApproverNo = '' then
            exit;

        ExpenseUser.Get(ApproverNo);
        ExpenseUser.TestField("Can Approve", true);
        ExpenseUser.TestField("User Id For Approvals");
    end;

    local procedure CheckOverlappingCoverage()
    var
        ExistingAlternate: Record "Expense Alternate Approver";
    begin
        ExistingAlternate.SetRange("Primary Approver No.", "Primary Approver No.");
        if ExistingAlternate.FindSet() then
            repeat
                if ExistingAlternate.SystemId <> SystemId then
                    if DatesOverlap(ExistingAlternate."Effective Start Date", ExistingAlternate."Effective End Date", "Effective Start Date", "Effective End Date") then
                        Error(OverlappingCoverageErr, "Primary Approver No.");
            until ExistingAlternate.Next() = 0;
    end;

    local procedure DatesOverlap(FirstStartDate: Date; FirstEndDate: Date; SecondStartDate: Date; SecondEndDate: Date): Boolean
    begin
        exit(
            (FirstStartDate <= SecondStartDate) and
            ((FirstEndDate = 0D) or (FirstEndDate >= SecondStartDate)) or
            (SecondStartDate <= FirstStartDate) and
            ((SecondEndDate = 0D) or (SecondEndDate >= FirstStartDate)));
    end;

    var
        ApproverCannotBeSameErr: Label '%1 cannot be the same as %2.', Comment = '%1 = Alternate approver field caption, %2 = Primary approver field caption';
        EffectiveStartAfterEndErr: Label '%1 cannot be after %2.', Comment = '%1 = Effective start date field caption, %2 = Effective end date field caption';
        OverlappingCoverageErr: Label 'Overlapping alternate coverage exists for primary approver %1.', Comment = '%1 = Primary approver number';
}
