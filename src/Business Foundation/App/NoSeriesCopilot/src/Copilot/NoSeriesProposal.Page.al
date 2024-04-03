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
                InstructionalText = 'Describe the number series you want to set up or change. For example, "Set up number series for sales module in the format @@-#####". You can omit the pattern, in this case, the system will suggest one for you.';
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
                Editable = false;
                Enabled = true;
                Visible = IsProposalDetailsVisible;
                SubPageLink = "Proposal No." = field("No.");
            }
        }
    }
    actions
    {
        area(PromptGuide)
        {
            action(NewNumberSeriesForPurchaseOrder)
            {
                Caption = 'Set up number series for purchase orders';
                trigger OnAction()
                begin
                    InputText := NewNoSeriesForPurchaseOrderLbl;
                    CurrPage.Update();
                end;
            }
            action(NewNumberSeriesForSalesModuleWithPattern)
            {
                Caption = 'Set up numbers for the sales module, using pattern';
                trigger OnAction()
                begin
                    InputText := NewNoSeriesForSalesModuleWithPatternLbl;
                    CurrPage.Update();
                end;
            }
            action(NewNumberSeriesForCompany)
            {
                Caption = 'Set up numbers series for the new companyy';
                trigger OnAction()
                begin
                    InputText := NewNoSeriesForCompanyLbl;
                    CurrPage.Update();
                end;
            }
            action(ChangeNoSeries)
            {
                Caption = 'Change the starting number of the sales order';
                trigger OnAction()
                begin
                    InputText := ChangeSalesOrderNumberLbl;
                    CurrPage.Update();
                end;
            }
        }
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
        NewNoSeriesForPurchaseOrderLbl: Label 'Set up number series for purchase orders';
        NewNoSeriesForSalesModuleWithPatternLbl: Label 'Set up number series for sales module in the format @@-#####';
        NewNoSeriesForCompanyLbl: Label 'Set up numbers series for the new company';
        ChangeSalesOrderNumberLbl: Label 'Change the number of the sales order to SO-1000';

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
        IsResponseTextVisible := ResponseText <> '';
        IsProposalDetailsVisible := not NoSeriesGenerated.IsEmpty;
    end;

    local procedure ApplyProposedNoSeries()
    var
        NoSeriesCopilotImpl: Codeunit "No. Series Copilot Impl.";
        NoSeriesGenerated: Record "No. Series Proposal Line";
    begin
        CurrPage.ProposalDetails.Page.GetTempRecord(Rec."No.", NoSeriesGenerated);
        NoSeriesCopilotImpl.ApplyProposedNoSeries(NoSeriesGenerated);
    end;
}