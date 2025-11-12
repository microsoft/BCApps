// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using System;
using System.Environment;
using System.IO;
using System.Reflection;
using System.Security.AccessControl;
using System.Utilities;

table 9650 "Custom Report Layout"
{
    Caption = 'Custom Report Layout';
    DataPerCompany = false;
    DrillDownPageID = "Custom Report Layouts";
    LookupPageID = "Custom Report Layouts";
    Permissions = TableData "Custom Report Layout" = rimd;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
        }
        field(2; "Report ID"; Integer)
        {
            Caption = 'Report ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
        }
        field(3; "Report Name"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Report),
                                                                           "Object ID" = field("Report ID")));
            Caption = 'Report Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
            TableRelation = Company;
        }
        field(6; Type; Enum "Custom Report Layout Type")
        {
            Caption = 'Type';
            InitValue = Word;
        }
        field(7; "Layout"; BLOB)
        {
            Caption = 'Layout';
        }
        field(8; "Last Modified"; DateTime)
        {
            Caption = 'Last Modified';
            Editable = false;
        }
        field(9; "Last Modified by User"; Code[50])
        {
            Caption = 'Last Modified by User';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(10; "File Extension"; Text[30])
        {
            Caption = 'File Extension';
            Editable = false;
        }
        field(11; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(12; "Custom XML Part"; BLOB)
        {
            Caption = 'Custom XML Part';
        }
        field(13; "App ID"; Guid)
        {
            Caption = 'App ID';
            Editable = false;
        }
        field(14; "Built-In"; Boolean)
        {
            Caption = 'Built-In';
            Editable = false;
        }
        field(15; "Layout Last Updated"; DateTime)
        {
            Caption = 'Layout Last Modified';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; "Report ID", "Company Name", Type)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Description)
        {
        }
    }

    trigger OnDelete()
    begin
        if "Built-In" then
            Error(DeleteBuiltInLayoutErr);
    end;

    trigger OnInsert()
    begin
        TestField("Report ID");
        if Code = '' then
            Code := GetDefaultCode("Report ID");
        SetUpdated();
    end;

    trigger OnModify()
    begin
        TestField("Report ID");
        SetUpdated();
    end;

    var
        ImportWordTxt: Label 'Import Word Document';
        ImportRdlcTxt: Label 'Import Report Layout';
        FileFilterWordTxt: Label 'Word Files (*.docx)|*.docx', Comment = '{Split=r''\|''}{Locked=s''1''}';
        FileFilterRdlcTxt: Label 'SQL Report Builder (*.rdl;*.rdlc)|*.rdl;*.rdlc', Comment = '{Split=r''\|''}{Locked=s''1''}';
        NoRecordsErr: Label 'There is no record in the list.';
        BuiltInTxt: Label 'Built-in layout';
#pragma warning disable AA0470
        CopyOfTxt: Label 'Copy of %1';
#pragma warning restore AA0470
        NewLayoutTxt: Label 'New layout';
        ErrorInLayoutErr: Label 'The following issue has been found in the layout %1 for report ID  %2:\%3.', Comment = '%1=a name, %2=a number, %3=a sentence/error description.';
        TemplateValidationQst: Label 'The RDLC layout does not comply with the current report design (for example, fields are missing or the report ID is wrong).\The following errors were detected during the layout validation:\%1\Do you want to continue?', Comment = '%1 = an error message.';
#pragma warning disable AA0470
        TemplateValidationErr: Label 'The RDLC layout does not comply with the current report design (for example, fields are missing or the report ID is wrong).\The following errors were detected during the document validation:\%1\You must update the layout to match the current report design.';
