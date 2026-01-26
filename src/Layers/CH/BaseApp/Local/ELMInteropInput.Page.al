// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

page 35563 "ELM Interop Input"
{
    Caption = 'Microsoft Dynamics NAV';
    PageType = Card;

    layout
    {
        area(content)
        {
            field(Operand; Operand)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Please type a value for the interoperability check';
            }
        }
    }

    actions
    {
    }

    var
        Operand: Decimal;

    [Scope('OnPrem')]
    procedure SetOperand(Op: Decimal)
    begin
        Operand := Op;
    end;

    [Scope('OnPrem')]
    procedure GetOperand(): Decimal
    begin
        exit(Operand);
    end;
}

