// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;
using System.Text;

page 6928 "Expense Reports API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Expense Report';
    EntitySetCaption = 'Expense Reports';
    DelayedInsert = true;
    EntityName = 'expenseReport';
    EntitySetName = 'expenseReports';
    PageType = API;
    ODataKeyFields = SystemId;
    SourceTable = "Expense Report Header";
    AboutText = 'Provides access to data from the Expense Report Header table';

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
                field(expenseUserNumber; Rec."Expense User No.")
                {
                    Caption = 'Expense User Number';
                }
                field(expenseUserSystemId; ExpenseUserSystemId)
                {
                    Caption = 'Expense User System Id';
                }
                field(expenseUserName; Rec."Expense User Name")
                {
                    Caption = 'Expense User Name';
                }
                field(expenseReportDate; Rec."Expense Report Date")
                {
                    Caption = 'Expense Report Date';
                }
                field(postingDate; Rec."Posting Date")
                {
                    Caption = 'Posting Date';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(amountLCY; Rec."Amount (LCY)")
                {
                    Caption = 'Total Amount (LCY)';
                }
                field(nonRefundableAmountLCY; Rec."Non-Refundable Amount (LCY)")
                {
                    Caption = 'Non-Refundable Amount (LCY)';
                }
                field(amountWithoutVATLCY; Rec."Amount without VAT (LCY)")
                {
                    Caption = 'Amount without VAT (LCY)';
                }
                field(currencyLCY; CurrencyLCYDisplay)
                {
                    Caption = 'Currency (LCY)';
                    Editable = false;
                }
                field(reimbursableAmount; Rec."Reimbursable Amount")
                {
                    Caption = 'Reimbursable Amount';
                }
                field(reimbursableAmountLCY; Rec."Reimbursable Amount (LCY)")
                {
                    Caption = 'Reimbursable Amount (LCY)';
                }
                field(vatAmountLCY; Rec."VAT Amount (LCY)")
                {
                    Caption = 'VAT Amount (LCY)';
                }
                field(shortcutDimension1Code; Rec."Shortcut Dimension 1 Code")
                {
                    Caption = 'Shortcut Dimension 1 Code';
                }
                field(shortcutDimension2Code; Rec."Shortcut Dimension 2 Code")
                {
                    Caption = 'Shortcut Dimension 2 Code';
                }
                field(employeePostingGroup; Rec."Employee Posting Group")
                {
                    Caption = 'Employee Posting Group';
                }
                field(languageCode; Rec."Language Code")
                {
                    Caption = 'Language Code';
                }
                field(comment; Rec.Comment)
                {
                    Caption = 'Comment';
                }
                field(reasonCode; Rec."Reason Code")
                {
                    Caption = 'Reason Code';
                }
                field(noSeries; Rec."No. Series")
                {
                    Caption = 'No. Series';
                }
                field(postingNoSeries; Rec."Posting No. Series")
                {
                    Caption = 'Posting No. Series';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field(antiCorruptionAttestation; Rec."Anti-corruption attestation")
                {
                    Caption = 'Anti-Corruption Attestation';
                }
                field(antiCorruptionDescription; Rec."Anti-corruption description")
                {
                    Caption = 'Anti-Corruption Description';
                }
                field(corrected; Rec.Corrected)
                {
                    Caption = 'Corrected';
                }
                field(correctedDocumentNo; Rec."Corrected Document No.")
                {
                    Caption = 'Corrected Document No.';
                }
                field(submissionDateTime; Rec."Submission DateTime")
                {
                    Caption = 'Submission Date and Time';
                }
                field(approvedRejectedDateTime; Rec."Approved/Rejected DateTime")
                {
                    Caption = 'Approved/Rejected Date and Time';
                }
                field(approvedRejectedByDisplayName; Rec."Approved/Rejected Exp.UserName")
                {
                    Caption = 'Approved/Rejected By Expense User Display Name';
                    Editable = false;
                }
                field(approvedRejectedByExpUserNo; Rec."Approved/Rejected Exp.User No.")
                {
                    Caption = 'Approved/Rejected By Expense User Number';
                    Editable = false;
                }
                field(approverComment; Rec.GetApproverComment())
                {
                    Caption = 'Approver Comment';
                    Editable = false;
                }
                field(submitterComment; Rec.GetSubmitterComment())
                {
                    Caption = 'Submitter Comment';
                    Editable = false;
                }
                field(finalApproverNo; Rec."Final Approver No.")
                {
                    Caption = 'Final Approver No.';
                    Editable = false;
                }
                field(finalApproverName; Rec."Final Approver Name")
                {
                    Caption = 'Final Approver Name';
                    Editable = false;
                }
                field(interimApproverNo; Rec."Interim Approver No.")
                {
                    Caption = 'Interim Approver No.';
                    Editable = false;
                }
                field(interimApproverName; Rec."Interim Approver Name")
                {
                    Caption = 'Interim Approver Name';
                    Editable = false;
                }
                field(reimbursementCurrencyCode; ReimbursementCurrencyCodeDisplay)
                {
                    Caption = 'Reimbursement Currency Code';

                    trigger OnValidate()
                    begin
                        Rec."Reimbursement Currency Code" := CurrencyHelper.GetCurrencyCodeFromAPI(ReimbursementCurrencyCodeDisplay);
                    end;
                }
                field(responsibilityCenter; Rec."Responsibility Center")
                {
                    Caption = 'Responsibility Center';
                }
                field(systemCreatedAt; Rec.SystemCreatedAt)
                {
                    Caption = 'System Created At';
                    Editable = false;
                }
                field(systemModifiedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'System Modified At';
                    Editable = false;
                }
                field(systemCreatedBy; Rec.SystemCreatedBy)
                {
                    Caption = 'System Created By';
                    Editable = false;
                }
                field(systemModifiedBy; Rec.SystemModifiedBy)
                {
                    Caption = 'System Modified By';
                    Editable = false;
                }
                field(createdByExpenseUserId; Rec."Created By Exp. User Id")
                {
                    Caption = 'Created By Expense User Id';
                    Editable = false;
                }
                field(modifiedByExpenseUserId; Rec."Modified By Exp. User Id")
                {
                    Caption = 'Modified By Expense User Id';
                    Editable = false;
                }
                field(spendRequestNo; Rec."Spend Request No.")
                {
                    Caption = 'Travel Request No.';
                }
                field(travelRequestId; Rec."Travel Request SystemId")
                {
                    Caption = 'Travel Request Id';
                    Editable = false;
                }
                field(spendRequestClose; Rec."Spend Request Close")
                {
                    Caption = 'Travel Request Close';
                }
                part(travelRequest; "Travel Requests API")
                {
                    Caption = 'Travel Request';
                    EntityName = 'travelRequest';
                    EntitySetName = 'travelRequests';
                    Multiplicity = ZeroOrOne;
                    SubPageLink = SystemId = field("Travel Request SystemId");
                }
                part(expenseReportLines; "Expense Report Lines API")
                {
                    Caption = 'Expense Report Lines';
                    EntityName = 'expenseReportLine';
                    EntitySetName = 'expenseReportLines';
                    SubPageLink = "Document No." = field("No.");
                }
                part(activityLogEntries; "Expense Activity Log API")
                {
                    Caption = 'Activity Log Entries';
                    EntityName = 'expenseActivityLogEntry';
                    EntitySetName = 'expenseActivityLogEntries';
                    SubPageLink = "Source Table ID" = const(Database::"Expense Report Header"),
                                  "Source Record System ID" = field(SystemId);
                }
            }
        }
    }

    var
        CurrencyHelper: Codeunit "Expense API Currency Helper";
        EAKPITrack: Codeunit "EA KPI Track";
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
        ExpenseAuditSubscribers: Codeunit "Expense Audit Subscribers";
        CurrencyLCYDisplay: Code[10];
        ReimbursementCurrencyCodeDisplay: Code[10];
        ExpenseUserSystemId: Guid;
        SubmitterFilter: Text;
        ExpenseReportCreatedLbl: Label 'Expense report created via API.', Locked = true;

    trigger OnInit()
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
    end;

    trigger OnOpenPage()
    begin
        // Avoid JIT load consistency errors by ensuring fields read in OnAfterGetRecord are included in the initial record buffer.
        Rec.AddLoadFields("Reimbursement Currency Code", "Expense User No.");
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        ProcessPendingApprovalByFilter();

        exit(Rec.Find(Which));
    end;

    trigger OnAfterGetRecord()
    var
        ExpenseUser: Record "Expense User";
    begin
        CurrencyLCYDisplay := CurrencyHelper.GetCurrencyCodeForAPI('');
        ReimbursementCurrencyCodeDisplay := CurrencyHelper.GetCurrencyCodeForAPI(Rec."Reimbursement Currency Code");
        ExpenseUserSystemId := ExpenseUser.GetSystemIdByExpenseUserNo(Rec."Expense User No.");
    end;

    trigger OnNewRecord(Belowx: Boolean)
    begin
        ReimbursementCurrencyCodeDisplay := '';
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec."Reimbursement Currency Code" := CurrencyHelper.GetCurrencyCodeFromAPI(ReimbursementCurrencyCodeDisplay);
        UpdateExpenseUserNoFromSystemId();
        if ExpenseAgentAPIValidation.IsCurrentUserExpenseAgent() then
            Rec.SetCalledFromExpenseAgent(true);

        // Do NOT remove, used for usage reporting
        Session.LogMessage('0000UBQ', ExpenseReportCreatedLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExpenseAuditSubscribers.TelemetryCategory());
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Rec."Reimbursement Currency Code" := CurrencyHelper.GetCurrencyCodeFromAPI(ReimbursementCurrencyCodeDisplay);
        UpdateExpenseUserNoFromSystemId();
        exit(true);
    end;

    local procedure ProcessPendingApprovalByFilter()
    var
        ApproverCode: Code[20];
        FilterGroup: Integer;
    begin
        FilterGroup := Rec.FilterGroup(4);
        ApproverCode := CopyStr(Rec.GetFilter("Pending Approval By"), 1, MaxStrLen(ApproverCode));

        Rec.SetRange("Pending Approval By");

        if (SubmitterFilter = '') and (ApproverCode <> '') then begin
            // The next line can be database intensive - limit its use
            SubmitterFilter := GetSubmitterFilter(ApproverCode);

            if SubmitterFilter <> '' then
                Rec.SetFilter("Expense User No.", SubmitterFilter)
            else
                // If there is an approver filter that can approve for no submitter, we should show an empty list
                Rec.SetRange(SystemId, CreateGuid());
        end;

        Rec.FilterGroup(FilterGroup);
    end;

    local procedure GetSubmitterFilter(ApproverCode: Code[20]) SubmitterFilterString: Text
    var
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        RecRef: RecordRef;
    begin
        ExpenseApprovalSetup.SetCurrentKey("Approver No.");
        ExpenseApprovalSetup.SetRange("Approver No.", ApproverCode);

        RecRef.GetTable(ExpenseApprovalSetup);
        SubmitterFilterString := SelectionFilterManagement.GetSelectionFilter(RecRef, ExpenseApprovalSetup.FieldNo("Expense User No."));

        ExpenseAgentSetup.Get();
        if ExpenseAgentSetup."Default Approver No." <> ApproverCode then
            exit;
        AppendDefaultSubmittersForDefaultApprover(SubmitterFilterString);
        if StrLen(SubmitterFilterString) > 2000 then
            SubmitterFilterString := '*'; // to avoid failing sql statements
    end;

    local procedure AppendDefaultSubmittersForDefaultApprover(var SubmitterFilterString: Text)
    var
        ExpenseUser: Record "Expense User";
        DefaultFilter: TextBuilder;
    begin
        if SubmitterFilterString <> '' then
            DefaultFilter.Append(SubmitterFilterString);

        ExpenseUser.SetAutoCalcFields("Approver No.");
        ExpenseUser.SetFilter("Approver No.", '%1', '');
        ExpenseUser.SetLoadFields("No.");
        if ExpenseUser.FindSet() then
            repeat
                if DefaultFilter.Length > 0 then
                    DefaultFilter.Append('|');
                DefaultFilter.Append(ExpenseUser."No.");
            until ExpenseUser.Next() = 0;

        SubmitterFilterString := DefaultFilter.ToText();
    end;

    local procedure UpdateExpenseUserNoFromSystemId()
    var
        ExpenseUser: Record "Expense User";
        NewExpenseUserNo: Code[20];
    begin
        NewExpenseUserNo := ExpenseUser.GetExpenseUserNoBySystemId(ExpenseUserSystemId);
        if (NewExpenseUserNo <> '') and (Rec."Expense User No." <> NewExpenseUserNo) then
            Rec."Expense User No." := NewExpenseUserNo;
    end;

    [ServiceEnabled]
    procedure ReleaseExpenseReport(var ActionContext: WebServiceActionContext)
    begin
        Rec.PerformManualRelease();
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Expense Reports API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    [ServiceEnabled]
    procedure ReopenExpenseReport(var ActionContext: WebServiceActionContext)
    begin
        Rec.PerformManualReopen(Rec);

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Expense Reports API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    [ServiceEnabled]
    procedure PendingApprovalExpenseReport(var ActionContext: WebServiceActionContext; SubmitterExpenseUserNo: Code[20])
    begin
        Rec.PerformManualPendingApproval(SubmitterExpenseUserNo);

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Expense Reports API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

