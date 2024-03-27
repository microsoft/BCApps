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
                field(SystemPrompt; SystemPrompt)
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
                field(ToolsDefinition; ToolsDefinition)
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
                group(Tool1)
                {
                    field(Tool1GeneralInstructionsPrompt; Tool1GeneralInstructionsPrompt)
                    {
                        ApplicationArea = All;
                        Caption = 'Tool 1 General Instructions Prompt';
                        NotBlank = true;
                        ShowMandatory = true;
                        ExtendedDatatype = Masked;
                        MultiLine = true;
                        trigger OnValidate()
                        begin
                            Rec.SetTool1GeneralInstructionsPromptToIsolatedStorage(Tool1GeneralInstructionsPrompt);
                        end;
                    }

                    field(Tool1LimitationsPrompt; Tool1LimitationsPrompt)
                    {
                        ApplicationArea = All;
                        Caption = 'Tool 1 Limitations Prompt';
                        NotBlank = true;
                        ShowMandatory = true;
                        ExtendedDatatype = Masked;
                        MultiLine = true;
                        trigger OnValidate()
                        begin
                            Rec.SetTool1LimitationsPromptToIsolatedStorage(Tool1LimitationsPrompt);
                        end;
                    }

                    field(Tool1CodeGuidelinesPrompt; Tool1CodeGuidelinesPrompt)
                    {
                        ApplicationArea = All;
                        Caption = 'Tool 1 Code Guidelines Prompt';
                        NotBlank = true;
                        ShowMandatory = true;
                        ExtendedDatatype = Masked;
                        MultiLine = true;
                        trigger OnValidate()
                        begin
                            Rec.SetTool1CodeGuidelinePromptToIsolatedStorage(Tool1CodeGuidelinesPrompt);
                        end;
                    }

                    field(Tool1DescriptionGuidelinesPrompt; Tool1DescriptionGuidelinesPrompt)
                    {
                        ApplicationArea = All;
                        Caption = 'Tool 1 Description Guidelines Prompt';
                        NotBlank = true;
                        ShowMandatory = true;
                        ExtendedDatatype = Masked;
                        MultiLine = true;
                        trigger OnValidate()
                        begin
                            Rec.SetTool1DescrGuidelinePromptToIsolatedStorage(Tool1DescriptionGuidelinesPrompt);
                        end;
                    }

                    field(ToolNumberGuidelinesPrompt; ToolNumberGuidelinesPrompt)
                    {
                        ApplicationArea = All;
                        Caption = 'Tool 1 Number Guidelines Prompt';
                        NotBlank = true;
                        ShowMandatory = true;
                        ExtendedDatatype = Masked;
                        MultiLine = true;
                        trigger OnValidate()
                        begin
                            Rec.SetTool1NumberGuidelinePromptToIsolatedStorage(ToolNumberGuidelinesPrompt);
                        end;
                    }

                    field(Tool1OutputExamplesPrompt; Tool1OutputExamplesPrompt)
                    {
                        ApplicationArea = All;
                        Caption = 'Tool 1 Output Examples Prompt';
                        NotBlank = true;
                        ShowMandatory = true;
                        ExtendedDatatype = Masked;
                        MultiLine = true;
                        trigger OnValidate()
                        begin
                            Rec.SetTool1OutputExamplesPromptToIsolatedStorage(Tool1OutputExamplesPrompt);
                        end;
                    }

                    field(Tool1OutputFormatPrompt; Tool1OutputFormatPrompt)
                    {
                        ApplicationArea = All;
                        Caption = 'Tool 1 Output Format Prompt';
                        NotBlank = true;
                        ShowMandatory = true;
                        ExtendedDatatype = Masked;
                        MultiLine = true;
                        trigger OnValidate()
                        begin
                            Rec.SetTool1OutputFormatPromptToIsolatedStorage(Tool1OutputFormatPrompt);
                        end;
                    }
                }
                group(Tool2)
                {
                    field(Tool2GeneralInstructionsPrompt; Tool2GeneralInstructionsPrompt)
                    {
                        ApplicationArea = All;
                        Caption = 'Tool 2 General Instructions Prompt';
                        NotBlank = true;
                        ShowMandatory = true;
                        ExtendedDatatype = Masked;
                        MultiLine = true;
                        trigger OnValidate()
                        begin
                            Rec.SetTool2GeneralInstructionsPromptToIsolatedStorage(Tool2GeneralInstructionsPrompt);
                        end;
                    }

                    field(Tool2LimitationsPrompt; Tool2LimitationsPrompt)
                    {
                        ApplicationArea = All;
                        Caption = 'Tool 2 Limitations Prompt';
                        NotBlank = true;
                        ShowMandatory = true;
                        ExtendedDatatype = Masked;
                        MultiLine = true;
                        trigger OnValidate()
                        begin
                            Rec.SetTool2LimitationsPromptToIsolatedStorage(Tool2LimitationsPrompt);
                        end;
                    }

                    field(Tool2CodeGuidelinesPrompt; Tool2CodeGuidelinesPrompt)
                    {
                        ApplicationArea = All;
                        Caption = 'Tool 2 Code Guidelines Prompt';
                        NotBlank = true;
                        ShowMandatory = true;
                        ExtendedDatatype = Masked;
                        MultiLine = true;
                        trigger OnValidate()
                        begin
                            Rec.SetTool2CodeGuidelinePromptToIsolatedStorage(Tool2CodeGuidelinesPrompt);
                        end;
                    }

                    field(Tool2DescriptionGuidelinesPrompt; Tool2DescriptionGuidelinesPrompt)
                    {
                        ApplicationArea = All;
                        Caption = 'Tool 2 Description Guidelines Prompt';
                        NotBlank = true;
                        ShowMandatory = true;
                        ExtendedDatatype = Masked;
                        MultiLine = true;
                        trigger OnValidate()
                        begin
                            Rec.SetTool2DescrGuidelinePromptToIsolatedStorage(Tool2DescriptionGuidelinesPrompt);
                        end;
                    }

                    field(Tool2NumberGuidelinesPrompt; Tool2NumberGuidelinesPrompt)
                    {
                        ApplicationArea = All;
                        Caption = 'Tool 2 Number Guidelines Prompt';
                        NotBlank = true;
                        ShowMandatory = true;
                        ExtendedDatatype = Masked;
                        MultiLine = true;
                        trigger OnValidate()
                        begin
                            Rec.SetTool2NumberGuidelinePromptToIsolatedStorage(Tool2NumberGuidelinesPrompt);
                        end;
                    }

                    field(Tool2OutputExamplesPrompt; Tool2OutputExamplesPrompt)
                    {
                        ApplicationArea = All;
                        Caption = 'Tool 2 Output Examples Prompt';
                        NotBlank = true;
                        ShowMandatory = true;
                        ExtendedDatatype = Masked;
                        MultiLine = true;
                        trigger OnValidate()
                        begin
                            Rec.SetTool2OutputExamplesPromptToIsolatedStorage(Tool2OutputExamplesPrompt);
                        end;
                    }

                    field(Tool2OutputFormatPrompt; Tool2OutputFormatPrompt)
                    {
                        ApplicationArea = All;
                        Caption = 'Tool 2 Output Format Prompt';
                        NotBlank = true;
                        ShowMandatory = true;
                        ExtendedDatatype = Masked;
                        MultiLine = true;
                        trigger OnValidate()
                        begin
                            Rec.SetTool2OutputFormatPromptToIsolatedStorage(Tool2OutputFormatPrompt);
                        end;
                    }
                }
            }
        }
    }

    var
        [NonDebuggable]
        SecretKey: Text;
        SystemPrompt: Text;
        ToolsDefinition: Text;
        Tool1GeneralInstructionsPrompt: Text;
        Tool1LimitationsPrompt: Text;
        Tool1CodeGuidelinesPrompt: Text;
        Tool1DescriptionGuidelinesPrompt: Text;
        ToolNumberGuidelinesPrompt: Text;
        Tool1OutputExamplesPrompt: Text;
        Tool1OutputFormatPrompt: Text;
        Tool2GeneralInstructionsPrompt: Text;
        Tool2LimitationsPrompt: Text;
        Tool2CodeGuidelinesPrompt: Text;
        Tool2DescriptionGuidelinesPrompt: Text;
        Tool2NumberGuidelinesPrompt: Text;
        Tool2OutputExamplesPrompt: Text;
        Tool2OutputFormatPrompt: Text;

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
        Tool1GeneralInstructionsPrompt := Rec.GetTool1GeneralInstructionsPromptFromIsolatedStorage();
        Tool1LimitationsPrompt := Rec.GetTool1LimitationsPromptFromIsolatedStorage();
        Tool1CodeGuidelinesPrompt := Rec.GetTool1CodeGuidelinePromptFromIsolatedStorage();
        Tool1DescriptionGuidelinesPrompt := Rec.GetTool1DescrGuidelinePromptFromIsolatedStorage();
        ToolNumberGuidelinesPrompt := Rec.GetTool1NumberGuidelinePromptFromIsolatedStorage();
        Tool1OutputExamplesPrompt := Rec.GetTool1OutputExamplesPromptFromIsolatedStorage();
        Tool1OutputFormatPrompt := Rec.GetTool1OutputExamplesPromptFromIsolatedStorage();
        Tool2GeneralInstructionsPrompt := Rec.GetTool2GeneralInstructionsPromptFromIsolatedStorage();
        Tool2LimitationsPrompt := Rec.GetTool2LimitationsPromptFromIsolatedStorage();
        Tool2CodeGuidelinesPrompt := Rec.GetTool2CodeGuidelinePromptFromIsolatedStorage();
        Tool2DescriptionGuidelinesPrompt := Rec.GetTool2DescrGuidelinePromptFromIsolatedStorage();
        Tool2NumberGuidelinesPrompt := Rec.GetTool2NumberGuidelinePromptFromIsolatedStorage();
        Tool2OutputExamplesPrompt := Rec.GetTool2OutputExamplesPromptFromIsolatedStorage();
        Tool2OutputFormatPrompt := Rec.GetTool2OutputExamplesPromptFromIsolatedStorage();
    end;

}