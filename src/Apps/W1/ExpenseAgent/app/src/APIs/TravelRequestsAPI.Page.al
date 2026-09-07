// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.SpendRequest;

page 7134 "Travel Requests API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Travel Request';
    EntitySetCaption = 'Travel Requests';
    DelayedInsert = true;
    EntityName = 'travelRequest';
    EntitySetName = 'travelRequests';
    PageType = API;
    ODataKeyFields = SystemId;
    SourceTable = "Spend Request";
    SourceTableView = where("Document Type" = const("Travel Request"));
    AboutText = 'Provides access to data from the Travel Request table';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(number; Rec."No.")
                {
                    Caption = 'No.';
                }
                field(requestedBy; Rec."Requested By")
                {
                    Caption = 'Requested By';
                    ToolTip = 'Specifies the employee who created the request. This value can be set only when creating the request.';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                    Editable = false;
                }
                field(glAccountNo; Rec."G/L Account No.")
                {
                    Caption = 'G/L Account No.';
                }
                field(purpose; Rec.Purpose)
                {
                    Caption = 'Purpose';
                }
                field(currencyCode; Rec."Currency Code")
                {
                    Caption = 'Currency Code';
                }
                field(totalExpectedAmount; Rec."Total Expected Amount")
                {
                    Caption = 'Total Expected Amount';
                }
                field(totalExpectedAmountLCY; Rec."Total Expected Amount (LCY)")
                {
                    Caption = 'Total Expected Amount (LCY)';
                    Editable = false;
                }
                field(totalSpentAmountLCY; Rec."Total Spent Amount (LCY)")
                {
                    Caption = 'Total Spent Amount (LCY)';
                    Editable = false;
                }
                field(totalLineAmountLCY; Rec."Total Line Amount (LCY)")
                {
                    Caption = 'Total Line Amount (LCY)';
                    Editable = false;
                }
                field(expectedStartDate; ExpectedStartDate)
                {
                    Caption = 'Expected Start Date';

                    trigger OnValidate()
                    begin
                        ExpectedStartDateProvided := true;
                    end;
                }
                field(expectedEndDate; ExpectedEndDate)
                {
                    Caption = 'Expected End Date';

                    trigger OnValidate()
                    begin
                        ExpectedEndDateProvided := true;
                    end;
                }
                field(closedAt; Rec."Closed At")
                {
                    Caption = 'Closed At';
                    Editable = false;
                }
                field(closedByDocumentNo; Rec."Closed By Document No.")
                {
                    Caption = 'Closed By Document No.';
                    Editable = false;
                }
                field(shortcutDimension1Code; Rec."Shortcut Dimension 1 Code")
                {
                    Caption = 'Shortcut Dimension 1 Code';
                }
                field(shortcutDimension2Code; Rec."Shortcut Dimension 2 Code")
                {
                    Caption = 'Shortcut Dimension 2 Code';
                }
                field(requestedFor; Rec."Requested For")
                {
                    Caption = 'Requested For';
                }
                field(businessJustification; Rec."Business Justification")
                {
                    Caption = 'Business Justification';
                }
                field(travelPolicyAcknowledgment; Rec."Travel Policy Acknowledgment")
                {
                    Caption = 'Travel Policy Acknowledgment';
                }
                field(internationalTravel; Rec."International Travel")
                {
                    Caption = 'International Travel';
                }
                field(originCountry; Rec."Origin Country/Region Code")
                {
                    Caption = 'Origin Country';
                }
                field(destinationCountry; Rec."Dest. Country/Region Code")
                {
                    Caption = 'Destination Country';
                }
                field(restrictions; Rec.Restrictions)
                {
                    Caption = 'Restrictions';
                }
                field(perDiemIncluded; Rec."Per Diem Included")
                {
                    Caption = 'Per Diem Included';
                }
                field(actualStartDateAndTime; Rec."Actual Start Date and Time")
                {
                    Caption = 'Actual Start Date and Time';
                }
                field(actualEndDateAndTime; Rec."Actual End Date and Time")
                {
                    Caption = 'Actual End Date and Time';
                }
                field(submittedByExpenseUserNo; Rec."Submitted By Expense User No.")
                {
                    Caption = 'Submitted By Expense User No.';
                    ToolTip = 'Specifies the expense user who submitted the travel request.';
                    Editable = false;
                }
                field(submittedAt; Rec."Submitted At")
                {
                    Caption = 'Submitted At';
                    ToolTip = 'Specifies the date and time when the travel request was submitted.';
                    Editable = false;
                }
                field(approvalExpenseUserNo; Rec."Approval Expense User No.")
                {
                    Caption = 'Approval Expense User No.';
                    ToolTip = 'Specifies the expense user who approved or rejected the travel request.';
                    Editable = false;
                }
                field(rejectionReason; Rec."Rejection Reason")
                {
                    Caption = 'Rejection Reason';
                    ToolTip = 'Specifies the reason the travel request was rejected.';
                    Editable = false;
                }
                part(travelRequestDetails; "Travel Request Details API")
                {
                    Caption = 'Travel Request Details';
                    EntityName = 'travelRequestDetail';
                    EntitySetName = 'travelRequestDetails';
                    SubPageLink = "Spend Request No." = field("No.");
                }
                part(travelers; "Travelers API")
                {
                    Caption = 'Travelers';
                    EntityName = 'traveler';
                    EntitySetName = 'travelers';
                    SubPageLink = "Spend Request No." = field("No.");
                }
            }
        }
    }

    trigger OnInit()
    var
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
    end;

    trigger OnOpenPage()
    begin
        Rec.AddLoadFields("Expected Start Date", "Expected End Date");
    end;

    trigger OnAfterGetRecord()
    begin
        ExpectedStartDate := Rec."Expected Start Date";
        ExpectedEndDate := Rec."Expected End Date";
        ExpectedStartDateProvided := false;
        ExpectedEndDateProvided := false;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(ExpectedStartDate);
        Clear(ExpectedEndDate);
        ExpectedStartDateProvided := false;
        ExpectedEndDateProvided := false;
    end;

    [ServiceEnabled]
    procedure SubmitTravelRequest(var ActionContext: WebServiceActionContext; SubmitterExpenseUserNo: Code[20])
    var
        TravelRequestApproval: Codeunit "Travel Request Approval";
    begin
        TravelRequestApproval.Submit(Rec, SubmitterExpenseUserNo);
        SetActionResponse(ActionContext);
    end;

    [ServiceEnabled]
    procedure ApproveTravelRequest(var ActionContext: WebServiceActionContext; ApproverExpenseUserNo: Code[20])
    var
        TravelRequestApproval: Codeunit "Travel Request Approval";
    begin
        TravelRequestApproval.Approve(Rec, ApproverExpenseUserNo);
        SetActionResponse(ActionContext);
    end;

    [ServiceEnabled]
    procedure RejectTravelRequest(var ActionContext: WebServiceActionContext; ApproverExpenseUserNo: Code[20]; RejectReason: Text)
    var
        TravelRequestApproval: Codeunit "Travel Request Approval";
    begin
        TravelRequestApproval.Reject(Rec, ApproverExpenseUserNo, RejectReason);
        SetActionResponse(ActionContext);
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        ProcessApproverFilter();
        exit(Rec.Find(Which));
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec."Document Type" := Rec."Document Type"::"Travel Request";
        Rec.TestField("Requested By");
        Rec.SetExpectedDatesForAPIInsert(ExpectedStartDate, ExpectedEndDate, ExpectedStartDateProvided, ExpectedEndDateProvided);
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if Rec.Status <> xRec.Status then
            Rec.FieldError(Status, StatusCannotBeChangedErr);
        // Allow the owner on POST and unchanged in PATCH payloads, but reject reassignment.
        if Rec."Requested By" <> xRec."Requested By" then
            Rec.FieldError("Requested By", RequestedByCannotBeChangedErr);

        Rec.ApplyExpectedDatesFromAPI(ExpectedStartDate, ExpectedEndDate, ExpectedStartDateProvided, ExpectedEndDateProvided);
        exit(true);
    end;

    local procedure ProcessApproverFilter()
    var
        TravelRequestApproval: Codeunit "Travel Request Approval";
        ApproverExpenseUserNo: Code[20];
        OriginalFilterGroup: Integer;
    begin
        if ApproverFilterApplied then
            exit;

        OriginalFilterGroup := Rec.FilterGroup(4);
        ApproverExpenseUserNo := CopyStr(Rec.GetFilter("Approver Expense User Filter"), 1, MaxStrLen(ApproverExpenseUserNo));
        if ApproverExpenseUserNo <> '' then
            TravelRequestApproval.ApplyApproverFilter(Rec, ApproverExpenseUserNo);
        Rec.FilterGroup(OriginalFilterGroup);
        ApproverFilterApplied := true;
    end;

    local procedure SetActionResponse(var ActionContext: WebServiceActionContext)
    begin
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Travel Requests API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    var
        ExpectedStartDate: Date;
        ExpectedEndDate: Date;
        ExpectedStartDateProvided: Boolean;
        ExpectedEndDateProvided: Boolean;
        ApproverFilterApplied: Boolean;
        StatusCannotBeChangedErr: Label 'can be changed only by submitting, approving, or rejecting the travel request';
        RequestedByCannotBeChangedErr: Label 'cannot be changed';
}
