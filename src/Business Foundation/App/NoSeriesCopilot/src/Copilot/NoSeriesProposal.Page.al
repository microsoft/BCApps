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
            group(CreateNewNoSeries)
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
            group(ModifyExistingNoSeries)
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
        NoSeriesGenerated: Record "No. Series Proposal Line";
        NoSeriesCopilotImpl: Codeunit "No. Series Copilot Impl.";
    begin
        NoSeriesCopilotImpl.Generate(Rec, ResponseText, NoSeriesGenerated, InputText);
        CurrPage.ProposalDetails.Page.Load(NoSeriesGenerated);
        IsResponseTextVisible := ResponseText <> '';
        IsProposalDetailsVisible := not NoSeriesGenerated.IsEmpty;
    end;

    local procedure ApplyProposedNoSeries()
    var
        NoSeriesGenerated: Record "No. Series Proposal Line";
        NoSeriesCopilotImpl: Codeunit "No. Series Copilot Impl.";
    begin
        CurrPage.ProposalDetails.Page.GetTempRecord(Rec."No.", NoSeriesGenerated);
        NoSeriesCopilotImpl.ApplyProposedNoSeries(NoSeriesGenerated);
    end;
}