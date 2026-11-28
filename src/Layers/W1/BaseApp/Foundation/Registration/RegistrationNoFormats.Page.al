// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Registration;

page 7402 "Registration No. Formats"
{
    ApplicationArea = Basic, Suite;
    AutoSplitKey = true;
    Caption = 'Registration No. Formats';
    DataCaptionFields = "Country/Region Code";
    PageType = List;
    SourceTable = "Registration No. Format";
    UsageCategory = Administration;
    AboutTitle = 'Define legal registration number formats';
    AboutText = 'Define one or more accepted formats per country or region. These rules check structure, not whether a number exists. Without a configured format, registration numbers are unrestricted up to 50 characters.';

    layout
    {
        area(content)
        {
            repeater(Formats)
            {
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                }
                field(Format; Rec.Format)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        RegistrationNoFeature: Codeunit "Registration No. Feature";
    begin
        RegistrationNoFeature.CheckEnabled();
    end;
}
