// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.SpendRequest;
using System.Telemetry;

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
    Permissions = tabledata "Spend Request" = rimd,
                  tabledata "Spend Request Detail" = rmd,
                  tabledata "Spend Request To G/L Link" = rd,
                  tabledata "Expense Report Header" = ri,
                  tabledata "Posted Expense Report Header" = r,
                  tabledata "Posted Expense Report Line" = r;

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

                    trigger OnValidate()
                    begin
                        RequestedByProvided := true;
                    end;
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
                field(currencyCode; CurrencyCodeDisplay)
                {
                    Caption = 'Currency Code';
                    ToolTip = 'Specifies the currency used for estimation. The local currency is represented by its currency code in the API.';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Currency Code", CurrencyHelper.GetCurrencyCodeFromAPI(CurrencyCodeDisplay));
                    end;
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
                    ToolTip = 'Specifies the expected start date of the travel request.';

                    trigger OnValidate()
                    begin
                        // Assigned without validation so the pair is checked once on insert/modify, regardless of field order.
                        Rec."Expected Start Date" := ExpectedStartDate;
                    end;
                }
                field(expectedEndDate; ExpectedEndDate)
                {
                    Caption = 'Expected End Date';
                    ToolTip = 'Specifies the expected end date of the travel request.';

                    trigger OnValidate()
                    begin
                        // Assigned without validation so the pair is checked once on insert/modify, regardless of field order.
                        Rec."Expected End Date" := ExpectedEndDate;
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
#if not CLEAN30
                field(internationalTravel; Rec."International Travel")
                {
                    Caption = 'International Travel';
                    ObsoleteReason = 'Use expenseLocation instead.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '30.0';
                }
                field(originCountry; Rec."Origin Country/Region Code")
                {
                    Caption = 'Origin Country';
                    ObsoleteReason = 'Use expenseLocation instead.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '30.0';
                }
                field(destinationCountry; Rec."Dest. Country/Region Code")
                {
                    Caption = 'Destination Country';
                    ObsoleteReason = 'Use expenseLocation instead.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '30.0';
                }
#endif
                field(restrictions; Rec.Restrictions)
                {
                    Caption = 'Restrictions';
                }
                field(perDiemIncluded; Rec."Per Diem Included")
                {
                    Caption = 'Per Diem Included';
                }
                field(expenseLocation; Rec."Expense Location")
                {
                    Caption = 'Expense Location';
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
                    Editable = false;
                }
                field(submittedAt; Rec."Submitted At")
                {
                    Caption = 'Submitted At';
                    Editable = false;
                }
                field(submitterComment; Rec."Submitter Comment")
                {
                    Caption = 'Submitter Comment';
                    Editable = false;
                }
                field(approvalExpenseUserNo; Rec."Approval Expense User No.")
                {
                    Caption = 'Approval Expense User No.';
                    Editable = false;
                }
                field(approvedRejectedDateTime; Rec."Approved/Rejected At")
                {
                    Caption = 'Approved/Rejected Date and Time';
                    ToolTip = 'Specifies the date and time when the travel request was approved or rejected.';
                    Editable = false;
                }
                field(approvedRejectedByDisplayName; Rec."Approval Expense User Name")
                {
                    Caption = 'Approved/Rejected By Expense User Display Name';
                    Editable = false;
                }
                field(approvedRejectedByExpUserNo; Rec."Approval Expense User No.")
                {
                    Caption = 'Approved/Rejected By Expense User Number';
                    ToolTip = 'Specifies the expense user who approved or rejected the travel request.';
                    Editable = false;
                }
                field(rejectionReason; Rec."Rejection Reason")
                {
                    Caption = 'Rejection Reason';
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
                part(employees; "Employees API")
                {
                    Caption = 'Employees';
                    EntityName = 'employee';
                    EntitySetName = 'employees';
                    SubPageLink = "Travel Request SystemId Filter" = field(SystemId);
                }
                part(activityLogEntries; "Expense Activity Log API")
                {
                    Caption = 'Activity Log Entries';
                    EntityName = 'expenseActivityLogEntry';
                    EntitySetName = 'expenseActivityLogEntries';
                    SubPageLink = "Source Table ID" = const(Database::"Spend Request"),
                                  "Source Record System ID" = field(SystemId);
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
        Rec.AddLoadFields("Currency Code", "Expected Start Date", "Expected End Date");
    end;

    trigger OnAfterGetRecord()
    begin
        CurrencyCodeDisplay := CurrencyHelper.GetCurrencyCodeForAPI(Rec."Currency Code");
        ExpectedStartDate := Rec."Expected Start Date";
        ExpectedEndDate := Rec."Expected End Date";
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ProcessOwnerFilter();
        Clear(Rec."Requested By");
        RequestedByProvided := false;
        Clear(CurrencyCodeDisplay);
        Clear(ExpectedStartDate);
        Clear(ExpectedEndDate);
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
    procedure SubmitTravelRequestWithComment(var ActionContext: WebServiceActionContext; SubmitterExpenseUserNo: Code[20]; SubmissionComment: Text)
    var
        TravelRequestApproval: Codeunit "Travel Request Approval";
    begin
        TravelRequestApproval.Submit(Rec, SubmitterExpenseUserNo, SubmissionComment);
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

    [ServiceEnabled]
    procedure CreateExpenseReport(var ActionContext: WebServiceActionContext)
    var
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        CheckOwnerScopeRequired();
        Rec.TestField("Document Type", Rec."Document Type"::"Travel Request");
        if Rec.Status <> Rec.Status::Approved then
            Error(GetTravelRequestMustBeApprovedError(Rec));
        Rec.TestField("Requested For");

        if not ExpenseReportHeader.CreateFromApprovedTravelRequestIfMissing(Rec) then begin
            ExpenseReportHeader.SetRange("Spend Request No.", Rec."No.");
            ExpenseReportHeader.SetRange("Expense User No.", Rec."Requested For");
            ExpenseReportHeader.SetLoadFields("No.");
            ExpenseReportHeader.FindFirst();
            Error(GetExpenseReportAlreadyLinkedError(ExpenseReportHeader, Rec));
        end;

        LogCreateExpenseReport();
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Expense Reports API");
        ActionContext.AddEntityKey(ExpenseReportHeader.FieldNo(SystemId), ExpenseReportHeader.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Created);
    end;

    local procedure GetTravelRequestMustBeApprovedError(TravelRequest: Record "Spend Request"): ErrorInfo
    var
        TravelRequestMustBeApprovedError: ErrorInfo;
    begin
        TravelRequestMustBeApprovedError.Message := StrSubstNo(TravelRequestMustBeApprovedErr, TravelRequest."No.");
        TravelRequestMustBeApprovedError.DataClassification := DataClassification::CustomerContent;
        TravelRequestMustBeApprovedError.ErrorType := ErrorType::Client;
        TravelRequestMustBeApprovedError.RecordId := TravelRequest.RecordId;
        TravelRequestMustBeApprovedError.FieldNo := TravelRequest.FieldNo(Status);
        TravelRequestMustBeApprovedError.PageNo := Page::"Travel Request Card";
        TravelRequestMustBeApprovedError.AddNavigationAction(ShowItLbl);
        exit(TravelRequestMustBeApprovedError);
    end;

    local procedure GetExpenseReportAlreadyLinkedError(ExpenseReportHeader: Record "Expense Report Header"; TravelRequest: Record "Spend Request"): ErrorInfo
    var
        ExpenseReportAlreadyLinkedError: ErrorInfo;
    begin
        ExpenseReportAlreadyLinkedError.Message := StrSubstNo(
            ExpenseReportAlreadyLinkedErr, TravelRequest."Requested For", ExpenseReportHeader."No.", TravelRequest."No.");
        ExpenseReportAlreadyLinkedError.Title := ExpenseReportAlreadyLinkedTitleErr;
        ExpenseReportAlreadyLinkedError.DetailedMessage := ExpenseReportAlreadyLinkedDetailsErr;
        ExpenseReportAlreadyLinkedError.DataClassification := DataClassification::EndUserIdentifiableInformation;
        ExpenseReportAlreadyLinkedError.ErrorType := ErrorType::Client;
        ExpenseReportAlreadyLinkedError.RecordId := ExpenseReportHeader.RecordId;
        ExpenseReportAlreadyLinkedError.PageNo := Page::"Expense Report";
        ExpenseReportAlreadyLinkedError.AddNavigationAction(ShowItLbl);
        exit(ExpenseReportAlreadyLinkedError);
    end;

    local procedure LogCreateExpenseReport()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUsage('0000VF2', ExpenseAgentSetup.GetFeatureName(), ExpenseReportCreatedLbl);
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        ProcessOwnerFilter();
        ProcessApproverFilter();
        exit(Rec.Find(Which));
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        StartDate: Date;
        EndDate: Date;
    begin
        Rec."Document Type" := Rec."Document Type"::"Travel Request";
        // Default the owner only at insertion so an owner-only POST remains a record change.
        if not RequestedByProvided then
            Rec."Requested By" := ProcessOwnerFilter();
        Rec.TestField("Requested By");
        CheckOwnerScope();
        CheckTravelDetails();

        // The table's OnInsert defaults both dates to WorkDate, so supplied dates are applied after the insert.
        StartDate := Rec."Expected Start Date";
        EndDate := Rec."Expected End Date";
        // Keep a client-supplied id so batch operations can address the new request by it.
        Rec.Insert(true, true);
        if (StartDate <> 0D) or (EndDate <> 0D) then begin
            if StartDate <> 0D then
                Rec."Expected Start Date" := StartDate;
            if EndDate <> 0D then
                Rec."Expected End Date" := EndDate;
            Rec.Validate("Expected Start Date");
            Rec.Validate("Expected End Date");
            Rec.Modify(true);
        end;
        ExpectedStartDate := Rec."Expected Start Date";
        ExpectedEndDate := Rec."Expected End Date";
        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if Rec.Status <> xRec.Status then
            Rec.FieldError(Status, StatusCannotBeChangedErr);
        // Allow the owner and traveler on POST and unchanged in PATCH payloads, but reject reassignment.
        if Rec."Requested By" <> xRec."Requested By" then
            Rec.FieldError("Requested By", RequestedByCannotBeChangedErr);
        if Rec."Requested For" <> xRec."Requested For" then
            Rec.FieldError("Requested For", RequestedByCannotBeChangedErr);

        CheckOwnerScope();
        if Rec."Expected Start Date" <> xRec."Expected Start Date" then
            Rec.Validate("Expected Start Date");
        if Rec."Expected End Date" <> xRec."Expected End Date" then
            Rec.Validate("Expected End Date");
        CheckTravelDetails();
        exit(true);
    end;

    local procedure CheckTravelDetails()
    begin
        // Checked on save rather than per field, so that the order of the fields in the request does not matter.
        Rec.CheckExpenseLocation();
        Rec.CheckActualDateTimes();
    end;

    local procedure ProcessOwnerFilter() OwnerEmployeeNo: Code[20]
    var
        TravelRequestApproval: Codeunit "Travel Request Approval";
        OwnerSystemId: Guid;
        OriginalFilterGroup: Integer;
    begin
        OriginalFilterGroup := Rec.FilterGroup(4);
        if Rec.GetFilter("Requested By User Id Filter") <> '' then begin
            OwnerSystemId := Rec.GetRangeMin("Requested By User Id Filter");
            OwnerEmployeeNo := TravelRequestApproval.ApplyOwnerFilter(Rec, OwnerSystemId);
        end;
        Rec.FilterGroup(OriginalFilterGroup);
    end;

    local procedure CheckOwnerScope()
    var
        OwnerEmployeeNo: Code[20];
    begin
        OwnerEmployeeNo := ProcessOwnerFilter();
        if OwnerEmployeeNo <> '' then
            Rec.TestField("Requested By", OwnerEmployeeNo);
    end;

    local procedure CheckOwnerScopeRequired()
    var
        OwnerEmployeeNo: Code[20];
    begin
        OwnerEmployeeNo := ProcessOwnerFilter();
        if OwnerEmployeeNo = '' then
            Error(OwnerScopeRequiredErr);
        Rec.TestField("Requested By", OwnerEmployeeNo);
    end;

    local procedure ProcessApproverFilter()
    var
        TravelRequestApproval: Codeunit "Travel Request Approval";
        ApproverExpenseUserNo: Code[20];
        ApproverSystemId: Guid;
        OriginalFilterGroup: Integer;
    begin
        OriginalFilterGroup := Rec.FilterGroup(4);
        if Rec.GetFilter("Approver User Id Filter") <> '' then begin
            ApproverSystemId := Rec.GetRangeMin("Approver User Id Filter");
            TravelRequestApproval.ApplyApproverFilter(Rec, ApproverSystemId);
        end else begin
            ApproverExpenseUserNo := CopyStr(Rec.GetFilter("Approver Expense User Filter"), 1, MaxStrLen(ApproverExpenseUserNo));
            if ApproverExpenseUserNo <> '' then
                TravelRequestApproval.ApplyApproverFilter(Rec, ApproverExpenseUserNo);
        end;
        Rec.FilterGroup(OriginalFilterGroup);
    end;

    local procedure SetActionResponse(var ActionContext: WebServiceActionContext)
    begin
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Travel Requests API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    var
        CurrencyHelper: Codeunit "Expense API Currency Helper";
        CurrencyCodeDisplay: Code[10];
        ExpectedStartDate: Date;
        ExpectedEndDate: Date;
        RequestedByProvided: Boolean;
        StatusCannotBeChangedErr: Label 'can be changed only by submitting, approving, rejecting, or reopening the travel request';
        RequestedByCannotBeChangedErr: Label 'cannot be changed';
        TravelRequestMustBeApprovedErr: Label 'Travel request %1 must be approved before an expense report can be created.', Comment = '%1 = Travel Request No.';
        ExpenseReportAlreadyLinkedErr: Label 'Expense user %1 already has expense report %2 linked to travel request %3.', Comment = '%1 = Expense User No., %2 = Expense Report No., %3 = Travel Request No.';
        ExpenseReportAlreadyLinkedTitleErr: Label 'Expense report already exists';
        ExpenseReportAlreadyLinkedDetailsErr: Label 'Open the existing expense report linked to this travel request.';
        ExpenseReportCreatedLbl: Label 'Expense report created from approved travel request', Locked = true;
        ShowItLbl: Label 'Show it';
        OwnerScopeRequiredErr: Label 'The create expense report action must be invoked through the owning expense user.';
}
