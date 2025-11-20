// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Opportunity;

using Microsoft.CRM.Contact;
using Microsoft.Sales.Document;
using System.Environment;

page 5128 "Close Opportunity"
{
    Caption = 'Close Opportunity';
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
            group(General)
            {
                Caption = 'General';
                field(OptionWon; Rec."Action Taken")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Opportunity Status';
                    ToolTip = 'Specifies the action that was taken when the entry was last updated. There are six options:';
                    ValuesAllowed = Won, Lost;

                    trigger OnValidate()
                    var
                        CloseOpportunityCode: Record "Close Opportunity Code";
                    begin
                        if Rec."Action Taken" = Rec."Action Taken"::Lost then
                            LostActionTakenOnValidate();
                        if Rec."Action Taken" = Rec."Action Taken"::Won then
                            WonActionTakenOnValidate();

                        case Rec."Action Taken" of
                            Rec."Action Taken"::Won:
                                begin
                                    CalcdCurrentValueLCYEnable := true;
                                    if Opp.Get(Rec."Opportunity No.") then
                                        SalesQuoteEnable := Opp."Sales Document No." <> '';
                                end;
                            Rec."Action Taken"::Lost:
                                begin
                                    CalcdCurrentValueLCYEnable := false;
                                    SalesQuoteEnable := false;
                                end;
                        end;

                        Rec.UpdateEstimates();
                        case Rec."Action Taken" of
                            Rec."Action Taken"::Won:
                                begin
                                    CloseOpportunityCode.SetRange(Type, CloseOpportunityCode.Type::Won);
                                    if CloseOpportunityCode.Count = 1 then begin
                                        CloseOpportunityCode.FindFirst();
                                        Rec."Close Opportunity Code" := CloseOpportunityCode.Code;
                                    end;
                                end;
                            Rec."Action Taken"::Lost:
                                begin
                                    CloseOpportunityCode.SetRange(Type, CloseOpportunityCode.Type::Lost);
                                    if CloseOpportunityCode.Count = 1 then begin
                                        CloseOpportunityCode.FindFirst();
                                        Rec."Close Opportunity Code" := CloseOpportunityCode.Code;
                                    end;
                                end;
                        end;
                    end;
                }
                field("Close Opportunity Code"; Rec."Close Opportunity Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Close Opportunity Code';
                    ToolTip = 'Specifies the code for closing the opportunity.';
                }
                field("Date of Change"; Rec."Date of Change")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Closing Date';
                    ToolTip = 'Specifies the date this opportunity entry was last changed.';
                }
                field("Calcd. Current Value (LCY)"; Rec."Calcd. Current Value (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Sales (LCY)';
                    Enabled = CalcdCurrentValueLCYEnable;
                    ToolTip = 'Specifies the calculated current value of the opportunity entry.';
                }
                field("Cancel Old To Do"; Rec."Cancel Old To Do")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Cancel Old Tasks';
                    ToolTip = 'Specifies a task is to be cancelled from the opportunity.';
                }
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
                ToolTip = 'Finish closing the opportunity.';
                Visible = IsOnMobile;

                trigger OnAction()
                begin
                    Rec.CheckStatus();
                    Rec.FinishWizard();
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
                    if Opp.Get(Rec."Opportunity No.") then begin
                        Opp.ShowQuote();
                        if SalesHeader.Get(SalesHeader."Document Type"::Quote, Opp."Sales Document No.") then begin
                            Rec."Calcd. Current Value (LCY)" := Rec.GetSalesDocValue(SalesHeader);
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
        OptionLostEnable := true;
        OptionWonEnable := true;
        SalesQuoteEnable := true;
        CalcdCurrentValueLCYEnable := true;
    end;

    trigger OnOpenPage()
    begin
        UpdateEditable();
        Rec."Cancel Old To Do" := true;
        IsOnMobile := ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Phone;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then begin
            Rec.CheckStatus();
            Rec.FinishWizard();
        end;
    end;

    var
        Cont: Record Contact;
        ClientTypeManagement: Codeunit "Client Type Management";
        CalcdCurrentValueLCYEnable: Boolean;
        OptionWonEnable: Boolean;
        OptionLostEnable: Boolean;
        IsOnMobile: Boolean;

#pragma warning disable AA0074
        Text000: Label 'untitled';
#pragma warning restore AA0074
        IsNotAValidSelectionErr: Label '%1 is not a valid selection.', Comment = '%1 - Field Value';

    protected var
        Opp: Record Opportunity;
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
        if Rec.GetFilter("Action Taken") <> '' then begin
            OptionWonEnable := false;
            OptionLostEnable := false;
        end;
    end;

    local procedure WonActionTakenOnValidate()
    begin
        if not OptionWonEnable then
            Error(IsNotAValidSelectionErr, Rec."Action Taken");
    end;

    local procedure LostActionTakenOnValidate()
    begin
        if not OptionLostEnable then
            Error(IsNotAValidSelectionErr, Rec."Action Taken");
    end;
}

