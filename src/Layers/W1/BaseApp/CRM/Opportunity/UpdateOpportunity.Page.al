// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Opportunity;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Task;
using Microsoft.Sales.Document;
using System.Environment;

page 5129 "Update Opportunity"
{
    Caption = 'Update Opportunity';
    DataCaptionExpression = Caption();
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Opportunity Entry";

    layout
    {
        area(content)
        {
            field("Action type"; Rec."Action Type")
            {
                ApplicationArea = RelationshipMgmt;
                ToolTip = 'Specifies options that you can take when you reenter an opportunity to update it in the Update Opportunity window. Certain options are not available, depending on what stage you are in for your opportunity. For example, if you are in stage 1, you cannot select the Previous option.';
                ValuesAllowed = First, Next, Previous, Skip, Jump, Update;

                trigger OnValidate()
                begin
                    if Rec."Action Type" = Rec."Action Type"::Update then
                        UpdateActionTypeOnValidate();
                    if Rec."Action Type" = Rec."Action Type"::Jump then
                        JumpActionTypeOnValidate();
                    if Rec."Action Type" = Rec."Action Type"::Skip then
                        SkipActionTypeOnValidate();
                    if Rec."Action Type" = Rec."Action Type"::Previous then
                        PreviousActionTypeOnValidate();
                    if Rec."Action Type" = Rec."Action Type"::Next then
                        NextActionTypeOnValidate();
                    if Rec."Action Type" = Rec."Action Type"::First then
                        FirstActionTypeOnValidate();

                    Rec.WizardActionTypeValidate2();
                    UpdateCntrls();
                end;
            }
            field("Sales Cycle Stage"; Rec."Sales Cycle Stage")
            {
                ApplicationArea = RelationshipMgmt;
                Editable = SalesCycleStageEditable;
                ToolTip = 'Specifies the sales cycle stage currently of the opportunity.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    Rec.LookupSalesCycleStage();
                    Rec.ValidateSalesCycleStage();
                end;

                trigger OnValidate()
                begin
                    Rec.WizardSalesCycleStageValidate2();
                    SalesCycleStageOnAfterValidate();
                end;
            }
            field("Sales Cycle Stage Description"; Rec."Sales Cycle Stage Description")
            {
                ApplicationArea = RelationshipMgmt;
                Editable = false;
                ToolTip = 'Specifies a description of the sales cycle stage.';
            }
            field("Date of Change"; Rec."Date of Change")
            {
                ApplicationArea = RelationshipMgmt;
                ToolTip = 'Specifies the date this opportunity entry was last changed.';
            }
            field("Estimated Value (LCY)"; Rec."Estimated Value (LCY)")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Estimated sales value (LCY)';
                ToolTip = 'Specifies the estimated value of the opportunity entry.';
            }
            field("Chances of Success %"; Rec."Chances of Success %")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Chances of Success (%)';
                ToolTip = 'Specifies the chances of success of the opportunity entry.';
            }
            field("Estimated Close Date"; Rec."Estimated Close Date")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Estimated Closing Date';
                ToolTip = 'Specifies the estimated date when the opportunity entry will be closed.';
            }
            field("Cancel Old To Do"; Rec."Cancel Old To Do")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Cancel Existing Open Tasks';
                Enabled = CancelOldTaskEnable;
                ToolTip = 'Specifies a task is to be cancelled from the opportunity.';
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Finish)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = '&Finish';
                Image = Approve;
                InFooterBar = true;
                ToolTip = 'Finish updating the opportunity.';
                Visible = IsOnMobile;

                trigger OnAction()
                begin
                    FinishPage();
                    CurrPage.Close();
                end;
            }
            action(SalesQuote)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Sales Quote';
                Enabled = SalesQuoteEnable;
                Image = Quote;
                InFooterBar = true;
                ToolTip = 'Create a sales quote based on the opportunity.';

                trigger OnAction()
                var
                    SalesHeader: Record "Sales Header";
                begin
                    if Opportunity.Get(Rec."Opportunity No.") then begin
                        Opportunity.ShowQuote();
                        if SalesHeader.Get(SalesHeader."Document Type"::Quote, Opportunity."Sales Document No.") then begin
                            Rec."Estimated Value (LCY)" := Rec.GetSalesDocValue(SalesHeader);
                            CurrPage.Update();
                        end;
                    end;
                end;
            }
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'New';

                actionref(Finish_Promoted; Finish)
                {
                }
                actionref(SalesQuote_Promoted; SalesQuote)
                {
                }
            }
        }
    }

    trigger OnInit()
    begin
        CancelOldTaskEnable := true;
        SalesQuoteEnable := true;
        OptionSixEnable := true;
        OptionFiveEnable := true;
        OptionFourEnable := true;
        OptionThreeEnable := true;
        OptionTwoEnable := true;
        OptionOneEnable := true;
        SalesCycleStageEditable := true;
    end;

    trigger OnOpenPage()
    begin
        IsOnMobile := ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Phone;
        Rec.CreateStageList();
        UpdateEditable();
        if Opportunity.Get(Rec."Opportunity No.") then
            if Opportunity."Sales Document No." <> '' then
                SalesQuoteEnable := true
            else
                SalesQuoteEnable := false;

        UpdateCntrls();
        UpdateEstimatedValues();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Rec.Validate("Sales Cycle Stage");
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then
            FinishPage();
    end;

    var
        Cont: Record Contact;
        SalesCycleStage: Record "Sales Cycle Stage";
        ClientTypeManagement: Codeunit "Client Type Management";
        SalesCycleStageEditable: Boolean;
        OptionOneEnable: Boolean;
        OptionTwoEnable: Boolean;
        OptionThreeEnable: Boolean;
        OptionFiveEnable: Boolean;
        OptionFourEnable: Boolean;
        OptionSixEnable: Boolean;
        CancelOldTaskEnable: Boolean;
        IsOnMobile: Boolean;

