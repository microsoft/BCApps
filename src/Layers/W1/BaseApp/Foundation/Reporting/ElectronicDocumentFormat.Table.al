// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using Microsoft.Projects.Project.Job;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Peppol;
using System.IO;
using System.Reflection;
using System.Telemetry;
using System.Utilities;

table 61 "Electronic Document Format"
{
    Caption = 'Electronic Document Format';
    LookupPageID = "Electronic Document Format";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Usage; Enum "Electronic Document Format Usage")
        {
            Caption = 'Usage';
        }
        field(4; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(5; "Codeunit ID"; Integer)
        {
            BlankZero = true;
            Caption = 'Codeunit ID';
            NotBlank = true;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Codeunit));

            trigger OnValidate()
            var
                PEPPOLManagement: Codeunit "PEPPOL Management";
                FeatureTelemetry: Codeunit "Feature Telemetry";
            begin
                if ShouldLogUptake() then begin
                    FeatureTelemetry.LogUptake('0000KOQ', PEPPOLManagement.GetPeppolTelemetryTok(), Enum::"Feature Uptake Status"::Discovered);
                    FeatureTelemetry.LogUptake('0000KOR', PEPPOLManagement.GetPeppolTelemetryTok(), Enum::"Feature Uptake Status"::"Set up");
                end;
            end;
        }
        field(6; "Codeunit Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Codeunit),
                                                                           "Object ID" = field("Codeunit ID")));
            Caption = 'Codeunit Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Delivery Codeunit ID"; Integer)
        {
            BlankZero = true;
            Caption = 'Delivery Codeunit ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Codeunit));
        }
        field(8; "Delivery Codeunit Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Codeunit),
                                                                           "Object ID" = field("Delivery Codeunit ID")));
            Caption = 'Delivery Codeunit Caption';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Code", Usage)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        CheckCodeunitExist();
    end;

    trigger OnModify()
    begin
        CheckCodeunitExist();
    end;

    var
        DataCompression: Codeunit "Data Compression";

        UnSupportedTableTypeErr: Label 'The %1 table is not supported.', Comment = '%1 = Sales Document Type';
        NonExistingDocumentFormatErr: Label 'The electronic document format %1 does not exist for the document type %2.', Comment = '%1 : document format, %2 document use eq Invoice';
        UnSupportedDocumentTypeErr: Label 'The document type %1 is not supported.', Comment = '%1 : document ytp eq Invocie ';
        ElectronicDocumentNotCreatedErr: Label 'The electronic document has not been created.';
        ElectronicFormatErr: Label 'The electronic format %1 does not exist.', Comment = '%1=Specified Electronic Format';

    procedure SendElectronically(var TempBlob: Codeunit "Temp Blob"; var ClientFileName: Text[250]; DocumentVariant: Variant; ElectronicFormat: Code[20])
    var
        RecordExportBuffer: Record "Record Export Buffer";
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessage: Record "Error Message";
        EntryTempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        EntryFileInStream: InStream;
        ZipFileOutStream: OutStream;
        DocumentUsage: Enum "Electronic Document Format Usage";
        StartID: Integer;
        EndID: Integer;
        IsMissingFileContent: Boolean;
    begin
        GetDocumentFormatUsage(DocumentUsage, DocumentVariant);

        if not Get(ElectronicFormat, DocumentUsage) then begin
            Usage := DocumentUsage;
            Error(NonExistingDocumentFormatErr, ElectronicFormat, Format(Usage));
        end;

        RecRef.GetTable(DocumentVariant);
        OnSendElectronicallyOnAfterRecRefGetTable(Rec, RecRef);

        StartID := 0;
        RecordExportBuffer.LockTable();
        if RecRef.FindSet() then
            repeat
                Clear(RecordExportBuffer);
                RecordExportBuffer.RecordID := RecRef.RecordId;
                RecordExportBuffer.ClientFileName :=
                  GetAttachmentFileName(RecRef, GetDocumentNo(RecRef), GetDocumentType(RecRef), 'xml');
                RecordExportBuffer.ZipFileName :=
                  GetAttachmentFileName(RecRef, GetDocumentNo(RecRef), GetDocumentType(RecRef), 'zip');
                OnSendElectronicallyOnBeforeRecordExportBufferInsert(RecordExportBuffer, RecRef);
                RecordExportBuffer.Insert(true);
                if StartID = 0 then
                    StartID := RecordExportBuffer.ID;
                EndID := RecordExportBuffer.ID;
            until RecRef.Next() = 0;

        RecordExportBuffer.SetRange(ID, StartID, EndID);
        if RecordExportBuffer.FindSet() then
            repeat
                ErrorMessage.SetContext(RecordExportBuffer);
                ErrorMessage.ClearLog();

                CODEUNIT.Run("Codeunit ID", RecordExportBuffer);

                TempErrorMessage.CopyFromContext(RecordExportBuffer);
                ErrorMessage.ClearLog(); // Clean up

                if not RecordExportBuffer."File Content".HasValue() then
                    IsMissingFileContent := true;
            until RecordExportBuffer.Next() = 0;

        // Display errors in case anything went wrong.
        TempErrorMessage.ShowErrorMessages(true);
        if IsMissingFileContent then
            Error(ElectronicDocumentNotCreatedErr);

        if RecordExportBuffer.Count > 1 then begin
            TempBlob.CreateOutStream(ZipFileOutStream);
            DataCompression.CreateZipArchive();
            ClientFileName := CopyStr(RecordExportBuffer.ZipFileName, 1, 250);
            RecordExportBuffer.FindSet();
            repeat
                RecordExportBuffer.GetFileContent(EntryTempBlob);
                EntryTempBlob.CreateInStream(EntryFileInStream);
                DataCompression.AddEntry(EntryFileInStream, RecordExportBuffer.ClientFileName);
            until RecordExportBuffer.Next() = 0;
            DataCompression.SaveZipArchive(ZipFileOutStream);
            DataCompression.CloseZipArchive();
        end else
            if RecordExportBuffer.FindFirst() then begin
                RecordExportBuffer.GetFileContent(TempBlob);
                ClientFileName := RecordExportBuffer.ClientFileName;
            end;

        OnSendElectronicallyOnBeforeDeleteAll(RecordExportBuffer, ClientFileName, DocumentVariant);

        RecordExportBuffer.DeleteAll();
    end;

