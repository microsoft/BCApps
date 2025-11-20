// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

page 166 "Dispute Status"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Dispute Status';
    PageType = List;
    SourceTable = "Dispute Status";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Code; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Overwrite on hold"; Rec."Overwrite on hold")
                {
                    ApplicationArea = Basic, Suite;
                }
            }

        }
    }
}
