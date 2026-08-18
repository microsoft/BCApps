// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.Wizard;

pageextension 139982 "Subc. TST WizProdRtng" extends "Temp Prod. Ord. Rtng List"
{
    actions
    {
        addlast(processing)
        {
            action(TestDelete)
            {
                ApplicationArea = All;
                Caption = 'Test Delete';

                trigger OnAction()
                begin
                    Rec.Delete(true);
                    Rec.CheckPreviousAndNextForTemp();
                end;
            }
        }
    }
}