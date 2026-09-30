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
                    Caption = 'Type of extension.';
                    ShowCaption = false;
                    ToolTip = 'Specifies extension type.';
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
    begin
        Version := StrSubstNo('%1.%2.%3', Rec."Version Major", Rec."Version Minor", Rec."Version Build");
        PublishedBy := StrSubstNo('by %1', Rec.Publisher);

        TypeOfExtension := '';

        if AllObjWithCaption.ReadPermission() then begin
            AllObjWithCaption.Reset();
            AllObjWithCaption.SetRange("App Package ID", Rec."Package ID");

            // page added by extension
            AllObjWithCaption.SetRange("Object ID", CurrentPageId);
            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Page);
            if not AllObjWithCaption.IsEmpty() then
                TypeOfExtension := TypeOfExtension + ', ' + NewPageLbl;

            // table added by extension
            AllObjWithCaption.SetRange("Object ID", CurrentTableId);
            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
            if not AllObjWithCaption.IsEmpty() then
                TypeOfExtension := TypeOfExtension + ', ' + NewTableLbl;

            AllObjWithCaption.Reset();
            AllObjWithCaption.SetRange("App Package ID", Rec."Package ID");

            // page extended by extension
            AllObjWithCaption.SetRange("Object Subtype", StrSubstNo('%1', CurrentPageId));
            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::PageExtension);
            if not AllObjWithCaption.IsEmpty() then
                TypeOfExtension := TypeOfExtension + ', ' + ExtPageLbl;

            // table extended by extension
            AllObjWithCaption.SetRange("Object Subtype", StrSubstNo('%1', CurrentTableId));
            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::TableExtension);
            if not AllObjWithCaption.IsEmpty() then
                TypeOfExtension := TypeOfExtension + ', ' + ExtTableLbl;

            TypeOfExtension := DelChr(TypeOfExtension, '<', ',');
        end;

        SetSourceSpecification();
    end;

    var
        PublishedApplication: Record "Published Application";
        Version: Text;
        PublishedBy: Text;
        IsExtensionListVisible: Boolean;
        IsSourceSpecificationEnabled: Boolean;
        TypeOfExtension: Text;
        CurrentPageId: Integer;
        CurrentTableId: Integer;
        NewPageLbl: Label 'Adds page';
        NewTableLbl: Label 'Adds table';
        ExtPageLbl: Label 'Extends page';
        ExtTableLbl: Label 'Extends table';

    procedure FilterForExtAffectingPage(PageId: Integer; TableId: Integer; FormId: Guid)
    begin
        if IsNullGuid(FormId) then; // Kept to not break existing code that calls this method with 3 parameters. The FormId parameter is not used in the current implementation.
        FilterForExtAffectingPage(PageId, TableId);
    end;

    procedure FilterForExtAffectingPage(PageId: Integer; TableId: Integer)
    var
        VSCodeRequestHelper: Codeunit "Page Inspection VS Code Helper";
    begin
        if (PageId = CurrentPageId) and (TableId = CurrentTableId) then
            exit;

        CurrentPageId := PageId;
        CurrentTableId := TableId;
        VSCodeRequestHelper.FilterForExtAffectingPage(PageId, TableId, Rec);
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