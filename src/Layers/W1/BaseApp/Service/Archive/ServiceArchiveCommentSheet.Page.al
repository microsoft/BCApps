// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Archive;

page 6266 "Service Archive Comment Sheet"
{
    Caption = 'Service Archive Comment Sheet';
    Editable = false;
    DeleteAllowed = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Service Comment Line Archive";

    layout
    {
        area(content)
        {
            repeater(Comments)
            {
                ShowCaption = false;
                field(Date; Rec."Comment Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the comment was entered.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies the service comment.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        CaptionString := CurrPage.Caption();
    end;

    var
        CaptionString: Text;

    procedure Caption(): Text
    var
        ServiceHeaderArchive: Record "Service Header Archive";
        ServiceItemLineArchive: Record "Service Item Line Archive";
        ServiceCommentLineArchive: Record "Service Comment Line Archive";
    begin
        if Rec.GetFilter("Table Name") <> '' then
            Evaluate(ServiceCommentLineArchive."Table Name", Rec.GetFilter("Table Name"));

        if Rec.GetFilter("Table Subtype") <> '' then
            Evaluate(ServiceCommentLineArchive."Table Subtype", Rec.GetFilter("Table Subtype"));

        if Rec.GetFilter("No.") <> '' then
            Evaluate(ServiceCommentLineArchive."No.", Rec.GetFilter("No."));

        if Rec.GetFilter(Type) <> '' then
            Evaluate(ServiceCommentLineArchive.Type, Rec.GetFilter(Type));

        if Rec.GetFilter("Table Line No.") <> '' then
            Evaluate(ServiceCommentLineArchive."Table Line No.", Rec.GetFilter("Table Line No."));

        if Rec.GetFilter("Doc. No. Occurrence") <> '' then
            Evaluate(ServiceCommentLineArchive."Doc. No. Occurrence", Rec.GetFilter("Doc. No. Occurrence"));

        if Rec.GetFilter("Version No.") <> '' then
            Evaluate(ServiceCommentLineArchive."Version No.", Rec.GetFilter("Version No."));

        if ServiceCommentLineArchive."Table Line No." > 0 then
            if ServiceItemLineArchive.Get(
                ServiceCommentLineArchive."Table Subtype", ServiceCommentLineArchive."No.", ServiceCommentLineArchive."Doc. No. Occurrence",
                ServiceCommentLineArchive."Version No.", ServiceCommentLineArchive."Table Line No.")
            then
                exit(
                  StrSubstNo('%1 %2 %3 - %4 ', ServiceItemLineArchive."Document Type", ServiceItemLineArchive."Document No.",
                    ServiceItemLineArchive.Description, ServiceCommentLineArchive.Type));

        if ServiceCommentLineArchive."Table Name" = ServiceCommentLineArchive."Table Name"::"Service Header" then
            if ServiceHeaderArchive.Get(
                ServiceCommentLineArchive."Table Subtype", ServiceCommentLineArchive."No.",
                ServiceCommentLineArchive."Doc. No. Occurrence", ServiceCommentLineArchive."Version No.")
            then
                exit(
                  StrSubstNo('%1 %2 %3 - %4 ', ServiceHeaderArchive."Document Type", ServiceHeaderArchive."No.",
                    ServiceHeaderArchive.Description, ServiceCommentLineArchive.Type));
    end;
}