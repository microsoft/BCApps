// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

table 8131 "Report Filename Route Buffer"
{
    // One row per route for choosing a pattern's Output Route Filter, like Dimension Selection Buffer.

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
        // Each describes the action or setting that produces the file.
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
    /// Any is left out: it means the platform did not say which route, not a route to limit to.
    /// </summary>
    /// <param name="SelectedRoutes">Enum ordinals of the routes to tick.</param>
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
    /// Enum order, except Download follows Preview, so the routes of the request page's Print,
    /// Preview and Send to... buttons are listed together.
    /// </summary>
    local procedure RouteDisplayOrder(Route: Enum "Report Filename Output Route"): Integer
    begin
        if Route = Route::Download then
            exit(Enum::"Report Filename Output Route"::Preview.AsInteger() * 10 + 5);
        exit(Route.AsInteger() * 10);
    end;

    /// <param name="Routes">Receives enum ordinals, in enum order.</param>
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

    /// <returns>Blank for a route added by another extension.</returns>
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
