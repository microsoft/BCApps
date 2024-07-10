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

            group(Tools)
            {
                group(ToolsGeneral)
                {
                    ShowCaption = false;

                    field(ToolsSelectionPrompt; ToolsSelectionPrompt)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Tools Selection Prompt';
                        Editable = false;
                        NotBlank = true;
                        ShowMandatory = true;
                        ExtendedDatatype = Masked;
                        MultiLine = true;
                        ToolTip = 'Specifies the value of the Tools Selection System Prompt field.';
                        trigger OnAssistEdit()
                        begin
                            Rec.ImportFromTextFile(ToolsSelectionPrompt);
                            Rec.SetToolsSelectionPromptToIsolatedStorage(ToolsSelectionPrompt);
                        end;
                    }
                }
                group(Tool1)
                {
                    field(Tool1Prompt; Tool1Prompt)
                    {
                        ApplicationArea = All;
                        Caption = 'Tool 1 Prompt';
                        Editable = false;
                        NotBlank = true;
                        ShowMandatory = true;
                        ExtendedDatatype = Masked;
                        MultiLine = true;
                        ToolTip = 'Specifies the value of the Tool 1 Prompt field.';
                        trigger OnAssistEdit()
                        begin
                            Rec.ImportFromTextFile(Tool1Prompt);
                            Rec.SetTool1PromptToIsolatedStorage(Tool1Prompt);
                        end;
                    }

                    field(Tool1Definition; Tool1Definition)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Tool 1 Definition';
                        Editable = false;
                        NotBlank = true;
                        ShowMandatory = true;
                        ExtendedDatatype = Masked;
                        MultiLine = true;
                        ToolTip = 'Specifies the value of the Tool 1 Definition field.';
                        trigger OnAssistEdit()
                        begin
                            Rec.ImportFromTextFile(Tool1Definition);
                            Rec.SetTool1DefinitionToIsolatedStorage(Tool1Definition);
                        end;
                    }
                }
                group(Tool2)
                {
                    field(Tool2Prompt; Tool2Prompt)
                    {
                        ApplicationArea = All;
                        Caption = 'Tool 2 Prompt';
                        Editable = false;
                        NotBlank = true;
                        ShowMandatory = true;
                        ExtendedDatatype = Masked;
                        MultiLine = true;
                        ToolTip = 'Specifies the value of the Tool 2 Prompt field.';
                        trigger OnAssistEdit()
                        begin
                            Rec.ImportFromTextFile(Tool2Prompt);
                            Rec.SetTool2PromptToIsolatedStorage(Tool2Prompt);
                        end;
                    }

                    field(Tool2Definition; Tool2Definition)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Tool 2 Definition';
                        Editable = false;
                        NotBlank = true;
                        ShowMandatory = true;
                        ExtendedDatatype = Masked;
                        MultiLine = true;
                        ToolTip = 'Specifies the value of the Tool 2 Definition field.';
                        trigger OnAssistEdit()
                        begin
                            Rec.ImportFromTextFile(Tool2Definition);
                            Rec.SetTool2DefinitionToIsolatedStorage(Tool2Definition);
                        end;
                    }
                }
                group(Tool3)
                {
                    field(Tool3Definition; Tool3Definition)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Tool 3 Definition';
                        Editable = false;
                        NotBlank = true;
                        ShowMandatory = true;
                        ExtendedDatatype = Masked;
                        MultiLine = true;
                        ToolTip = 'Specifies the value of the Tool 3 Definition field.';
                        trigger OnAssistEdit()
                        begin
                            Rec.ImportFromTextFile(Tool3Definition);
                            Rec.SetTool3DefinitionToIsolatedStorage(Tool3Definition);
                        end;
                    }
                }
                group(Tool4)
                {
                    field(Tool4Definition; Tool4Definition)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Tool 4 Definition';
                        Editable = false;
                        NotBlank = true;
                        ShowMandatory = true;
                        ExtendedDatatype = Masked;
                        MultiLine = true;
                        ToolTip = 'Specifies the value of the Tool 4 Definition field.';
                        trigger OnAssistEdit()
                        begin
                            Rec.ImportFromTextFile(Tool4Definition);
                            Rec.SetTool4DefinitionToIsolatedStorage(Tool4Definition);
                        end;
                    }
                }
            }
        }
    }

    var
        [NonDebuggable]
        SecretKey: Text;
        ToolsSelectionPrompt: Text;
        Tool1Prompt: Text;
        Tool1Definition: Text;
        Tool2Prompt: Text;
        Tool2Definition: Text;
        Tool3Definition: Text;
        Tool4Definition: Text;

    trigger OnOpenPage()
    begin
        if not Rec.Get() then
            Rec.Insert();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SecretKey := Rec.GetSecretKeyFromIsolatedStorage();
        ToolsSelectionPrompt := Rec.GetToolsSelectionPromptFromIsolatedStorage();
        Tool1Prompt := Rec.GetTool1PromptFromIsolatedStorage();
        Tool1Definition := Rec.GetTool1DefinitionFromIsolatedStorage();
        Tool2Prompt := Rec.GetTool2PromptFromIsolatedStorage();
        Tool2Definition := Rec.GetTool2DefinitionFromIsolatedStorage();
        Tool3Definition := Rec.GetTool3DefinitionFromIsolatedStorage();
        Tool4Definition := Rec.GetTool4DefinitionFromIsolatedStorage();
    end;

}