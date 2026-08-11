// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Projects.Project.Job;

#pragma warning disable AS0032 // The field with name 'createdBy' was removed before AS0032 was introduced.
page 6927 "Expenses API"
#pragma warning restore AS0032
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Expense';
    EntitySetCaption = 'Expenses';
    DelayedInsert = true;
    EntityName = 'expense';
    EntitySetName = 'expenses';
    PageType = API;
    ODataKeyFields = SystemId;
    SourceTable = Expense;
    AboutText = 'Provides access to data from the Expense table';

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
                field(expenseReportNo; Rec."Expense Report No.")
                {
                    Caption = 'Expense Report No.';
                }
                field(expenseCategory; Rec."Expense Category")
                {
                    Caption = 'Expense Category';
                }
                field(expenseSubcategory; Rec."Expense Subcategory")
                {
                    Caption = 'Expense Subcategory';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(justification; Rec.Justification)
                {
                    Caption = 'Justification';
                }
                field(expenseDate; Rec."Expense Date")
                {
                    Caption = 'Expense Date';
                }
                field(expenseTime; Rec."Expense Time")
                {
                    Caption = 'Expense Time';
                }
                field(expenseExtDocNo; Rec."Expense Ext. Doc. No.")
                {
                    Caption = 'Expense External Document No.';
                }
                field(currencyCode; CurrencyCodeDisplay)
                {
                    Caption = 'Currency Code';

                    trigger OnValidate()
                    begin
                        Rec."Currency Code" := CurrencyHelper.GetCurrencyCodeFromAPI(CurrencyCodeDisplay);
                    end;
                }
                field(amount; Rec.Amount)
                {
                    Caption = 'Amount';
                }
                field(amountLCY; Rec."Amount (LCY)")
                {
                    Caption = 'Amount (LCY)';
                }
                field(currencyLCY; CurrencyLCYDisplay)
                {
                    Caption = 'Currency (LCY)';
                    Editable = false;
                }
                field(merchantName; Rec."Merchant Name")
                {
                    Caption = 'Merchant Name';
                }
                field(merchantRegistrationNumber; Rec."Merchant Registration No.")
                {
                    Caption = 'Merchant Registration Number';
                }
                field(merchantVATNumber; Rec."Merchant VAT Registration No.")
                {
                    Caption = 'Merchant VAT Registration Number';
                }
                field(receiptAttached; Rec."Receipt Attached")
                {
                    Caption = 'Receipt Attached';
                }
                field(receiptEntry; Rec."Receipt Entry")
                {
                    Caption = 'Receipt Entry';
                }
                field(shortcutDimension1Code; Rec."Shortcut Dimension 1 Code")
                {
                    Caption = 'Shortcut Dimension 1 Code';
                }
                field(shortcutDimension2Code; Rec."Shortcut Dimension 2 Code")
                {
                    Caption = 'Shortcut Dimension 2 Code';
                }
                field(paymentMethodCode; Rec."Payment Method Code")
                {
                    Caption = 'Payment Method Code';
                }
                field(refundable; Rec.Refundable)
                {
                    Caption = 'Refundable';
                }
                field(billable; Rec.Billable)
                {
                    Caption = 'Billable';
                }
                field(billableToCustomer; Rec."Billable to Customer")
                {
                    Caption = 'Billable to Customer';
                }
                field(expenseLocation; Rec."Expense Location")
                {
                    Caption = 'Expense Location';
                }
                field(startingDateAndTime; Rec."Starting Date and Time")
                {
                    Caption = 'Starting Date and Time';
                }
                field(endingDateAndTime; Rec."Ending Date and Time")
                {
                    Caption = 'Ending Date and Time';
                }
                field(nonRefundableAmount; Rec."Non-Refundable Amount")
                {
                    Caption = 'Non-Refundable Amount';
                }
                field(mileage; Rec.Mileage)
                {
                    Caption = 'Mileage';
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'Unit of Measure Code';
                }
                field(startingPoint; Rec."Starting Point")
                {
                    Caption = 'Starting Point';
                }
                field(endingPoint; Rec."Ending Point")
                {
                    Caption = 'Ending Point';
                }
                field(roundTrip; Rec."Round Trip")
                {
                    Caption = 'Round Trip';
                    ToolTip = 'Specifies whether the mileage expense is a round trip.';
                }
                field(totalMileage; TotalMileage)
                {
                    Caption = 'Total Mileage';
                    ToolTip = 'Specifies the total mileage for reimbursement.';
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
                field(creditCardFeedNo; Rec."Credit Card Feed No.")
                {
                    Caption = 'Credit Card Feed No.';
                }
                field(extractionConfidence; Rec."Extraction Confidence")
                {
                    Caption = 'Extraction Confidence';
                }
                field(vatBusPostingGroup; Rec."VAT Bus. Posting Group")
                {
                    Caption = 'VAT Bus. Posting Group';
                }
                field(vatProdPostingGroup; Rec."VAT Prod. Posting Group")
                {
                    Caption = 'VAT Prod. Posting Group';
                }
                field(expenseDetailRequired; Rec."Expense Detail Required")
                {
                    Caption = 'Expense Detail Required';
                }
                field(applyRuleId; Rec."Applied Rule Id")
                {
                    Caption = 'Applied Rule Id';
                }
                field(reimbursementType; Rec."Reimbursement Type")
                {
                    Caption = 'Reimbursement Type';
                }
                field(ruleViolations; Rec."Rule Violations")
                {
                    Caption = 'Rule Violations';
                }
                field(createdDateTime; Rec."Created Date-Time")
                {
                    Caption = 'Created Date Time';
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
                field(projectNo; Rec."Job No.")
                {
                    Caption = 'Project No.';
                }
                field(projectTaskNo; Rec."Job Task No.")
                {
                    Caption = 'Project Task No.';
                }
                field(projectDescription; JobDescription)
                {
                    Caption = 'Project Description';
                    Editable = false;
                }
                field(projectTaskDescription; JobTaskDescription)
                {
                    Caption = 'Project Task Description';
                    Editable = false;
                }

                part(attachments; "Expense Attachments API")
                {
                    EntityName = 'expenseAttachment';
                    EntitySetName = 'expenseAttachments';
                    SubPageLink = "Document Id" = field(SystemId);
                }
                part(expenseItemizations; "Expense Itemizations API")
                {
                    Caption = 'Expense Itemizations';
                    EntityName = 'expenseItemization';
                    EntitySetName = 'expenseItemizations';
                    SubPageLink = "Expense No." = field("No.");
                }
                part(expenseParticipants; "Expense Participants API")
                {
                    Caption = 'Expense Participants';
                    EntityName = 'expenseParticipant';
                    EntitySetName = 'expenseParticipants';
                    SubPageLink = "Expense No." = field("No.");
                }
                part(expensePerDiem; "Expense Per Diem API")
                {
                    Caption = 'Expense Per Diem';
                    EntityName = 'expenseperdiem';
                    EntitySetName = 'expenseperdiems';
                    SubPageLink = "Expense No." = field("No.");
                }
                part(expenseRuleViolations; "Expense Rule Violations API")
                {
                    Caption = 'Expense Rule Violations';
                    EntityName = 'expenseRuleViolation';
                    EntitySetName = 'expenseRuleViolations';
                    SubPageLink = "Expense No." = field("No.");
                }
            }
        }
    }
    var
        CurrencyHelper: Codeunit "Expense API Currency Helper";
        ExpenseAutoPopulation: Codeunit "Expense Auto Population";
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
        ExpenseAuditSubscribers: Codeunit "Expense Audit Subscribers";
        CurrencyCodeDisplay: Code[10];
        XCurrencyCodeDisplay: Code[10];
        CurrencyLCYDisplay: Code[10];
        ExpenseUserSystemId: Guid;
        TotalMileage: Decimal;
        JobDescription: Text[100];
        JobTaskDescription: Text[100];
        ExpenseCreatedLbl: Label 'Expense created via API.', Locked = true;

    trigger OnInit()
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
        CurrencyLCYDisplay := CurrencyHelper.GetCurrencyCodeForAPI('');
    end;

    trigger OnOpenPage()
    begin
        // Avoid JIT load consistency errors by ensuring fields read in OnAfterGetRecord are included in the initial record buffer.
        Rec.AddLoadFields("Currency Code", "Expense User No.", Mileage, "Round Trip");
    end;

    trigger OnAfterGetRecord()
    var
        ExpenseUser: Record "Expense User";
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        CurrencyCodeDisplay := CurrencyHelper.GetCurrencyCodeForAPI(Rec."Currency Code");
        XCurrencyCodeDisplay := CurrencyCodeDisplay;
        ExpenseUserSystemId := ExpenseUser.GetSystemIdByExpenseUserNo(Rec."Expense User No.");
        TotalMileage := ExpenseAutoPopulation.GetEffectiveDistance(Rec.Mileage, Rec."Round Trip");

        JobDescription := '';
        JobTaskDescription := '';
        if Rec."Job No." <> '' then begin
            Job.SetLoadFields(Description);
            if Job.Get(Rec."Job No.") then
                JobDescription := Job.Description;
            if Rec."Job Task No." <> '' then begin
                JobTask.SetLoadFields(Description);
                if JobTask.Get(Rec."Job No.", Rec."Job Task No.") then
                    JobTaskDescription := JobTask.Description;
            end;
        end;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        CurrencyCodeDisplay := '';
        XCurrencyCodeDisplay := '';
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if CurrencyCodeDisplay <> XCurrencyCodeDisplay then
            Rec."Currency Code" := CurrencyHelper.GetCurrencyCodeFromAPI(CurrencyCodeDisplay);
        UpdateExpenseUserNoFromSystemId();
        if ExpenseAgentAPIValidation.IsCurrentUserExpenseAgent() then
            Rec.SetCalledFromExpenseAgent(true);

        // Do NOT remove, used for usage reporting
        Session.LogMessage('0000UBR', ExpenseCreatedLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExpenseAuditSubscribers.TelemetryCategory());
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if CurrencyCodeDisplay <> XCurrencyCodeDisplay then
            Rec."Currency Code" := CurrencyHelper.GetCurrencyCodeFromAPI(CurrencyCodeDisplay);
        UpdateExpenseUserNoFromSystemId();
        exit(true);
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
    procedure ReleaseExpense(var ActionContext: WebServiceActionContext)
    begin
        Rec.PerformManualRelease();

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Expenses API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    [ServiceEnabled]
    procedure ReopenExpense(var ActionContext: WebServiceActionContext)
    begin
        Rec.PerformManualReopen(Rec);

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Expenses API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    [ServiceEnabled]
    procedure ValidateExpenseRule(var ActionContext: WebServiceActionContext)
    begin
        Rec.ApplyRule(false, true);

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Expenses API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    [ServiceEnabled]
    procedure ApplyExpenseRule(var ActionContext: WebServiceActionContext)
    begin
        Rec.ApplyRule();
        Rec.Modify();

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Expenses API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}