// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Registration;

page 7404 "Registration No. Migration"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Registration No. Migration';
    PageType = List;
    SourceTable = "Registration No. Migration";
    UsageCategory = Administration;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                field("Record Type"; Rec."Record Type")
                {
                }
                field("Record ID"; Rec."Record ID")
                {
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                }
                field("Local Registration No."; Rec."Local Registration No.")
                {
                }
                field("Registration Number"; Rec."Registration Number")
                {
                }
                field(Resolution; Rec.Resolution)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        RegistrationNoFeature: Codeunit "Registration No. Feature";
    begin
        RegistrationNoFeature.RefreshMigration();
    end;
}
