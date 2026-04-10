// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using System.Globalization;

/// <summary>
/// Provides multilingual translation management for dimension names and captions.
/// Enables users to define dimension translations for different languages to support international business operations.
/// </summary>
/// <remarks>
/// Used for maintaining dimension translations across multiple languages for consistent reporting and user interface localization.
/// Integrates with the Language table to provide dimension names in the user's preferred language.
/// </remarks>
page 580 "Dimension Translations"
{
    Caption = 'Dimension Translations';
    DataCaptionFields = "Code";
    PageType = List;
    SourceTable = "Dimension Translation";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Language ID"; Rec."Language ID")
                {
                    ApplicationArea = Dimensions;
                    LookupPageID = "Windows Languages";
                }
                field("Language Name"; Rec."Language Name")
                {
                    ApplicationArea = Dimensions;
                    DrillDown = false;
                    Editable = false;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Dimensions;
                }
                field("Code Caption"; Rec."Code Caption")
                {
                    ApplicationArea = Dimensions;
                }
                field("Filter Caption"; Rec."Filter Caption")
                {
                    ApplicationArea = Dimensions;
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
    }
}

