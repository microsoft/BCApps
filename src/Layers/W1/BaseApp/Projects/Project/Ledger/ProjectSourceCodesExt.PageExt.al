// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Ledger;

using Microsoft.Foundation.AuditCodes;

pageextension 241 ProjectSourceCodesExt extends "Source Codes"
{
    actions
    {
        addafter("G/L Registers")
        {
            action("Job Registers")
            {
                ApplicationArea = Jobs;
                Caption = 'Project Registers';
                Image = JobRegisters;
                RunObject = Page "Job Registers";
                RunPageLink = "Source Code" = field(Code);
                RunPageView = sorting("Source Code");
                ToolTip = 'Open the related project registers.';
            }
        }
    }
}
