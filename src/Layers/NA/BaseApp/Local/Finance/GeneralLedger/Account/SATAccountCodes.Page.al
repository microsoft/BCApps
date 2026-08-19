// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

page 27001 "SAT Account Codes"
{
    Caption = 'SAT Account Codes';
    PageType = List;
    SourceTable = "SAT Account Code";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the SAT account.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies a description of the SAT account.';
                }
            }
        }
    }

    actions
    {
    }
}