#if not CLEAN25
    [Obsolete('Replaced by same procedure in codeunit "Serv. Electr. Doc. Format"', '25.0')]
    procedure ValidateElectronicServiceDocument(ServiceHeader: Record Microsoft.Service.Document."Service Header"; ElectronicFormat: Code[20])
    var
        ServElectrDocFormat: Codeunit "Serv. Electr. Doc. Format";
    begin
        ServElectrDocFormat.ValidateElectronicServiceDocument(ServiceHeader, ElectronicFormat);
    end;
#endif

    procedure ValidateElectronicSalesDocument(SalesHeader: Record "Sales Header"; ElectronicFormat: Code[20])
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        if not ElectronicDocumentFormat.Get(ElectronicFormat, Usage::"Sales Validation") then
            exit; // no validation required

        CODEUNIT.Run(ElectronicDocumentFormat."Codeunit ID", SalesHeader);
    end;

    procedure ValidateElectronicJobsDocument(Job: Record Job; ElectronicFormat: Code[20])
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        if not ElectronicDocumentFormat.Get(ElectronicFormat, Usage::"Job Quote") then
            exit; // no validation required

        CODEUNIT.Run(ElectronicDocumentFormat."Codeunit ID", Job);
    end;

    procedure ValidateElectronicJobTasksDocument(JobTask: Record "Job Task"; ElectronicFormat: Code[20])
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        if not ElectronicDocumentFormat.Get(ElectronicFormat, Usage::"Job Task Quote") then
            exit; // no validation required

        CODEUNIT.Run(ElectronicDocumentFormat."Codeunit ID", JobTask);
    end;

    procedure GetAttachmentFileName(RecordVariant: Variant; DocumentNo: Code[20]; DocumentType: Text; Extension: Code[3]) FileName: Text[250]
    var
        FileMgt: Codeunit "File Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetAttachmentFileName(RecordVariant, DocumentNo, DocumentType, Extension, IsHandled, FileName);
        if not IsHandled then
            FileName :=
                CopyStr(
                    StrSubstNo('%1 - %2 %3.%4', FileMgt.StripNotsupportChrInFileName(CompanyName), DocumentType, DocumentNo, Extension), 1, 250);
    end;

