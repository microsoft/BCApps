// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.SpendRequest;

page 7136 "Travel Request List"
{
    Caption = 'Travel Requests';
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;
    SourceTable = "Spend Request";
    SourceTableView = where("Document Type" = const("Travel Request"));
    CardPageId = "Travel Request Card";
    Editable = false;
    RefreshOnActivate = true;

    AboutTitle = 'About travel requests';
    AboutText = 'A travel request captures the intent to travel, its purpose, expected cost, and travelers, so it can be reviewed and approved before any expense is incurred.';
    AdditionalSearchTerms = 'Travel Requisition, Trip Request, Travel Authorization';

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies the number of the travel request.';
                }
                field("Requested For"; Rec."Requested For")
                {
                    ToolTip = 'Specifies the expense user for whom the travel request is being created.';
                }
                field(Purpose; Rec.Purpose)
                {
                    ToolTip = 'Specifies the purpose of the travel request.';
                }
                field(Status; Rec.Status)
                {
                    ToolTip = 'Specifies the status of the travel request.';
                }
                field("Total Expected Amount (LCY)"; Rec."Total Expected Amount (LCY)")
                {
                    ToolTip = 'Specifies the total expected amount of the travel request in local currency.';
                }
                field("Expected Start Date"; Rec."Expected Start Date")
                {
                    ToolTip = 'Specifies the expected start date of the travel.';
                }
                field("Expected End Date"; Rec."Expected End Date")
                {
                    ToolTip = 'Specifies the expected end date of the travel.';
                }
            }
        }
    }
    actions
    {
        area(Navigation)
        {
            action(Travelers)
            {
                Image = Travel;
                Caption = 'Travelers';
                ToolTip = 'View the travelers associated with this travel request.';
                ApplicationArea = Basic, Suite;
                RunObject = page "Travelers";
                RunPageLink = "Spend Request No." = field("No.");
            }
        }
        area(Promoted)
        {
            group(Category_TravelRequest)
            {
                Caption = 'Travel Request';

                actionref(Travelers_Promoted; Travelers)
                {
                }
            }
        }
    }
}
