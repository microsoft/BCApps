// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

/// <summary>
/// Subform page for displaying and managing business unit setup configurations within parent pages.
/// Provides list part functionality for business unit consolidation parameter management.
/// </summary>
/// <remarks>
/// List part page integrated into business unit setup workflows for configuration management.
/// Displays business unit setup records with read-only access for consolidation parameter review.
/// Used within larger business unit management interfaces for consolidated setup information display.
/// </remarks>
page 1827 "Business Units Setup Subform"
{
    Caption = 'Business Units Setup Subform';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Business Unit Setup";
    SourceTableTemporary = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Include; Rec.Include)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        CurrPage.Caption := '';
    end;
}

