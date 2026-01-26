// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Foundation.AuditCodes;

page 7000041 "Cartera Source Cd. Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Cartera Source Code Setup';
    PageType = Card;
    SourceTable = "Source Code Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Cartera Journal"; Rec."Cartera Journal")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source code related to the entries posted from the portfolio journal.';
                }
                field("Compress Bank Acc. Ledger"; Rec."Compress Bank Acc. Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted using the Date Compress Bank Acc. Ledger batch job.';
                }
                field("Compress Check Ledger"; Rec."Compress Check Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code linked to entries that are posted using the Delete Check Ledger Entries batch job.';
                }
            }
        }
    }

    actions
    {
    }
}

