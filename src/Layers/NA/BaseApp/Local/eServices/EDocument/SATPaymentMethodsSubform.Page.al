// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Bank.BankAccount;

page 27012 "SAT Payment Methods Subform"
{
    Caption = 'SAT Payment Methods Subform';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Payment Method";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the SAT payment method.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the SAT payment method.';
                }
                field("SAT Method of Payment"; Rec."SAT Method of Payment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the SAT payment method.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        CurrPage.Caption := '';
    end;
}

