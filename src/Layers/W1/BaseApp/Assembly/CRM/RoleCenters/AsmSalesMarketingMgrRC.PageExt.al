// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.RoleCenters;

using Microsoft.Assembly.Reports;

pageextension 930 "Asm. Sales Marketing Mgr. RC" extends "Sales & Marketing Manager RC"
{
    actions
    {
        addafter("Item Substitutions")
        {
            action("Assemble to Order - Sales")
            {
                ApplicationArea = Assembly;
                Caption = 'Assemble to Order - Sales';
                RunObject = report "Assemble to Order - Sales";
            }
        }
    }
}