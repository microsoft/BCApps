// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Apps.AppSource;
using System.Apps;

pageextension 2515 AppSourceExtensionManagement extends "Extension Management"
{
    actions
    {
        addafter("Refresh")
        {
            action("Microsoft AppSource Gallery")
            {
                ApplicationArea = All;
                Caption = 'AppSource Gallery';
                Enabled = IsSaas;
                Image = NewItem;
                ToolTip = 'Browse the Microsoft AppSource Gallery for new extensions to install.';
                Visible = IsOnPremDisplay;
                RunObject = Page "AppSource Product List";
                RunPageMode = View;
            }
        }

        addfirst(Promoted)
        {
            actionref("Microsoft AppSource Gallery_Promoted"; "Microsoft AppSource Gallery") { }
        }
    }

    var
        IsSaas: boolean;
        IsOnPremDisplay: boolean;

    trigger OnOpenPage()
    begin
        GetPageProperties();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        GetPageProperties();
    end;

    local procedure GetPageProperties()
    begin
        IsSaas := IsSaasEnvironment();
        IsOnPremDisplay := IsOnPremDisplayTarget();
    end;
}