namespace System.AI;

page 2020 "Image Analysis Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Image Analysis Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    Permissions = TableData "Azure AI Usage" = rimd;
    ShowFilter = false;
    SourceTable = "Image Analysis Setup";
    UsageCategory = Administration;
    AdditionalSearchTerms = 'Item from picture,Azure Cognitive Services,Computer Vision';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Api Uri"; Rec."Api Uri")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'API URI';
                    ToolTip = 'Specifies the API URI for the Computer Vision account to use with Azure Cognitive Services.';

                    trigger OnValidate()
                    begin
                        if (Rec."Api Uri" <> '') and (ApiKey <> '') then
                            SetInfiniteAccess();
                    end;
                }
                field("<Api Key>"; ApiKey)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'API Key';
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the API key for the Computer Vision account to use with Azure Cognitive Services.';

                    trigger OnValidate()
                    begin
                        Rec.SetApiKey(SecretStrSubstNo(ApiKey));

                        if (Rec."Api Uri" <> '') and (ApiKey <> '') then
                            SetInfiniteAccess();
                    end;
                }
                field(LimitType; LimitType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Limit Type';
                    Editable = false;
                    ToolTip = 'Specifies the unit of time to limit the usage of the Computer Vision service.';
                }
                field(LimitValue; LimitValue)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Limit Value';
                    Editable = false;
                    ToolTip = 'Specifies the number of images that can be analyzed per unit of time.';
                }
                field(NumberOfCalls; NumberOfCalls)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Analyses Performed';
                    Editable = false;
                    ToolTip = 'Specifies the number of images that have been analyzed per unit of time.';
                }
            }
            part(ImageAnalysisScenarios; "Image Analysis Scenarios Part")
            {
                ApplicationArea = Basic, Suite;
                AccessByPermission = TableData "Image Analysis Scenario" = rimd;
                Caption = 'Enable/Disable Image Analysis Scenarios';
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(SetupAction)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Computer Vision API Documentation';
                Image = LinkWeb;
                ToolTip = 'Set up a Computer Vision account with Azure Cognitive Services to do image analysis with Dynamics 365.';

                trigger OnAction()
                begin
                    HyperLink('https://go.microsoft.com/fwlink/?linkid=848400');
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(SetupAction_Promoted; SetupAction)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        AzureAIUsage: Codeunit "Azure AI Usage";
        AzureAIService: Enum "Azure AI Service";
    begin
        Rec.GetSingleInstance();
        if not Rec.GetApiKeyAsSecret().IsEmpty() then
            ApiKey := '***';
        if (Rec."Api Uri" <> '') and (ApiKey <> '') then
            AzureAIUsage.SetImageAnalysisIsSetup(true)
        else
            AzureAIUsage.SetImageAnalysisIsSetup(false);

        AzureAIService := AzureAIService::"Computer Vision";

        LimitType := AzureAIUsage.GetLimitPeriod(AzureAIService);
        LimitValue := AzureAIUsage.GetResourceLimit(AzureAIService);
        NumberOfCalls := AzureAIUsage.GetTotalProcessingTime(AzureAIService);
    end;

    var
        [NonDebuggable]
        ApiKey: Text;
        LimitType: Option Year,Month,Day,Hour;
        LimitValue: Integer;
        NumberOfCalls: Integer;

    local procedure SetInfiniteAccess()
    var
        AzureAIUsageImpl: Codeunit "Azure AI Usage Impl.";
    begin
        AzureAIUsageImpl.SetInfiniteImageAnalysisAccess(Rec);
        LimitType := AzureAIUsageImpl.GetLimitPeriod("Azure AI Service"::"Computer Vision");
        LimitValue := AzureAIUsageImpl.GetResourceLimit("Azure AI Service"::"Computer Vision");
    end;
}

