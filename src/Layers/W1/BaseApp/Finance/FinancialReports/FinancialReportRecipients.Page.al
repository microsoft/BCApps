// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

page 8361 "Financial Report Recipients"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Financial Report Recipients';
    DataCaptionFields = "Financial Report Name", "Financial Report Schedule Code";
    PageType = List;
    SourceTable = "Financial Report Recipient";

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Financial Report Name"; Rec."Financial Report Name")
                {
                    Visible = false;
                }
                field("Financial Report Schedule Code"; Rec."Financial Report Schedule Code")
                {
                    Visible = false;
                }
                field("User ID"; Rec."User ID")
                {
                    ShowMandatory = true;
                }
                field("User Full Name"; Rec."User Full Name")
                {
                }
            }
        }
    }
}