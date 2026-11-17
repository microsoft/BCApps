// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Projects.Project.Job;

page 6913 "Posted Exp. Report Lines API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Posted Expense Report Line';
    EntitySetCaption = 'Posted Expense Report Lines';
    EntityName = 'postedExpenseReportLine';
    EntitySetName = 'postedExpenseReportLines';
    PageType = API;
    ODataKeyFields = SystemId;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    DataAccessIntent = ReadOnly;
    SourceTable = "Posted Expense Report Line";
    AboutText = 'Provides access to data from the Posted Expense Report Line table';

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
                field(amountWithoutVATLCY; Rec."Amount without VAT (LCY)")
                {
                    Caption = 'Amount without VAT (LCY)';
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
                field(expenseExtDocNo; Rec."Expense Ext. Doc. No.")
                {
                    Caption = 'Expense External Document No.';
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

                part(expense; "Expenses API")
                {
                    EntityName = 'expense';
                    EntitySetName = 'expenses';
                    Multiplicity = ZeroOrOne;
                    SubPageLink = "No." = field("Expense No.");
                }
                part(expenseReportLineItemization; "Posted Exp. Rep. Line Item API")
                {
                    EntityName = 'postedExpenseReportLineItemization';
                    EntitySetName = 'postedExpenseReportLineItemizations';
                    SubPageLink = "Expense Report No." = field("Document No."),
                                  "Expense Report Line No." = field("Line No.");
                }
                part(attachments; "Posted Exp. Rep. Line Att. API")
                {
                    EntityName = 'postedExpenseReportLineAttachment';
                    EntitySetName = 'postedExpenseReportLineAttachments';
                    SubPageLink = "Document Id" = field(SystemId);
                }
                part(expensePolicyEvaluations; "Posted Policy Evaluations API")
                {
                    EntityName = 'postedExpensePolicyEvaluation';
                    EntitySetName = 'postedExpensePolicyEvaluations';
                    SubPageLink = "Subject System Id" = field(SystemId), "Subject Type" = const("Expense Report Line");
                }
            }
        }
    }

    var
        CurrencyHelper: Codeunit "Expense API Currency Helper";
        ExpenseAutoPopulation: Codeunit "Expense Auto Population";
        CurrencyCodeDisplay: Code[10];
        CurrencyLCYDisplay: Code[10];
        TotalMileage: Decimal;
        JobDescription: Text[100];
        JobTaskDescription: Text[100];

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
        Rec.AddLoadFields("Expense Currency Code", Mileage, "Round Trip", "Job No.", "Job Task No.");
    end;

    trigger OnAfterGetRecord()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        CurrencyCodeDisplay := CurrencyHelper.GetCurrencyCodeForAPI(Rec."Expense Currency Code");
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
}