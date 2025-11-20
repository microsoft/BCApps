// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment.Configuration;

using System.Reflection;
using System.Apps;

pageextension 2510 "Extension Subscribers" extends "Extension Management"
{
    actions
    {
        addafter("Deployment Status")
        {
            action("Event Subscribers")
            {
                Caption = 'Event Subscriptions';
                ToolTip = 'Show integration event subscriptions used by this extension.';
                ApplicationArea = All;
                Image = SetupList;
                RunObject = Page "Event Subscriptions";
                RunPageLink = "Originating Package ID" = field("Package ID");
            }
        }
    }
}
