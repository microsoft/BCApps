// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Insurance;

using Microsoft.Foundation.AuditCodes;

pageextension 5636 InsSourceCodesExt extends "Source Codes"
{
    actions
    {
        addafter("G/L Registers")
        {
            action("I&nsurance Registers")
            {
                ApplicationArea = FixedAssets;
                Caption = 'I&nsurance Registers';
                Image = InsuranceRegisters;
                RunObject = Page "Insurance Registers";
                RunPageLink = "Source Code" = field(Code);
                RunPageView = sorting("Source Code");
                ToolTip = 'View posted insurance entries.';
            }
        }
    }
}
