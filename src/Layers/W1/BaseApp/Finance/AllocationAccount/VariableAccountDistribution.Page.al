// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AllocationAccount;

/// <summary>
/// Configuration interface for variable allocation distribution rules with dynamic calculation capabilities.
/// Provides setup for breakdown accounts, calculation periods, and dimension filters for variable allocation methods.
/// </summary>
page 2671 "Variable Account Distribution"
{
    PageType = ListPart;
    SourceTable = "Alloc. Account Distribution";
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Destination Account Type"; Rec."Destination Account Type")
                {
                    ApplicationArea = All;
                }
                field("Destination Account Number"; Rec."Destination Account Number")
                {
                    ApplicationArea = All;
                }
                field("Destination Account Name"; Rec.LookupDistributionAccountName())
                {
                    Caption = 'Destination Account Name';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the account name that the amount will be posted to.';
                    Editable = false;
                }
                field("Breakdown Account Type"; Rec."Breakdown Account Type")
                {
                    ApplicationArea = All;
                }
                field("Breakdown Account Number"; Rec."Breakdown Account Number")
                {
                    ApplicationArea = All;
                }
                field("Breakdown Account Name"; Rec.LookupBreakdownAccountName())
                {
                    Caption = 'Breakdown Account Name';
                    Editable = false;
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the Account that is used to calculate percentage for the distributions.';
                }
                field("Calculation Period"; Rec."Calculation Period")
                {
                    ApplicationArea = All;
                }
                field(Filters; FiltersTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Breakdown Account Balance Filters';
                    ToolTip = 'Specifies the fitlers that will be used when the balance is calculated.';
                    Editable = false;

                    trigger OnAssistEdit()
                    begin
                        Page.RunModal(Page::"Alloc. Acc. Dist. Filters", Rec);
                        FiltersTxt := GetFiltersText();
                    end;
                }
                field("Dimension 1 Filter"; Rec."Dimension 1 Filter")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Dimension 2 Filter"; Rec."Dimension 2 Filter")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Dimension 3 Filter"; Rec."Dimension 3 Filter")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Dimension 4 Filter"; Rec."Dimension 4 Filter")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Dimension 5 Filter"; Rec."Dimension 5 Filter")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Dimension 6 Filter"; Rec."Dimension 6 Filter")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Dimension 7 Filter"; Rec."Dimension 7 Filter")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Dimension 8 Filter"; Rec."Dimension 8 Filter")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
            }
        }
    }
    actions
    {
        area(processing)
        {
            action(PreviewDistributions)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Test Allocation';
                Image = Translation;
#pragma warning disable AA0219
                ToolTip = 'Test the allocation account''s setup by distributing an amount on different dates.';
#pragma warning restore AA0219
                Scope = Page;

                trigger OnAction()
                var
                    AllocationAccount: Record "Allocation Account";
                    AllocationAccountPreview: Page "Allocation Account Preview";
                begin
                    AllocationAccount.Get(Rec."Allocation Account No.");
                    AllocationAccountPreview.UpdateAllocationAccount(AllocationAccount);
                    AllocationAccountPreview.Run();
                end;
            }
            action(Dimensions)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Dimensions';
                Image = Dimensions;
                ShortCutKey = 'Shift+Ctrl+D';
#pragma warning disable AA0219
                ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';
#pragma warning restore AA0219

                trigger OnAction()
                begin
                    Rec.ShowDimensions();
                    if Rec."Dimension Set ID" <> xRec."Dimension Set ID" then
                        Rec.Modify();
                end;
            }
            action(DefineFilters)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Breakdown account balance filters';
                Image = FilterLines;
                ToolTip = 'Specifies the fitlers that will be used when the balance is calculated.';

                trigger OnAction()
                begin
                    Page.RunModal(Page::"Alloc. Acc. Dist. Filters", Rec);
                    FiltersTxt := GetFiltersText();
                end;
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Account Type" := Rec."Account Type"::Variable;
        Rec."Calculation Period" := xRec."Calculation Period";
        Rec."Destination Account Type" := xRec."Destination Account Type";
    end;

    trigger OnOpenPage()
    begin
        if (Rec.GetFilters() <> '') then
            if (not Rec.Find()) then
                if Rec.FindFirst() then;
    end;

    trigger OnAfterGetRecord()
    begin
        FiltersTxt := GetFiltersText();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        FiltersTxt := GetFiltersText();
    end;

    local procedure GetFiltersText(): Text
    var
        FiltersTextBuilder: TextBuilder;
    begin
        if Rec."Dimension 1 Filter" <> '' then
            FiltersTextBuilder.Append(StrSubstNo(FilterCaptionLbl, Rec.GetDimensionCaption(1), Rec."Dimension 1 Filter"));
        if Rec."Dimension 2 Filter" <> '' then
            FiltersTextBuilder.Append(StrSubstNo(FilterCaptionLbl, Rec.GetDimensionCaption(2), Rec."Dimension 2 Filter"));
        if Rec."Dimension 3 Filter" <> '' then
            FiltersTextBuilder.Append(StrSubstNo(FilterCaptionLbl, Rec.GetDimensionCaption(3), Rec."Dimension 3 Filter"));
        if Rec."Dimension 4 Filter" <> '' then
            FiltersTextBuilder.Append(StrSubstNo(FilterCaptionLbl, Rec.GetDimensionCaption(4), Rec."Dimension 4 Filter"));
        if Rec."Dimension 5 Filter" <> '' then
            FiltersTextBuilder.Append(StrSubstNo(FilterCaptionLbl, Rec.GetDimensionCaption(5), Rec."Dimension 5 Filter"));
        if Rec."Dimension 6 Filter" <> '' then
            FiltersTextBuilder.Append(StrSubstNo(FilterCaptionLbl, Rec.GetDimensionCaption(6), Rec."Dimension 6 Filter"));
        if Rec."Dimension 7 Filter" <> '' then
            FiltersTextBuilder.Append(StrSubstNo(FilterCaptionLbl, Rec.GetDimensionCaption(7), Rec."Dimension 7 Filter"));
        if Rec."Dimension 8 Filter" <> '' then
            FiltersTextBuilder.Append(StrSubstNo(FilterCaptionLbl, Rec.GetDimensionCaption(8), Rec."Dimension 8 Filter"));

        if Rec."Business Unit Code Filter" <> '' then
            FiltersTextBuilder.Append(StrSubstNo(FilterCaptionLbl, BusinessUnitCodeFilterLblLbl, Rec."Business Unit Code Filter"));

        exit(FiltersTextBuilder.ToText());
    end;

    var
        FilterCaptionLbl: Label '%1 - %2; ', Locked = true;
        BusinessUnitCodeFilterLblLbl: Label 'Business Unit Code Filter';
        FiltersTxt: Text;
}


