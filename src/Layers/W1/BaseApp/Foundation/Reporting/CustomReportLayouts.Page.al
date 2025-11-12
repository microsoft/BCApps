// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using Microsoft.EServices.EDocument;
using System.Integration;
using System.IO;
using System.Reflection;
using System.Security.User;
using System.Utilities;
using System.Environment.Configuration;

page 9650 "Custom Report Layouts"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Custom Report Layouts';
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Custom Report Layout";
    SourceTableView = sorting("Report ID", "Company Name", Type);
    UsageCategory = Administration;
    AboutTitle = 'About Custom Report Layouts';
    AboutText = '**This page has been deprecated and will be removed in a later release**. Please migrate your layouts to the new system page _Report Layouts_ using the _Migrate to System Layouts_ action.';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = IsNotBuiltIn;
                    ToolTip = 'Specifies the Code.';
                    Visible = false;
                }
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = false;
                    ToolTip = 'Specifies the object ID of the report.';
                }
                field("Report Name"; Rec."Report Name")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = false;
                    ToolTip = 'Specifies the name of the report.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the report layout.';
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Business Central company that the report layout applies to. You to create report layouts that can only be used on reports when they are run for a specific to a company. If the field is blank, then the layout will be available for use in all companies.';
                }
                field("Built-In"; Rec."Built-In")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = false;
                    ToolTip = 'Specifies if the report layout is built-in or not.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the file type of the report layout. The following table includes the types that are available:';
                }
                field("Last Modified"; Rec."Last Modified")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date and time of the last change to the report layout entry.';
                    Visible = false;
                }
                field("Last Modified by User"; Rec."Last Modified by User")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user who made the last change to the report layout entry.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."Last Modified by User");
                    end;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control11; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
            systempart(Control12; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
        }
    }

    actions
    {
        area(creation)
        {
            action(NewLayout)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'New';
                Ellipsis = true;
                Image = NewDocument;
                ToolTip = 'Create a new built-in layout for reports.';

                trigger OnAction()
                begin
                    Rec.CopyBuiltInReportLayout();
                end;
            }
            action(CopyRec)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Copy';
                Image = CopyDocument;
                ToolTip = 'Make a copy of a built-in layout for reports.';

                trigger OnAction()
                begin
                    Rec.CopyReportLayout();
                end;
            }
        }
        area(processing)
        {
            action(OpenInOneDrive)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open in OneDrive';
                ToolTip = 'Copy the file to your Business Central folder in OneDrive and open it in a new window so you can manage or share the file.', Comment = 'OneDrive should not be translated';
                Image = Cloud;
                Visible = ShareOptionsVisible;
                Enabled = ShareOptionsEnabled;
                Scope = Repeater;
                trigger OnAction()
                var
                    FileManagement: Codeunit "File Management";
                    DocumentServiceMgt: Codeunit "Document Service Management";
                    FileName: Text;
                    FileExtension: Text;
                    InStream: InStream;
                begin
                    FileName := FileManagement.StripNotsupportChrInFileName(Rec."Report Name");
                    FileExtension := DocxFileExtensionLbl;
                    Rec.Layout.CreateInStream(InStream);
                    DocumentServiceMgt.OpenInOneDrive(FileName, FileExtension, InStream);
                end;
            }
            action(EditInOneDrive)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit in OneDrive';
                ToolTip = 'Copy the file to your Business Central folder in OneDrive and open it in a new window so you can edit the file.', Comment = 'OneDrive should not be translated';
                Image = Cloud;
                Visible = ShareOptionsVisible;
                Enabled = ShareOptionsEnabled;
                Scope = Repeater;

                trigger OnAction()
                var
                    DocumentServiceMgt: Codeunit "Document Service Management";
                    TempBlob: Codeunit "Temp Blob";
                    InStream: InStream;
                    OutStream: OutStream;
                begin
                    Rec.Layout.CreateInStream(InStream);
                    TempBlob.CreateOutStream(OutStream);
                    CopyStream(OutStream, InStream);

                    if DocumentServiceMgt.EditInOneDrive(Rec."Report Name" + DocxFileExtensionLbl, DocxFileExtensionLbl, TempBlob) then begin
                        Rec.Layout.CreateOutStream(OutStream);
                        TempBlob.CreateInStream(InStream);
                        CopyStream(OutStream, InStream);
                        Rec.Modify();
                    end;
                end;
            }
            action(ShareWithOneDrive)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Share';
                ToolTip = 'Copy the file to your Business Central folder in OneDrive and share the file. You can also see who it''s already shared with.', Comment = 'OneDrive should not be translated';
                Image = Share;
                Visible = ShareOptionsVisible;
                Enabled = ShareOptionsEnabled;
                Scope = Repeater;
                trigger OnAction()
                var
                    FileManagement: Codeunit "File Management";
                    DocumentServiceMgt: Codeunit "Document Service Management";
                    FileName: Text;
                    FileExtension: Text;
                    InStream: InStream;
                begin
                    FileName := FileManagement.StripNotsupportChrInFileName(Rec."Report Name");
                    FileExtension := DocxFileExtensionLbl;

                    Rec.Layout.CreateInStream(InStream);
                    DocumentServiceMgt.ShareWithOneDrive(FileName, FileExtension, InStream);
                end;
            }
            action(ExportWordXMLPart)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export Word XML Part';
                Image = Export;
                ToolTip = 'Export to a Word XML file.';

                trigger OnAction()
                begin
                    Rec.ExportSchema('', true);
                end;
            }
            action(ImportLayout)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Import Layout';
                Image = Import;
                ToolTip = 'Import a Word file.';

                trigger OnAction()
                begin
                    Rec.ImportReportLayout('');
                end;
            }
            action(ExportLayout)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export Layout';
                Image = Export;
                ToolTip = 'Export a Word file.';

                trigger OnAction()
                begin
                    Rec.ExportReportLayout('', true);
                end;
            }
            action(UpdateWordLayout)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Update Layout';
                Image = UpdateXML;
                ToolTip = 'Update specific report layouts or all custom report layouts that might be affected by dataset changes.';

                trigger OnAction()
                begin
                    if Rec.CanBeModified() then
                        if Rec.UpdateReportLayout(false, false) then
                            Message(UpdateSuccesMsg, Format(Rec.Type))
                        else
                            Message(UpdateNotRequiredMsg, Format(Rec.Type));
                end;
            }
            action(MigrateToSystemLayouts)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Migrate to System Layouts';
                ToolTip = 'Migrate the selected custom report layouts to system layouts.';

                trigger OnAction()
                var
                    CustomReportLayout: Record "Custom Report Layout";
                    FeatureReportSelection: Codeunit "Feature - Report Selection";
                begin
                    CustomReportLayout.Copy(Rec);
                    CurrPage.SetSelectionFilter(CustomReportLayout);
                    FeatureReportSelection.MigrateCustomReportLayouts(CustomReportLayout);
                end;
            }
        }
        area(reporting)
        {
            action(RunReport)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Run Report';
                Image = "Report";
                ToolTip = 'Run a test report.';

                trigger OnAction()
                begin
                    Rec.RunCustomReport();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'New', Comment = 'Generated from the PromotedActionCategories property index 0.';

                actionref(NewLayout_Promoted; NewLayout)
                {
                }
                actionref(CopyRec_Promoted; CopyRec)
                {
                }
            }
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(RunReport_Promoted; RunReport)
                {
                }
                group(Category_Category4)
                {
                    Caption = 'Layout', Comment = 'Generated from the PromotedActionCategories property index 3.';

                    actionref(UpdateWordLayout_Promoted; UpdateWordLayout)
                    {
                    }
                    actionref(ImportLayout_Promoted; ImportLayout)
                    {
                    }
                    actionref(ExportLayout_Promoted; ExportLayout)
                    {
                    }
                }
                group(OneDrive)
                {
                    Caption = 'OneDrive';
                    ShowAs = SplitButton;
                    Image = Cloud;

                    actionref(OpenInOneDrive_Promoted; OpenInOneDrive)
                    {
                    }
                    actionref(EditInOneDrive_Promoted; EditInOneDrive)
                    {
                    }
                    actionref(ShareWithOneDrive_Promoted; ShareWithOneDrive)
                    {
                    }
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
                actionref(MigrateToSystem_promoted; MigrateToSystemLayouts)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        CustomReportLayout: Record "Custom Report Layout";
        ReportLayoutSelection: Record "Report Layout Selection";
        DocumentSharing: Codeunit "Document Sharing";
    begin
        CurrPage.Caption := GetPageCaption();
        ReportLayoutSelection.ClearTempLayoutSelected();
        IsNotBuiltIn := not Rec."Built-In";
        CurrPage.SetSelectionFilter(CustomReportLayout);
        IsMultiSelect := CustomReportLayout.Count() > 1;
        ShareOptionsVisible := DocumentSharing.ShareEnabled(Enum::"Document Sharing Source"::System);
        ShareOptionsEnabled := not IsMultiSelect and IsNotBuiltIn and (Rec.Type = Rec.Type::Word);
    end;

    trigger OnClosePage()
    var
        ReportLayoutSelection: Record "Report Layout Selection";
    begin
        ReportLayoutSelection.ClearTempLayoutSelected();
    end;

    trigger OnOpenPage()
    begin
        PageName := CurrPage.Caption;
        CurrPage.Caption := GetPageCaption();
        Rec.SetRange("Built-In", false);
    end;

    var
        UpdateSuccesMsg: Label 'The %1 layout has been updated to use the current report design.', Comment = '%1 will be replaced by the layout name.';
        UpdateNotRequiredMsg: Label 'The %1 layout is up-to-date. No further updates are required.', Comment = '%1 will be replaced by the layout name.';
        PageName: Text;
        CaptionTxt: Label '%1 - %2 %3', Locked = true;
        IsNotBuiltIn: Boolean;
        IsMultiSelect: Boolean;
        ShareOptionsVisible: Boolean;
        ShareOptionsEnabled: Boolean;
        DocxFileExtensionLbl: Label '.docx';

    local procedure GetPageCaption(): Text
    var
        AllObjWithCaption: Record AllObjWithCaption;
        FilterText: Text;
        ReportID: Integer;
    begin
        if Rec."Report ID" <> 0 then
            exit(StrSubstNo(CaptionTxt, PageName, Rec."Report ID", Rec."Report Name"));
        Rec.FilterGroup(4);
        FilterText := Rec.GetFilter("Report ID");
        Rec.FilterGroup(0);
        if Evaluate(ReportID, FilterText) then
            if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Report, ReportID) then
                exit(StrSubstNo(CaptionTxt, PageName, ReportID, AllObjWithCaption."Object Caption"));
        exit(PageName);
    end;
}