#if not CLEAN25
    [Obsolete('Replaced by GetDocumentFormatUsage() with enum parameter', '25.0')]
    procedure GetDocumentUsage(var DocumentUsage: Option; DocumentVariant: Variant)
    var
        DocumentFormatUsage: Enum "Electronic Document Format Usage";
    begin
        DocumentFormatUsage := "Electronic Document Format Usage".FromInteger(DocumentUsage);
        GetDocumentFormatUsage(DocumentFormatUsage, DocumentVariant);
        DocumentUsage := DocumentFormatUsage.AsInteger();
    end;
#endif

    procedure GetDocumentFormatUsage(var DocumentFormatUsage: Enum "Electronic Document Format Usage"; DocumentVariant: Variant)
    var
        DocumentRecordRef: RecordRef;
#if not CLEAN25
        DocumentUsage: Option;
#endif
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDocumentFormatUsage(Rec, DocumentVariant, DocumentFormatUsage, IsHandled);
#if not CLEAN25
        DocumentUsage := DocumentFormatUsage.AsInteger();
        OnBeforeGetDocumentUsage(Rec, DocumentVariant, DocumentUsage, IsHandled);
        DocumentFormatUsage := "Electronic Document Format Usage".FromInteger(DocumentUsage);
#endif
        if IsHandled then
            exit;

        DocumentRecordRef.GetTable(DocumentVariant);
        case DocumentRecordRef.Number of
            Database::"Sales Invoice Header":
                DocumentFormatUsage := DocumentFormatUsage::"Sales Invoice";
            Database::"Sales Cr.Memo Header":
                DocumentFormatUsage := DocumentFormatUsage::"Sales Credit Memo";
            Database::"Sales Header":
                GetDocumentUsageForSalesHeader(DocumentFormatUsage, DocumentVariant);
            Database::Job:
                DocumentFormatUsage := DocumentFormatUsage::"Job Quote";
            Database::"Job Task":
                DocumentFormatUsage := DocumentFormatUsage::"Job Task Quote";
            else begin
                IsHandled := false;
                OnGetDocumentFormatUsageCaseElse(DocumentRecordRef, DocumentFormatUsage, IsHandled);
                if not IsHandled then
                    Error(UnSupportedTableTypeErr, DocumentRecordRef.Caption);
            end;
        end;
    end;

    procedure GetDocumentNo(DocumentVariant: Variant): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        Job: Record Job;
        DocumentRecordRef: RecordRef;
        DocumentNo: Code[20];
        IsHandled: Boolean;
    begin
        if DocumentVariant.IsRecord then
            DocumentRecordRef.GetTable(DocumentVariant)
        else
            if DocumentVariant.IsRecordRef then
                DocumentRecordRef := DocumentVariant;

        case DocumentRecordRef.Number of
            DATABASE::"Sales Invoice Header":
                begin
                    SalesInvoiceHeader := DocumentVariant;
                    exit(SalesInvoiceHeader."No.");
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    SalesCrMemoHeader := DocumentVariant;
                    exit(SalesCrMemoHeader."No.");
                end;
            DATABASE::"Sales Header":
                begin
                    SalesHeader := DocumentVariant;
                    exit(SalesHeader."No.");
                end;
            DATABASE::Job:
                begin
                    Job := DocumentVariant;
                    exit(Job."No.");
                end;
            else begin
                IsHandled := false;
                OnGetDocumentNoCaseElse(DocumentVariant, DocumentNo, IsHandled, DocumentRecordRef);
                if IsHandled then
                    exit(DocumentNo);

                Error(UnSupportedTableTypeErr, DocumentRecordRef.Caption);
            end;
        end;
    end;

    local procedure GetDocumentUsageForSalesHeader(var DocumentFormatUsage: Enum "Electronic Document Format Usage"; SalesHeader: Record "Sales Header")
    var
