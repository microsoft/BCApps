pageextension 324 "No. Series Ext" extends "No. Series"
{
    actions
    {
        addfirst(Promoted)
        {
            actionref("Generate_Promoted"; "Generate With Copilot") { }
        }
        addfirst(Processing)
        {
            action("Generate With Copilot")
            {
                Caption = 'Generate';
                ToolTip = 'Generate No. Series using Copilot';
                Image = Sparkle;
                ApplicationArea = All;
                Visible = CopilotActionsVisible;

                trigger OnAction()
                var
                    FeatureTelemetry: Codeunit "Feature Telemetry";
                    NoSeriesCopilotRegister: Codeunit "No. Series Copilot Register";
                    NoSeriesCopilotImpl: Codeunit "No. Series Copilot Impl.";
                    AzureOpenAI: Codeunit "Azure OpenAI";
                    NoSeriesCopilot: Page "No. Series Proposal";
                begin
                    NoSeriesCopilotRegister.RegisterCapability();
                    if not AzureOpenAI.IsEnabled(Enum::"Copilot Capability"::"No. Series Copilot") then
                        exit;

                    FeatureTelemetry.LogUptake('0000LF4', NoSeriesCopilotImpl.FeatureName(), Enum::"Feature Uptake Status"::Discovered); //TODO: Update signal id

                    NoSeriesCopilot.LookupMode := true;
                    if NoSeriesCopilot.RunModal = Action::LookupOK then
                        CurrPage.Update();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        FeatureKey: Record "Feature Key";
        FeatureManagementFacade: Codeunit "Feature Management Facade";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if not FeatureKey.Get(NumberSeriesWithAILbl) then
            CopilotActionsVisible := true
        else
            CopilotActionsVisible := FeatureManagementFacade.IsEnabled(NumberSeriesWithAILbl);

        if CopilotActionsVisible then
            CopilotActionsVisible := EnvironmentInformation.IsSaaSInfrastructure();
    end;

    var
        CopilotActionsVisible: Boolean;
        NumberSeriesWithAILbl: label 'NumberSeriesWithAI', Locked = true;

}