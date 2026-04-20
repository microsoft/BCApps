// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.Reflection;

/// <summary>
/// Simple single-column lookup that lets a user pick a page. Displays entries in the format
/// "Company Information (Card page, id 1)". Backed by a temporary buffer so the list is
/// searchable and sorted by default.
/// </summary>
page 8431 "Perf. Analysis Page Lookup"
{
    Caption = 'Pages';
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Perf. Analysis Page Buf";
    SourceTableTemporary = true;
    SourceTableView = sorting(Display);
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    LinksAllowed = false;
    Permissions = tabledata AllObjWithCaption = r,
                  tabledata "Page Metadata" = r;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Display; Rec.Display)
                {
                    Caption = 'Page';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the page caption, its page type, and its id.';
                }
            }
        }
    }

    var
        DisplayFmtLbl: Label '%1 (%2 page on %3, id %4)', Comment = '%1 = page caption, %2 = page type (Card, List, ...), %3 = source table caption, %4 = page id';
        DisplayNoSourceFmtLbl: Label '%1 (%2 page, id %3)', Comment = '%1 = page caption, %2 = page type, %3 = page id';

    trigger OnOpenPage()
    begin
        LoadPages();
    end;

    local procedure LoadPages()
    var
        PageMetadata: Record "Page Metadata";
        AllObjWithCaption: Record AllObjWithCaption;
        Caption: Text[250];
        SourceTableCaption: Text[250];
    begin
        Rec.Reset();
        Rec.DeleteAll();
        PageMetadata.SetFilter(PageType, '<>%1&<>%2', PageMetadata.PageType::API, PageMetadata.PageType::NavigatePage);
        if not PageMetadata.FindSet() then
            exit;
        repeat
            Caption := '';
            if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Page, PageMetadata.ID) then
                Caption := CopyStr(AllObjWithCaption."Object Caption", 1, MaxStrLen(Caption));
            if Caption = '' then
                Caption := PageMetadata.Name;
            SourceTableCaption := '';
            if PageMetadata.SourceTable <> 0 then
                if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, PageMetadata.SourceTable) then
                    SourceTableCaption := CopyStr(AllObjWithCaption."Object Caption", 1, MaxStrLen(SourceTableCaption));
            Rec.Init();
            Rec."Page Id" := PageMetadata.ID;
            Rec.Name := PageMetadata.Name;
            Rec."Page Type" := CopyStr(Format(PageMetadata.PageType), 1, MaxStrLen(Rec."Page Type"));
            if SourceTableCaption <> '' then
                Rec.Display := CopyStr(StrSubstNo(DisplayFmtLbl, Caption, Rec."Page Type", SourceTableCaption, PageMetadata.ID), 1, MaxStrLen(Rec.Display))
            else
                Rec.Display := CopyStr(StrSubstNo(DisplayNoSourceFmtLbl, Caption, Rec."Page Type", PageMetadata.ID), 1, MaxStrLen(Rec.Display));
            if Rec.Insert() then;
        until PageMetadata.Next() = 0;
        Rec.SetCurrentKey(Display);
        if Rec.FindFirst() then;
    end;
}
