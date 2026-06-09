// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

/// <summary>
/// Subform page displaying the mandates associated with an Avalara activation record.
/// </summary>
page 6375 "Activation Subform"
{
    ApplicationArea = All;
    Caption = 'Mandates';
    PageType = ListPart;
    SourceTable = "Activation Mandate";
    SourceTableTemporary = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Country Mandate"; Rec."Country Mandate")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Country Mandate field.';
                }
                field("Country Code"; Rec."Country Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Country Code field.';
                }
                field("Mandate Type"; Rec."Mandate Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Mandate Type field.';
                }
                field("Company ID"; Rec."Company Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Company Id field.';
                }
                field(Activated; Rec.Activated)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Activated field.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Blocked field.';
                }
            }
        }
    }
}