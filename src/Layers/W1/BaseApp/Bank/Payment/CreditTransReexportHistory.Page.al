// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

/// <summary>
/// Page 1209 "Credit Trans Re-export History" displays the history of credit transfer re-export operations.
/// This page shows when payment files were re-exported and by which users, providing an audit trail for payment processing.
/// </summary>
/// <remarks>
/// Source table: Credit Trans Re-export History. Used for tracking payment file
/// re-export activities to maintain compliance and audit requirements.
/// </remarks>
page 1209 "Credit Trans Re-export History"
{
    Caption = 'Credit Trans Re-export History';
    Editable = false;
    PageType = List;
    SourceTable = "Credit Trans Re-export History";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Re-export Date"; Rec."Re-export Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the payment file was re-exported.';
                }
                field("Re-exported By"; Rec."Re-exported By")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user who re-exported the payment file.';
                }
            }
        }
    }

    actions
    {
    }
}