#pragma warning restore AA0470
        AbortWithValidationErr: Label 'The RDLC layout action has been canceled because of validation errors.';
        ModifyBuiltInLayoutQst: Label 'This is a built-in custom report layout, and it cannot be modified.\\Do you want to modify a copy of the custom report layout instead?';
        NoLayoutSelectedMsg: Label 'You must specify if you want to insert a Word layout or an RDLC layout for the report.';
        DeleteBuiltInLayoutErr: Label 'This is a built-in custom report layout, and it cannot be deleted.';
        ModifyBuiltInLayoutErr: Label 'This is a built-in custom report layout, and it cannot be modified.';

    local procedure SetUpdated()
    begin
        "Last Modified" := RoundDateTime(CurrentDateTime);
        "Last Modified by User" := CopyStr(UserId(), 1, 50);
    end;

    procedure InitBuiltInLayout(ReportID: Integer; LayoutType: Option): Code[20]
    var
        CustomReportLayout: Record "Custom Report Layout";
        TempBlob: Codeunit "Temp Blob";
        DocumentReportMgt: Codeunit "Document Report Mgt.";
        OutStr: OutStream;
    begin
        if ReportID = 0 then
            exit;

        CustomReportLayout.Init();
        CustomReportLayout."Report ID" := ReportID;
        CustomReportLayout.Type := "Custom Report Layout Type".FromInteger(LayoutType);
        CustomReportLayout.Description := CopyStr(StrSubstNo(CopyOfTxt, BuiltInTxt), 1, MaxStrLen(Description));
        CustomReportLayout."Built-In" := false;
        CustomReportLayout.Code := GetDefaultCode(ReportID);
        CustomReportLayout.Insert(true);

        case LayoutType of
            CustomReportLayout.Type::Word.AsInteger():
                begin
                    if not LoadInternalWordLayout(ReportID, TempBlob) then begin
                        TempBlob.CreateOutStream(OutStr);
                        DocumentReportMgt.NewWordLayout(ReportID, OutStr);
                        CustomReportLayout.Description := CopyStr(NewLayoutTxt, 1, MaxStrLen(Description));
                    end;

                    CustomReportLayout.SetLayoutBlob(TempBlob);
                end;
            CustomReportLayout.Type::RDLC.AsInteger():
                if LoadInternalRdlcLayout(ReportID, TempBlob) then
                        CustomReportLayout.SetLayoutBlob(TempBlob);
            else
                OnInitBuiltInLayout(CustomReportLayout, ReportID, LayoutType);
        end;

        CustomReportLayout.SetDefaultCustomXmlPart();
        CustomReportLayout.SetLayoutLastUpdated();

        exit(CustomReportLayout.Code);
    end;

    /// <summary>
    /// Internal resplacement for the soon deprecated Report.WordLayout function. This function will load the internal Word layout for the given report using the virtual table Report Layout List.
    /// </summary>
    /// <param name="ReportID">Report Id.</param>
    /// <param name="TempBlob">Layout will be provided in the blob object if the procedure return true.</param>
    /// <returns>True if the layout was loaded.</returns>
    local procedure LoadInternalWordLayout(ReportID: Integer; var TempBlob: Codeunit "Temp Blob"): Boolean
    var
        ReportLayoutList: Record "Report Layout List";
        LayoutStream: OutStream;
        ExportStatus: Boolean;
    begin
        ReportLayoutList.SetFilter("Report ID", '=%1', ReportID);
        ReportLayoutList.SetFilter("Layout Format", '=%1', ReportLayoutList."Layout Format"::Word);
        if not ReportLayoutList.FindFirst() then
            exit(false);

        TempBlob.CreateOutStream(LayoutStream);
        ExportStatus := ReportLayoutList.Layout.ExportStream(LayoutStream);
        exit(ExportStatus)
    end;

    /// <summary>
    /// Internal resplacement for the soon deprecated Report.RdlcLayout function. This function will load the internal RDLC layout for the given report using the virtual table Report Layout List.
    /// </summary>
    /// <param name="ReportID">Report Id.</param>
    /// <param name="TempBlob">Layout will be provided in the blob object if the procedure return true.</param>
    /// <returns>True if the layout was loaded.</returns>
    local procedure LoadInternalRdlcLayout(ReportID: Integer; var TempBlob: Codeunit "Temp Blob"): Boolean
    var
        ReportLayoutList: Record "Report Layout List";
        LayoutStream: OutStream;
        ExportStatus: Boolean;
    begin
        ReportLayoutList.SetFilter("Report ID", '=%1', ReportID);
        ReportLayoutList.SetFilter("Layout Format", '=%1', ReportLayoutList."Layout Format"::RDLC);
        if not ReportLayoutList.FindFirst() then
            exit(false);

        TempBlob.CreateOutStream(LayoutStream);
        ExportStatus := ReportLayoutList.Layout.ExportStream(LayoutStream);
        exit(ExportStatus)
    end;

    procedure CopyBuiltInReportLayout()
    var
        ReportLayoutLookup: Page "Report Layout Lookup";
        ReportID: Integer;
        LayoutSelected: Boolean;
    begin
        FilterGroup(4);
        if GetFilter("Report ID") = '' then
            FilterGroup(0);
        if GetFilter("Report ID") <> '' then
            if Evaluate(ReportID, GetFilter("Report ID")) then
                ReportLayoutLookup.SetReportID(ReportID);
        FilterGroup(0);
        if ReportLayoutLookup.RunModal() = ACTION::OK then begin
            if ReportLayoutLookup.SelectedAddWordLayot() then
                InitBuiltInLayout(ReportLayoutLookup.SelectedReportID(), Type::Word.AsInteger());
            if ReportLayoutLookup.SelectedAddRdlcLayot() then
                InitBuiltInLayout(ReportLayoutLookup.SelectedReportID(), Type::RDLC.AsInteger());

            LayoutSelected := ReportLayoutLookup.SelectedAddWordLayot() or ReportLayoutLookup.SelectedAddRdlcLayot();
            if (not LayoutSelected) and (not ReportLayoutLookup.InitCustomTypeLayouts()) then
                MESSAGE(NoLayoutSelectedMsg);
        end;
    end;

    procedure CopyReportLayout(): Code[20]
    var
        CustomReportLayout: Record "Custom Report Layout";
        TempBlob: Codeunit "Temp Blob";
    begin
        if IsEmpty() then
            Error(NoRecordsErr);

        CalcFields(Layout, "Custom XML Part");
        CustomReportLayout := Rec;

        Description := CopyStr(StrSubstNo(CopyOfTxt, Description), 1, MaxStrLen(Description));
        Code := GetDefaultCode("Report ID");
        "Built-In" := false;
        OnCopyRecordOnBeforeInsertLayout(Rec, CustomReportLayout);
        Insert(true);

        if CustomReportLayout."Built-In" then begin
            CustomReportLayout.GetLayoutBlob(TempBlob);
            SetLayoutBlob(TempBlob);
        end;

        if not HasCustomXmlPart() then
            SetDefaultCustomXmlPart();

        exit(Code);
    end;

    procedure ImportReportLayout(DefaultFileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        FileName: Text;
        FileFilterTxt: Text;
        ImportTxt: Text;
    begin
        if IsEmpty() then
            Error(NoRecordsErr);

        if not CanBeModified() then
            exit;

        case Type of
            Type::Word:
                begin
                    ImportTxt := ImportWordTxt;
                    FileFilterTxt := FileFilterWordTxt;
                end;
            Type::RDLC:
                begin
                    ImportTxt := ImportRdlcTxt;
                    FileFilterTxt := FileFilterRdlcTxt;
                end;
        end;

        OnImportLayoutSetFileFilter(Rec, FileFilterTxt);
        FileName := FileMgt.BLOBImportWithFilter(TempBlob, ImportTxt, DefaultFileName, FileFilterTxt, FileFilterTxt);
        if FileName = '' then
            exit;

        ImportLayoutBlob(TempBlob, CopyStr(UpperCase(FileMgt.GetExtension(FileName)), 1, 30));
    end;

    [Scope('OnPrem')]
    procedure ImportLayoutBlob(var TempBlob: Codeunit "Temp Blob"; FileExtension: Text[30])
    var
        OutputTempBlob: Codeunit "Temp Blob";
        DocumentReportMgt: Codeunit "Document Report Mgt.";
        DocumentInStream: InStream;
        DocumentOutStream: OutStream;
        ErrorMessage: Text;
        XmlPart: Text;
    begin
        // Layout is stored in the DocumentInStream (RDLC requires UTF8 encoding for which reason is stream is created in the case block.
        // Result is stored in the DocumentOutStream (..)
        TestField("Report ID");
        OutputTempBlob.CreateOutStream(DocumentOutStream);
        XmlPart := GetWordXmlPart("Report ID");

        case Type of
            Type::Word:
                begin
                    // Run update
                    TempBlob.CreateInStream(DocumentInStream);
                    ErrorMessage := DocumentReportMgt.TryUpdateWordLayout(DocumentInStream, DocumentOutStream, '', XmlPart);
                    // Validate the Word document layout against the layout of the current report
                    if ErrorMessage = '' then begin
                        CopyStream(DocumentOutStream, DocumentInStream);
                        DocumentReportMgt.ValidateWordLayout("Report ID", DocumentInStream, true, true);
                    end;
                end;
            Type::RDLC:
                begin
                    // Update the Rdlc document layout against the layout of the current report
                    TempBlob.CreateInStream(DocumentInStream, TEXTENCODING::UTF8);
                    ErrorMessage := DocumentReportMgt.TryUpdateRdlcLayout("Report ID", DocumentInStream, DocumentOutStream, '', XmlPart, false);
                end;
        end;

        OnImportLayoutBlob(Rec, TempBlob, FileExtension, XmlPart, DocumentOutStream);

        SetLayoutBlob(OutputTempBlob);

        if FileExtension <> '' then
            "File Extension" := FileExtension;
        SetDefaultCustomXmlPart();
        Modify(true);
        SetLayoutLastUpdated();
        Commit();

        if ErrorMessage <> '' then
            Message(ErrorMessage);
    end;

    procedure ExportReportLayout(DefaultFileName: Text; ShowFileDialog: Boolean): Text
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
    begin
        OnBeforeExportReportLayout(Rec, DefaultFileName, ShowFileDialog);

        // Update is needed in case of report layout mismatches word layout
        // Do not update build-in layout as it is read only
        if not "Built-In" then
            UpdateReportLayout(true, false); // Don't block on errors (return false) as we in all cases want to have an export file to edit.

        GetLayoutBlob(TempBlob);
        if not TempBlob.HasValue() then
            exit('');

        if DefaultFileName = '' then
            DefaultFileName := '*.' + GetFileExtension();

        exit(FileMgt.BLOBExport(TempBlob, DefaultFileName, ShowFileDialog));
    end;

    [Scope('OnPrem')]
    procedure ValidateLayout(useConfirm: Boolean; UpdateContext: Boolean): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        DocumentReportMgt: Codeunit "Document Report Mgt.";
        DocumentInStream: InStream;
        ValidationErrorFormat: Text;
    begin
        TestField("Report ID");
        GetLayoutBlob(TempBlob);
        if not TempBlob.HasValue() then
            exit;

        TempBlob.CreateInStream(DocumentInStream);

        case Type of
            Type::Word:
                exit(DocumentReportMgt.ValidateWordLayout("Report ID", DocumentInStream, useConfirm, UpdateContext));
            Type::RDLC:
                if not TryValidateRdlcReport(DocumentInStream) then begin
                    if useConfirm then begin
                        if not Confirm(TemplateValidationQst, false, GetLastErrorText) then
                            Error(AbortWithValidationErr);
                    end else begin
                        ValidationErrorFormat := TemplateValidationErr;
                        Error(ValidationErrorFormat, GetLastErrorText);
                    end;
                    exit(false);
                end;
        end;

        exit(true);
    end;

    procedure UpdateReportLayout(ContinueOnError: Boolean; IgnoreDelete: Boolean) LayoutUpdated: Boolean
    var
        ErrorMessage: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateLayout(LayoutUpdated, IsHandled);
        if IsHandled then
            exit(LayoutUpdated);

        ErrorMessage := TryUpdateLayout(IgnoreDelete);

        if ErrorMessage = '' then begin
            if Type = Type::Word then
                exit(ValidateLayout(true, true));
            exit(true); // We have no validate for RDLC
        end;

        ErrorMessage := StrSubstNo(ErrorInLayoutErr, Description, "Report ID", ErrorMessage);
        if ContinueOnError then begin
            Message(ErrorMessage);
            exit(true);
        end;

        Error(ErrorMessage);
    end;

    [Scope('OnPrem')]
    procedure TryUpdateLayout(IgnoreDelete: Boolean): Text
    var
        InTempBlob: Codeunit "Temp Blob";
        OutTempBlob: Codeunit "Temp Blob";
        DocumentReportMgt: Codeunit "Document Report Mgt.";
        DocumentInStream: InStream;
        DocumentOutStream: OutStream;
        CurrentCustomXmlPart: Text;
        StoredCustomXmlPart: Text;
        ErrorMessage: Text;
    begin
        TestCustomXmlPart();
        TestField("Report ID");
        CurrentCustomXmlPart := GetWordXmlPart("Report ID");
        StoredCustomXmlPart := GetCustomXmlPart();

        if "Layout Last Updated" > "Last Modified" then
            if CurrentCustomXmlPart = StoredCustomXmlPart then
                exit(''); // no need to update

        GetLayoutBlob(InTempBlob);
        if not InTempBlob.HasValue() then
            exit('');
        InTempBlob.CreateInStream(DocumentInStream);

        case Type of
            Type::Word:
                begin
                    OutTempBlob.CreateOutStream(DocumentOutStream);
                    ErrorMessage := DocumentReportMgt.TryUpdateWordLayout(DocumentInStream, DocumentOutStream, StoredCustomXmlPart, CurrentCustomXmlPart);
                end;
            Type::RDLC:
                begin
                    OutTempBlob.CreateOutStream(DocumentOutStream, TEXTENCODING::UTF8);
                    ErrorMessage := DocumentReportMgt.TryUpdateRdlcLayout(
                        "Report ID", DocumentInStream, DocumentOutStream, StoredCustomXmlPart, CurrentCustomXmlPart, IgnoreDelete);
                end;
        end;

        SetCustomXmlPart(CurrentCustomXmlPart);

        if OutTempBlob.HasValue() then
            SetLayoutBlob(OutTempBlob);

        SetLayoutLastUpdated();

        exit(ErrorMessage);
    end;

    local procedure GetWordXML(var TempBlob: Codeunit "Temp Blob")
    var
        OutStr: OutStream;
    begin
        TestField("Report ID");
        TempBlob.CreateOutStream(OutStr, TEXTENCODING::UTF16);
        OutStr.WriteText(REPORT.WordXmlPart("Report ID"));
    end;

    [Scope('OnPrem')]
    procedure ExportSchema(DefaultFileName: Text; ShowFileDialog: Boolean) Result: Text
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeExportSchema(Rec, DefaultFileName, ShowFileDialog, IsHandled);
        if IsHandled then
            exit(Result);

        TestField(Type, Type::Word);

        if DefaultFileName = '' then
            DefaultFileName := '*.xml';

        GetWordXML(TempBlob);
        if TempBlob.HasValue() then
            exit(FileMgt.BLOBExport(TempBlob, DefaultFileName, ShowFileDialog));
    end;

    procedure GetFileExtension() FileExt: Text[4]
    begin
        case Type of
            Type::Word:
                FileExt := 'docx';
            Type::RDLC:
                FileExt := 'rdl';
            else
                OnGetFileExtension(Rec, FileExt);
        end;
    end;

    procedure GetWordXmlPart(ReportID: Integer): Text
    var
        WordXmlPart: Text;
    begin
        // Store the current design as an extended WordXmlPart. This data is used for later updates / refactorings.
        WordXmlPart := REPORT.WordXmlPart(ReportID, true);
        exit(WordXmlPart);
    end;

    procedure RunCustomReport()
    var
        ReportLayoutSelection: Record "Report Layout Selection";
    begin
        if "Report ID" = 0 then
            exit;

        ReportLayoutSelection.SetTempLayoutSelected(Code);
        REPORT.RunModal("Report ID");
        ReportLayoutSelection.ClearTempLayoutSelected();
    end;

    [Scope('OnPrem')]
    procedure ApplyUpgrade(var ReportUpgrade: DotNet ReportUpgradeSet; var ReportChangeLogCollection: DotNet IReportChangeLogCollection; testOnly: Boolean)
    var
        InTempBlob: Codeunit "Temp Blob";
        OutTempBlob: Codeunit "Temp Blob";
        TempReportChangeLogCollection: DotNet IReportChangeLogCollection;
        DataInStream: InStream;
        DataOutStream: OutStream;
        ModifyLayout: Boolean;
    begin
        GetLayoutBlob(InTempBlob);
        if not InTempBlob.HasValue() then
            exit;

        if ReportUpgrade.ChangeCount < 1 then
            exit;

        Clear(DataInStream);
        Clear(DataOutStream);

        case Type of
            Type::Word:
                begin
                    InTempBlob.CreateInStream(DataInStream);
                    OutTempBlob.CreateOutStream(DataOutStream);
                end;
            Type::RDLC:
                begin
                    InTempBlob.CreateInStream(DataInStream, TEXTENCODING::UTF8);
                    OutTempBlob.CreateOutStream(DataOutStream, TEXTENCODING::UTF8);
                end;
        end;

        TempReportChangeLogCollection := ReportUpgrade.Upgrade(Description, DataInStream, DataOutStream);

        if not testOnly then begin
            if TempReportChangeLogCollection.Failures = 0 then begin
                SetDefaultCustomXmlPart();
                ModifyLayout := true;
            end;
            if OutTempBlob.HasValue() then begin
                SetLayoutBlob(OutTempBlob);
                ModifyLayout := true;
            end;
            if ModifyLayout then
                Commit();
        end;

        if TempReportChangeLogCollection.Count > 0 then
            if IsNull(ReportChangeLogCollection) then
                ReportChangeLogCollection := TempReportChangeLogCollection
            else
                ReportChangeLogCollection.AddRange(TempReportChangeLogCollection);
    end;

    [TryFunction]
    local procedure TryValidateRdlcReport(var InStr: InStream)
    var
        RdlcReportManager: DotNet RdlcReportManager;
        RdlcString: Text;
    begin
        InStr.Read(RdlcString);
        RdlcReportManager.ValidateReport("Report ID", RdlcString);
    end;

    local procedure FilterOnReport(ReportID: Integer)
    begin
        Reset();
        SetCurrentKey("Report ID", "Company Name", Type);
        SetFilter("Company Name", '%1|%2', '', StrSubstNo('@%1', CompanyName));
        SetRange("Report ID", ReportID);
        SetRange("Built-In", false);
    end;

    procedure LookupLayoutOK(ReportID: Integer): Boolean
    begin
        FilterOnReport(ReportID);
        OnLookupLayoutOKOnBeforePageRun(Rec);
        exit(PAGE.RunModal(PAGE::"Custom Report Layouts", Rec) = ACTION::LookupOK);
    end;

    procedure GetDefaultCode(ReportID: Integer): Code[20]
    var
        CustomReportLayout: Record "Custom Report Layout";
        NewCode: Code[20];
    begin
        CustomReportLayout.SetRange("Report ID", ReportID);
        CustomReportLayout.SetFilter(Code, StrSubstNo('%1-*', ReportID));
        if CustomReportLayout.FindLast() then
            NewCode := IncStr(CustomReportLayout.Code)
        else
            NewCode := StrSubstNo('%1-000001', ReportID);

        exit(NewCode);
    end;

    [Scope('OnPrem')]
    procedure CanBeModified(): Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCanBeModified(Rec, IsHandled);
        if IsHandled then
            exit;

        if not "Built-In" then
            exit(true);

        if not Confirm(ModifyBuiltInLayoutQst) then
            exit(false);

        CopyReportLayout();
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure NewExtensionLayout(ExtensionAppId: Guid; LayoutDataTable: DotNet DataTable)
    var
        Row: DotNet DataRow;
        Version: Text;
    begin
        Row := LayoutDataTable.Rows.Item(0);
        if LayoutDataTable.Columns.Contains('NavApplicationVersion') then
            Version := Row.Item('NavApplicationVersion');

        case Version of
            else
                HandleW10Layout(ExtensionAppId, Row, LayoutDataTable);
        end;
    end;

    local procedure HandleW10Layout(ExtensionAppId: Guid; Row: DotNet DataRow; LayoutDataTable: DotNet DataTable)
    var
        CustomReportLayout: Record "Custom Report Layout";
        LayoutCode: Code[20];
    begin
        if not LayoutDataTable.Columns.Contains('Code') then begin
            LayoutCode := 'MS-EXT-0000000001';
            CustomReportLayout.SetFilter(Code, 'MS-EXT-*');
            if CustomReportLayout.FindLast() then
                LayoutCode := IncStr(CustomReportLayout.Code);
        end else
            LayoutCode := Row.Item('Code');

        CustomReportLayout.Reset();
        CustomReportLayout.Init();
        CustomReportLayout.Code := LayoutCode;
        CustomReportLayout."App ID" := ExtensionAppId;
        CustomReportLayout.Type := Row.Item('Type');
        CustomReportLayout."Custom XML Part" := Row.Item('CustomXMLPart');
        CustomReportLayout.Description := Row.Item('Description');
        CustomReportLayout.Layout := Row.Item('Layout');
        CustomReportLayout."Report ID" := Row.Item('ReportID');
        CustomReportLayout.CalcFields("Report Name");
        CustomReportLayout."Built-In" := true;
        CustomReportLayout.Insert();
    end;

    procedure HasLayout(): Boolean
    begin
        if "Built-In" then
            exit(HasBuiltInLayout());
        exit(HasNonBuiltInLayout());
    end;

    procedure HasCustomXmlPart(): Boolean
    begin
        if "Built-In" then
            exit(HasBuiltInCustomXmlPart());
        exit(HasNonBuiltInCustomXmlPart());
    end;

    procedure GetLayout(): Text
    begin
        if "Built-In" then
            exit(GetBuiltInLayout());
        exit(GetNonBuiltInLayout());
    end;

    procedure GetCustomXmlPart(): Text
    begin
        if "Built-In" then
            exit(GetBuiltInCustomXmlPart());
        exit(GetNonBuiltInCustomXmlPart());
    end;

    procedure GetLayoutBlob(var TempBlob: Codeunit "Temp Blob")
    var
        ReportLayout: Record "Report Layout";
    begin
        Clear(TempBlob);
        TempBlob.FromRecord(Rec, FieldNo(Layout));

        if "Built-In" then
            if not TempBlob.HasValue() then begin // not a built-in report from an extension
                ReportLayout.Get(Code);
                TempBlob.FromRecord(ReportLayout, ReportLayout.FieldNo(Layout));
            end;
    end;

    procedure ClearLayout()
    begin
        if "Built-In" then
            Error(ModifyBuiltInLayoutErr);
        SetNonBuiltInLayout('');
    end;

    procedure ClearCustomXmlPart()
    begin
        if "Built-In" then
            Error(ModifyBuiltInLayoutErr);
        SetNonBuiltInCustomXmlPart('');
    end;

    procedure CanModify(): Boolean
    var
        User: Record User;
        [SecurityFiltering(SecurityFilter::Ignored)]
        CustomReportLayout: Record "Custom Report Layout";
    begin
        if CurrentTransactionType() = TransactionType::Report then
            exit(false);
        if not CustomReportLayout.WritePermission() then
            exit(false);
        if not User.Get(UserSecurityId()) then
            exit(true);
        exit(User."License Type" <> User."License Type"::"Limited User");
    end;

    procedure TestLayout()
    var
        ReportLayout: Record "Report Layout";
    begin
        if not "Built-In" then begin
            CalcFields(Layout);
            TestField(Layout);
            exit;
        end;
        ReportLayout.Get(Code);
        ReportLayout.CalcFields(Layout);
        ReportLayout.TestField(Layout);
    end;

    procedure TestCustomXmlPart()
    var
        ReportLayout: Record "Report Layout";
    begin
        if not "Built-In" then begin
            CalcFields("Custom XML Part");
            TestField("Custom XML Part");
            exit;
        end;
        ReportLayout.Get(Code);
        ReportLayout.CalcFields("Custom XML Part");
        ReportLayout.TestField("Custom XML Part");
    end;

    procedure SetLayout(Content: Text)
    begin
        if "Built-In" then
            Error(ModifyBuiltInLayoutErr);
        SetNonBuiltInLayout(Content);
    end;

    procedure SetCustomXmlPart(Content: Text)
    begin
        if "Built-In" then
            Error(ModifyBuiltInLayoutErr);
        SetNonBuiltInCustomXmlPart(Content);
    end;

    procedure SetDefaultCustomXmlPart()
    begin
        SetCustomXmlPart(GetWordXmlPart("Report ID"));
    end;

    procedure SetLayoutBlob(var TempBlob: Codeunit "Temp Blob")
    var
        RecordRef: RecordRef;
    begin
        if "Built-In" then
            Error(ModifyBuiltInLayoutErr);
        Clear(Layout);
        if TempBlob.HasValue() then begin
            RecordRef.GetTable(Rec);
            TempBlob.ToRecordRef(RecordRef, FieldNo(Layout));
            RecordRef.SetTable(Rec);
        end;
        if CanModify() then
            Modify();
    end;

    local procedure HasNonBuiltInLayout(): Boolean
    begin
        CalcFields(Layout);
        exit(Layout.HasValue);
    end;

    local procedure HasNonBuiltInCustomXmlPart(): Boolean
    begin
        CalcFields("Custom XML Part");
        exit("Custom XML Part".HasValue);
    end;

    local procedure HasBuiltInLayout(): Boolean
    var
        ReportLayout: Record "Report Layout";
    begin
        if not ReportLayout.Get(Code) then
            exit(false);

        ReportLayout.CalcFields(Layout);
        exit(ReportLayout.Layout.HasValue);
    end;

    local procedure HasBuiltInCustomXmlPart(): Boolean
    var
        ReportLayout: Record "Report Layout";
    begin
        if not ReportLayout.Get(Code) then
            exit(false);

        ReportLayout.CalcFields("Custom XML Part");
        exit(ReportLayout."Custom XML Part".HasValue);
    end;

    local procedure GetNonBuiltInLayout(): Text
    var
        InStr: InStream;
        Content: Text;
    begin
        CalcFields(Layout);
        if not Layout.HasValue() then
            exit('');

        case Type of
            Type::RDLC:
                Layout.CreateInStream(InStr, TEXTENCODING::UTF8);
            Type::Word:
                Layout.CreateInStream(InStr);
            else
                OnGetNonBuiltInLayout(Rec, InStr);
        end;

        InStr.Read(Content);
        exit(Content);
    end;

    local procedure GetNonBuiltInCustomXmlPart(): Text
    var
        InStr: InStream;
        Content: Text;
    begin
        CalcFields("Custom XML Part");
        if not "Custom XML Part".HasValue() then
            exit('');

        "Custom XML Part".CreateInStream(InStr, TEXTENCODING::UTF16);
        InStr.Read(Content);
        exit(Content);
    end;

    local procedure GetBuiltInLayout(): Text
    var
        ReportLayout: Record "Report Layout";
        InStr: InStream;
        Content: Text;
    begin
        if not ReportLayout.Get(Code) then
            exit('');

        ReportLayout.CalcFields(Layout);
        if not ReportLayout.Layout.HasValue() then
            exit('');

        case Type of
            Type::RDLC:
                ReportLayout.Layout.CreateInStream(InStr, TEXTENCODING::UTF8);
            Type::Word:
                ReportLayout.Layout.CreateInStream(InStr);
        end;

        InStr.Read(Content);
        exit(Content);
    end;

    local procedure GetBuiltInCustomXmlPart(): Text
    var
        ReportLayout: Record "Report Layout";
        InStr: InStream;
        Content: Text;
    begin
        if not ReportLayout.Get(Code) then
            exit('');

        ReportLayout.CalcFields("Custom XML Part");
        if not ReportLayout."Custom XML Part".HasValue() then
            exit('');

        ReportLayout."Custom XML Part".CreateInStream(InStr, TEXTENCODING::UTF16);
        InStr.Read(Content);
        exit(Content);
    end;

    local procedure SetNonBuiltInLayout(Content: Text)
    var
        OutStr: OutStream;
    begin
        Clear(Layout);
        if Content <> '' then begin
            case Type of
                Type::RDLC:
                    Layout.CreateOutStream(OutStr, TEXTENCODING::UTF8);
                Type::Word:
                    Layout.CreateOutStream(OutStr);
            end;
            OutStr.Write(Content);
        end;
        if CanModify() then
            Modify();
    end;

    local procedure SetNonBuiltInCustomXmlPart(Content: Text)
    var
        OutStr: OutStream;
    begin
        Clear("Custom XML Part");
        if Content <> '' then begin
            "Custom XML Part".CreateOutStream(OutStr, TEXTENCODING::UTF16);
            OutStr.Write(Content);
        end;

        if CanModify() then
            Modify();
    end;

    internal procedure SetLayoutLastUpdated()
    begin
        "Layout Last Updated" := RoundDateTime(CurrentDateTime);

        if CanModify() then
            Rec.Modify();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCanBeModified(var CustomReportLayout: Record "Custom Report Layout"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateLayout(var LayoutUpdated: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExportReportLayout(CustomReportLayout: Record "Custom Report Layout"; var DefaultFileName: Text; ShowFileDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExportSchema(CustomReportLayout: Record "Custom Report Layout"; var DefaultFileName: Text; ShowFileDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRecordOnBeforeInsertLayout(var ToCustomReportLayout: Record "Custom Report Layout"; FromCustomReportLayout: Record "Custom Report Layout")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetNonBuiltInLayout(CustomReportLayout: Record "Custom Report Layout"; var InStream: InStream)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetFileExtension(CustomReportLayout: Record "Custom Report Layout"; var FileExt: Text[4])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnImportLayoutBlob(CustomReportLayout: Record "Custom Report Layout"; var TempBlob: Codeunit "Temp Blob"; FileExtension: Text[30]; XmlPart: Text; DocumentOutStream: OutStream)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnImportLayoutSetFileFilter(CustomReportLayout: Record "Custom Report Layout"; var FileFilterTxt: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitBuiltInLayout(var CustomReportLayout: Record "Custom Report Layout"; ReportID: Integer; LayoutType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupLayoutOKOnBeforePageRun(var CustomReportLayout: Record "Custom Report Layout")
    begin
    end;
}
