// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Projects.Project.Job;

page 6929 "Expense Report Lines API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Expense Report Line';
    EntitySetCaption = 'Expense Report Lines';
    DelayedInsert = true;
    EntityName = 'expenseReportLine';
    EntitySetName = 'expenseReportLines';
    PageType = API;
    ODataKeyFields = SystemId;
    SourceTable = "Expense Report Line";
    AboutText = 'Provides access to data from the Expense Report Line table';

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
                field(documentNo; Rec."Document No.")
                {
                    Caption = 'Document No.';
                }
                field(expenseUserNumber; Rec."Expense User No.")
                {
                    Caption = 'Expense User Number';
                }
                field(expenseUserSystemId; ExpenseUserSystemId)
                {
                    Caption = 'Expense User System Id';
                }
                field(expenseNo; Rec."Expense No.")
                {
                    Caption = 'Expense No.';
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(expenseCategory; Rec."Expense Category")
                {
                    Caption = 'Expense Category';
                }
                field(expenseSubcategoryCode; Rec."Expense Subcategory Code")
                {
                    Caption = 'Expense Subcategory Code';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(justification; Rec.Justification)
                {
                    Caption = 'Justification';
                }
                field(additionalInformation; Rec."Additional Information")
                {
                    Caption = 'Additional Information';
                }
                field(expenseDate; Rec."Expense Date")
                {
                    Caption = 'Expense Date';
                }
                field(expenseTime; Rec."Expense Time")
                {
                    Caption = 'Expense Time';
                }
                field(currencyCode; CurrencyCodeDisplay)
                {
                    Caption = 'Currency Code';

                    trigger OnValidate()
                    begin
                        Rec."Expense Currency Code" := CurrencyHelper.GetCurrencyCodeFromAPI(CurrencyCodeDisplay);
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
                field(nonRefundableAmount; Rec."Non-Refundable Amount")
                {
                    Caption = 'Non-Refundable Amount';
                }
                field(nonRefundableAmountLCY; Rec."Non-Refundable Amount (LCY)")
                {
                    Caption = 'Non-Refundable Amount (LCY)';
                }
                field(amountWithoutVAT; Rec."Amount without VAT")
                {
                    Caption = 'Amount without VAT';
                }
                field(amountWithoutVATLCY; Rec."Amount without VAT (LCY)")
                {
                    Caption = 'Amount without VAT (LCY)';
                }
                field(vatAmount; Rec."VAT Amount")
                {
                    Caption = 'VAT Amount';
                }
                field(vatAmountLCY; Rec."VAT Amount (LCY)")
                {
                    Caption = 'VAT Amount (LCY)';
                }
                field(vatBusPostingGroup; Rec."VAT Bus. Posting Group")
                {
                    Caption = 'VAT Bus. Posting Group';
                }
                field(vatLiable; Rec."VAT Liable")
                {
                    Caption = 'VAT Liable';
                }
                field(vatProdPostingGroup; Rec."VAT Prod. Posting Group")
                {
                    Caption = 'VAT Prod. Posting Group';
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
                field(reimbursementType; Rec."Reimbursement Type")
                {
                    Caption = 'Reimbursement Type';
                }
                field(reimbursableAmount; Rec."Reimbursable Amount")
                {
                    Caption = 'Reimbursable Amount';
                }
                field(reimbursableAmountLCY; Rec."Reimbursable Amount (LCY)")
                {
                    Caption = 'Reimbursable Amount (LCY)';
                }
                field(receiptAttached; Rec."Receipt Attached")
                {
                    Caption = 'Receipt Attached';
                }
                field(receiptEntry; Rec."Receipt Entry")
                {
                    Caption = 'Receipt Entry';
                }
                field(accountType; Rec."Account Type")
                {
                    Caption = 'Account Type';
                }
                field(accountNo; Rec."Account No.")
                {
                    Caption = 'Account No.';
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
                field(spendRequestNo; Rec."Spend Request No.")
                {
                    Caption = 'Travel Request No.';
                }
                field(spendRequestClose; Rec."Spend Request Close")
                {
                    Caption = 'Travel Request Close';
                }
                field(purchaseInvoice; Rec."Purchase Invoice")
                {
                    Caption = 'Purchase Invoice';
                }
                field(postedPurchInvoiceNo; Rec."Posted Purch. Invoice No.")
                {
                    Caption = 'Posted Purchase Invoice No.';
                }
                field(vendorNo; Rec."Vendor No.")
                {
                    Caption = 'Vendor No.';
                }
                field(postedDate; Rec."Posted Date")
                {
                    Caption = 'Posted Date';
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
                field(startingPoint; Rec."Starting Point")
                {
                    Caption = 'Starting Point';
                }
                field(endingPoint; Rec."Ending Point")
                {
                    Caption = 'Ending Point';
                }
                field(mileage; Rec.Mileage)
                {
                    Caption = 'Mileage';
                }
                field(roundTrip; Rec."Round Trip")
                {
                    Caption = 'Round Trip';
                    ToolTip = 'Specifies whether the mileage expense is a round trip.';
                }
                field(vehicleType; Rec."Vehicle Type")
                {
                    Caption = 'Vehicle Type';
                    ToolTip = 'Specifies the vehicle type used for this mileage expense.';
                }
                field(totalMileage; TotalMileage)
                {
                    Caption = 'Total Mileage';
                    ToolTip = 'Specifies the total mileage for reimbursement.';
                    Editable = false;
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'Unit of Measure Code';
                }
                field(appliedRuleId; Rec."Applied Rule Id")
                {
                    Caption = 'Applied Rule Id';
                }
                field(creditCardFeedNo; Rec."Credit Card Feed No.")
                {
                    Caption = 'Credit Card Feed No.';
                }
                field(expenseDetailRequired; Rec."Expense Detail Required")
                {
                    Caption = 'Expense Detail Required';
                }
                field(expenseExtDocNo; Rec."Expense Ext. Doc. No.")
                {
                    Caption = 'Expense External Document No.';
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
                field(userConfirmed; Rec."User Confirmed")
                {
                    Caption = 'User Confirmed';
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
                field(policiesEvaluatedAt; Rec."Policies Evaluated At")
                {
                    Caption = 'Policies Evaluated At';
                    Editable = false;
                }
                field(policyEvalVersion; Rec."Policy Eval Version")
                {
                    Caption = 'Policy Eval Version';
                    Editable = false;
                }
                field(policyStatus; PolicyStatusDisplay)
                {
                    Caption = 'Policy Status';
                    Editable = false;
                }
                field(hasPolicyViolation; HasPolicyViolationDisplay)
                {
                    Caption = 'Has Policy Violation';
                    Editable = false;
                }

                part(expense; "Expenses API")
                {
                    EntityName = 'expense';
                    EntitySetName = 'expenses';
                    Multiplicity = ZeroOrOne;
                    SubPageLink = "No." = field("Expense No.");
                }
                part(expenseReportLineItemization; "Expense Report Line Item API")
                {
                    EntityName = 'expenseReportLineItemization';
                    EntitySetName = 'expenseReportLineItemizations';
                    SubPageLink = "Expense Report No." = field("Document No."),
                                  "Expense Report Line No." = field("Line No.");
                }
                part(expenseReportLineParticip; "Exp. Report Line Particip. API")
                {
                    EntityName = 'expenseReportLineParticipant';
                    EntitySetName = 'expenseReportLineParticipants';
                    SubPageLink = "Expense Report No." = field("Document No."),
                                  "Expense Report Line No." = field("Line No.");
                }
                part(expenseReportLinePerDiem; "Exp. Report Line Per Diem API")
                {
                    EntityName = 'expenseReportLinePerDiem';
                    EntitySetName = 'expenseReportLinePerDiems';
                    SubPageLink = "Expense Report No." = field("Document No."),
                                  "Expense Report Line No." = field("Line No.");
                }
                part(attachments; "Exp. Rep. Line Attachments API")
                {
                    EntityName = 'expenseReportLineAttachment';
                    EntitySetName = 'expenseReportLineAttachments';
                    SubPageLink = "Document Id" = field(SystemId);
                }
                part(expenseReportRuleViolations; "Exp. Rep. Rule Violations API")
                {
                    Caption = 'Expense Report Rule Violations';
                    EntityName = 'expenseReportRuleViolation';
                    EntitySetName = 'expenseReportRuleViolations';
                    SubPageLink = "Expense Report No." = field("Document No."),
                                  "Report Line No." = field("Line No.");
                }
                part(expensePolicyEvaluations; "Expense Policy Evaluations API")
                {
                    Caption = 'Expense Policy Evaluations';
                    EntityName = 'expensePolicyEvaluation';
                    EntitySetName = 'expensePolicyEvaluations';
                    SubPageLink = "Subject System Id" = field(SystemId), "Subject Type" = const("Expense Report Line"), "Subject Version" = field("Policy Eval Version");
                }
                part(policiesToEvaluate; "Exp. Policies To Eval API")
                {
                    Caption = 'Policies To Evaluate';
                    EntityName = 'policyToEvaluate';
                    EntitySetName = 'policiesToEvaluate';
                    SubPageLink = "Subject System Id" = field(SystemId);
                }
            }
        }
    }

    var
        CurrencyHelper: Codeunit "Expense API Currency Helper";
        ExpenseAutoPopulation: Codeunit "Expense Auto Population";
        CurrencyCodeDisplay: Code[10];
        XCurrencyCodeDisplay: Code[10];
        CurrencyLCYDisplay: Code[10];
        ExpenseUserSystemId: Guid;
        TotalMileage: Decimal;
        JobDescription: Text[100];
        JobTaskDescription: Text[100];
        PolicyStatusDisplay: Enum "Expense Policy Status";
        HasPolicyViolationDisplay: Boolean;
        TargetExpenseReportNotFoundErr: Label 'Expense report with Id %1 not found.', Comment = '%1 = Expense Report Header SystemId';

    trigger OnInit()
    var
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
        CurrencyLCYDisplay := CurrencyHelper.GetCurrencyCodeForAPI('');
    end;

    trigger OnOpenPage()
    begin
        // Avoid JIT load consistency errors by ensuring fields read in OnAfterGetRecord are included in the initial record buffer.
        Rec.AddLoadFields("Expense Currency Code", "Expense User No.", Mileage, "Round Trip", "Policy Eval Version", "Evaluated Policy Version");
    end;

    trigger OnAfterGetRecord()
    var
        ExpenseUser: Record "Expense User";
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        CurrencyCodeDisplay := CurrencyHelper.GetCurrencyCodeForAPI(Rec."Expense Currency Code");
        XCurrencyCodeDisplay := CurrencyCodeDisplay;
        ExpenseUserSystemId := ExpenseUser.GetSystemIdByExpenseUserNo(Rec."Expense User No.");
        TotalMileage := ExpenseAutoPopulation.GetEffectiveDistance(Rec.Mileage, Rec."Round Trip");
        PolicyStatusDisplay := Rec.GetPolicyStatus();
        HasPolicyViolationDisplay := PolicyStatusDisplay = PolicyStatusDisplay::Flagged;

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

    trigger OnNewRecord(Belowx: Boolean)
    begin
        CurrencyCodeDisplay := '';
        XCurrencyCodeDisplay := '';
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if CurrencyCodeDisplay <> XCurrencyCodeDisplay then
            Rec."Expense Currency Code" := CurrencyHelper.GetCurrencyCodeFromAPI(CurrencyCodeDisplay);
        UpdateExpenseUserNoFromSystemId();
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if CurrencyCodeDisplay <> XCurrencyCodeDisplay then
            Rec."Expense Currency Code" := CurrencyHelper.GetCurrencyCodeFromAPI(CurrencyCodeDisplay);
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
    procedure MoveExpenseReportLine(var ActionContext: WebServiceActionContext; TargetExpenseReportId: Guid)
    var
        TargetExpenseReportHeader: Record "Expense Report Header";
    begin
        if not TargetExpenseReportHeader.GetBySystemId(TargetExpenseReportId) then
            Error(TargetExpenseReportNotFoundErr, TargetExpenseReportId);

        Rec.MoveToExpenseReport(TargetExpenseReportHeader."No.");

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Expense Report Lines API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    [ServiceEnabled]
    procedure ValidateExpenseReportRule(var ActionContext: WebServiceActionContext)
    begin
        Rec.ApplyRule(false, true);

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Expense Report Lines API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    [ServiceEnabled]
    procedure ApplyExpenseReportRule(var ActionContext: WebServiceActionContext)
    begin
        Rec.ApplyRule();
        Rec.Modify(true);

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Expense Report Lines API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    [ServiceEnabled]
    procedure MarkPoliciesEvaluated(var ActionContext: WebServiceActionContext; EvaluatedSubjectVersion: Integer)
    begin
        Rec.MarkPoliciesEvaluated(EvaluatedSubjectVersion);

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Expense Report Lines API");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}