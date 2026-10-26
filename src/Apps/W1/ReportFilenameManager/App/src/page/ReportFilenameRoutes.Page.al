// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

page 8135 "Report Filename Routes"
{
    // Chooses the routes a pattern applies to. Modelled on Dimension Selection-Multiple: read back
    // when RunModal returns OK, as it does when the page is closed with Close. None ticked means
    // every route.

    Caption = 'Output Routes';
    PageType = Worksheet;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "Report Filename Route Buffer";
    SourceTableTemporary = true;
    // Print, Preview and Download first: the routes of the request page's Print, Preview and
    // Send to... buttons.
    SourceTableView = sorting("Display Order");
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Instruction)
            {
                ShowCaption = false;
                InstructionalText = 'Select the routes this pattern applies to. Select none to apply it to every route.';
            }
            repeater(Routes)
            {
                ShowCaption = false;
                field(Selected; Rec.Selected)
                {
                    ApplicationArea = All;
                }
                field("Output Route"; Rec."Output Route")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    /// <param name="SelectedRoutes">Enum ordinals; empty means every route.</param>
    internal procedure SetRoutes(SelectedRoutes: List of [Integer])
    begin
        Rec.FillRoutes(SelectedRoutes);
    end;

    /// <param name="TickedRoutes">Receives enum ordinals.</param>
    internal procedure GetRoutes(var TickedRoutes: List of [Integer])
    begin
        Rec.GetSelectedRoutes(TickedRoutes);
    end;
}
