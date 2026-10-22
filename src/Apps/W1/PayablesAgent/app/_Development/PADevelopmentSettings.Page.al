#if DEVELOPMENT
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

page 3314 "PA Development Settings"
{
    Caption = 'Payables Agent Development Settings';
    PageType = Card;
    SourceTable = "PA Development Settings";
    ApplicationArea = All;
    UsageCategory = Administration;
    AdditionalSearchTerms = 'Payables Agent developer,V2,simulate agent';
    InsertAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Enable V2"; Rec."Enable V2")
                {
                    ApplicationArea = All;
                }
                field("Simulate Agent Experience"; Rec."Simulate Agent Experience")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        DevelopmentSettings: Codeunit "PA Development Settings";
    begin
        DevelopmentSettings.GetSettings(Rec);
    end;
}
#endif
