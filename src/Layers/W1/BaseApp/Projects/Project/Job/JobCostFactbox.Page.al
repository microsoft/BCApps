// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Job;

page 1030 "Job Cost Factbox"
{
    Caption = 'Project Details';
    Editable = false;
    LinksAllowed = false;
    PageType = CardPart;
    SourceTable = Job;

    layout
    {
        area(content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = Jobs;
                Caption = 'Project No.';
                ToolTip = 'Specifies the project number.';

                trigger OnDrillDown()
                begin
                    ShowDetails();
                end;
            }
            group("Budget Cost")
            {
                Caption = 'Budget Cost';
                field(PlaceHolderLbl; PlaceHolderLbl)
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    Enabled = false;
                    ToolTip = 'Specifies nothing.';
                    Visible = false;
                }
                field(ScheduleCostLCY; CL[1])
                {
                    ApplicationArea = Jobs;
                    Caption = 'Resource';
                    Editable = false;
                    ToolTip = 'Specifies the total budgeted cost of resources associated with this project.';

                    trigger OnDrillDown()
                    begin
                        JobCalcStatistics.ShowPlanningLine(1, true);
                    end;
                }
                field(ScheduleCostLCYItem; CL[2])
                {
                    ApplicationArea = Jobs;
                    Caption = 'Item';
                    Editable = false;
                    ToolTip = 'Specifies the total budgeted cost of items associated with this project.';

                    trigger OnDrillDown()
                    begin
                        JobCalcStatistics.ShowPlanningLine(2, true);
                    end;
                }
                field(ScheduleCostLCYGLAcc; CL[3])
                {
                    ApplicationArea = Jobs;
                    Caption = 'G/L Account';
                    Editable = false;
                    ToolTip = 'Specifies the total budgeted cost of general journal entries associated with this project.';

                    trigger OnDrillDown()
                    begin
                        JobCalcStatistics.ShowPlanningLine(3, true);
                    end;
                }
                field(ScheduleCostLCYTotal; CL[4])
                {
                    ApplicationArea = Jobs;
                    Caption = 'Total';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = true;
                    ToolTip = 'Specifies the total budget cost of a project.';

                    trigger OnDrillDown()
                    begin
                        JobCalcStatistics.ShowPlanningLine(0, true);
                    end;
                }
            }
            group("Actual Cost")
            {
                Caption = 'Actual Cost';
                field(Placeholder2; PlaceHolderLbl)
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    Enabled = false;
                    ToolTip = 'Specifies nothing.';
                    Visible = false;
                }
                field(UsageCostLCY; CL[5])
                {
                    ApplicationArea = Jobs;
                    Caption = 'Resource';
                    Editable = false;
                    ToolTip = 'Specifies the total usage cost of resources associated with this project.';

                    trigger OnDrillDown()
                    begin
                        JobCalcStatistics.ShowLedgEntry(1, true);
                    end;
                }
                field(UsageCostLCYItem; CL[6])
                {
                    ApplicationArea = Jobs;
                    Caption = 'Item';
                    Editable = false;
                    ToolTip = 'Specifies the total usage cost of items associated with this project.';

                    trigger OnDrillDown()
                    begin
                        JobCalcStatistics.ShowLedgEntry(2, true);
                    end;
                }
                field(UsageCostLCYGLAcc; CL[7])
                {
                    ApplicationArea = Jobs;
                    Caption = 'G/L Account';
                    Editable = false;
                    ToolTip = 'Specifies the total usage cost of general journal entries associated with this project.';

                    trigger OnDrillDown()
                    begin
                        JobCalcStatistics.ShowLedgEntry(3, true);
                    end;
                }
                field(UsageCostLCYTotal; CL[8])
                {
                    ApplicationArea = Jobs;
                    Caption = 'Total';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = true;
                    ToolTip = 'Specifies the total costs used for a project.';

                    trigger OnDrillDown()
                    begin
                        JobCalcStatistics.ShowLedgEntry(0, true);
                    end;
                }
            }
            group("Billable Price")
            {
                Caption = 'Billable Price';
                field(Placeholder3; PlaceHolderLbl)
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    Enabled = false;
                    ToolTip = 'Specifies nothing.';
                    Visible = false;
                }
                field(BillablePriceLCY; PL[9])
                {
                    ApplicationArea = Jobs;
                    Caption = 'Resource';
                    Editable = false;
                    ToolTip = 'Specifies the total billable price of resources associated with this project.';

                    trigger OnDrillDown()
                    var
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforeOnDrillDownBillablePriceLCY(Rec, IsHandled);
                        if not IsHandled then
                            JobCalcStatistics.ShowPlanningLine(1, false);
                    end;
                }
                field(BillablePriceLCYItem; PL[10])
                {
                    ApplicationArea = Jobs;
                    Caption = 'Item';
                    Editable = false;
                    ToolTip = 'Specifies the total billable price of items associated with this project.';

                    trigger OnDrillDown()
                    var
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforeOnDrillDownBillablePriceLCYItem(Rec, IsHandled);
                        if not IsHandled then
                            JobCalcStatistics.ShowPlanningLine(2, false);
                    end;
                }
                field(BillablePriceLCYGLAcc; PL[11])
                {
                    ApplicationArea = Jobs;
                    Caption = 'G/L Account';
                    Editable = false;
                    ToolTip = 'Specifies the total billable price for project planning lines of type G/L account.';

                    trigger OnDrillDown()
                    var
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforeOnDrillDownBillablePriceLCYGLAcc(Rec, IsHandled);
                        if not IsHandled then
                            JobCalcStatistics.ShowPlanningLine(3, false);
                    end;
                }
                field(BillablePriceLCYTotal; PL[12])
                {
                    ApplicationArea = Jobs;
                    Caption = 'Total';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = true;
                    ToolTip = 'Specifies the total billable price used for a project.';

                    trigger OnDrillDown()
                    var
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforeOnDrillDownBillablePriceLCYTotal(Rec, IsHandled);
                        if not IsHandled then
                            JobCalcStatistics.ShowPlanningLine(0, false);
                    end;
                }
            }
            group("Invoiced Price")
            {
                Caption = 'Invoiced Price';
                field(Placeholder4; PlaceHolderLbl)
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    Enabled = false;
                    ToolTip = 'Specifies nothing.';
                    Visible = false;
                }
                field(InvoicedPriceLCY; PL[13])
                {
                    ApplicationArea = Jobs;
                    Caption = 'Resource';
                    Editable = false;
                    ToolTip = 'Specifies the total invoiced price of resources associated with this project.';

                    trigger OnDrillDown()
                    var
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforeOnDrillDownInvoicedPriceLCY(Rec, IsHandled);
                        if not IsHandled then
                            JobCalcStatistics.ShowLedgEntry(1, false);
                    end;
                }
                field(InvoicedPriceLCYItem; PL[14])
                {
                    ApplicationArea = Jobs;
                    Caption = 'Item';
                    Editable = false;
                    ToolTip = 'Specifies the total invoiced price of items associated with this project.';

                    trigger OnDrillDown()
                    var
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforeOnDrillDownInvoicedPriceLCYItem(Rec, IsHandled);
                        if not IsHandled then
                            JobCalcStatistics.ShowLedgEntry(2, false);
                    end;
                }
                field(InvoicedPriceLCYGLAcc; PL[15])
                {
                    ApplicationArea = Jobs;
                    Caption = 'G/L Account';
                    Editable = false;
                    ToolTip = 'Specifies the total invoiced price of general journal entries associated with this project.';

                    trigger OnDrillDown()
                    var
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforeOnDrillDownInvoicedPriceLCYGLAcc(Rec, IsHandled);
                        if not IsHandled then
                            JobCalcStatistics.ShowLedgEntry(3, false);
                    end;
                }
                field(InvoicedPriceLCYTotal; PL[16])
                {
                    ApplicationArea = Jobs;
                    Caption = 'Total';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = true;
                    ToolTip = 'Specifies the total invoiced price of a project.';

                    trigger OnDrillDown()
                    var
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforeOnDrillDownInvoicedPriceLCYTotal(Rec, IsHandled);
                        if not IsHandled then
                            JobCalcStatistics.ShowLedgEntry(0, false);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        Clear(JobCalcStatistics);
        JobCalcStatistics.JobCalculateCommonFilters(Rec);
        JobCalcStatistics.CalculateAmounts();
        JobCalcStatistics.GetLCYCostAmounts(CL);
        JobCalcStatistics.GetLCYPriceAmounts(PL);
    end;

    var
        JobCalcStatistics: Codeunit "Job Calculate Statistics";
        PlaceHolderLbl: Label 'Placeholder';
        CL: array[16] of Decimal;
        PL: array[16] of Decimal;

    local procedure ShowDetails()
    begin
        PAGE.Run(PAGE::"Job Card", Rec);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnDrillDownBillablePriceLCY(var Job: Record Job; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnDrillDownBillablePriceLCYTotal(var Job: Record Job; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnDrillDownBillablePriceLCYGLAcc(var Job: Record Job; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnDrillDownBillablePriceLCYItem(var Job: Record Job; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnDrillDownInvoicedPriceLCYGLAcc(var Job: Record Job; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnDrillDownInvoicedPriceLCYTotal(var Job: Record Job; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnDrillDownInvoicedPriceLCYItem(var Job: Record Job; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnDrillDownInvoicedPriceLCY(var Job: Record Job; var IsHandled: Boolean);
    begin
    end;
}
