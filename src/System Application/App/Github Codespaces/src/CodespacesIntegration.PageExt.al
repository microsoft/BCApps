// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration.Codespaces;

using System.Apps;

pageextension 8430 "Codespaces Integration" extends "Extension Management"
{
    actions
    {
        // Add changes to page actions here
        addafter("Open Source in VS Code")
        {
            group(Codespaces2)
            {
                Caption = 'GitHub Codespaces';

                action("Launch in Codespaces")
                {
                    ApplicationArea = All;
                    Caption = 'Open in Codespaces 2';
                    ToolTip = 'Open this extension in GitHub Codespaces 2.';
                    Promoted = true;
                    PromotedCategory = Category18;
                    PromotedIsBig = true;
                    Image = Cloud;
                    Visible = true;
                    Scope = Repeater;
                    RunObject = page "Codespaces Config. Wizard";
                }
            }
        }

    }
}