// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.SpendRequest;

page 6999 "Expense Report SubPage"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "Expense Report Line";
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Expense No."; Rec."Expense No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expense report number this line belongs to.';
                    Visible = false;
                }
                field("Expense Category"; Rec."Expense Category")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expense category for the line. Determines whether the line requires per diem, mileage, participants, or itemization details.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Rule Violations"; Rec."Rule Violations")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if there are any rule violations for the expense line.';
                }
                field("Expense Location"; Rec."Expense Location")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies where the expense occurred. Available when the expense requires per diem details.';
                    ShowMandatory = IsPerDiemCategory;
                    Editable = IsPerDiemCategory;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a brief description of the expense line.';
                }
                field(Justification; Rec.Justification)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason for the expense. Helps approvers understand why the expense was incurred.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Additional Information"; Rec."Additional Information")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies additional information for the expense line.';
                    Visible = false;
                }
                field(Billable; Rec.Billable)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the expense is billable to a customer.';
                    Visible = false;
                }
                field("Billable to Customer"; Rec."Billable to Customer")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer to bill for this expense when it is billable.';
                    Visible = false;
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment method used for this expense, for example corporate card or cash.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Expense Date"; Rec."Expense Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the expense was incurred. Used for reporting and validation purposes.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Expense Currency Code"; Rec."Expense Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency used for this expense. Not editable for per diem expenses.';
                    Editable = not (Rec."Expense Detail Required" = Rec."Expense Detail Required"::"Per Diem");

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT product posting group used when posting VAT for this expense.';
                    Visible = false;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount of the expense for this line, including any applicable taxes. Changing the amount will update related totals automatically.';
                    Editable = not ((Rec."Expense Detail Required" = Rec."Expense Detail Required"::"Per Diem") or (Rec."Expense Detail Required" = Rec."Expense Detail Required"::Mileage));

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field(AmountLCY; Rec."Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount of the expense for this line in local currency, including any applicable taxes. Automatically calculated from the amount and exchange rate.';
                    Editable = false;
                }
                field("Reimbursement Type"; Rec."Reimbursement Type")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                    ToolTip = 'Specifies how the expense is reimbursed, for example cash or payroll.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Reimbursable Amount (LCY)"; Rec."Reimbursable Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the portion of the expense that will be reimbursed to the employee in local currency. Calculated from amount, VAT, and reductions.';
                    Visible = false;
                }
                field("Reimbursable Amount"; Rec."Reimbursable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = GetReimbursementAmountCaption();
                    Editable = false;
                    ToolTip = 'Specifies the portion of the expense that will be reimbursed to the employee. Calculated from amount, VAT, and reductions.';
                }
                field("Refundable Amount (LCY)"; Rec."Refundable Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the portion of the expense that will be refundable in local currency. Calculated from amount, VAT, and reductions.';
                    Visible = false;
                }
                field("Refundable Amount"; Rec."Refundable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = GetReimbursementAmountCaption();
                    Editable = false;
                    ToolTip = 'Specifies the portion of the expense that will be refundable. Calculated from amount, VAT, and reductions.';
                    Visible = false;
                }
                field("Spend Request No."; Rec."Spend Request No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Starting Date and Time"; Rec."Starting Date and Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start date and time used for per diem calculations. Available when the expense requires per diem details.';
                    Editable = IsPerDiemCategory;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Ending Date and Time"; Rec."Ending Date and Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the end date and time used for per diem calculations. Available when the expense requires per diem details.';
                    Editable = IsPerDiemCategory;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Starting Point"; Rec."Starting Point")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the starting point for mileage calculations. Available when the expense requires mileage details.';
                    Editable = IsMileageCategory;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Ending Point"; Rec."Ending Point")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ending point for mileage calculations. Available when the expense requires mileage details.';
                    Editable = IsMileageCategory;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                    Editable = false;
                    ToolTip = 'Specifies the unit of measure for mileage calculations. Available when the expense requires mileage details.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field(Mileage; Rec.Mileage)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the distance traveled for mileage reimbursement. Available when the expense requires mileage details.';
                    Editable = IsMileageCategory;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
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
                    Editable = IsMileageCategory;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field(Refundable; Rec.Refundable)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Refundable field.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("VAT Liable"; Rec."VAT Liable")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the VAT Liable field.';
                    Editable = not ((Rec."Expense Detail Required" = Rec."Expense Detail Required"::"Per Diem") or (Rec."Expense Detail Required" = Rec."Expense Detail Required"::Mileage));

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("VAT Amount"; Rec."VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the VAT Amount field.';
                    Visible = false;
                    Editable = Rec."VAT Liable";

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("VAT Amount (LCY)"; Rec."VAT Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the VAT Amount (LCY) field.';
                    Visible = false;
                }
                field("Amount without VAT"; Rec."Amount without VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Amount without VAT field.';
                    Visible = false;
                }
                field("Amount without VAT (LCY)"; Rec."Amount without VAT (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Amount without VAT (LCY) field.';
                    Visible = false;
                }
                field("Non-Refundable Amount"; Rec."Non-Refundable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Non-Refundable Amount field.';
                    Editable = Rec.Refundable and (not IsItemizationCategory);

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Non-Refundable Amount (LCY)"; Rec."Non-Refundable Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Non-Refundable Amount (LCY) field.';
                    Editable = Rec.Refundable and (not IsItemizationCategory);
                    Visible = false;
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
                        ToolTip = 'Specifies the total amount for the expense report in local currency. Calculated from all expense lines.';
                    }
                    field(TotalNonRefundableAmountLCY; TotalNonRefundableAmountLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatExpression = '';
                        AutoFormatType = 1;
                        Caption = 'Total Non-Refundable Amount (LCY)';
                        DrillDown = false;
                        Editable = false;
                        ToolTip = 'Specifies the total amount of reductions for the expense report in local currency. Calculated from line reductions.';
                    }
                    field(TotalVATAmount; TotalVATAmountLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatExpression = '';
                        AutoFormatType = 1;
                        Caption = 'Total VAT Amount (LCY)';
                        DrillDown = false;
                        Editable = false;
                        ToolTip = 'Specifies the sum of the value in the Amount LCY field on all lines in the document.';
                        Visible = false;
                    }
                    field(TotalAmountWithoutVAT; TotalAmountWithoutVATLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatExpression = '';
                        AutoFormatType = 1;
                        Caption = 'Total Amount Without VAT (LCY)';
                        DrillDown = false;
                        Editable = false;
                        ToolTip = 'Specifies the sum of the value in the Line Amount VAT field on all lines in the document minus any discount amount in the Invoice Discount Amount field.';
                        Visible = false;
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
                        ToolTip = 'Specifies the total reimbursable amount for the expense report in local currency. Calculated from line reimbursable amounts.';
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
                            ToolTip = 'Specifies the total refundable amount for the expense report in local currency. Calculated from line refundable amounts.';
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
                    begin
                        Rec.ShowExpenseBillingInformation();
                        CurrPage.Update(true);
                    end;
                }
                action("Participants")
                {
                    Image = PersonInCharge;
                    Caption = 'Participants';
                    ToolTip = 'View and manage participants for this expense report line';
                    ApplicationArea = Basic, Suite;
                    Visible = IsParticipantCategory;

                    trigger OnAction()
                    begin
                        Rec.ShowParticipants();

                        CurrPage.Update(true);
                    end;
                }
                action("Itemizations")
                {
                    Image = ItemGroup;
                    Caption = 'Itemizations';
                    ToolTip = 'View and manage itemizations for this expense report line';
                    ApplicationArea = Basic, Suite;
                    Visible = IsItemizationCategory;

                    trigger OnAction()
                    begin
                        Rec.ShowItemization();

                        CurrPage.Update(true);
                    end;
                }
                action("PerDiem")
                {
                    Image = CalculateCost;
                    Caption = 'Per Diem';
                    ToolTip = 'View and manage per diem entries for this expense report line';
                    ApplicationArea = Basic, Suite;
                    Visible = IsPerDiemCategory;

                    trigger OnAction()
                    begin
                        Rec.ShowPerDiem();

                        CurrPage.Update(true);
                    end;
                }
                action(Expense)
                {
                    Image = Document;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Expense';
                    RunObject = Page Expense;
                    RunPageLink = "No." = field("Expense No.");
                    Enabled = Rec."Expense No." <> '';
                    ToolTip = 'View the details of the expense associated with this expense report line.';
                }
                action("View Applied Rule")
                {
                    Image = FileContract;
                    ApplicationArea = Basic, Suite;
                    Caption = 'View Applied Rule';
                    Enabled = IsRuleApplied;
                    ToolTip = 'View the details of the expense rule that has been applied to this expense report line.';

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
                action("VAT Specification")
                {
                    ApplicationArea = Basic, Suite;
                    Image = VATPostingSetup;
                    Caption = 'VAT Specification';
                    ToolTip = 'View and approve the per-rate VAT breakdown for this expense report line.';
                    RunObject = Page "Expense Report Line VAT Spec.";
                    RunPageLink = "Document No." = field("Document No."), "Document Line No." = field("Line No.");
                    Visible = AllowVATReclaim;
                }
                action("Spend Request")
                {
                    ApplicationArea = Basic, Suite;
                    Image = ProjectExpense;
                    Caption = 'Spend Request';
                    ToolTip = 'View the details of the spend request associated with this expense report line.';
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
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseAutoPopulation: Codeunit "Expense Auto Population";
        TotalAmountLCY: Decimal;
        TotalVATAmountLCY: Decimal;
        TotalAmountWithoutVATLCY: Decimal;
        TotalNonRefundableAmountLCY: Decimal;
        TotalReimbursableAmountLCY, TotalRefundableAmountLCY : Decimal;
        TotalReimbursableAmount, TotalRefundableAmount : Decimal;
        IsMileageCategory, IsPerDiemCategory, IsParticipantCategory, IsItemizationCategory : Boolean;
        IsRuleApplied: Boolean;
        TotalMileage: Decimal;
        AllowVATReclaim: Boolean;
        ReimbursementAmountLbl: Label '%1 (%2)', Comment = '%1 = Field Caption, %2 = Field Value';
        LCYLbl: Label 'LCY';

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
        if ExpenseReportHeader.Get(Rec."Document No.") then begin
            ExpenseReportHeader.CalcFields(
                "Amount (LCY)", "Non-Refundable Amount (LCY)", "VAT Amount (LCY)", "Amount without VAT (LCY)",
                "Reimbursable Amount (LCY)", "Reimbursable Amount", "Refundable Amount (LCY)", "Refundable Amount");

            TotalAmountLCY := ExpenseReportHeader."Amount (LCY)";
            TotalVATAmountLCY := ExpenseReportHeader."VAT Amount (LCY)";
            TotalAmountWithoutVATLCY := ExpenseReportHeader."Amount without VAT (LCY)";
            TotalNonRefundableAmountLCY := ExpenseReportHeader."Non-Refundable Amount (LCY)";
            TotalReimbursableAmountLCY := ExpenseReportHeader."Reimbursable Amount (LCY)";
            TotalReimbursableAmount := ExpenseReportHeader."Reimbursable Amount";
            TotalRefundableAmountLCY := ExpenseReportHeader."Refundable Amount (LCY)";
            TotalRefundableAmount := ExpenseReportHeader."Refundable Amount";
        end;
    end;

    local procedure GetReimbursementAmountCaption(): Text
    begin
        if not ExpenseReportHeader.Get(Rec."Document No.") then
            exit;

        if ExpenseReportHeader."Reimbursement Currency Code" <> '' then
            exit(StrSubstNo(ReimbursementAmountLbl, Rec.FieldCaption("Reimbursable Amount"), ExpenseReportHeader."Reimbursement Currency Code"))
        else
            exit(StrSubstNo(ReimbursementAmountLbl, Rec.FieldCaption("Reimbursable Amount"), LCYLbl));
    end;
}