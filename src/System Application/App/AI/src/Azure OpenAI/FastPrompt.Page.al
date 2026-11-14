// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

/// <summary>
/// Page for resolving a fast prompt by its ECS key.
/// </summary>
page 7776 "Fast Prompt"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(Request)
            {
                field(ECSKey; ECSKey)
                {
                    ApplicationArea = All;
                    Caption = 'ECS key';
                    ToolTip = 'Specifies the ECS key used to resolve the fast prompt.';
                }
            }
            group(Response)
            {
                field(IsFastPrompt; IsFastPrompt)
                {
                    ApplicationArea = All;
                    Caption = 'Fast prompt resolved';
                    Editable = false;
                    ToolTip = 'Specifies whether the ECS key resolved to a fast prompt.';
                }
                field(Template; Template)
                {
                    ApplicationArea = All;
                    Caption = 'Template';
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'Specifies the resolved fast prompt template.';
                }
                field(ErrorCode; ErrorCode)
                {
                    ApplicationArea = All;
                    Caption = 'Error code';
                    Editable = false;
                    ToolTip = 'Specifies the error code returned while resolving the fast prompt.';
                }
                field(ErrorMessage; ErrorMessage)
                {
                    ApplicationArea = All;
                    Caption = 'Error message';
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'Specifies the error message returned while resolving the fast prompt.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(GetFastPrompt)
            {
                ApplicationArea = All;
                Caption = 'Get Fast Prompt';
                Image = GetLines;
                ToolTip = 'Resolves the fast prompt for the specified ECS key.';

                trigger OnAction()
                begin
                    ResolveFastPrompt();
                end;
            }
        }
    }

    var
        ECSKey: Text[250];
        IsFastPrompt: Boolean;
        Template: Text;
        ErrorCode: Text;
        ErrorMessage: Text;

    [NonDebuggable]
    local procedure ResolveFastPrompt()
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
        FastPromptResponse: Codeunit "AOAI Fast Prompt Response";
    begin
        Clear(Template);
        Clear(ErrorCode);
        Clear(ErrorMessage);
        IsFastPrompt := AzureOpenAI.GetFastPrompt(ECSKey, FastPromptResponse);
        Template := FastPromptResponse.GetTemplate().Unwrap();
        ErrorCode := FastPromptResponse.GetErrorCode();
        ErrorMessage := FastPromptResponse.GetErrorMessage();
    end;
}