#if not CLEAN25
        DocumentUsage: Option;
#endif
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDocumentFormatUsageForSalesHeader(Rec, SalesHeader, DocumentFormatUsage, IsHandled);
#if not CLEAN25
        DocumentUsage := DocumentFormatUsage.AsInteger();
        OnBeforeGetDocumentUsageForSalesHeader(Rec, SalesHeader, DocumentUsage, IsHandled);
        DocumentFormatUsage := "Electronic Document Format Usage".FromInteger(DocumentUsage);
#endif
        if IsHandled then
            exit;

        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Order:
                exit;
            SalesHeader."Document Type"::Invoice:
                DocumentFormatUsage := Usage::"Sales Invoice";
            SalesHeader."Document Type"::"Credit Memo":
                DocumentFormatUsage := Usage::"Sales Credit Memo";
            else
                Error(UnSupportedDocumentTypeErr, Format(SalesHeader."Document Type"));
        end;
    end;

    local procedure CheckCodeunitExist()
    var
        AllObj: Record AllObj;
    begin
        AllObj.Get(AllObj."Object Type"::Codeunit, "Codeunit ID");
    end;

    procedure ValidateElectronicFormat(ElectronicFormat: Code[20])
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        ElectronicDocumentFormat.SetRange(Code, ElectronicFormat);
        if ElectronicDocumentFormat.IsEmpty() then
            Error(ElectronicFormatErr, ElectronicFormat);
    end;

    procedure GetDocumentType(DocumentVariant: Variant) DocumentTypeText: Text[50]
    var
        DummySalesHeader: Record "Sales Header";
        TranslationHelper: Codeunit "Translation Helper";
        ReportDistributionManagement: Codeunit "Report Distribution Management";
        DocumentRecordRef: RecordRef;
    begin
        TranslationHelper.SetGlobalLanguageByCode(ReportDistributionManagement.GetDocumentLanguageCode(DocumentVariant));

        if DocumentVariant.IsRecord then
            DocumentRecordRef.GetTable(DocumentVariant)
        else
            if DocumentVariant.IsRecordRef then
                DocumentRecordRef := DocumentVariant;
        case DocumentRecordRef.Number of
            DATABASE::"Sales Invoice Header":
                DocumentTypeText := Format("Sales Document Type"::Invoice);
            DATABASE::"Sales Cr.Memo Header":
                DocumentTypeText := Format("Sales Document Type"::"Credit Memo");
            DATABASE::Job:
                DocumentTypeText := Format("Sales Document Type"::Quote);
            DATABASE::"Sales Header":
                begin
                    DummySalesHeader := DocumentVariant;
                    if DummySalesHeader."Document Type" = DummySalesHeader."Document Type"::Quote then
                        DocumentTypeText := Format(DummySalesHeader."Document Type"::Quote);
                end;
            else
                OnGetDocumentTypeCaseElse(DocumentVariant, DocumentTypeText, DocumentRecordRef);
        end;

        TranslationHelper.RestoreGlobalLanguage();
    end;

    procedure InsertElectronicFormat(InsertElectronicFormatCode: Code[20]; InsertElectronicFormatDescription: Text[250]; CodeunitID: Integer; DeliveryCodeunitID: Integer; InsertElectronicFormatUsage: Option)
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        if ElectronicDocumentFormat.Get(InsertElectronicFormatCode, InsertElectronicFormatUsage) then
            exit;

        ElectronicDocumentFormat.Init();
        ElectronicDocumentFormat.Code := InsertElectronicFormatCode;
        ElectronicDocumentFormat.Description := InsertElectronicFormatDescription;
        ElectronicDocumentFormat."Codeunit ID" := CodeunitID;
        ElectronicDocumentFormat."Delivery Codeunit ID" := DeliveryCodeunitID;
        ElectronicDocumentFormat.Usage := "Electronic Document Format Usage".FromInteger(InsertElectronicFormatUsage);
        ElectronicDocumentFormat.Insert();
    end;

    local procedure ShouldLogUptake() Result: Boolean
    begin
        if "Codeunit ID" in [
            Codeunit::"PEPPOL Validation", Codeunit::"Exp. Sales Inv. PEPPOL BIS3.0", Codeunit::"Exp. Sales CrM. PEPPOL BIS3.0"]
        then
            exit(true);

        OnAfterShouldLogUptake(Rec, Result);
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnDiscoverElectronicFormat()
    begin
    end;

