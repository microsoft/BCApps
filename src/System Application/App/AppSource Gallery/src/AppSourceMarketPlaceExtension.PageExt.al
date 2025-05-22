// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEAN25
namespace System.Apps.AppSource;
using System.Apps;

#pragma warning disable AL0432
pageextension 2516 AppSourceMarketPlaceExtension extends "Extension Marketplace"
#pragma warning restore AL0432
{
    ObsoleteState = Pending;
    ObsoleteReason = 'This page will be obsoleted. Microsoft AppSource apps feature will replace the Extension Marketplace.';
    ObsoleteTag = '25.0';

    actions
    {
        addlast("Navigation")
        {
            action("Microsoft AppSource Gallery")
            {
                ApplicationArea = All;
                Caption = 'AppSource Gallery';
                Image = NewItem;
                ToolTip = 'Browse the Microsoft AppSource Gallery for new extensions to install.';
                RunObject = Page "AppSource Product List";
                RunPageMode = View;
                ObsoleteState = Pending;
                ObsoleteReason = 'This page will be obsoleted. Microsoft AppSource apps feature will replace the Extension Marketplace.';
                ObsoleteTag = '25.0';
            }
        }

        addfirst("Promoted")
        {
            actionref("Microsoft AppSource Gallery_Promoted"; "Microsoft AppSource Gallery") { }
        }

    }
}
#endif