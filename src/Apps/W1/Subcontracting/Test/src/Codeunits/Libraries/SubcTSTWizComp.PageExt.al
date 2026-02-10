// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Manufacturing.Subcontracting;

pageextension 139981 "Subc. TST WizComp" extends "Subc. Temp Prod Order Comp"
{
    actions
    {
        addlast(Processing)
        {
            action("Sub Delete")
            {
                ApplicationArea = All;
                Caption = 'Delete';
                Image = Delete;
                ToolTip = 'Delete the current record.';
                trigger OnAction()
                begin
                    Rec.Delete(true);
                    LinesChanged := true;
                end;
            }
        }
    }
}