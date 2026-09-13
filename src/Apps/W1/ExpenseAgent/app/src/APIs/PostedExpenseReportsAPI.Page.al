// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6957 "Posted Expense Reports API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Posted Expense Report';
    EntitySetCaption = 'Posted Expense Reports';
    EntityName = 'postedExpenseReport';
    EntitySetName = 'postedExpenseReports';
    PageType = API;
    ODataKeyFields = SystemId;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    DataAccessIntent = ReadOnly;
    SourceTable = "Posted Expense Report Header";
    AboutText = 'Provides access to data from the Posted Expense Report Header table';

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
                field(expenseUserNo; Rec."Expense User No.")
                {
                    Caption = 'Expense User No.';
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
                field(antiCorruptionAttestation; Rec."Anti-Corruption Attestation")
                {
                    Caption = 'Anti-Corruption Attestation';
                }
                field(antiCorruptionDescription; Rec."Anti-Corruption Description")
                {
                    Caption = 'Anti-Corruption Description';
                }
                field(corrected; Rec.Corrected)
                {
                    Caption = 'Corrected';
                }
                field(submissionDateTime; Rec."Submission DateTime")
                {
                    Caption = 'Submission Date and Time';
                }
                field(approvedRejectedDateTime; Rec."Approved/Rejected DateTime")
                {
                    Caption = 'Approved/Rejected Date and Time';
                }
                field(approvedRejectedBy; Rec."Approved/Rejected By")
                {
                    Caption = 'Approved/Rejected By';
                }
                field(currencyCode; CurrencyCodeDisplay)
                {
                    Caption = 'Currency Code';
                }
                field(responsibilityCenter; Rec."Responsibility Center")
                {
                    Caption = 'Responsibility Center';
                }
                field(spendRequestNo; Rec."Spend Request No.")
                {
                    Caption = 'Travel Request No.';
                }
                field(spendRequestClose; Rec."Spend Request Close")
                {
                    Caption = 'Travel Request Close';
                }
                part(postedExpenseReportLines; "Posted Exp. Report Lines API")
                {
                    Caption = 'Posted Expense Report Lines';
                    EntityName = 'postedExpenseReportLine';
                    EntitySetName = 'postedExpenseReportLines';
                    SubPageLink = "Document No." = field("No.");
                }
                part(activityLogEntries; "Expense Activity Log API")
                {
                    Caption = 'Activity Log Entries';
                    EntityName = 'expenseActivityLogEntry';
                    EntitySetName = 'expenseActivityLogEntries';
                    SubPageLink = "Source Table ID" = const(Database::"Posted Expense Report Header"),
                                  "Source Record System ID" = field(SystemId);
                }
            }
        }
    }

    var
        CurrencyHelper: Codeunit "Expense API Currency Helper";
        CurrencyCodeDisplay: Code[10];
        CurrencyLCYDisplay: Code[10];

    trigger OnInit()
    var
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
    end;

    trigger OnOpenPage()
    begin
        // Avoid JIT load consistency errors by ensuring fields read in OnAfterGetRecord are included in the initial record buffer.
        Rec.AddLoadFields("Reimbursement Currency Code");
    end;

    trigger OnAfterGetRecord()
    begin
        CurrencyCodeDisplay := CurrencyHelper.GetCurrencyCodeForAPI(Rec."Reimbursement Currency Code");
        CurrencyLCYDisplay := CurrencyHelper.GetCurrencyCodeForAPI('');
    end;
}
