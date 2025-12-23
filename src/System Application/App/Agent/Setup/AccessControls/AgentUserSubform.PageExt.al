#if not CLEAN28
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Security.AccessControl;
using System.Security.User;

pageextension 4318 "Agent User Subform" extends "User Subform"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'The Agent User Subform page extension is obsolete. Use the View Agent Access Control page instead.';
    ObsoleteTag = '28.0';

    layout
    {
        modify(Company)
        {
            Visible = (not IsAgent) or ShowCompanyField;
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(AgentShowHideCompany)
            {
                ApplicationArea = All;
                Caption = 'Show/hide company';
                Enabled = IsAgent;
                Image = CompanyInformation;
                ToolTip = 'Show or hide the company name.';
                Visible = IsAgent;

                ObsoleteState = Pending;
                ObsoleteReason = 'The Agent User Subform page extension is obsolete. Use the View Agent Access Control page instead.';
                ObsoleteTag = '28.0';

                trigger OnAction()
                begin
                    ShowCompanyField := not ShowCompanyField;
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        User: Record User;
    begin
        if User.Get(Rec."User Security ID") then
            IsAgent := User."License Type" = User."License Type"::Agent
        else
            IsAgent := false;
    end;

    var
        IsAgent: Boolean;
        ShowCompanyField: Boolean;
}
#endif