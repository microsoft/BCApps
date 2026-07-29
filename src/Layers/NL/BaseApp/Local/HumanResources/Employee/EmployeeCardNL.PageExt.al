// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Employee;

pageextension 11352 "Employee Card NL" extends "Employee Card"
{
    layout
    {
        addafter("Application Method")
        {
            field("Transaction Mode Code"; Rec."Transaction Mode Code")
            {
                ApplicationArea = BasicHR;
            }
        }
        addafter("Bank Account No.")
        {
            field("Bank Name"; Rec."Bank Name")
            {
                ApplicationArea = BasicHR;
            }
            field("Bank City"; Rec."Bank City")
            {
                ApplicationArea = BasicHR;
            }
        }
    }
}
