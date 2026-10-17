// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
table 50116 "Report Filename Route Buffer"
{
    // The routes a pattern's Output Route Filter is chosen from, one row per route with a tick
    // box, the way Base Application's Dimension Selection Buffer offers dimensions. Never stored:
    // the routes are filled in, ticked and read back in memory.
    //
    // It replaced a filter page, which offered the table's system fields - Created At, Row Version
    // and the rest - beside the one field that meant anything, and asked for a filter expression
    // where a choice from a handful of fixed routes was all there was to make.

    Caption = 'Report Filename Route Buffer';
    TableType = Temporary;
    Access = Internal;
    Extensible = false;

    fields
    {
        field(1; "Output Route"; Enum "Report Filename Output Route")
        {
            Caption = 'Output Route';
            ToolTip = 'Specifies a way out of Business Central that a pattern can be limited to.';
        }
        field(2; Selected; Boolean)
        {
            Caption = 'Selected';
            ToolTip = 'Specifies that the pattern applies to this route. Select none to apply the pattern to every route.';
        }
        field(3; Description; Text[250])
        {
            Caption = 'Description';
            ToolTip = 'Specifies what in Business Central produces a file on this route.';
        }
        field(4; "Display Order"; Integer)
        {
            Caption = 'Display Order';
            ToolTip = 'Specifies where the route is listed.';
        }
    }

    keys
    {
        key(PK; "Output Route")
        {
            Clustered = true;
        }
        key(Display; "Display Order")
        {
        }
    }

    var
        // One rule for every row, agreed with the user on 7 October, night: the action that makes
        // the file, in Business Central's own words, in one sentence that reads on its own.
        PrintDescriptionLbl: Label 'Print... then Print.';
        PreviewDescriptionLbl: Label 'Print... then Preview: the file downloaded from the preview.';
        SaveDescriptionLbl: Label 'A file saved without being shown, such as by a job queue entry or an extension.';
        DownloadDescriptionLbl: Label 'Print... then Send to....';
        EmailDescriptionLbl: Label 'A document sent by email.';
        AttachAsPdfDescriptionLbl: Label 'The Attach as PDF action on a document.';
        ScheduledDescriptionLbl: Label 'A report scheduled to run, saved in the Report Inbox.';
        DiskDescriptionLbl: Label 'Send with a document sending profile whose Disk is PDF.';
        PdfAndElectronicDocumentDescriptionLbl: Label 'Send with a document sending profile whose Disk or Email Attachment is PDF & Electronic Document: the PDF in the zip.';
        ElectronicDocumentDescriptionLbl: Label 'Send with a document sending profile whose Disk or Email Attachment includes Electronic Document: the XML and its zip.';

    /// <summary>
    /// One row for every route a pattern can be limited to, ticked where the pattern already is.
    /// Any is left out: it is what a delivery is when the platform does not say which route it
    /// took, not a route a pattern is limited to.
    /// </summary>
    /// <param name="SelectedRoutes">The routes to tick, as enum ordinals.</param>
    internal procedure FillRoutes(SelectedRoutes: List of [Integer])
    var
        Ordinal: Integer;
    begin
        Rec.Reset();
        Rec.DeleteAll();
        foreach Ordinal in Enum::"Report Filename Output Route".Ordinals() do
            if Ordinal <> Enum::"Report Filename Output Route"::Any.AsInteger() then begin
                Rec.Init();
                Rec."Output Route" := Enum::"Report Filename Output Route".FromInteger(Ordinal);
                Rec.Selected := SelectedRoutes.Contains(Ordinal);
                Rec.Description := RouteDescription(Rec."Output Route");
                Rec."Display Order" := RouteDisplayOrder(Rec."Output Route");
                Rec.Insert();
            end;
        Rec.SetCurrentKey("Display Order");
        if Rec.FindFirst() then;
    end;

    /// <summary>
    /// Where a route is listed: in the enum's order, except that Download follows Preview, so the
    /// three buttons of the window Print... opens - Print, Preview and Send to... - are listed
    /// together. Raised by the user on 7 October, night: Save sat between them.
    /// </summary>
    /// <param name="Route">The route.</param>
    /// <returns>The position to sort by.</returns>
    local procedure RouteDisplayOrder(Route: Enum "Report Filename Output Route"): Integer
    begin
        if Route = Route::Download then
            exit(Enum::"Report Filename Output Route"::Preview.AsInteger() * 10 + 5);
        exit(Route.AsInteger() * 10);
    end;

    /// <summary>
    /// The ticked routes, in the enum's order.
    /// </summary>
    /// <param name="Routes">Receives the routes, as enum ordinals.</param>
    internal procedure GetSelectedRoutes(var Routes: List of [Integer])
    var
        TempRouteBuffer: Record "Report Filename Route Buffer" temporary;
    begin
        Clear(Routes);
        TempRouteBuffer.Copy(Rec, true);
        TempRouteBuffer.Reset();
        TempRouteBuffer.SetRange(Selected, true);
        if TempRouteBuffer.FindSet() then
            repeat
                Routes.Add(TempRouteBuffer."Output Route".AsInteger());
            until TempRouteBuffer.Next() = 0;
    end;

    /// <summary>
    /// What produces a file on a route, in the words of the buttons that do it - several captions
    /// read as synonyms on their own, Save, Download and Disk above all. A route another extension
    /// adds has no description here.
    /// </summary>
    /// <param name="Route">The route.</param>
    /// <returns>The description; blank for a route this app does not know.</returns>
    local procedure RouteDescription(Route: Enum "Report Filename Output Route"): Text[250]
    begin
        case Route of
            Route::Print:
                exit(PrintDescriptionLbl);
            Route::Preview:
                exit(PreviewDescriptionLbl);
            Route::Save:
                exit(SaveDescriptionLbl);
            Route::Download:
                exit(DownloadDescriptionLbl);
            Route::Email:
                exit(EmailDescriptionLbl);
            Route::AttachAsPdf:
                exit(AttachAsPdfDescriptionLbl);
            Route::Scheduled:
                exit(ScheduledDescriptionLbl);
            Route::Disk:
                exit(DiskDescriptionLbl);
            Route::PdfAndElectronicDocument:
                exit(PdfAndElectronicDocumentDescriptionLbl);
            Route::ElectronicDocument:
                exit(ElectronicDocumentDescriptionLbl);
        end;
        exit('');
    end;
}