#pragma warning disable AA0074
        Text000: Label 'untitled';
#pragma warning disable AA0470
        Text666: Label '%1 is not a valid selection.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        Opportunity: Record Opportunity;
        SalesQuoteEnable: Boolean;

    procedure Caption(): Text
    var
        CaptionStr: Text;
    begin
        if Cont.Get(Rec."Contact Company No.") then
            CaptionStr := CopyStr(Cont."No." + ' ' + Cont.Name, 1, MaxStrLen(CaptionStr));
        if Cont.Get(Rec."Contact No.") then
            CaptionStr := CopyStr(CaptionStr + ' ' + Cont."No." + ' ' + Cont.Name, 1, MaxStrLen(CaptionStr));
        if CaptionStr = '' then
            CaptionStr := Text000;

        exit(CaptionStr);
    end;

    local procedure UpdateEditable()
    begin
        OptionOneEnable := Rec.NoOfSalesCyclesFirst() > 0;
        OptionTwoEnable := Rec.NoOfSalesCyclesNext() > 0;
        OptionThreeEnable := Rec.NoOfSalesCyclesPrev() > 0;
        OptionFourEnable := Rec.NoOfSalesCyclesSkip() > 1;
        OptionFiveEnable := Rec.NoOfSalesCyclesUpdate() > 0;
        OptionSixEnable := Rec.NoOfSalesCyclesJump() > 1;
    end;

    local procedure UpdateCntrls()
    var
        Task: Record "To-do";
    begin
        case Rec."Action Type" of
            Rec."Action Type"::First:
                begin
                    SalesCycleStageEditable := false;
                    CancelOldTaskEnable := false;
                end;
            Rec."Action Type"::Next:
                begin
                    SalesCycleStageEditable := false;
                    CancelOldTaskEnable := true;
                end;
            Rec."Action Type"::Previous:
                begin
                    SalesCycleStageEditable := false;
                    CancelOldTaskEnable := true;
                end;
            Rec."Action Type"::Skip:
                begin
                    SalesCycleStageEditable := true;
                    CancelOldTaskEnable := true;
                end;
            Rec."Action Type"::Update:
                begin
                    SalesCycleStageEditable := false;
                    CancelOldTaskEnable := false;
                end;
            Rec."Action Type"::Jump:
                begin
                    SalesCycleStageEditable := true;
                    CancelOldTaskEnable := true;
                end;
        end;
        Task.Reset();
        Task.SetCurrentKey("Opportunity No.");
        Task.SetRange("Opportunity No.", Rec."Opportunity No.");
        if Task.FindFirst() then
            CancelOldTaskEnable := true;
        Rec.Modify();
    end;

    local procedure SalesCycleStageOnAfterValidate()
    begin
        if SalesCycleStage.Get(Rec."Sales Cycle Code", Rec."Sales Cycle Stage") then
            Rec."Sales Cycle Stage Description" := SalesCycleStage.Description;
    end;

    local procedure FirstActionTypeOnValidate()
    begin
        if not OptionOneEnable then
            Error(Text666, Rec."Action Type");
    end;

    local procedure NextActionTypeOnValidate()
    begin
        if not OptionTwoEnable then
            Error(Text666, Rec."Action Type");
    end;

    local procedure PreviousActionTypeOnValidate()
    begin
        if not OptionThreeEnable then
            Error(Text666, Rec."Action Type");
    end;

    local procedure SkipActionTypeOnValidate()
    begin
        if not OptionFourEnable then
            Error(Text666, Rec."Action Type");
    end;

    local procedure JumpActionTypeOnValidate()
    begin
        if not OptionSixEnable then
            Error(Text666, Rec."Action Type");
    end;

    local procedure UpdateActionTypeOnValidate()
    begin
        if not OptionFiveEnable then
            Error(Text666, Rec."Action Type");
    end;

    local procedure FinishPage()
    begin
        Rec.CheckStatus2();
        Rec.FinishWizard2();
    end;

    local procedure UpdateEstimatedValues()
    var
        SalesCycleStage: Record "Sales Cycle Stage";
        SalesHeader: Record "Sales Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateEstimatedValues(Opportunity, Rec, IsHandled);
        if IsHandled then
            exit;

        if SalesCycleStage.Get(Rec."Sales Cycle Code", Rec."Sales Cycle Stage") then begin
            Rec."Estimated Close Date" := CalcDate(SalesCycleStage."Date Formula", Rec."Date of Change");
            Rec."Chances of Success %" := SalesCycleStage."Chances of Success %";
        end;
        if SalesHeader.Get(SalesHeader."Document Type"::Quote, Opportunity."Sales Document No.") then
            Rec."Estimated Value (LCY)" := Rec.GetSalesDocValue(SalesHeader);

        OnUpdateEstimatedValuesOnBeforeModify(Rec, SalesHeader);
        Rec.Modify();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateEstimatedValues(Opportunity: Record Opportunity; var OpportunityEntry: Record "Opportunity Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateEstimatedValuesOnBeforeModify(var OpportunityEntry: Record "Opportunity Entry"; SalesHeader: Record "Sales Header")
    begin
    end;
}

