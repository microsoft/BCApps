namespace System.Tooling;

using System.Apps;
using System.Reflection;

page 9633 "Page Inspection Extensions"
{
    Caption = 'Page Inspection Extensions';
    PageType = ListPart;
    SourceTable = "NAV App Installed App";
    SourceTableView = where(Name = filter(<> '_Exclude_*'));
    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Visible = IsExtensionListVisible;
                field("App ID"; Rec."App ID")
                {
                    ApplicationArea = All;
                    Caption = 'App ID';
                    ShowCaption = false;
                    ToolTip = 'Specifies the ID of the extension.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Name';
                    DrillDown = true;
                    ShowCaption = false;
                    ToolTip = 'Specifies the name of the extension.';
                }
                field(Version; Version)
                {
                    ApplicationArea = All;
                    Caption = 'Version';
                    ShowCaption = false;
                    ToolTip = 'Specifies the version of extension.';
                }
                field(PublishedBy; PublishedBy)
                {
                    ApplicationArea = All;
                    Caption = 'Published by';
                    ShowCaption = false;
                    ToolTip = 'Specifies who published the extension.';
                }
                field(TypeOfExtension; TypeOfExtension)
                {
                    ApplicationArea = All;
                    Caption = 'Extension execution info and type.';
                    ShowCaption = false;
                    ToolTip = 'Specifies extension execution information and extension type.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Open Source in VS Code")
            {
                AccessByPermission = System "Tools, Zoom" = X;
                ApplicationArea = All;
                Caption = 'Open Source in VS Code';
                Enabled = IsSourceSpecificationEnabled;
                Image = Download;
                Scope = Repeater;
                ToolTip = 'Open the source code for the extension based on the source control information.';

                trigger OnAction()
                var
                    PageInspectionVSCodeHelper: Codeunit "Page Inspection VS Code Helper";
                begin
                    PageInspectionVSCodeHelper.OpenExtensionSourceInVSCode(PublishedApplication);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        ExtensionExecutionInfo: Record "Extension Execution Info";
        ExtensionType: Text;
        ExtensionInfo: Text;
        SeparatorText: Text;
    begin
        Version := StrSubstNo('%1.%2.%3', Rec."Version Major", Rec."Version Minor", Rec."Version Build");
        PublishedBy := StrSubstNo('by %1', Rec.Publisher);

        ExtensionType := '';
        ExtensionInfo := '';

        if AllObjWithCaption.ReadPermission() then begin
            AllObjWithCaption.Reset();
            AllObjWithCaption.SetRange("App Package ID", Rec."Package ID");

            // page added by extension
            AllObjWithCaption.SetRange("Object ID", CurrentPageId);
            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Page);
            if AllObjWithCaption.FindFirst() then
                ExtensionType := ExtensionType + ', ' + NewPageLbl;

            // table added by extension
            AllObjWithCaption.SetRange("Object ID", CurrentTableId);
            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
            if AllObjWithCaption.FindFirst() then
                ExtensionType := ExtensionType + ', ' + NewTableLbl;

            AllObjWithCaption.Reset();
            AllObjWithCaption.SetRange("App Package ID", Rec."Package ID");

            // page extended by extension
            AllObjWithCaption.SetRange("Object Subtype", StrSubstNo('%1', CurrentPageId));
            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::PageExtension);
            if AllObjWithCaption.FindFirst() then
                ExtensionType := ExtensionType + ', ' + ExtPageLbl;

            // table extended by extension
            AllObjWithCaption.SetRange("Object Subtype", StrSubstNo('%1', CurrentTableId));
            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::TableExtension);
            if AllObjWithCaption.FindFirst() then
                ExtensionType := ExtensionType + ', ' + ExtTableLbl;

            ExtensionType := DelChr(ExtensionType, '<', ',');

            AllObjWithCaption.Reset();
            AllObjWithCaption.SetRange("App Package ID", Rec."Package ID");

            if AllObjWithCaption.FindFirst() then
                if ExtensionExecutionInfo.ReadPermission() then begin
                    ExtensionExecutionInfo.Reset();
                    ExtensionExecutionInfo.SetRange("Form ID", CurrentFormId);
                    ExtensionExecutionInfo.SetRange("Runtime Package ID", AllObjWithCaption."App Runtime Package ID");

                    if ExtensionExecutionInfo.FindFirst() then
                        ExtensionInfo := StrSubstNo(
                            MillisecondsAndSubscribersLbl,
                            Format(ExtensionExecutionInfo."Execution Time"),
                            Format(ExtensionExecutionInfo."Subscriber Execution Count"))
                    else
                        ExtensionInfo := NoExtensionInfoLbl;
                end;
        end;

        if (StrLen(ExtensionType) > 0) and (StrLen(ExtensionInfo) > 0) then
            SeparatorText := '; '
        else
            SeparatorText := '';

        TypeOfExtension := StrSubstNo(TypeOfExtensionFmtLbl, ExtensionInfo, SeparatorText, ExtensionType);

        SetSourceSpecification();
    end;

    var
        PublishedApplication: Record "Published Application";
        Version: Text;
        PublishedBy: Text;
        IsExtensionListVisible: Boolean;
        IsSourceSpecificationEnabled: Boolean;
        TypeOfExtension: Text;
        CurrentFormId: Guid;
        CurrentPageId: Integer;
        CurrentTableId: Integer;
        NewPageLbl: Label 'Adds page';
        NewTableLbl: Label 'Adds table';
        ExtPageLbl: Label 'Extends page';
        ExtTableLbl: Label 'Extends table';
        MillisecondsAndSubscribersLbl: Label '%1ms, %2 subs.', Comment = '%1 is millisceonds, %2 is subscribers. "subs." is an abbreviation of "subscribers"';
        NoExtensionInfoLbl: Label 'No extension info';
        TypeOfExtensionFmtLbl: Label '%1%2%3', Locked = true;

    procedure FilterForExtAffectingPage(PageId: Integer; TableId: Integer; FormId: Guid)
    var
        VSCodeRequestHelper: Codeunit "Page Inspection VS Code Helper";
    begin
        if (PageId = CurrentPageId) and (TableId = CurrentTableId) then
            exit;

        CurrentPageId := PageId;
        CurrentTableId := TableId;
        CurrentFormId := FormId;

        VSCodeRequestHelper.FilterForExtAffectingPage(PageId, TableId, FormId, Rec);
        CurrPage.Update(false);
    end;

    [Scope('OnPrem')]
    procedure SetExtensionListVisibility(NewVisibilityValue: Boolean)
    begin
        IsExtensionListVisible := NewVisibilityValue;
    end;

    [Scope('OnPrem')]
    procedure SetSourceSpecification()
    var
        PageInspectionVSCodeHelper: Codeunit "Page Inspection VS Code Helper";
    begin
        PageInspectionVSCodeHelper.FindPublishedApplication(Rec, PublishedApplication);
        IsSourceSpecificationEnabled := PublishedApplication."Source Repository Url" <> '';
    end;
}