// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Ledger;

using Microsoft.Foundation.AuditCodes;

pageextension 240 ResSourceCodesExt extends "Source Codes"
{
    actions
    {
        addafter("G/L Registers")

        {
            action("Resource Registers")
            {
                ApplicationArea = Jobs;
                Caption = 'Resource Registers';
                Image = ResourceRegisters;
                RunObject = Page "Resource Registers";
                RunPageLink = "Source Code" = field(Code);
                RunPageView = sorting("Source Code");
                ToolTip = 'View a list of all the resource registers. Every time a resource entry is posted, a register is created. Every register shows the first and last entry numbers of its entries. You can use the information in a resource register to document when entries were posted.';
            }
        }
    }
}
