// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.SpendRequest;
using Microsoft.Sales.Document;

page 6993 "Posted Expense Report SubP."
{
    Caption = 'Lines';
    PageType = ListPart;
    Editable = false;
    SourceTable = "Posted Expense Report Line";
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Expense Date"; Rec."Expense Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date the expense was incurred.';
                }
                field("Expense Category"; Rec."Expense Category")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the category that classifies this expense line.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the expense line.';
                }
                field(Justification; Rec.Justification)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason or justification for the expense.';
                }
                field("Currency Code"; Rec."Expense Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency used for this expense line.';
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the VAT Prod. Posting Group field.';
                    Visible = false;
                }
                field(Refundable; Rec.Refundable)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the expense amount is refundable.';
                }
                field("Amount"; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line amount in the transaction currency.';
                }
                field("Non-Refundable Amount"; Rec."Non-Refundable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Non-Refundable Amount field.';
                }
                field("Reimbursable Amount"; Rec."Reimbursable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the portion eligible for reimbursement.';
                }
                field("Refundable Amount"; Rec."Refundable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the portion eligible for Refundable.';
                    Visible = false;
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line amount converted to local currency.';
                }
                field("Non-Refundable Amount (LCY)"; Rec."Non-Refundable Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Non-Refundable Amount (LCY) field.';
                }
                field("Reimbursable Amount (LCY)"; Rec."Reimbursable Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reimbursable amount converted to local currency.';
                }
                field("Refundable Amount (LCY)"; Rec."Refundable Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the refundable amount converted to local currency.';
                    Visible = false;
                }
                field("Reimbursement Type"; Rec."Reimbursement Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Reimbursement Type field.';
                    Visible = false;
                }
                field("Spend Request No."; Rec."Spend Request No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("VAT Liable"; Rec."VAT Liable")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether VAT applies to this expense line';
                    Visible = false;
                }
                field("VAT Amount (LCY)"; Rec."VAT Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT amount converted to local currency.';
                    Visible = false;
                }
                field("Amount without VAT (LCY)"; Rec."Amount without VAT (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line amount excluding VAT, in local currency.';
                    Visible = false;
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment method used for refunds or reimbursements.';
                }
                field(Mileage; Rec.Mileage)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the one-way distance traveled for mileage reimbursement.';
                }
                field("Total Mileage"; TotalMileage)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 0;
                    Caption = 'Total Mileage';
                    ToolTip = 'Specifies the total mileage for reimbursement. If round trip, this is double the one-way distance.';
                    Editable = false;
                }
                field("Round Trip"; Rec."Round Trip")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Job Ledger Entry No."; Rec."Job Ledger Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                    ToolTip = 'Specifies the related job ledger entry number, if any.';
                }
            }
            group(control51)
            {
                ShowCaption = false;
                group(Control45)
                {
                    ShowCaption = false;

                    field(TotalAmountLCY; TotalAmountLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatExpression = '';
                        AutoFormatType = 1;
                        Caption = 'Total Amount (LCY)';
                        DrillDown = false;
                        Editable = false;
                        ToolTip = 'Specifies the total invoice amount in local currency.';
                    }
                    field(TotalNonRefundableAmountLCY; TotalNonRefundableAmountLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatExpression = '';
                        AutoFormatType = 1;
                        Caption = 'Total Non-Refundable Amount (LCY)';
                        DrillDown = false;
                        Editable = false;
                        ToolTip = 'Specifies the total reductions applied to the document in local currency.';
                    }
                    field(TotalVATAmount; TotalVATAmountLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatExpression = '';
                        AutoFormatType = 1;
                        Caption = 'Total VAT. Amount (LCY)';
                        DrillDown = false;
                        Editable = false;
                        Visible = false;
                        ToolTip = 'Specifies the total VAT amount for the document in local currency.';
                    }
                    field(TotalAmountWithoutVAT; TotalAmountWithoutVATLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatExpression = '';
                        AutoFormatType = 1;
                        Caption = 'Total Amount Without VAT. (LCY)';
                        DrillDown = false;
                        Editable = false;
                        Visible = false;
                        ToolTip = 'Specifies the total amount excluding VAT in local currency.';
                    }
                }
                group(Control28)
                {
                    ShowCaption = false;
                    field(TotalReimbursableAmountLCY; TotalReimbursableAmountLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatExpression = '';
                        AutoFormatType = 1;
                        Caption = 'Total Reimbursable Amount (LCY)';
                        DrillDown = false;
                        Editable = false;
                        ToolTip = 'Specifies the total reimbursable amount in local currency.';
                    }
                    field(TotalReimbursableAmount; TotalReimbursableAmount)
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatExpression = Rec.GetReimbursementCurrencyCode();
                        AutoFormatType = 1;
                        Caption = 'Total Reimbursable Amount';
                        DrillDown = false;
                        Editable = false;
                        ToolTip = 'Specifies the sum of the reimbursement amount in reimbursement currency on all lines in the document.';
                    }
                    group("Refundable Amounts")
                    {
                        ShowCaption = false;
                        Visible = (TotalRefundableAmount <> 0) or (TotalRefundableAmountLCY <> 0);
                        field(TotalRefundableAmountLCY; TotalRefundableAmountLCY)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = '';
                            AutoFormatType = 1;
                            Caption = 'Total Refundable Amount (LCY)';
                            DrillDown = false;
                            Editable = false;
                            ToolTip = 'Specifies the total refundable amount in local currency.';
                        }
                        field(TotalRefundableAmount; TotalRefundableAmount)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec.GetReimbursementCurrencyCode();
                            AutoFormatType = 1;
                            Caption = 'Total Refundable Amount';
                            DrillDown = false;
                            Editable = false;
                            ToolTip = 'Specifies the sum of the refundable amount in refundable currency on all lines in the document.';
                        }
                    }
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            group(Line)
            {
                Caption = 'Line';
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
                action("Comments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Comments';
                    Image = ViewComments;
                    ToolTip = 'View or add comments for the record.';

                    trigger OnAction()
                    begin
                        Rec.ShowLineComments();
                    end;
                }
                action("Show Billable Information")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Billable Information';
                    Image = ShowList;
                    ToolTip = 'Show or hide billable information fields';
                    Visible = (Rec."Document No." <> '') and (Rec."Line No." <> 0);

                    trigger OnAction()
                    var
                        PostedExpenseReportLine: Record "Posted Expense Report Line";
                    begin
                        PostedExpenseReportLine.Get(Rec."Document No.", Rec."Line No.");
                        Commit();
                        Page.RunModal(Page::"Posted Expense Billing Info.", PostedExpenseReportLine);
                    end;
                }
                action("Participants")
                {
                    Image = PersonInCharge;
                    Caption = 'Participants';
                    ToolTip = 'View and manage participants for this posted expense report line';
                    RunObject = page "Posted Exp. Rep. Line Particip";
                    RunPageLink = "Expense Report No." = field("Document No."), "Expense Report Line No." = field("Line No.");
                    Visible = IsParticipantCategory;
                    ApplicationArea = Basic, Suite;
                }
                action("Itemizations")
                {
                    Image = ItemGroup;
                    Caption = 'Itemizations';
                    ToolTip = 'View and manage itemizations for this posted expense report line';
                    RunObject = page "Posted Exp. Report Line Items";
                    RunPageLink = "Expense Report No." = field("Document No."), "Expense Report Line No." = field("Line No.");
                    Visible = IsItemizationCategory;
                    ApplicationArea = Basic, Suite;
                }
                action("PerDiem")
                {
                    Image = CalculateCost;
                    Caption = 'Per Diem';
                    ToolTip = 'View and manage per diem entries for this posted expense report line';
                    RunObject = page "Posted Exp. Rep. Line Per Diem";
                    RunPageLink = "Expense Report No." = field("Document No."), "Expense Report Line No." = field("Line No.");
                    Visible = IsPerDiemCategory;
                    ApplicationArea = Basic, Suite;
                }
                action("VAT Specification")
                {
                    ApplicationArea = Basic, Suite;
                    Image = VATPostingSetup;
                    Caption = 'VAT Specification';
                    ToolTip = 'View the per-rate VAT breakdown for this expense report line.';
                    RunObject = Page "Posted Exp.Rep.Line VAT Spec";
                    RunPageLink = "Expense Report No." = field("Document No."), "Expense Report Line No." = field("Line No.");
                    Visible = AllowVATReclaim;
                }
                action("SalesDocument")
                {
                    Image = Documents;
                    Caption = 'Sales Document';
                    ToolTip = 'View and manage sales document entries for this posted expense report line';
                    RunObject = page "Sales Lines";
                    RunPageLink = "Posted Exp. Report No." = field("Document No."),
                                  "Posted Exp. Report Line No." = field("Line No.");
                    ApplicationArea = Basic, Suite;
                }
                action(Expense)
                {
                    Image = Document;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Expense';
                    RunObject = Page Expense;
                    RunPageLink = "No." = field("Expense No.");
                    Enabled = Rec."Expense No." <> '';
                    ToolTip = 'View the details of the expense associated with this posted expense report line.';
                }
                action("View Applied Rule")
                {
                    Image = FileContract;
                    ApplicationArea = Basic, Suite;
                    Caption = 'View Applied Rule';
                    Enabled = IsRuleApplied;
                    ToolTip = 'View the details of the expense rule that has been applied to this posted expense report line.';

                    trigger OnAction()
                    var
                        ExpenseRuleHeader: Record "Expense Rule Header";
                    begin
                        if IsNullGuid(Rec."Applied Rule Id") then
                            exit;

                        ExpenseRuleHeader.GetBySystemId(Rec."Applied Rule Id");
                        Commit();
                        Page.RunModal(Page::"Expense Rule Card", ExpenseRuleHeader);
                    end;
                }
                action("Spend Request")
                {
                    ApplicationArea = Basic, Suite;
                    Image = ProjectExpense;
                    Caption = 'Spend Request';
                    ToolTip = 'View the details of the spend request associated with this posted expense report line.';
                    RunObject = Page "Spend Request Card";
                    RunPageLink = "No." = field("Spend Request No.");
                    Visible = Rec."Spend Request No." <> '';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        ValidateHeaderAmountField();
        UpdateControls();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        ValidateHeaderAmountField();
        UpdateControls();
    end;

    trigger OnAfterGetRecord()
    begin
        ValidateHeaderAmountField();
        UpdateControls();
    end;

    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseAutoPopulation: Codeunit "Expense Auto Population";
        TotalAmountLCY: Decimal;
        TotalVATAmountLCY: Decimal;
        TotalAmountWithoutVATLCY: Decimal;
        TotalNonRefundableAmountLCY: Decimal;
        TotalReimbursableAmount, TotalReimbursableAmountLCY : Decimal;
        TotalRefundableAmount, TotalRefundableAmountLCY : Decimal;
        IsMileageCategory, IsPerDiemCategory, IsParticipantCategory, IsItemizationCategory : Boolean;
        IsRuleApplied: Boolean;
        TotalMileage: Decimal;
        AllowVATReclaim: Boolean;

    local procedure UpdateControls()
    begin
        IsPerDiemCategory := Rec."Expense Detail Required" = Rec."Expense Detail Required"::"Per Diem";
        IsMileageCategory := Rec."Expense Detail Required" = Rec."Expense Detail Required"::Mileage;
        IsItemizationCategory := Rec."Expense Detail Required" = Rec."Expense Detail Required"::Itemize;
        IsParticipantCategory := Rec."Expense Detail Required" = Rec."Expense Detail Required"::Participants;

        IsRuleApplied := not IsNullGuid(Rec."Applied Rule Id");
        if IsMileageCategory then
            TotalMileage := ExpenseAutoPopulation.GetEffectiveDistance(Rec.Mileage, Rec."Round Trip")
        else
            TotalMileage := 0;

        ExpenseAgentSetup.GetRecordOnce();
        AllowVATReclaim := ExpenseAgentSetup."Allow VAT Reclaim";
    end;

    local procedure ValidateHeaderAmountField()
    begin
        if PostedExpenseReportHeader.Get(Rec."Document No.") then begin
            PostedExpenseReportHeader.CalcFields(
                "Amount (LCY)", "Non-Refundable Amount (LCY)", "Reimbursable Amount (LCY)",
                "VAT Amount (LCY)", "Amount without VAT (LCY)", "Refundable Amount (LCY)",
                "Reimbursable Amount", "Refundable Amount");

            TotalAmountLCY := PostedExpenseReportHeader."Amount (LCY)";
            TotalVATAmountLCY := PostedExpenseReportHeader."VAT Amount (LCY)";
            TotalAmountWithoutVATLCY := PostedExpenseReportHeader."Amount without VAT (LCY)";
            TotalNonRefundableAmountLCY := PostedExpenseReportHeader."Non-Refundable Amount (LCY)";
            TotalReimbursableAmountLCY := PostedExpenseReportHeader."Reimbursable Amount (LCY)";
            TotalRefundableAmountLCY := PostedExpenseReportHeader."Refundable Amount (LCY)";
            TotalReimbursableAmount := PostedExpenseReportHeader."Reimbursable Amount";
            TotalRefundableAmount := PostedExpenseReportHeader."Refundable Amount";
        end;
    end;
}