#if not CLEAN25
    [Obsolete('Replaced by event OnBeforeGetDocumentFormatUsage', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDocumentUsage(ElectronicDocumentFormat: Record "Electronic Document Format"; DocumentVariant: Variant; var DocumentUsage: Option; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDocumentFormatUsage(ElectronicDocumentFormat: Record "Electronic Document Format"; DocumentVariant: Variant; var DocumentFormatUsage: Enum "Electronic Document Format Usage"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    [Obsolete('Replaced by event OnBeforeGetDocumentFormatUsageForSalesHeader', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDocumentUsageForSalesHeader(ElectronicDocumentFormat: Record "Electronic Document Format"; SalesHeader: Record "Sales Header"; var DocumentUsage: Option; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDocumentFormatUsageForSalesHeader(ElectronicDocumentFormat: Record "Electronic Document Format"; SalesHeader: Record "Sales Header"; var DocumentUsage: Enum "Electronic Document Format Usage"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforeGetDocumentUsageForServiceHeader(ElectronicDocumentFormat: Record "Electronic Document Format"; ServiceHeader: Record Microsoft.Service.Document."Service Header"; var DocumentUsage: Option; var IsHandled: Boolean)
    begin
        OnBeforeGetDocumentUsageForServiceHeader(ElectronicDocumentFormat, ServiceHeader, DocumentUsage, IsHandled);
    end;

    [Obsolete('Replaced by event OnBeforeGetDocumentFormatUsageForServiceHeader in codeunit "Serv. Electr. Doc. Format"', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDocumentUsageForServiceHeader(ElectronicDocumentFormat: Record "Electronic Document Format"; ServiceHeader: Record Microsoft.Service.Document."Service Header"; var DocumentUsage: Option; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnGetDocumentNoCaseElse(DocumentVariant: Variant; var DocumentNo: Code[20]; var IsHandled: Boolean; DocumentRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDocumentTypeCaseElse(DocumentVariant: Variant; var DocumentTypeText: Text[50]; DocumentRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendElectronicallyOnBeforeDeleteAll(var RecordExportBuffer: Record "Record Export Buffer"; var ClientFileName: Text[250]; DocumentVariant: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendElectronicallyOnBeforeRecordExportBufferInsert(var RecordExportBuffer: Record "Record Export Buffer"; RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendElectronicallyOnAfterRecRefGetTable(ElectronicDocumentFormat: Record "Electronic Document Format"; var RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetAttachmentFileName(RecordVariant: Variant; DocumentNo: Code[20]; DocumentType: Text; Extension: Code[3]; var IsHandled: Boolean; var FileName: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDocumentFormatUsageCaseElse(DocumentRecordRef: RecordRef; var DocumentFormatUsage: Enum "Electronic Document Format Usage"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShouldLogUptake(var ElectronicDocumentFormat: Record "Electronic Document Format"; var Result: Boolean)
    begin
    end;
}

