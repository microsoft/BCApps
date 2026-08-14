// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7122 "Expense Activity Log API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Expense Activity Log Entry';
    EntitySetCaption = 'Expense Activity Log Entries';
    EntityName = 'expenseActivityLogEntry';
    EntitySetName = 'expenseActivityLogEntries';
    PageType = API;
    DelayedInsert = true;
    SourceTable = "Expense Activity Log Entry";
    ODataKeyFields = SystemId;
    DataAccessIntent = ReadOnly;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    AboutText = 'Provides activity history when scoped through an expense report, posted expense report, or expense user. Direct unscoped access is not allowed. Expense user history requires the historyActorRole filter.';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'ID';
                }
                field(entryNumber; Rec."Entry No.")
                {
                    Caption = 'Entry Number';
                }
                field(sourceTableId; Rec."Source Table ID")
                {
                    Caption = 'Source Table ID';
                }
                field(sourceId; Rec."Source Record System ID")
                {
                    Caption = 'Source ID';
                }
                field(subjectTableId; Rec."Subject Table ID")
                {
                    Caption = 'Subject Table ID';
                }
                field(subjectId; Rec."Subject System ID")
                {
                    Caption = 'Subject ID';
                }
                field(documentNumber; Rec."Document No.")
                {
                    Caption = 'Document Number';
                }
                field(documentDescription; Rec."Document Description")
                {
                    Caption = 'Document Description';
                }
                field(eventType; Rec."Event Type")
                {
                    Caption = 'Event Type';
                }
                field(occurredAt; Rec."Occurred At")
                {
                    Caption = 'Occurred At';
                }
                field(initiatedBy; Rec."Initiated By")
                {
                    Caption = 'Initiated By';
                }
                field(actorRole; Rec."Actor Role")
                {
                    Caption = 'Actor Role';
                }
                field(actorTableId; Rec."Actor Table ID")
                {
                    Caption = 'Actor Table ID';
                }
                field(actorId; Rec."Actor Record System ID")
                {
                    Caption = 'Actor ID';
                }
                field(actorDisplayName; Rec."Actor Display Name")
                {
                    Caption = 'Actor Display Name';
                }
                field(comment; Rec.Comment)
                {
                    Caption = 'Comment';
                }
                field(amountLCY; Rec."Amount (LCY)")
                {
                    Caption = 'Amount (LCY)';
                }
                field(currencyLCY; CurrencyLCY)
                {
                    Caption = 'Currency (LCY)';
                }
                field(nonRefundableAmountLCY; Rec."Non-Refundable Amount (LCY)")
                {
                    Caption = 'Non-Refundable Amount (LCY)';
                }
                field(reimbursableAmount; Rec."Reimbursable Amount")
                {
                    Caption = 'Reimbursable Amount';
                }
                field(reimbursableAmountLCY; Rec."Reimbursable Amount (LCY)")
                {
                    Caption = 'Reimbursable Amount (LCY)';
                }
                field(refundableAmount; Rec."Refundable Amount")
                {
                    Caption = 'Refundable Amount';
                }
                field(refundableAmountLCY; Rec."Refundable Amount (LCY)")
                {
                    Caption = 'Refundable Amount (LCY)';
                }
                field(reimbursementCurrencyCode; ReimbursementCurrencyCode)
                {
                    Caption = 'Reimbursement Currency Code';
                }
                field(reimbursementCurrencyFactor; Rec."Reimbursement Currency Factor")
                {
                    Caption = 'Reimbursement Currency Factor';
                }
                field(categories; Rec.Categories)
                {
                    Caption = 'Categories';
                }
                field(attachedReceiptCount; Rec."Attached Receipt Count")
                {
                    Caption = 'Attached Receipt Count';
                }
                field(expenseCount; Rec."Expense Count")
                {
                    Caption = 'Expense Count';
                }
                field(historyActorRole; Rec."History Actor Role Filter")
                {
                    Caption = 'History Actor Role';
                }
            }
        }
    }

    var
        CurrencyHelper: Codeunit "Expense API Currency Helper";
        CurrencyLCY: Code[10];
        HistoryScopeApplied: Boolean;
        ReimbursementCurrencyCode: Code[10];
        HistoryActorRoleRequiredErr: Label 'The historyActorRole filter must be specified as Submitter or Approver.';
        ActivityScopeRequiredErr: Label 'Activity log entries must be requested through an expense report, posted expense report, or expense user.';

    trigger OnInit()
    var
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
    end;

    trigger OnOpenPage()
    begin
        // Avoid JIT load consistency errors by including fields read in OnAfterGetRecord in the initial record buffer.
        Rec.AddLoadFields("Reimbursement Currency Code");
    end;

    trigger OnAfterGetRecord()
    begin
        Clear(CurrencyLCY);
        Clear(ReimbursementCurrencyCode);
        if Rec."Event Type" in [Rec."Event Type"::Submitted, Rec."Event Type"::Resubmitted, Rec."Event Type"::Posted] then begin
            CurrencyLCY := CurrencyHelper.GetCurrencyCodeForAPI('');
            ReimbursementCurrencyCode := CurrencyHelper.GetCurrencyCodeForAPI(Rec."Reimbursement Currency Code");
        end;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        ApplyHistoryScope();
        exit(Rec.Find(Which));
    end;

    local procedure ApplyHistoryScope()
    var
        OriginalFilterGroup: Integer;
        HasHistoryActorFilters: Boolean;
        HasSourceFilters: Boolean;
        HistoryActorRoleFilter: Text;
    begin
        if HistoryScopeApplied then
            exit;

        OriginalFilterGroup := Rec.FilterGroup();
        HistoryActorRoleFilter := Rec.GetFilter("History Actor Role Filter");
        Rec.FilterGroup(4);
        HasSourceFilters :=
            (Rec.GetFilter("Source Table ID") <> '') and
            (Rec.GetFilter("Source Record System ID") <> '');
        HasHistoryActorFilters :=
            (Rec.GetFilter("History Actor Table ID Filter") <> '') and
            (Rec.GetFilter("History Actor System ID Filter") <> '');
        if HistoryActorRoleFilter = '' then
            HistoryActorRoleFilter := Rec.GetFilter("History Actor Role Filter");
        Rec.FilterGroup(0);
        if HasHistoryActorFilters then begin
            if HistoryActorRoleFilter <> '' then begin
                Rec.SetCurrentKey("Occurred At", "Entry No.");
                Rec.Ascending(false);
                Rec.SetRange("History Subject Match", true)
            end else
                Error(HistoryActorRoleRequiredErr);
        end else
            if HasSourceFilters then begin
                Rec.SetCurrentKey("Source Table ID", "Source Record System ID", "Occurred At", "Entry No.");
                Rec.Ascending(false);
            end else
                Error(ActivityScopeRequiredErr);
        Rec.FilterGroup(OriginalFilterGroup);
        HistoryScopeApplied := true;
    end;

}
