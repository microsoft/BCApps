// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7229 "EACorpCardJQSchedule"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Corp Card Import Schedule';
    PageType = ListPlus;
    SourceTable = EACorpCardProvider;

    layout
    {
        area(Content)
        {
            part(Schedule; EACorpCardJQScheduleSubpage)
            {
                ApplicationArea = Basic, Suite;
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RefreshSchedule)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Refresh Schedule';
                Image = Refresh;
                ToolTip = 'Refresh Job Queue status from system.';

                trigger OnAction()
                begin
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
