// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

page 8374 "Fin. Report Package Recipients"
{
    AnalysisModeEnabled = false;
    ApplicationArea = Basic, Suite;
    Caption = 'Financial Report Package Recipients';
    DataCaptionFields = "Package Code", "Schedule Code";
    PageType = List;
    SourceTable = "Fin. Report Package Recipient";
    UsageCategory = None;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Code; Rec."Package Code")
                {
                    Visible = false;
                }
                field("User ID"; Rec."User ID")
                {
                    ShowMandatory = true;
                }
                field("User Full Name"; Rec."User Full Name") { }
                field("User Email"; Rec."User Email") { }
            }
        }
    }
}