#if not CLEAN30
    [Obsolete('Use ReleaseAndMarkPendingApprovalExpenseReportWithComment instead.', '30.0')]
    [ServiceEnabled]
    procedure ReleaseAndMarkPendingApprovalExpenseReport(var ActionContext: WebServiceActionContext; SubmitterExpenseUserNo: Code[20])
    begin
        Rec.PerformManualReleaseAndPendingApproval(SubmitterExpenseUserNo, '');

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Expense Reports API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

#endif
    [ServiceEnabled]
    procedure ReleaseAndMarkPendingApprovalExpenseReportWithComment(var ActionContext: WebServiceActionContext; SubmitterExpenseUserNo: Code[20]; SubmissionComment: Text)
    begin
        Rec.PerformManualReleaseAndPendingApproval(SubmitterExpenseUserNo, SubmissionComment);

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Expense Reports API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    [ServiceEnabled]
    procedure ApprovedExpenseReport(var ActionContext: WebServiceActionContext; ApproverExpenseUserNo: Code[20])
    begin
        Rec.PerformManualApproved(ApproverExpenseUserNo);

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Expense Reports API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    [ServiceEnabled]
    procedure ApprovedExpenseReportWithPolicyOverride(var ActionContext: WebServiceActionContext; ApproverExpenseUserNo: Code[20]; SkipPolicyValidation: Boolean)
    begin
        Rec.PerformManualApproved(ApproverExpenseUserNo, SkipPolicyValidation);

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Expense Reports API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    [ServiceEnabled]
    procedure RejectedExpenseReport(var ActionContext: WebServiceActionContext; ApproverExpenseUserNo: Code[20]; RejectReason: Text)
    begin
        Rec.PerformManualRejected(ApproverExpenseUserNo, RejectReason);

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Expense Reports API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    [ServiceEnabled]
    procedure RejectAndReopenExpenseReport(var ActionContext: WebServiceActionContext; ApproverExpenseUserNo: Code[20]; RejectReason: Text)
    begin
        Rec.PerformManualRejectedAndReopen(ApproverExpenseUserNo, RejectReason);

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Expense Reports API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    [ServiceEnabled]
    procedure AddExpenseToReport(var ActionContext: WebServiceActionContext; ExpenseId: Guid)
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseNotFoundErr: Label 'Expense with Id %1 not found.', Comment = '%1 = Expense System Id';
    begin
        Expense.SetRange(SystemId, expenseId);
        if Expense.FindFirst() then begin
            ExpenseReportLine := CreateExpenseReport.AddSingleExpenseToExpenseReport(Expense, Rec);
            EAKPITrack.UpdateExpenseReportLineEntry(ExpenseReportLine);
        end else
            Error(ExpenseNotFoundErr, ExpenseId);

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Expense Reports API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    [ServiceEnabled]
    procedure AssignInterimApprover(var ActionContext: WebServiceActionContext; InterimApproverExpenseUserNo: Code[20]; ActorExpenseUserNo: Code[20])
    begin
        Rec.AssignInterimApprover(InterimApproverExpenseUserNo, ActorExpenseUserNo);

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Expense Reports API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

}