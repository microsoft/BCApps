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
                field("Functions Prompt"; FunctionsPrompt)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Functions Prompt';
                    NotBlank = true;
                    ShowMandatory = true;
                    ExtendedDatatype = Masked;
                    MultiLine = true;
                    trigger OnValidate()
                    begin
                        Rec.SetFunctionsPromptToIsolatedStorage(FunctionsPrompt);
                    end;
                }
            }
        }
    }

    var
        [NonDebuggable]
        SecretKey: Text;
        SystemPrompt: Text;
        FunctionsPrompt: Text;


    trigger OnOpenPage()
    begin
        if not Rec.Get() then
            Rec.Insert();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SecretKey := Rec.GetSecretKeyFromIsolatedStorage();
        SystemPrompt := Rec.GetSystemPromptFromIsolatedStorage();
        FunctionsPrompt := Rec.GetFunctionsPromptFromIsolatedStorage();
    end;

}