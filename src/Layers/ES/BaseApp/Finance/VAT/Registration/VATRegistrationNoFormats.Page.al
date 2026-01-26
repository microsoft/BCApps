// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

using Microsoft.Finance.VAT.Reporting;

/// <summary>
/// List page for managing VAT registration number format rules by country/region.
/// Provides interface for defining and maintaining country-specific VAT number validation patterns.
/// </summary>
page 575 "VAT Registration No. Formats"
{
    AutoSplitKey = true;
    Caption = 'VAT Registration No. Formats';
    DataCaptionFields = "Country/Region Code";
    PageType = List;
    SourceTable = "VAT Registration No. Format";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(Format; Rec.Format)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Check VAT Registration No."; Rec."Check VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Test VAT Registration Number")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test VAT Registration Number';
                    Image = SuggestNumber;
                    RunObject = Report "Test VAT Registration Number";
                    ToolTip = 'View the company VAT registration numbers for customers, vendors, and company contacts. VAT registration numbers consist of 15 alphanumeric characters. The first two characters indicate the country/region where the business is registered. For example, ES indicates Spain.';
                }
            }
        }
    }
}

