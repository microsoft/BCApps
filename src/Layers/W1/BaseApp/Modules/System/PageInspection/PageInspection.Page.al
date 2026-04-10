namespace System.Tooling;

using System.Apps;
using System.Reflection;

page 9631 "Page Inspection"
{
    Caption = 'Page Inspection';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    InstructionalText = 'See information about the page, its different elements, and the source behind the data it displays.';
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Page Info And Fields";
    Extensible = false;

    layout
    {
        area(content)
        {
            group(Control5)
            {
                ShowCaption = false;
                field(PageInfo; PageInfo)
                {
                    ApplicationArea = All;
                    Caption = 'Page';
                    ToolTip = 'Specifies the selected page''s name, number, and type.';
                }
            }
            group(ExploreInVSCode)
            {
                Visible = ShowExploreInVSCodeLink;
                ShowCaption = false;
                field(ExploreInVsCodeTextLbl; ExploreInVsCodeTextLbl)
                {
                    AccessByPermission = System "Tools, Zoom" = X;
                    ApplicationArea = All;
                    DrillDown = true;
                    ExtendedDatatype = URL;
                    ShowCaption = false;
                    ToolTip = 'Specifies the URL that opens this page in Visual Studio Code and attaches debugger to current session.';

                    trigger OnDrillDown()
                    begin
                        PageInspectionVSCodeHelper.NavigateToPageDefinitionInVSCode(Rec, UpdateExploreInVsCodeRequestURL);
                        UpdateExploreInVsCodeRequestURL := false;
                    end;
                }
            }
            group(Control12)
            {
                ShowCaption = false;
                Visible = PageIsReportRequest;
                field(PageIsReportRequestTextLbl; PageIsReportRequestTextLbl)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    ToolTip = 'Specifies that the page is related to a report.';
                }
            }
            group(Control20)
            {
                ShowCaption = false;
                Visible = PageIsRoleCenter;
                field(PageIsRoleCenterTextLbl; PageIsRoleCenterTextLbl)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    ToolTip = 'Specifies that the page has a Role Center type page.';
                }
            }
            group(Control24)
            {
                ShowCaption = false;
                Visible = not PageIsOpening and IsViewQueryPage;
                field(QueryInfo; QueryInfo)
                {
                    ApplicationArea = All;
                    Caption = 'Query';
                    ToolTip = 'Specifies the name and number of the inspected query.';
                }
            }
            group(Control10)
            {
                ShowCaption = false;
                Visible = not PageIsOpening and not PageIsSystem and not PageIsReportRequest and not PageIsReportViewer and not PageIsXMLPortPage and not PageIsRoleCenter and not IsViewQueryPage;
                field(TableInfo; TableInfo)
                {
                    ApplicationArea = All;
                    Caption = 'Table';
                    ToolTip = 'Specifies the name and number of the selected page''s source table.';
                }
            }
            group(Control27)
            {
                ShowCaption = false;
                Visible = PageIsReportViewer;
                field(PageIsReportViewerTextLbl; PageIsReportViewerTextLbl)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    ToolTip = 'Specifies that the page is related to a report.';
                }
            }
            group(Control28)
            {
                ShowCaption = false;
                Visible = PageIsXMLPortPage;
                field(PageIsXMLPortPageTextLbl; PageIsXMLPortPageTextLbl)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    ToolTip = 'Specifies that the page is related to an XMLPort page.';
                }
            }
            group(Control29)
            {
                ShowCaption = false;
                Visible = PageIsSystem;
                field(PageIsSystemTextLbl; PageIsSystemTextLbl)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    ToolTip = 'Specifies that the page is a system page.';
                }
            }
            group(Control11)
            {
                ShowCaption = false;
                Visible = not PageIsOpening and not PageIsSystem and not PageIsReportRequest and not PageIsReportViewer and not PageIsXMLPortPage and not PageIsRoleCenter and not IsViewTablePage and PageHasSourceTable and not PageSourceTableIsTemporary and not IsViewQueryPage;
                field(ViewTableLbl; ViewTableLbl)
                {
                    AccessByPermission = System "Tools, Zoom" = X;
                    ApplicationArea = All;
                    DrillDown = true;
                    ExtendedDatatype = URL;
                    ShowCaption = false;
                    ToolTip = 'Specifies the URL to view all records and fields of the page''s source table in a separate browser window. Requires permission to run tables.';

                    trigger OnDrillDown()
                    begin
                        HyperLink(ViewFullTableURL);
                    end;
                }
            }
            group(Control7)
            {
                ShowCaption = false;
                Visible = not PageIsOpening and not PageIsSystem and not PageIsReportRequest and not PageIsReportViewer and not PageIsXMLPortPage and not PageIsRoleCenter and not PageIsSystemPart and not IsViewQueryPage and PageHasSourceTable and PageSourceTableIsTemporary;
                field(SourceTableIsTemporaryLbl; SourceTableIsTemporaryLbl)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    ToolTip = 'Specifies that the table is a temporary table.';
                }
            }
            group(Control14)
            {
                ShowCaption = false;
                Visible = PageIsOpening;
                field(PageIsOpeningTextLbl; PageIsOpeningTextLbl)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    ToolTip = 'Specifies that the page is being opened.';
                }
            }
            grid(Control13)
            {
                ShowCaption = false;
                field(ShowFieldsTextLbl; ShowFieldsTextLbl)
                {
                    AccessByPermission = System "Tools, Zoom" = X;
                    ApplicationArea = All;
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = ShowFields;
                    ShowCaption = false;
                    ToolTip = 'Specifies all fields for the current record, including those not shown on the page. The information includes the field''s name, number, data type, value, and if it is a primary key (PK).';

                    trigger OnDrillDown()
                    begin
                        ShowFields := true;
                        ShowExtensions := false;
                        ShowFilters := false;

                        ShowNoPermissionForExtensions := false;

                        UpdateVisiblePart();
                    end;
                }
                field(ShowExtensionsTextLbl; ShowExtensionsTextLbl)
                {
                    AccessByPermission = System "Tools, Zoom" = X;
                    ApplicationArea = All;
                    DrillDown = true;
                    Style = Strong;
                    StyleExpr = ShowExtensions;
                    ShowCaption = false;
                    ToolTip = 'Specifies which installed extensions add or modify the page or source table.';

                    trigger OnDrillDown()
                    var
                        AllObjWithCaption: Record AllObjWithCaption;
                        NavAppInstalledApp: Record "NAV App Installed App";
                    begin
                        ShowExtensions := true;
                        ShowFields := false;
                        ShowFilters := false;

                        if AllObjWithCaption.ReadPermission and NavAppInstalledApp.ReadPermission then
                            ShowNoPermissionForExtensions := false
                        else
                            ShowNoPermissionForExtensions := true;

                        UpdateVisiblePart();
                    end;
                }
                field(ShowFiltersTextLbl; ShowFiltersTextLbl)
                {
                    AccessByPermission = System "Tools, Zoom" = X;
                    ApplicationArea = All;
                    Style = Strong;
                    StyleExpr = ShowFilters;
                    ShowCaption = false;
                    ToolTip = 'Specifies the filters that are applied to the page to refine the data.';

                    trigger OnDrillDown()
                    begin
                        ShowFilters := true;
                        ShowFields := false;
                        ShowExtensions := false;

                        ShowNoPermissionForExtensions := false;

                        UpdateVisiblePart();
                    end;
                }
            }
            part("Fields"; "Page Inspection Fields")
            {
                AccessByPermission = System "Tools, Zoom" = X;
                ApplicationArea = All;
                Visible = ShowFields;
            }
            part(Extensions; "Page Inspection Extensions")
            {
                AccessByPermission = System "Tools, Zoom" = X;
                ApplicationArea = All;
                Editable = false;
                Visible = ShowExtensions and not ShowNoPermissionForExtensions;
            }
            part(Filters; "Page Inspection Filters")
            {
                AccessByPermission = System "Tools, Zoom" = X;
                ApplicationArea = All;
                Visible = ShowFilters;
            }
            group(Control22)
            {
                ShowCaption = false;
                Visible = ShowNoPermissionForExtensions;
                field(NoViewExtensionsPermissionLbl; NoViewExtensionsPermissionLbl)
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ShowCaption = false;
                    ToolTip = 'Specifies that you do not have permission to view the tables that list the extensions affecting this page.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        SetElementsVisibilities();
        UpdateVisiblePart();
    end;

    trigger OnOpenPage()
    begin
        SetInitialVisibilities();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(Rec.FindFirst());
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(0);
    end;

    var
        PageInspectionVSCodeHelper: Codeunit "Page Inspection VS Code Helper";
        PageInfo: Text;
        TableInfo: Text;
        QueryInfo: Text;
        InfoFormatOneDetailLbl: Label '%1', Locked = true;
        InfoFormatTwoDetailsLbl: Label '%1 (%2)', Locked = true;
        InfoFormatThreeDetailsLbl: Label '%1 (%2, %3)', Locked = true;
        InfoFormatSecondDetailOnlyLbl: Label '(%1)', Locked = true;
        ViewFullTableURL: Text;
        ViewTableLbl: Label 'View table';
        UpdateExploreInVsCodeRequestURL: Boolean;
        ExploreInVsCodeTextLbl: Label 'Explore page in Visual Studio Code';
        ShowExploreInVSCodeLink: Boolean;
        ShowFields: Boolean;
        ShowExtensions: Boolean;
        ShowFilters: Boolean;
        ShowFieldsTextLbl: Label 'Table Fields';
        ShowExtensionsTextLbl: Label 'Extensions';
        ShowFiltersTextLbl: Label 'Page Filters';
        NoViewExtensionsPermissionLbl: Label 'You do not have permission to view the tables that list the extensions affecting this page.';
        NoSourceTableLbl: Label 'This page does not have a source table.';
        ShowNoPermissionForExtensions: Boolean;
        PageHasSourceTable: Boolean;
        PageSourceTableIsTemporary: Boolean;
        SourceTableIsTemporaryLbl: Label 'The source table of this page is temporary.';
        PageIsSystemPart: Boolean;
        PageIsReportRequest: Boolean;
        PageIsReportRequestTextLbl: Label 'This is a report request page.';
        PageIsXMLPortPage: Boolean;
        PageIsXMLPortPageTextLbl: Label 'This is an XMLPort page.';
        PageIsReportViewer: Boolean;
        PageIsReportViewerTextLbl: Label 'This is a report viewer page.';
        PageIsRoleCenter: Boolean;
        PageIsRoleCenterTextLbl: Label 'This is a role center page.';
        IsViewTablePage: Boolean;
        ViewTablePageLbl: Label 'View Table page.';
        IsViewQueryPage: Boolean;
        PageIsSystem: Boolean;
        PageIsSystemTextLbl: Label 'This is a system page.';
        PageIsOpening: Boolean;
        PageIsOpeningTextLbl: Label 'This page is being opened.';

    local procedure SetInitialVisibilities()
    begin
        ShowExploreInVSCodeLink := false;
        ShowFields := true;
        ShowExtensions := false;
        ShowFilters := false;
        ShowNoPermissionForExtensions := false;
        PageHasSourceTable := true;
        PageSourceTableIsTemporary := false;

        PageIsSystemPart := false;
        PageIsReportRequest := false;
        PageIsReportViewer := false;
        PageIsRoleCenter := false;
        PageIsSystem := false;
        PageIsOpening := false;
        IsViewTablePage := false;
        IsViewQueryPage := false;
    end;

    local procedure SetElementsVisibilities()
    var
        PageMetadata: Record "Page Metadata";
        BaseUrlTxt: Text;
    begin
        if Rec."Source Data Type" = 'Query' then begin
            IsViewQueryPage := true;
            QueryInfo := StrSubstNo(InfoFormatTwoDetailsLbl, Rec."Source Table Name", Rec."Source Table No.");
        end else
            IsViewQueryPage := false;

        PageMetadata.Reset();
        PageMetadata.SetFilter(ID, '%1', Rec."Page ID");
        if PageMetadata.FindFirst() then
            PageSourceTableIsTemporary := PageMetadata.SourceTableTemporary
        else
            PageSourceTableIsTemporary := false;

        if Rec."Page ID" = 0 then begin
            if Rec."Page Name" = '' then
                PageInfo := StrSubstNo(InfoFormatSecondDetailOnlyLbl, Rec."Page Type")
            else
                if Rec."Page Type" = '' then
                    PageInfo := StrSubstNo(InfoFormatOneDetailLbl, Rec."Page Name")
                else
                    PageInfo := StrSubstNo(InfoFormatTwoDetailsLbl, Rec."Page Name", Rec."Page Type")
        end else
            if Rec."Page Type" = '' then
                PageInfo := StrSubstNo(InfoFormatTwoDetailsLbl, Rec."Page Name", Rec."Page ID")
            else
                PageInfo := StrSubstNo(InfoFormatThreeDetailsLbl, Rec."Page Name", Rec."Page ID", Rec."Page Type");

        if Rec."Page Name" = ViewTablePageLbl then begin
            IsViewTablePage := true;
            PageInfo := StrSubstNo(InfoFormatTwoDetailsLbl, Rec."Page Name", Rec."Page Type");
        end else
            IsViewTablePage := false;

        if Rec."Source Table No." <= 0 then begin
            TableInfo := NoSourceTableLbl;
            PageHasSourceTable := false;
        end else begin
            TableInfo := StrSubstNo(InfoFormatTwoDetailsLbl, Rec."Source Table Name", Rec."Source Table No.");
            PageHasSourceTable := true;
            BaseUrlTxt := GetUrl(CLIENTTYPE::Current, CompanyName);
            if StrPos(BaseUrlTxt, '?') = 0 then
                ViewFullTableURL := StrSubstNo('%1?table=%2', BaseUrlTxt, Rec."Source Table No.")
            else
                ViewFullTableURL := StrSubstNo('%1&table=%2', BaseUrlTxt, Rec."Source Table No.");
        end;

        PageIsRoleCenter := (Rec."Current Form ID" = '00000000-0000-0000-0000-000000000001');

        PageIsReportRequest := (Rec."Current Form ID" = '00000000-0000-0000-0000-000000000002');

        PageIsSystemPart := (Rec."Current Form ID" = '00000000-0000-0000-0000-000000000003') or
          (Rec."Current Form ID" = '00000000-0000-0000-0000-000000000004');

        PageIsReportViewer := (Rec."Current Form ID" = '00000000-0000-0000-0000-000000000005');

        PageIsXMLPortPage := (Rec."Page Type" = 'XMLPort');

        PageIsSystem := (Rec."Current Form ID" = '00000000-0000-0000-0000-000000000006');

        PageIsOpening := (Rec."Current Form ID" = '00000000-0000-0000-0000-000000000007');

        ShowExploreInVSCodeLink := not PageIsOpening and not PageIsSystem and not PageIsReportRequest and not PageIsReportViewer and not PageIsXMLPortPage and not IsViewTablePage and not IsViewQueryPage;

        UpdateExploreInVsCodeRequestURL := true;
    end;

    local procedure UpdateVisiblePart()
    begin
        // Always update the fields - even when the part is not visible, otherwise 
        // it risks displaying the wrong set of fields when it is made visible
        CurrPage.Fields.PAGE.UpdatePage(Rec."Current Form ID", Rec."Current Form Bookmark");
        CurrPage.Fields.PAGE.SetFieldListVisibility(PageHasSourceTable);

        if ShowExtensions then begin
            CurrPage.Extensions.PAGE.FilterForExtAffectingPage(Rec."Page ID", Rec."Source Table No.", Rec."Current Form ID");
            CurrPage.Extensions.PAGE.SetExtensionListVisibility(not PageIsReportRequest and not PageIsReportViewer and not PageIsSystem and not ShowNoPermissionForExtensions);
        end;

        if ShowFilters then begin
            CurrPage.Filters.PAGE.UpdatePage(Rec."Current Form ID", Rec."Current Form Bookmark");
            CurrPage.Filters.PAGE.SetFilterListVisibility(PageHasSourceTable);
        end;
    end;
}
