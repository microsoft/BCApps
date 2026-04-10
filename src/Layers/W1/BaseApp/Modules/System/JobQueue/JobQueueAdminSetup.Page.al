// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Threading;

page 1182 "Job Queue Admin Setup"
{
    PageType = ListPart;
    SourceTable = "Job Queue Notified Admin";
    Caption = 'Job Queue Admin List';
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(User; Rec."User Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'The User Name of the Job Queue Admin';
                }
            }
        }
    }
}