// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

page 332 "No. Series Proposal"
{
    Caption = 'Generate No. Series with Copilot';
    DataCaptionExpression = PageCaptionLbl;
    PageType = PromptDialog;
    IsPreview = true;
    Extensible = false;
    ApplicationArea = All;
    Editable = true;
    SourceTable = "No. Series Proposal";
    SourceTableTemporary = true;
    InherentPermissions = X;
    InherentEntitlements = X;

    layout
    {
        area(PromptOptions)
        {
        }
        area(Prompt)
        {
            field(InputText; InputText)
            {
                Caption = 'Request';
                InstructionalText = 'Describe the number series you want to create or change.';
                ShowCaption = false;
                MultiLine = true;
                ApplicationArea = All;
                trigger OnValidate()
                begin
                    CurrPage.Update();
                end;
            }

        }
        area(Content)
        {
            group(AIResponse)
            {
                ShowCaption = false;
                Visible = IsResponseTextVisible;
                field(ResponseText; ResponseText)
                {
                    Caption = 'AI Response';
                    MultiLine = true;
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                    Enabled = false;
                }
            }
            part(ProposalDetails; "No. Series Proposal Sub")
            {
                Caption = 'No. Series proposals';
                ShowFilter = false;
                ApplicationArea = All;
                Visible = IsProposalDetailsVisible;
                SubPageLink = "Proposal No." = field("No.");
            }
        }
    }
#pragma warning disable AW0005
    actions
    {
        area(PromptGuide)
        {
            group(CreateNewNoSeriesGroup)
            {
                Caption = 'Create new';

                action(NewNumberSeriesFor)
                {
                    ApplicationArea = All;
                    Caption = 'Create number series for [purchase orders]';
                    ToolTip = 'Sample prompt for creating number series. Replace [purchase orders] with the entity you want to create number series for.';
                    trigger OnAction()
                    begin
                        InputText := CreateNoSeriesForLbl;
                        CurrPage.Update();
                    end;
                }
                action(NewNumberSeriesForModuleWithPattern)
                {
                    ApplicationArea = All;
                    Caption = 'Create numbers for the [sales] module, using pattern [@@-#####]';
                    ToolTip = 'Sample prompt for creating number series for a specific module with a specific pattern. Replace [sales] with the module you want to create number series for and [@@-#####] with the pattern you want to use.';
                    trigger OnAction()
                    begin
                        InputText := CreateNoSeriesForModuleWithPatternLbl;
                        CurrPage.Update();
                    end;
                }
                action(NewNumberSeriesForCompany)
                {
                    ApplicationArea = All;
                    Caption = 'Create numbers series for the new company';
                    ToolTip = 'Sample prompt for creating number series for a new company.';
                    trigger OnAction()
                    begin
                        InputText := CreateNoSeriesForCompanyLbl;
                        CurrPage.Update();
                    end;
                }
            }
            group(ModifyExistingNoSeriesGroup)
            {
                Caption = 'Modify existing';

                action(ChangeNumberTo)
                {
                    Caption = 'Change the [sales order] number to [SO-10001]';
                    ToolTip = 'Sample prompt for changing the number series. Replace [sales order] with the entity you want to change the number series for and [SO-10001] with the new number.';
                    trigger OnAction()
                    begin
                        InputText := ChangeNumberLbl;
                        CurrPage.Update();
                    end;
                }
            }
            group(PrepareForNextYearGroup)
            {
                Caption = 'Prepare for next year';

                action(SetupForNextYear)
                {
                    Caption = 'Set up number series for the next year';
                    ToolTip = 'Sample prompt for setting up number series for the next year.';
                    trigger OnAction()
                    begin
                        InputText := SetupForNextYearLbl;
                        CurrPage.Update();
                    end;
                }
                action(SetupModuleForNextYear)
                {
                    Caption = 'Set up number series for the [sales] module for the next year';
                    ToolTip = 'Sample prompt for setting up number series for a specific module for the next year. Replace [sales] with the module you want to set up number series for.';
                    trigger OnAction()
                    begin
                        InputText := SetupModuleForNextYearLbl;
                        CurrPage.Update();
                    end;
                }
            }
        }
#pragma warning restore AW0005

        area(SystemActions)
        {
            systemaction(Generate)
            {
                Caption = 'Generate';
                Tooltip = 'Generate no. series';
                trigger OnAction()
                begin
                    GenerateNoSeries();
                end;
            }
            systemaction(Regenerate)
            {
                Caption = 'Regenerate';
                Tooltip = 'Regenerate no. series';
                trigger OnAction()
                begin
                    GenerateNoSeries();
                end;
            }
            systemaction(Cancel)
            {
                ToolTip = 'Discards all suggestions and dismisses the dialog';
            }
            systemaction(Ok)
            {
                Caption = 'Keep it';
                ToolTip = 'Accepts the current suggestion and dismisses the dialog';
            }
        }
    }

    var
        InputText: Text;
        ResponseText: Text;
        PageCaptionLbl: text;
        IsResponseTextVisible: Boolean;
        IsProposalDetailsVisible: Boolean;
        CreateNoSeriesForLbl: Label 'Create number series for ';
        CreateNoSeriesForModuleWithPatternLbl: Label 'Create number series for [specify here] module in the format ';
        CreateNoSeriesForCompanyLbl: Label 'Create numbers series for the new company';
        ChangeNumberLbl: Label 'Change the [specify here] number to ';
        SetupForNextYearLbl: Label 'Set up number series for the next year';
        SetupModuleForNextYearLbl: Label 'Set up number series for the [specify here] module for the next year';

    trigger OnAfterGetCurrRecord()
    begin
        PageCaptionLbl := Rec.GetInputText();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
    begin
        if CloseAction = CloseAction::OK then
            ApplyProposedNoSeries();
    end;

    local procedure GenerateNoSeries()
    var
        GeneratedNoSeries: Record "No. Series Proposal Line";
        NoSeriesCopilotImpl: Codeunit "No. Series Copilot Impl.";
    begin
        NoSeriesCopilotImpl.Generate(Rec, ResponseText, GeneratedNoSeries, InputText);
        CurrPage.ProposalDetails.Page.Load(GeneratedNoSeries);
        IsResponseTextVisible := ResponseText <> '';
        IsProposalDetailsVisible := not GeneratedNoSeries.IsEmpty;
    end;

    local procedure ApplyProposedNoSeries()
    var
        GeneratedNoSeries: Record "No. Series Proposal Line";
        NoSeriesCopilotImpl: Codeunit "No. Series Copilot Impl.";
    begin
        CurrPage.ProposalDetails.Page.GetTempRecord(Rec."No.", GeneratedNoSeries);
        NoSeriesCopilotImpl.ApplyProposedNoSeries(GeneratedNoSeries);
    end;
}