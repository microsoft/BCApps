// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.SpendRequest;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.NoSeries;
using System.Utilities;

tableextension 6908 "Expense Spend Request" extends "Spend Request"
{
    fields
    {
        field(6900; "Requested For"; Code[20])
        {
            Caption = 'Requested For';
            ToolTip = 'Specifies the expense user for whom the spend request is being created.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Expense User";

            trigger OnValidate()
            begin
                TestStatusOpen();
                if SpendRequestExists() then
                    UpdateRequestedForTraveler(xRec."Requested For");
            end;
        }
        field(6901; "Business Justification"; Text[2048])
        {
            Caption = 'Business Justification';
            ToolTip = 'Specifies the business justification for the travel.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(6902; "Travel Policy Acknowledgment"; Boolean)
        {
            Caption = 'Travel Policy Acknowledgment';
            ToolTip = 'Specifies whether the travel policy has been acknowledged.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(6903; "International Travel"; Boolean)
        {
            Caption = 'International Travel';
            ToolTip = 'Specifies whether the travel is international.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(6904; "Origin Country/Region Code"; Code[10])
        {
            Caption = 'Origin Country/Region Code';
            ToolTip = 'Specifies the origin country for the travel.';
            DataClassification = CustomerContent;
            TableRelation = "Country/Region".Code;

            trigger OnValidate()
            begin
                TestStatusOpen();
                UpdateInternationalTravel();
            end;
        }
        field(6905; "Dest. Country/Region Code"; Code[10])
        {
            Caption = 'Destination Country/Region Code';
            ToolTip = 'Specifies the destination country for the travel.';
            DataClassification = CustomerContent;
            TableRelation = "Country/Region".Code;

            trigger OnValidate()
            begin
                TestStatusOpen();
                UpdateInternationalTravel();
            end;
        }
        field(6906; "Restrictions"; Text[250])
        {
            Caption = 'Restrictions';
            ToolTip = 'Specifies any travel restrictions that apply.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(6907; "Per Diem Included"; Boolean)
        {
            Caption = 'Per Diem Included';
            ToolTip = 'Specifies whether per diem is included in the requisition.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(6911; "Actual Start Date and Time"; DateTime)
        {
            Caption = 'Actual Start Date and Time';
            ToolTip = 'Specifies the actual start date and time of the travel.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(6912; "Actual End Date and Time"; DateTime)
        {
            Caption = 'Actual End Date and Time';
            ToolTip = 'Specifies the actual end date and time of the travel.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(6913; "Approver Expense User Filter"; Code[20])
        {
            Caption = 'Approver Expense User Filter';
            FieldClass = FlowFilter;
            TableRelation = "Expense User"."No.";
        }
        field(6914; "Submitted By Expense User No."; Code[20])
        {
            Caption = 'Submitted By Expense User No.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = "Expense User"."No.";
        }
        field(6915; "Submitted At"; DateTime)
        {
            Caption = 'Submitted At';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(6916; "Approval Expense User No."; Code[20])
        {
            Caption = 'Approval Expense User No.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = "Expense User"."No.";
        }
        field(6917; "Rejection Reason"; Text[2048])
        {
            Caption = 'Rejection Reason';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
    trigger OnInsert()
    var
        StartDateProvided: Boolean;
        EndDateProvided: Boolean;
    begin
        StartDateProvided := APIStartDateProvided;
        EndDateProvided := APIEndDateProvided;
        APIStartDateProvided := false;
        APIEndDateProvided := false;

        // The base OnInsert initializes both dates to WorkDate. Restore API inputs before persistence.
        ApplyExpectedDatesFromAPI(APIExpectedStartDate, APIExpectedEndDate, StartDateProvided, EndDateProvided);
    end;

    trigger OnAfterInsert()
    begin
        if Rec."Document Type" = Rec."Document Type"::"Travel Request" then
            InsertRequestedForTraveler();
    end;

    trigger OnBeforeDelete()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        LinkedExpenseReportExistsErr: Label 'You cannot delete travel request %1 because it is linked to an expense report.', Comment = '%1 = Travel request number';
    begin
        if Rec."Document Type" <> Rec."Document Type"::"Travel Request" then
            exit;

        ExpenseReportHeader.SetRange("Spend Request No.", Rec."No.");
        if not ExpenseReportHeader.IsEmpty() then
            Error(LinkedExpenseReportExistsErr, Rec."No.");
    end;

    trigger OnDelete()
    var
        Traveler: Record Traveler;
    begin
        Traveler.SetRange("Spend Request No.", Rec."No.");
        Traveler.DeleteAll();
    end;

    var
        APIExpectedStartDate: Date;
        APIExpectedEndDate: Date;
        APIStartDateProvided: Boolean;
        APIEndDateProvided: Boolean;
        ReplaceRequestedForTravelerQst: Label 'The %1 was changed. A traveler was automatically added for the previous %1. Do you want to remove that traveler and add a new one for the current %1 instead?', Comment = '%1 = Requested For field caption';

    internal procedure SetExpectedDatesForAPIInsert(StartDate: Date; EndDate: Date; StartDateProvided: Boolean; EndDateProvided: Boolean)
    begin
        APIExpectedStartDate := StartDate;
        APIExpectedEndDate := EndDate;
        APIStartDateProvided := StartDateProvided;
        APIEndDateProvided := EndDateProvided;
    end;

    internal procedure ApplyExpectedDatesFromAPI(StartDate: Date; EndDate: Date; StartDateProvided: Boolean; EndDateProvided: Boolean)
    begin
        // Populate the final pair before either field trigger validates it; omitted values remain unchanged.
        if StartDateProvided then
            Rec."Expected Start Date" := StartDate;
        if EndDateProvided then
            Rec."Expected End Date" := EndDate;

        if StartDateProvided then
            Rec.Validate("Expected Start Date");
        if EndDateProvided then
            Rec.Validate("Expected End Date");
    end;

    internal procedure InsertRequestedForTraveler()
    var
        Traveler: Record Traveler;
    begin
        if Rec."Requested For" = '' then
            exit;

        if RequestedForTravelerExists(Rec."Requested For") then
            exit;

        Traveler.Init();
        Traveler."Spend Request No." := Rec."No.";
        Traveler."Line No." := GetNextTravelerLineNo();
        Traveler.Validate("Expense User No.", Rec."Requested For");
        Traveler.Insert(true);
    end;

    local procedure UpdateRequestedForTraveler(PreviousRequestedFor: Code[20])
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if Rec."Requested For" = PreviousRequestedFor then
            exit;

        if (PreviousRequestedFor <> '') and RequestedForTravelerExists(PreviousRequestedFor) then begin
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(ReplaceRequestedForTravelerQst, Rec.FieldCaption("Requested For")), true) then
                exit;

            RemoveRequestedForTraveler(PreviousRequestedFor);
        end;

        InsertRequestedForTraveler();
    end;

    local procedure RequestedForTravelerExists(ExpenseUserNo: Code[20]): Boolean
    var
        Traveler: Record Traveler;
    begin
        if ExpenseUserNo = '' then
            exit(false);

        Traveler.SetRange("Spend Request No.", Rec."No.");
        Traveler.SetRange("Expense User No.", ExpenseUserNo);
        exit(not Traveler.IsEmpty());
    end;

    local procedure RemoveRequestedForTraveler(ExpenseUserNo: Code[20])
    var
        Traveler: Record Traveler;
    begin
        Traveler.SetRange("Spend Request No.", Rec."No.");
        Traveler.SetRange("Expense User No.", ExpenseUserNo);
        Traveler.DeleteAll(true);
    end;

    local procedure GetNextTravelerLineNo(): Integer
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        exit(SequenceNoMgt.GetNextSeqNo(Database::Traveler))
    end;

    local procedure UpdateInternationalTravel()
    begin
        if (Rec."Origin Country/Region Code" = '') or (Rec."Dest. Country/Region Code" = '') then begin
            Rec.Validate("International Travel", false);
            exit;
        end;

        Rec.Validate("International Travel", Rec."Origin Country/Region Code" <> Rec."Dest. Country/Region Code");
    end;

    local procedure SpendRequestExists(): Boolean
    var
        SpendRequest: Record "Spend Request";
    begin
        if Rec."No." = '' then
            exit(false);

        SpendRequest.SetLoadFields("No.");
        exit(SpendRequest.Get(Rec."No."));
    end;
}