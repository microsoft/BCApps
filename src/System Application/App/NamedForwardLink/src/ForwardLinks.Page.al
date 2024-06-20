// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities; // Todo Can we change this to System.Utilities?

using System.Utilities;

/// <summary>
/// The page displays the forward links. 
/// </summary>
page 1431 "Forward Links"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Forward Links';
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Named Forward Link";
    UsageCategory = Administration;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the link. The name should be meaningful and unique.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the target of the link.';
                }
                field(Link; Rec.Link)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the URL of the link.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Load)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Load';
                Image = Import;
                ToolTip = 'Fills the table with pre-defined links.';

                trigger OnAction()
                var
                    NamedForwardLink: Codeunit "Named Forward Link";
                begin
                    NamedForwardLink.OnLoadNamedForwardLinks();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Load_Promoted; Load)
                {
                }
            }
        }
    }
}

