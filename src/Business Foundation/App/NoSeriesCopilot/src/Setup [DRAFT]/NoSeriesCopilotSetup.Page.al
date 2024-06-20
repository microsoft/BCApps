/// <summary>
/// This page is used to setup the Copilot No. Series. The page is used to store the secret key and the endpoint of the Azure OpenAI service.
/// Should be removed once the number series copilot is fully integrated with the system.
/// </summary>

namespace Microsoft.Foundation.NoSeries;

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
                    ToolTip = 'Specifies the value of the Endpoint field.';
                }
                field(Deployment; Rec.Deployment)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Deployment field.';
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
                    ToolTip = 'Specifies the value of the Secret Key field.';
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
                    ToolTip = 'Specifies the value of the System Prompt field.';
                    trigger OnValidate()
                    begin
                        Rec.SetNoSeriesGenerationSystemPromptToIsolatedStorage(SystemPrompt);
                    end;
                }
            }
            group(Tools)
            {
                group(ToolsGeneral)
                {
                    ShowCaption = false;

                    field(ToolsSystemPrompt; ToolsSystemPrompt)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Tools Selection System Prompt';
                        NotBlank = true;
                        ShowMandatory = true;
                        ExtendedDatatype = Masked;
                        MultiLine = true;
                        ToolTip = 'Specifies the value of the Tools Selection System Prompt field.';
                        trigger OnValidate()
                        begin
                            Rec.SetToolsSystemPromptToIsolatedStorage(ToolsSystemPrompt);
                        end;
                    }
                }
                group(Tool1)
                {
                    field(Tool1Definition; Tool1Definition)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Tool 1 Definition';
                        NotBlank = true;
                        ShowMandatory = true;
                        ExtendedDatatype = Masked;
                        MultiLine = true;
                        ToolTip = 'Specifies the value of the Tool 1 Definition field.';
                        trigger OnValidate()
                        begin
                            Rec.SetTool1DefinitionToIsolatedStorage(Tool1Definition);
                        end;
                    }

                    field(Tool1GeneralInstructionsPrompt; Tool1GeneralInstructionsPrompt)
                    {
                        ApplicationArea = All;
                        Caption = 'Tool 1 General Instructions Prompt';
                        NotBlank = true;
                        ShowMandatory = true;
                        ExtendedDatatype = Masked;
                        MultiLine = true;
                        ToolTip = 'Specifies the value of the Tool 1 General Instructions Prompt field.';
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
                        ToolTip = 'Specifies the value of the Tool 1 Limitations Prompt field.';
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
                        ToolTip = 'Specifies the value of the Tool 1 Code Guidelines Prompt field.';
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
                        ToolTip = 'Specifies the value of the Tool 1 Description Guidelines Prompt field.';
                        trigger OnValidate()
                        begin
                            Rec.SetTool1DescrGuidelinePromptToIsolatedStorage(Tool1DescriptionGuidelinesPrompt);
                        end;
                    }

                    field(Tool1NumberGuidelinesPrompt; Tool1NumberGuidelinesPrompt)
                    {
                        ApplicationArea = All;
                        Caption = 'Tool 1 Number Guidelines Prompt';
                        NotBlank = true;
                        ShowMandatory = true;
                        ExtendedDatatype = Masked;
                        MultiLine = true;
                        ToolTip = 'Specifies the value of the Tool 1 Number Guidelines Prompt field.';
                        trigger OnValidate()
                        begin
                            Rec.SetTool1NumberGuidelinePromptToIsolatedStorage(Tool1NumberGuidelinesPrompt);
                        end;
                    }

                    field(Tool1CustomPatternsPrompt; Tool1CustomPatternsPrompt)
                    {
                        ApplicationArea = All;
                        Caption = 'Tool 1 Custom Patterns Prompt';
                        NotBlank = true;
                        ShowMandatory = true;
                        ExtendedDatatype = Masked;
                        MultiLine = true;
                        ToolTip = 'Specifies the value of the Tool 1 Custom Patterns Prompt field.';
                        trigger OnValidate()
                        begin
                            Rec.SetTool1CustomPatternsPromptToIsolatedStorage(Tool1CustomPatternsPrompt);
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
                        ToolTip = 'Specifies the value of the Tool 1 Output Examples Prompt field.';
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
                        ToolTip = 'Specifies the value of the Tool 1 Output Format Prompt field.';
                        trigger OnValidate()
                        begin
                            Rec.SetTool1OutputFormatPromptToIsolatedStorage(Tool1OutputFormatPrompt);
                        end;
                    }
                }
                group(Tool2)
                {
                    field(Tool2Definition; Tool2Definition)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Tool 2 Definition';
                        NotBlank = true;
                        ShowMandatory = true;
                        ExtendedDatatype = Masked;
                        MultiLine = true;
                        ToolTip = 'Specifies the value of the Tool 2 Definition field.';
                        trigger OnValidate()
                        begin
                            Rec.SetTool2DefinitionToIsolatedStorage(Tool2Definition);
                        end;
                    }

                    field(Tool2GeneralInstructionsPrompt; Tool2GeneralInstructionsPrompt)
                    {
                        ApplicationArea = All;
                        Caption = 'Tool 2 General Instructions Prompt';
                        NotBlank = true;
                        ShowMandatory = true;
                        ExtendedDatatype = Masked;
                        MultiLine = true;
                        ToolTip = 'Specifies the value of the Tool 2 General Instructions Prompt field.';
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
                        ToolTip = 'Specifies the value of the Tool 2 Limitations Prompt field.';
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
                        ToolTip = 'Specifies the value of the Tool 2 Code Guidelines Prompt field.';
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
                        ToolTip = 'Specifies the value of the Tool 2 Description Guidelines Prompt field.';
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
                        ToolTip = 'Specifies the value of the Tool 2 Number Guidelines Prompt field.';
                        trigger OnValidate()
                        begin
                            Rec.SetTool2NumberGuidelinePromptToIsolatedStorage(Tool2NumberGuidelinesPrompt);
                        end;
                    }

                    field(Tool2CustomPatternsPrompt; Tool2CustomPatternsPrompt)
                    {
                        ApplicationArea = All;
                        Caption = 'Tool 2 Custom Patterns Prompt';
                        NotBlank = true;
                        ShowMandatory = true;
                        ExtendedDatatype = Masked;
                        MultiLine = true;
                        ToolTip = 'Specifies the value of the Tool 2 Custom Patterns Prompt field.';
                        trigger OnValidate()
                        begin
                            Rec.SetTool2CustomPatternsPromptToIsolatedStorage(Tool2CustomPatternsPrompt);
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
                        ToolTip = 'Specifies the value of the Tool 2 Output Examples Prompt field.';
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
                        ToolTip = 'Specifies the value of the Tool 2 Output Format Prompt field.';
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
        ToolsSystemPrompt: Text;
        Tool1Definition: Text;
        Tool1GeneralInstructionsPrompt: Text;
        Tool1LimitationsPrompt: Text;
        Tool1CodeGuidelinesPrompt: Text;
        Tool1DescriptionGuidelinesPrompt: Text;
        Tool1NumberGuidelinesPrompt: Text;
        Tool1CustomPatternsPrompt: Text;
        Tool1OutputExamplesPrompt: Text;
        Tool1OutputFormatPrompt: Text;
        Tool2Definition: Text;
        Tool2GeneralInstructionsPrompt: Text;
        Tool2LimitationsPrompt: Text;
        Tool2CodeGuidelinesPrompt: Text;
        Tool2DescriptionGuidelinesPrompt: Text;
        Tool2NumberGuidelinesPrompt: Text;
        Tool2CustomPatternsPrompt: Text;
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
        SystemPrompt := Rec.GetNoSeriesGenerationSystemPromptFromIsolatedStorage();
        ToolsSystemPrompt := Rec.GetToolsSystemPromptFromIsolatedStorage();
        Tool1Definition := Rec.GetTool1DefinitionFromIsolatedStorage();
        Tool1GeneralInstructionsPrompt := Rec.GetTool1GeneralInstructionsPromptFromIsolatedStorage();
        Tool1LimitationsPrompt := Rec.GetTool1LimitationsPromptFromIsolatedStorage();
        Tool1CodeGuidelinesPrompt := Rec.GetTool1CodeGuidelinePromptFromIsolatedStorage();
        Tool1DescriptionGuidelinesPrompt := Rec.GetTool1DescrGuidelinePromptFromIsolatedStorage();
        Tool1NumberGuidelinesPrompt := Rec.GetTool1NumberGuidelinePromptFromIsolatedStorage();
        Tool1CustomPatternsPrompt := Rec.GetTool1CustomPatternsPromptFromIsolatedStorage();
        Tool1OutputExamplesPrompt := Rec.GetTool1OutputExamplesPromptFromIsolatedStorage();
        Tool1OutputFormatPrompt := Rec.GetTool1OutputExamplesPromptFromIsolatedStorage();
        Tool2Definition := Rec.GetTool2DefinitionFromIsolatedStorage();
        Tool2GeneralInstructionsPrompt := Rec.GetTool2GeneralInstructionsPromptFromIsolatedStorage();
        Tool2LimitationsPrompt := Rec.GetTool2LimitationsPromptFromIsolatedStorage();
        Tool2CodeGuidelinesPrompt := Rec.GetTool2CodeGuidelinePromptFromIsolatedStorage();
        Tool2DescriptionGuidelinesPrompt := Rec.GetTool2DescrGuidelinePromptFromIsolatedStorage();
        Tool2NumberGuidelinesPrompt := Rec.GetTool2NumberGuidelinePromptFromIsolatedStorage();
        Tool2CustomPatternsPrompt := Rec.GetTool2CustomPatternsPromptFromIsolatedStorage();
        Tool2OutputExamplesPrompt := Rec.GetTool2OutputExamplesPromptFromIsolatedStorage();
        Tool2OutputFormatPrompt := Rec.GetTool2OutputExamplesPromptFromIsolatedStorage();
    end;

}