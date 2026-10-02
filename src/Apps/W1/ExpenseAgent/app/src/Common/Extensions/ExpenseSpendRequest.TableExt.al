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
            ToolTip = 'Specifies the expense user for whom the travel request is being created.';
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
            ObsoleteReason = 'Replaced by the Expense Location field.';
#if not CLEAN30
            ObsoleteState = Pending;
            ObsoleteTag = '30.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '33.0';
#endif

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
            ObsoleteReason = 'Replaced by the Expense Location field.';
#if not CLEAN30
            ObsoleteState = Pending;
            ObsoleteTag = '30.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '33.0';
#endif

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(6905; "Dest. Country/Region Code"; Code[10])
        {
            Caption = 'Destination Country/Region Code';
            ToolTip = 'Specifies the destination country for the travel.';
            DataClassification = CustomerContent;
            TableRelation = "Country/Region".Code;
            ObsoleteReason = 'Replaced by the Expense Location field.';
#if not CLEAN30
            ObsoleteState = Pending;
            ObsoleteTag = '30.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '33.0';
#endif

            trigger OnValidate()
            begin
                TestStatusOpen();
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
            ToolTip = 'Specifies whether per diem is included in the travel request.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusOpen();
                if not Rec."Per Diem Included" then
                    Rec.Validate("Expense Location", '');
            end;
        }
        field(6908; "Expense Location"; Code[20])
        {
            Caption = 'Expense Location';
            ToolTip = 'Specifies the expense location of the travel. The expense location can only be used, and is required, when per diem is included.';
            DataClassification = CustomerContent;
            TableRelation = "Expense Location"."No.";

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(6910; "Requested For Name"; Text[100])
        {
            Caption = 'Requested For Name';
            FieldClass = FlowField;
            CalcFormula = lookup("Expense User".Name where("No." = field("Requested For")));
            ToolTip = 'Specifies the name of the expense user for whom the travel request is being created.';
        }
        field(6911; "Actual Start Date and Time"; DateTime)
        {
            Caption = 'Actual Start Date and Time';
            ToolTip = 'Specifies the actual start date and time of the travel. Required when per diem is included.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(6912; "Actual End Date and Time"; DateTime)
        {
            Caption = 'Actual End Date and Time';
            ToolTip = 'Specifies the actual end date and time of the travel. Required when per diem is included.';
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
            ToolTip = 'Specifies the expense user who submitted the travel request.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = "Expense User"."No.";
        }
        field(6915; "Submitted At"; DateTime)
        {
            Caption = 'Submitted At';
            ToolTip = 'Specifies the date and time when the travel request was submitted.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(6916; "Approval Expense User No."; Code[20])
        {
            Caption = 'Approval Expense User No.';
            ToolTip = 'Specifies the expense user who approved or rejected the travel request.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = "Expense User"."No.";
        }
        field(6917; "Rejection Reason"; Text[2048])
        {
            Caption = 'Rejection Reason';
            ToolTip = 'Specifies the reason the travel request was rejected.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(6918; "Requested By User Id Filter"; Guid)
        {
            Caption = 'Requested By User Id Filter';
            FieldClass = FlowFilter;
            TableRelation = "Expense User".SystemId;
        }
        field(6919; "Approver User Id Filter"; Guid)
        {
            Caption = 'Approver User Id Filter';
            FieldClass = FlowFilter;
            TableRelation = "Expense User".SystemId;
        }
        field(6920; "Approval Expense User Name"; Text[100])
        {
            Caption = 'Approval Expense User Name';
            ToolTip = 'Specifies the display name of the expense user who approved or rejected the travel request.';
            FieldClass = FlowField;
            CalcFormula = lookup("Expense User".Name where("No." = field("Approval Expense User No.")));
            Editable = false;
        }
        field(6921; "Submitter Comment"; Text[2048])
        {
            Caption = 'Submitter Comment';
            ToolTip = 'Specifies the latest comment from the submitter when submitting a travel request or resubmitting a rejected travel request.';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
    trigger OnInsert()
    begin
        CheckExpenseLocation();
        CheckActualDateTimes();
    end;

    trigger OnModify()
    begin
        // Checked on save rather than per field, so that the order of the fields in an API request does not matter.
        CheckExpenseLocation();
        CheckActualDateTimes();
    end;

    trigger OnAfterInsert()
    begin
        if Rec."Document Type" = Rec."Document Type"::"Travel Request" then
            InsertRequestedForTraveler();
    end;

    trigger OnBeforeDelete()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
    begin
        if Rec."Document Type" <> Rec."Document Type"::"Travel Request" then
            exit;

        ExpenseReportHeader.SetRange("Spend Request No.", Rec."No.");
        if ExpenseReportHeader.FindFirst() then
            Error(GetLinkedExpenseReportError(ExpenseReportHeader.RecordId, Page::"Expense Report"));

        ExpenseReportLine.SetRange("Spend Request No.", Rec."No.");
        if ExpenseReportLine.FindFirst() then
            Error(GetLinkedExpenseReportError(ExpenseReportLine.RecordId, Page::"Expense Report Lines"));

        PostedExpenseReportHeader.SetRange("Spend Request No.", Rec."No.");
        if PostedExpenseReportHeader.FindFirst() then
            Error(GetLinkedExpenseReportError(PostedExpenseReportHeader.RecordId, Page::"Posted Expense Report"));

        PostedExpenseReportLine.SetRange("Spend Request No.", Rec."No.");
        if PostedExpenseReportLine.FindFirst() then
            Error(GetLinkedExpenseReportError(PostedExpenseReportLine.RecordId, Page::"Posted Expense Report Lines"));
    end;

    trigger OnDelete()
    var
        Traveler: Record Traveler;
        ExpenseActivityLogMgt: Codeunit "Expense Activity Log Mgt.";
    begin
        Traveler.SetRange("Spend Request No.", Rec."No.");
        Traveler.DeleteAll();

        if Rec."Document Type" = Rec."Document Type"::"Travel Request" then
            ExpenseActivityLogMgt.DeleteEntriesForSource(Database::"Spend Request", Rec.SystemId);
    end;

    var
        ReplaceRequestedForTravelerQst: Label 'The %1 was changed. A traveler was automatically added for the previous %1. Do you want to remove that traveler and add a new one for the current %1 instead?', Comment = '%1 = Requested For field caption';
        ExpenseLocationRequiresPerDiemErr: Label '%1 can only be specified when %2 is selected.', Comment = '%1 = Expense Location field caption, %2 = Per Diem Included field caption';
        ActualEndBeforeStartErr: Label '%1 cannot be before %2.', Comment = '%1 = Actual End Date and Time field caption, %2 = Actual Start Date and Time field caption';

    internal procedure CheckExpenseLocation()
    begin
        if (Rec."Expense Location" <> '') and not Rec."Per Diem Included" then
            Error(ExpenseLocationRequiresPerDiemErr, Rec.FieldCaption("Expense Location"), Rec.FieldCaption("Per Diem Included"));
    end;

    internal procedure CheckActualDateTimes()
    begin
        if (Rec."Actual Start Date and Time" = 0DT) or (Rec."Actual End Date and Time" = 0DT) then
            exit;

        if Rec."Actual End Date and Time" < Rec."Actual Start Date and Time" then
            Error(ActualEndBeforeStartErr, Rec.FieldCaption("Actual End Date and Time"), Rec.FieldCaption("Actual Start Date and Time"));
    end;

    local procedure GetLinkedExpenseReportError(ReportRecordId: RecordId; ReportPageNo: Integer): ErrorInfo
    var
        LinkedReportError: ErrorInfo;
        LinkedExpenseReportExistsErr: Label 'You cannot delete travel request %1 because it is linked to an expense report.', Comment = '%1 = Travel request number';
        LinkedExpenseReportTitleErr: Label 'Travel request is linked to an expense report';
        LinkedExpenseReportDetailsErr: Label 'Open the related report to see where this travel request is used. Posted history cannot be removed by deleting the travel request.';
        ShowItLbl: Label 'Show it';
    begin
        LinkedReportError.Message := StrSubstNo(LinkedExpenseReportExistsErr, Rec."No.");
        LinkedReportError.Title := LinkedExpenseReportTitleErr;
        LinkedReportError.DetailedMessage := LinkedExpenseReportDetailsErr;
        LinkedReportError.DataClassification := DataClassification::CustomerContent;
        LinkedReportError.ErrorType := ErrorType::Client;
        LinkedReportError.RecordId := ReportRecordId;
        LinkedReportError.PageNo := ReportPageNo;
        LinkedReportError.AddNavigationAction(ShowItLbl);
        exit(LinkedReportError);
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
        Traveler: Record Traveler;
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if Rec."Requested For" = PreviousRequestedFor then
            exit;

        // A previous traveler with a linked expense report stays on the travel request.
        if (PreviousRequestedFor <> '') and RequestedForTravelerExists(PreviousRequestedFor) and
           not Traveler.HasLinkedExpenseReports(Rec."No.", PreviousRequestedFor)
        then begin
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