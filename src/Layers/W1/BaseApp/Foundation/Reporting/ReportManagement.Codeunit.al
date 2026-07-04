// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using System.Device;
using System.Environment;
using System.Environment.Configuration;
using System.Reflection;
using System.Text;
using System.Utilities;

codeunit 44 ReportManagement
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        NotSupportedErr: Label 'The value is not supported.';
        NoWritePermissionsErr: Label 'Unable to set the default printer. You need write (Insert, Modify and Delete) permission for the Printer Selection table.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'GetPrinterName', '', false, false)]
    local procedure GetPrinterNameSubscriber(ReportID: Integer; var PrinterName: Text[250])
    begin
        GetPrinterName(ReportID, PrinterName);
    end;

    procedure GetPrinterName(ReportID: Integer; var PrinterName: Text[250])
    var
        PrinterSelection: Record "Printer Selection";
    begin
        Clear(PrinterSelection);

        if PrinterSelection.ReadPermission then
            if not PrinterSelection.Get(UserId, ReportID) then
                if not PrinterSelection.Get('', ReportID) then
                    if not PrinterSelection.Get(UserId, 0) then
                        if PrinterSelection.Get('', 0) then;
        PrinterName := PrinterSelection."Printer Name";

        OnAfterGetPrinterName(ReportID, PrinterName, PrinterSelection);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Printer Setup", 'OnSetAsDefaultPrinter', '', false, false)]
    local procedure OnSetAsDefaultPrinterForCurrentUser(PrinterID: Text; UserID: Text; var IsHandled: Boolean)
    var
        PrinterSelection: Record "Printer Selection";
        [SecurityFiltering(SecurityFilter::Ignored)]
        PrinterSelection2: Record "Printer Selection";
    begin
        if IsHandled then
            exit;

        if not PrinterSelection2.WritePermission then
            Error(NoWritePermissionsErr);

        if PrinterSelection.Get(UserID, 0) then begin
            PrinterSelection."Printer Name" := CopyStr(PrinterID, 1, MaxStrLen((PrinterSelection."Printer Name")));
            PrinterSelection.Modify(true);
        end else begin
            PrinterSelection.Validate("User ID", UserID);
            PrinterSelection.Validate("Report ID", 0);
            PrinterSelection."Printer Name" := CopyStr(PrinterID, 1, MaxStrLen((PrinterSelection."Printer Name")));
            PrinterSelection.Insert(true);
        end;

        IsHandled := true;
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Printer Setup", 'GetPrinterSelectionsPage', '', false, false)]
    procedure GetPrinterSelectionsPage(var PageID: Integer; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;
        PageID := Page::"Printer Selections";
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'GetPaperTrayForReport', '', false, false)]
    local procedure GetPaperTrayForReport(ReportID: Integer; var FirstPage: Integer; var DefaultPage: Integer; var LastPage: Integer)
    begin
        OnAfterGetPaperTrayForReport(ReportID, FirstPage, DefaultPage, LastPage)
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'HasCustomLayout', '', false, false)]
    local procedure HasCustomLayout(ObjectType: Option "Report","Page"; ObjectID: Integer; var LayoutType: Option "None",RDLC,Word,Excel,Custom)
    var
    begin
        if ObjectType <> ObjectType::Report then
            Error(NotSupportedErr);
        OnAfterHasCustomLayout(ObjectType, ObjectID, LayoutType);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'CustomDocumentMergerEx', '', false, false)]
    local procedure CustomDocumentMergerEx(ObjectID: Integer; ReportAction: Option SaveAsPdf,SaveAsWord,SaveAsExcel,Preview,Print,SaveAsHtml; ObjectPayload: JsonObject; XmlData: InStream; LayoutData: InStream; var DocumentStream: OutStream; var Success: Boolean)
    begin
        if (Success) then
            exit;

        OnCustomDocumentMergerEx(ObjectID, ReportAction, ObjectPayload, XmlData, LayoutData, DocumentStream, Success);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'SelectedBuiltinLayoutType', '', false, false)]
    local procedure SelectedBuiltinLayoutType(ObjectID: Integer; var LayoutType: Option "None",RDLC,Word,Excel,Custom)
    var
        ReportLayoutSelection: Record "Report Layout Selection";
    begin
        LayoutType := ReportLayoutSelection.SelectedBuiltinLayoutType(ObjectID);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'SubstituteReport', '', false, false)]
    local procedure SubstituteReport(ReportId: Integer; RunMode: Option Normal,ParametersOnly,Execute,Print,SaveAs,RunModal; RequestPageXml: Text; RecordRef: RecordRef; var NewReportId: Integer)
    begin
        OnAfterSubstituteReport(ReportId, RunMode, RequestPageXml, RecordRef, NewReportId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'OnDocumentPrintReady', '', false, false)]
    local procedure OnDocumentPrintReady(ObjectType: Option "Report","Page"; ObjectID: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var Success: Boolean);
    begin
        if ObjectType <> ObjectType::Report then
            Error(NotSupportedErr);

        OnAfterDocumentPrintReady(ObjectType, ObjectId, ObjectPayload, DocumentStream, Success);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'SetupPrinters', '', true, true)]
    procedure SetupPrinters(var Printers: Dictionary of [Text[250], JsonObject]);
    begin
        OnAfterSetupPrinters(Printers);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'OnIntermediateDocumentReady', '', false, false)]
    local procedure OnIntermediateDocumentReady(ObjectId: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var TargetStream: OutStream; var Success: Boolean)
    begin
        OnAfterIntermediateDocumentReady(ObjectId, ObjectPayload, DocumentStream, TargetStream, Success);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'OnDocumentReady', '', false, false)]
    local procedure OnDocumentReady(ObjectId: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var TargetStream: OutStream; var Success: Boolean)
    begin
        OnAfterDocumentReady(ObjectId, ObjectPayload, DocumentStream, TargetStream, Success);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'OnDocumentDownload', '', false, false)]
    local procedure OnDocumentDownload(ObjectId: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var Success: Boolean)
    begin
        OnAfterDocumentDownload(ObjectId, ObjectPayload, DocumentStream, Success);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'SelectReportLayoutCode', '', false, false)]
    local procedure SelectReportLayoutCode(ObjectId: Integer; var LayoutCode: Text; var LayoutType: Option "None",RDLC,Word,Excel,Custom; var Success: Boolean)
    var
        CustomReportLayout: Record "Custom Report Layout";
        FeatureKey: Record "Feature Key";
        ReportLayoutSelection: Record "Report Layout Selection";
        DesignTimeReportSelection: Codeunit "Design-time Report Selection";
        AppLayoutType: Enum "Custom Report Layout Type";
        SelectedLayoutName: Text[250];
        SelectedAppID: Guid;
        PlatformRenderingInPlatformTxt: Label 'RenderWordReportsInPlatform', Locked = true;
    begin
        OnSelectReportLayoutCode(ObjectId, LayoutCode, LayoutType, Success);
        if Success then
            exit;

        LayoutType := LayoutType::None; // Unknown layout type
        SelectedLayoutName := DesignTimeReportSelection.GetSelectedLayout();
        SelectedAppID := DesignTimeReportSelection.GetSelectedAppID();

        // Temporarily selected layout for Design-time report execution or for looping in batch report scenarios?
        if SelectedLayoutName = '' then
            // look in the app layout selection table for a selected layout for this report id.
            if ReportLayoutSelection.Get(ObjectId, CompanyName) and
               (ReportLayoutSelection.Type = ReportLayoutSelection.Type::"Custom Layout")
            then
                SelectedLayoutName := ReportLayoutSelection."Custom Report Layout Code";

        if (SelectedLayoutName <> '') and (StrLen(SelectedLayoutName) <= MaxStrLen(CustomReportLayout."Code")) then
            // The code field in Custom Report Layout table can have a maximum size of 20 characters.
            if CustomReportLayout.Get(SelectedLayoutName.ToUpper()) then begin
                LayoutCode := CustomReportLayout.Code;
                AppLayoutType := CustomReportLayout.Type;
                case AppLayoutType of
                    AppLayoutType::RDLC:
                        LayoutType := LayoutType::RDLC;
                    AppLayoutType::Word:
                        LayoutType := LayoutType::Word;
                    else
                        // Layout Type extensions
                        if (FeatureKey.Get(PlatformRenderingInPlatformTxt) and (FeatureKey.Enabled = FeatureKey.Enabled::"All Users")) then
                            // Platform rendering - The OnCustomDocumentMerger event will handle the rendering logic
                            LayoutType := LayoutType::Custom
                        else
                            // App rendering - The type will be treated like a word file and rendered by the app.
                            LayoutType := LayoutType::Word;
                end;
                Success := true;
                exit;
            end;

        if SelectedLayoutName <> '' then begin
            // A layout code is defined, but not found in application table. The layout type is not known and it's expected that the code refers to a layout in the platform. 
            // Return the layout code to platform for further processing.
            if IsNullGuid(SelectedAppID) then
                LayoutCode := SelectedLayoutName
            else
                LayoutCode := SelectedLayoutName + '::' + Format(SelectedAppID);

            Success := true;
        end;
        DesignTimeReportSelection.ClearLayoutSelection();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'FetchReportLayoutByCode', '', false, false)]
    local procedure FetchReportLayoutByCode(ObjectId: Integer; LayoutCode: Text; var TargetStream: OutStream; var Success: Boolean)
    var
        CustomReportLayout: Record "Custom Report Layout";
        TempBlobIn: codeunit "Temp Blob";
        TempInStream: InStream;
    begin
        OnFetchReportLayoutByCode(ObjectId, LayoutCode, TargetStream, Success);
        if Success then
            exit;

        if not CustomReportLayout.Get(LayoutCode) then
            LayoutCode := '';

        if LayoutCode <> '' then begin
            CustomReportLayout.GetLayoutBlob(TempBlobIn);
            TempBlobIn.CreateInStream(TempInStream);
            CopyStream(TargetStream, TempInStream);
            Success := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'SelectReportLayoutUI', '', false, false)]
    local procedure SelectReportLayoutUI(ObjectID: Integer; var LayoutName: Text; var LayoutAppID: Guid; var Success: Boolean)
    var
        ReportLayoutList: Record "Report Layout List";
        IsSelectionHandled: Boolean;
    begin
        ReportLayoutList.SetRange(ReportLayoutList."Report ID", ObjectID);
        OnSelectReportLayout(ReportLayoutList, IsSelectionHandled);

        if IsSelectionHandled and (ReportLayoutList."Report ID" = ObjectID) then begin
            LayoutName := ReportLayoutList."Name";
            LayoutAppID := ReportLayoutList."Application ID";
            Success := true;
        end;

        OnAfterSelectReportLayoutUI(ObjectID, LayoutName, LayoutAppID, Success);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'GetFilename', '', false, false)]
    local procedure GetFilename(ReportID: Integer; Caption: Text[250]; ObjectPayload: JsonObject; FileExtension: Text[30]; ReportRecordRef: RecordRef; var Filename: Text; var Success: Boolean)
    begin
        if Success then
            exit;

        OnGetFilename(ReportID, Caption, ObjectPayload, FileExtension, ReportRecordRef, Filename, Success);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'GetCompanyMetadata', '', false, false)]
    local procedure GetCompanyMetadataSubscriber(ReportId: Integer; var CompanyMetadata: JsonObject)
    begin
        GetCompanyMetadata(CompanyMetadata);
    end;

    /// <summary>
    /// Populates the shared CompanyMetadata payload from Company Information for the report layouts'
    /// company block. Empty-safe: with no Company Information record the fields are emitted blank
    /// rather than erroring. Public so it can be invoked/verified directly; extension and
    /// localization fields are added by subscribing to the platform GetCompanyMetadata event
    /// directly (the payload is additive), so no BaseApp OnAfter event is exposed here.
    /// </summary>
    /// <param name="CompanyMetadata">The JSON object to merge the company payload into; existing keys with the same names are overwritten.</param>
    [InherentPermissions(PermissionObjectType::TableData, Database::"Company Information", 'r')]
    procedure GetCompanyMetadata(var CompanyMetadata: JsonObject)
    var
        CompanyInfo: Record "Company Information";
        FormatAddress: Codeunit "Format Address";
        CompanyMetadataBuilder: Codeunit "Company Metadata Builder";
        AddrArray: array[8] of Text[100];
        Index: Integer;
    begin
        if not CompanyInfo.Get() then
            CompanyInfo.Init();

        CompanyMetadataBuilder.SetName(CompanyInfo.Name);
        CompanyMetadataBuilder.SetDisplayName(GetCompanyDisplayName());

        FormatAddress.Company(AddrArray, CompanyInfo);
        for Index := 1 to ArrayLen(AddrArray) do
            CompanyMetadataBuilder.AddAddressLine(AddrArray[Index]);

        CompanyMetadataBuilder.SetPhone(CompanyInfo."Phone No.");
        CompanyMetadataBuilder.SetPhoneCaption(CompanyInfo.FieldCaption("Phone No."));
        CompanyMetadataBuilder.SetFaxNo(CompanyInfo."Fax No.");
        CompanyMetadataBuilder.SetFaxNoCaption(CompanyInfo.FieldCaption("Fax No."));
        CompanyMetadataBuilder.SetEmail(CompanyInfo."E-Mail");
        CompanyMetadataBuilder.SetEmailCaption(CompanyInfo.FieldCaption("E-Mail"));
        CompanyMetadataBuilder.SetHomePage(CompanyInfo."Home Page");
        CompanyMetadataBuilder.SetHomePageCaption(CompanyInfo.FieldCaption("Home Page"));
        CompanyMetadataBuilder.SetLogo(GetLogoBase64(CompanyInfo));
        CompanyMetadataBuilder.SetVATRegistrationNo(CompanyInfo."VAT Registration No.");
        CompanyMetadataBuilder.SetVATRegistrationNoCaption(CompanyInfo.FieldCaption("VAT Registration No."));
        CompanyMetadataBuilder.SetRegistrationNo(CompanyInfo."Registration No.");
        CompanyMetadataBuilder.SetRegistrationNoCaption(CompanyInfo.FieldCaption("Registration No."));
        CompanyMetadataBuilder.SetBankName(CompanyInfo."Bank Name");
        CompanyMetadataBuilder.SetBankNameCaption(CompanyInfo.FieldCaption("Bank Name"));
        CompanyMetadataBuilder.SetBankAccountNo(CompanyInfo."Bank Account No.");
        CompanyMetadataBuilder.SetBankAccountNoCaption(CompanyInfo.FieldCaption("Bank Account No."));
        CompanyMetadataBuilder.SetBankBranchNo(CompanyInfo."Bank Branch No.");
        CompanyMetadataBuilder.SetBankBranchNoCaption(CompanyInfo.FieldCaption("Bank Branch No."));
        CompanyMetadataBuilder.SetIBAN(CompanyInfo.IBAN);
        CompanyMetadataBuilder.SetIBANCaption(CompanyInfo.FieldCaption(IBAN));
        CompanyMetadataBuilder.SetBankSWIFT(CompanyInfo."SWIFT Code");
        CompanyMetadataBuilder.SetBankSWIFTCaption(CompanyInfo.FieldCaption("SWIFT Code"));
        CompanyMetadataBuilder.SetGiroNo(CompanyInfo."Giro No.");
        CompanyMetadataBuilder.SetGiroNoCaption(CompanyInfo.FieldCaption("Giro No."));

        CompanyMetadataBuilder.WriteTo(CompanyMetadata);
    end;

    /// <summary>
    /// Company display name, mirroring how the platform builds ReportRequest/CompanyDisplayName
    /// (ReportRequestXmlRuntime): the tenant Company record's display name
    /// (CompanyProperty.DisplayName() -> session.Company.CompanyDisplayName), falling back to the
    /// company name when the display name is blank. NOT Company Information."Name 2".
    /// </summary>
    local procedure GetCompanyDisplayName(): Text
    var
        DisplayName: Text;
    begin
        DisplayName := CompanyProperty.DisplayName();
        if DisplayName = '' then
            DisplayName := CompanyName();
        exit(DisplayName);
    end;

    local procedure GetLogoBase64(var CompanyInfo: Record "Company Information"): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        InStr: InStream;
    begin
        // Use the Ok return: CalcFields on a BLOB re-reads the row and raises a runtime error when
        // the record does not exist (the CompanyInfo.Init() path), which would break the empty-safe
        // contract of GetCompanyMetadata.
        if not CompanyInfo.CalcFields(Picture) then
            exit('');
        if not CompanyInfo.Picture.HasValue() then
            exit('');
        CompanyInfo.Picture.CreateInStream(InStr);
        exit(Base64Convert.ToBase64(InStr));
    end;

    [IntegrationEvent(false, false)]
    procedure OnSelectReportLayout(var ReportLayoutList: Record "Report Layout List"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSelectReportLayoutUI(ObjectID: Integer; var LayoutName: Text; var LayoutAppID: Guid; Success: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPrinterName(ReportID: Integer; var PrinterName: Text[250]; PrinterSelection: Record "Printer Selection")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHasCustomLayout(ObjectType: Option "Report","Page"; ObjectID: Integer; var LayoutType: Option "None",RDLC,Word,Excel,Custom)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPaperTrayForReport(ReportID: Integer; var FirstPage: Integer; var DefaultPage: Integer; var LastPage: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSubstituteReport(ReportId: Integer; RunMode: Option Normal,ParametersOnly,Execute,Print,SaveAs,RunModal; RequestPageXml: Text; RecordRef: RecordRef; var NewReportId: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDocumentPrintReady(ObjectType: Option "Report","Page"; ObjectID: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var Success: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetupPrinters(var Printers: Dictionary of [Text[250], JsonObject]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIntermediateDocumentReady(ObjectId: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var TargetStream: OutStream; var Success: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDocumentReady(ObjectId: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var TargetStream: OutStream; var Success: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDocumentDownload(ObjectId: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var Success: Boolean)
    begin
    end;

    /// <summary>
    /// Invoke the OnCustomDocumentMergeEx trigger, which handled user defiend report renders given a dataset and a layout. The Render must be implemented in AL and return the output stream as defined by the format given in ReportAction.
    /// </summary>
    /// <param name="ObjectId">The report object id.</param>
    /// <param name="ReportAction">The report action, which can be one of SaveAsPdf, SaveAsWord, SaveAsExcel, Preview, Print or SaveAsHtml.</param>
    /// <param name="ObjectPayload">The JSON payload that defines metadata for the present report run.</param>
    /// <param name="XmlData">The xml data set in an input stream</param>
    /// <param name="LayoutData">The layout input stream. The actual format stored in the stream is defined by the layoutmodel json property (custom formats by the layoutmimetype property in the payload).</param>
    /// <param name="DocumentStream">Output stream that will contain the rendered output documents.</param>
    /// <param name="IsHandled">Will be set to true if the procedure call handled the merge.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCustomDocumentMergerEx(ObjectID: Integer; ReportAction: Option SaveAsPdf,SaveAsWord,SaveAsExcel,Preview,Print,SaveAsHtml; ObjectPayload: JsonObject; var XmlData: InStream; LayoutData: InStream; var DocumentStream: OutStream; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Fetch the currently selected layout code and layout type from application.
    /// </summary>
    /// <param name="ObjectId">The object id.</param>
    /// <param name="LayoutCode">The report layout code if an application override has been set for the current run.</param>
    /// <param name="LayoutType">The Layout type contained in the target stream.</param>
    /// <param name="IsHandled">Will be set to true if the subscriber handled the action.</param>
    /// <remarks>Internal event that will be removed when the report runtime API has been updated</remarks>
    [IntegrationEvent(false, false)]
    local procedure OnSelectReportLayoutCode(ObjectId: Integer; var LayoutCode: Text; var LayoutType: Option "None",RDLC,Word,Excel,Custom; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Fetch the currently selected layout code from application.
    /// </summary>
    /// <param name="ObjectId">The object id.</param>
    /// <param name="LayoutCode">The report layout code if an application override has been set for the current run.</param>
    /// <param name="TargetStream">The layout will be written to this stream.</param>
    /// <param name="IsHandled">Will be set to true if the layout was found in the application database.</param>
    /// <remarks>Internal event that will be removed when the report runtime API has been updated.</remarks>
    [IntegrationEvent(false, false)]
    local procedure OnFetchReportLayoutByCode(ObjectId: Integer; LayoutCode: Text; var TargetStream: OutStream; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetFilename(ReportID: Integer; Caption: Text[250]; ObjectPayload: JsonObject; FileExtension: Text[30]; ReportRecordRef: RecordRef; var Filename: Text; var Success: Boolean)
    begin
    end;
}
