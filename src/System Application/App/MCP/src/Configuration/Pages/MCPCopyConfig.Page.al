// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

page 8355 "MCP Copy Config"
{
    Caption = 'Copy Model Context Protocol (MCP) Server Configuration';
    PageType = StandardDialog;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(Control1)
            {
                ShowCaption = false;
                field(InstructionMessage; InstructionMessage)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    MultiLine = true;
                    Style = Attention;
                    Visible = InstructionMessage <> '';
                }
                field(ConfigName; ConfigName)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the new MCP configuration.';
                    Caption = 'New Configuration Name';
                }
                field(ConfigDescription; ConfigDescription)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the new MCP configuration.';
                    Caption = 'New Configuration Description';
                }
            }
        }
    }

    var
        ConfigName: Text[100];
        ConfigDescription: Text[250];
        InstructionMessage: Text;

    internal procedure GetConfigName(): Text[100]
    begin
        exit(ConfigName);
    end;

    internal procedure GetConfigDescription(): Text[250]
    begin
        exit(ConfigDescription);
    end;

    internal procedure SetConfigName(NewConfigName: Text[100])
    begin
        ConfigName := NewConfigName;
    end;

    internal procedure SetConfigDescription(NewConfigDescription: Text[250])
    begin
        ConfigDescription := NewConfigDescription;
    end;

    internal procedure SetInstructionMessage(NewInstructionMessage: Text)
    begin
        InstructionMessage := NewInstructionMessage;
    end;
}