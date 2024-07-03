#if not CLEAN24
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Apps;

using System.Integration;

/// <summary>
/// Shows the Extension Marketplace.
/// </summary>
page 2502 "Extension Marketplace"
{
    Caption = 'Extension Marketplace';
    PageType = Card;
    ApplicationArea = All;
    Editable = false;
    ObsoleteState = Pending;
    ObsoleteReason = 'This page will be obsoleted. Microsoft AppSource apps feature will replace the Extension Marketplace.';
    ObsoleteTag = '24.0';

    layout
    {
        area(Content)
        {
            usercontrol(Marketplace; WebPageViewer)
            {
                ApplicationArea = Basic, Suite;
                Visible = false;
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action("Microsoft AppSource Gallery")
            {
                Caption = 'AppSource Gallery';
                Image = NewItem;
                ToolTip = 'Browse the Microsoft AppSource Gallery for new extensions to install.';
                RunObject = Page 2515;
                RunPageMode = View;
            }
        }
        area(Promoted)
        {
            actionref("Microsoft AppSource Gallery_Promoted"; "Microsoft AppSource Gallery")
            {
            }
        }
    }

    procedure SetSearchText(Text: Text)
    begin
    end;

    internal procedure SetAppsourceUrl(Url: Text)
    begin
    end;
}
#endif
