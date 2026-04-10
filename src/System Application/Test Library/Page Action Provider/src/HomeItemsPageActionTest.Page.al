// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Integration;

page 132617 "Home Items Page Action Test"
{
    Caption = 'Role Center';
    PageType = RoleCenter;

    actions
    {
        area(embedding)
        {
            action(PageWithViews)
            {
                ApplicationArea = All;
                Caption = 'Page with views';
                RunObject = page "Views Page Action Test";
                ToolTip = 'Test page with views';
            }
            action(EmptyPage)
            {
                ApplicationArea = All;
                Caption = 'Empty card page';
                RunObject = page "Empty Card Page Action Test";
                ToolTip = 'Test empty card page';
            }
        }
        area(Processing)
        {
            action(PageWithViewsInProcesing)
            {
                ApplicationArea = All;
                Caption = 'Page with views';
                RunObject = page "Views Page Action Test";
                ToolTip = 'Test page with views';
            }
        }
    }
}

