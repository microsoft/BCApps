/// <summary>
/// This page is used to setup the Copilot No. Series. The page is used to store the secret key and the endpoint of the Azure OpenAI service.
/// Should be removed once the number series copilot is fully integrated with the system.
/// </summary>
page 9245 "No. Series Copilot Setup"
{

    Caption = 'No. Series with Copilot Setup';
    PageType = Card;
    SourceTable = "No. Series Copilot Setup";
    InsertAllowed = false;
    DeleteAllowed = false;
    ApplicationArea = All;
    UsageCategory = Administration;
    AdditionalSearchTerms = 'no series copilot, number series copilot';


    layout
    {
        area(content)
        {
            group(General)
            {
                field(Endpoint; Rec.Endpoint)
                {
                    ApplicationArea = All;
                }
                field(Deployment; Rec.Deployment)
                {
                    ApplicationArea = All;
                }
            }
            group(Secrets)
            {
                field(SecretKey; SecretKey)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Secret Key';
                    NotBlank = true;
                    ShowMandatory = true;
                    ExtendedDatatype = Masked;
                    trigger OnValidate()
                    begin
                        Rec.SetSecretKeyToIsolatedStorage(SecretKey);
                    end;
                }
            }
            group(Prompts)
            {
                field("System Prompt"; SystemPrompt)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'System Prompt';
                    NotBlank = true;
                    ShowMandatory = true;
                    ExtendedDatatype = Masked;
                    MultiLine = true;
                    trigger OnValidate()
                    begin
                        Rec.SetSystemPromptToIsolatedStorage(SystemPrompt);
                    end;
                }
            }
            group(Tools)
            {
                field("Tools Definition"; ToolsDefinition)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Tools Definition';
                    NotBlank = true;
                    ShowMandatory = true;
                    ExtendedDatatype = Masked;
                    MultiLine = true;
                    trigger OnValidate()
                    begin
                        Rec.SetToolsDefinitionToIsolatedStorage(ToolsDefinition);
                    end;
                }

                field("Tool 1 Output Format"; Tool1OutputFormat)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Tool 1 Output Format';
                    NotBlank = true;
                    ShowMandatory = true;
                    ExtendedDatatype = Masked;
                    MultiLine = true;
                    trigger OnValidate()
                    begin
                        Rec.SetTool1OutputFormatToIsolatedStorage(Tool1OutputFormat);
                    end;

                }
            }
        }
    }

    var
        [NonDebuggable]
        SecretKey: Text;
        SystemPrompt: Text;
        ToolsDefinition: Text;
        Tool1OutputFormat: Text;



    trigger OnOpenPage()
    begin
        if not Rec.Get() then
            Rec.Insert();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SecretKey := Rec.GetSecretKeyFromIsolatedStorage();
        SystemPrompt := Rec.GetSystemPromptFromIsolatedStorage();
        ToolsDefinition := Rec.GetToolsDefinitionFromIsolatedStorage();
        Tool1OutputFormat := Rec.GetTool1OutputFormatFromIsolatedStorage();
    end;

}