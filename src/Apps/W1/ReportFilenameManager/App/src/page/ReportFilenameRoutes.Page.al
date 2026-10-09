// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
page 50120 "Report Filename Routes"
{
    // Chooses the routes a pattern applies to: a tick box per route, with what produces a file on
    // it. Built as Base Application's Dimension Selection-Multiple is - a worksheet over a
    // temporary buffer, opened modally, read back when RunModal returns OK, which closing it does
    // (Close and Esc alike, measured) - which 29 objects use to choose several
    // dimensions where a read-only field shows the choice (Close Income Statement among them).
    //
    // The line above the list says what ticking nothing means, as Cash Flow Forecast Entries and
    // Config. Package Import Preview put their note above theirs: a pattern limited to no route
    // would name nothing, so none ticked is every route.

    Caption = 'Output Routes';
    PageType = Worksheet;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "Report Filename Route Buffer";
    SourceTableTemporary = true;
    // Print, Preview and Download first: the three buttons of the window Print... opens.
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

    /// <summary>
    /// Fills the page with every route, ticked where the pattern already applies.
    /// </summary>
    /// <param name="SelectedRoutes">The pattern's routes, as enum ordinals; empty for every route.</param>
    internal procedure SetRoutes(SelectedRoutes: List of [Integer])
    begin
        Rec.FillRoutes(SelectedRoutes);
    end;

    /// <summary>
    /// The routes ticked when the page closed.
    /// </summary>
    /// <param name="TickedRoutes">Receives the routes, as enum ordinals.</param>
    internal procedure GetRoutes(var TickedRoutes: List of [Integer])
    begin
        Rec.GetSelectedRoutes(TickedRoutes);
    end;
}
