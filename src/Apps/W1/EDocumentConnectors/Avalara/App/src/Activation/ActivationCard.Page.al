// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

/// <summary>
/// Card page displaying the details of an Avalara activation record and its associated mandates.
/// </summary>
page 6377 "Activation Card"
{
    ApplicationArea = All;
    Caption = 'Activation Details';
    Editable = false;
    PageType = Card;
    SourceTable = "Activation Header";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(ID; Rec.ID)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the the Activation ID field';
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Company Name field.';
                }
                field(Jurisdiction; Rec.Jurisdiction)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Jurisdiction field.';
                }
                field("Scheme Id"; Rec."Scheme Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Scheme Id field.';
                }
                field(Identifier; Rec.Identifier)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Identifier field.';
                }
                field("Full Authority Value"; Rec."Full Authority Value")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Full Authority Value field.';
                }
                field("Status Code"; Rec."Status Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Status Code field.';
                }
                field("Status Message"; Rec."Status Message")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Specifies the value of the Status Message field.';
                }
                field("Last Modified"; Rec."Last Modified")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Last Modified field.';
                }
                field("Meta Location"; Rec."Meta Location")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Meta Location field.';
                }
                field("Company Id"; Rec."Company Id")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Company Id field.';
                }
                field("Company Location"; Rec."Company Location")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Company Location field.';
                }
            }
            part(Mandates; "Activation Subform")
            {
                ApplicationArea = All;
                SubPageLink = "Activation ID" = field(ID);
            }
        }
    }
}