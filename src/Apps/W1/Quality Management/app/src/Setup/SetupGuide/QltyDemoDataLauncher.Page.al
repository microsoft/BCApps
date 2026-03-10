// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Setup;

/// <summary>
/// Minimal launcher page that delegates to codeunit. Required by Guided Experience.
/// </summary>
page 20422 "Qlty. Demo Data Launcher"
{
    Caption = 'Quality Management Demo Data';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {

        }
    }

    trigger OnInit()
    var
        QltyDemoDataMgmt: Codeunit "Qlty. Demo Data Mgmt.";
    begin
        // Launch immediately before page renders
        QltyDemoDataMgmt.LaunchDemoData();
        CurrPage.Close();
    end;
}
