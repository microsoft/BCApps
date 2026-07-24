// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Manufacturing.Wizard;

pageextension 137435 "Temp ProdOrdCompList Ext." extends "Temp Prod. Order Comp. List"
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
                end;
            }
        }
    }
}