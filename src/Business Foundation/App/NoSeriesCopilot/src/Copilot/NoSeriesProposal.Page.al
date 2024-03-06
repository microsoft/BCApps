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
            field(ResponseText; ResponseText)
            {
                Caption = 'AI Response';
                MultiLine = true;
                ApplicationArea = All;
                Editable = false;
                Enabled = false;
            }
            part(ProposalDetails; "No. Series Proposal Sub")
            {
                Caption = 'No. Series proposals';
                ShowFilter = false;
                ApplicationArea = All;
                Editable = false;
                Enabled = true;
                Visible = IsProposalDetailsVisible;
                SubPageLink = "Proposal No." = field("No.");
            }
        }
    }
    actions
    {
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
        IsProposalDetailsVisible: Boolean;

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
        NoSeriesCopilotImpl: Codeunit "No. Series Copilot Impl.";
        NoSeriesGenerated: Record "No. Series Proposal Line";
    begin
        NoSeriesCopilotImpl.Generate(Rec, ResponseText, NoSeriesGenerated, InputText);
        CurrPage.ProposalDetails.Page.Load(NoSeriesGenerated);
        IsProposalDetailsVisible := not NoSeriesGenerated.IsEmpty;
    end;

    local procedure ApplyProposedNoSeries()
    var
        NoSeriesCopilotImpl: Codeunit "No. Series Copilot Impl.";
        NoSeriesGenerated: Record "No. Series Proposal Line";
    begin
        Error('Not implemented');
        // CurrPage.ProposalDetails.Page.GetTempRecord(Rec."No.", NoSeriesGenerated);
        // NoSeriesCopilotImpl.ApplyProposedNoSeries(NoSeriesGenerated);
    end;
}