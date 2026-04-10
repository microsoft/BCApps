// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Clause;

using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Reminder;
using System.Reflection;

/// <summary>
/// Stores VAT clause definitions for including explanatory text on VAT-related documents.
/// Supports multilingual translations and document-type-specific variations for compliance with VAT reporting requirements.
/// </summary>
/// <remarks>
/// Primary table for VAT clause management with extended text support and language translation capabilities.
/// Integrates with sales documents, invoices, credit memos, reminders, and finance charge memos for regulatory compliance.
/// Extensibility: Translation management, extended text integration, and custom VAT clause processing events.
/// </remarks>
table 560 "VAT Clause"
{
    Caption = 'VAT Clause';
    DrillDownPageID = "VAT Clauses";
    LookupPageID = "VAT Clauses";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the VAT clause used for referencing in VAT posting setup and documents.
        /// </summary>
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the code for a VAT clause, which is used to provide a VAT description associated with a sales line on a sales invoice, credit memo, or other sales document.';
            NotBlank = true;
        }
        /// <summary>
        /// Primary description text of the VAT clause displayed on documents and reports.
        /// </summary>
        field(2; Description; Text[250])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the descriptive text that is associated with a VAT clause.';
        }
        /// <summary>
        /// Additional description text providing extended information about the VAT clause requirements.
        /// </summary>
        field(3; "Description 2"; Text[250])
        {
            Caption = 'Description 2';
            ToolTip = 'Specifies an additional description of a VAT clause.';
        }
        /// <summary>
        /// Timestamp indicating when the VAT clause record was last modified for audit and synchronization purposes.
        /// </summary>
        field(10; "Last Modified DateTime"; DateTime)
        {
            Caption = 'Last Modified DateTime';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        VATClauseTranslation: Record "VAT Clause Translation";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATClauseTranslation.SetRange("VAT Clause Code", Code);
        VATClauseTranslation.DeleteAll();

        VATPostingSetup.SetRange("VAT Clause Code", Code);
        VATPostingSetup.ModifyAll("VAT Clause Code", '');
    end;

    trigger OnInsert()
    begin
        SetLastModifiedDateTime();
    end;

    trigger OnModify()
    begin
        SetLastModifiedDateTime();
    end;

    trigger OnRename()
    begin
        SetLastModifiedDateTime();
    end;

    local procedure SetLastModifiedDateTime()
    begin
        "Last Modified DateTime" := CurrentDateTime;
    end;

    /// <summary>
    /// Translates VAT clause description to the specified language using translation table lookup.
    /// Updates the current record's description fields with translated text if available.
    /// </summary>
    /// <param name="Language">Language code for the desired translation</param>
    procedure TranslateDescription(Language: Code[10])
    var
        VATClauseTranslation: Record "VAT Clause Translation";
    begin
        if VATClauseTranslation.Get(Code, Language) then
            FillDescriptions(VATClauseTranslation.Description, VATClauseTranslation."Description 2");
    end;

    local procedure TryFindDescriptionByDocumentType(DocumentType: Enum "VAT Clause Document Type"; LanguageCode: Code[10]): Boolean
    var
        VATClauseByDocType: Record "VAT Clause by Doc. Type";
        VATClauseByDocTypeTrans: Record "VAT Clause by Doc. Type Trans.";
    begin
        if VATClauseByDocTypeTrans.get(Code, DocumentType, LanguageCode) then begin
            FillDescriptions(VATClauseByDocTypeTrans.Description, VATClauseByDocTypeTrans."Description 2");
            exit(true);
        end;

        if VATClauseByDocType.get(Code, DocumentType) then begin
            FillDescriptions(VATClauseByDocType.Description, VATClauseByDocType."Description 2");
            exit(true);
        end;
    end;

    /// <summary>
    /// Retrieves the complete description text for the VAT clause based on the related document context.
    /// Attempts extended text lookup first, then document-type-specific descriptions, and finally standard translations.
    /// </summary>
    /// <param name="RecRelatedVariant">Related document record variant for context determination</param>
    /// <returns>Complete description text for the VAT clause based on document context and language</returns>
    procedure GetDescriptionText(RecRelatedVariant: Variant) Result: Text
    var
        DocumentType: Enum "VAT Clause Document Type";
        LanguageCode: Code[10];
    begin
        Result := GetDescriptionByExtendedText(RecRelatedVariant);
        if Result <> '' then
            exit(Result);

        if GetDocumentTypeAndLanguageCode(RecRelatedVariant, DocumentType, LanguageCode) then begin
            TryFindDescriptionByDocumentType(DocumentType, LanguageCode);
            TranslateDescription(LanguageCode);
            exit(Description + ' ' + "Description 2");
        end;

        OnAfterGetDescription(Rec, DocumentType, LanguageCode);
        exit(Description + ' ' + "Description 2");
    end;

    local procedure GetDescriptionByExtendedText(RecRelatedVariant: Variant) Result: Text
    var
        ExtendedTextHeader: Record "Extended Text Header";
        TempExtendedTextLine: Record "Extended Text Line" temporary;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        IssuedReminderHeader: Record "Issued Reminder Header";
        DataTypeManagement: Codeunit "Data Type Management";
        TransferExtendedText: Codeunit "Transfer Extended Text";
        RecRef: RecordRef;
        LanguageCode: Code[10];
        DocDate: Date;
        IsHandled: Boolean;
    begin
        if not DataTypeManagement.GetRecordRef(RecRelatedVariant, RecRef) then
            exit;

        ExtendedTextHeader.SetRange("Table Name", ExtendedTextHeader."Table Name"::"VAT Clause");
        ExtendedTextHeader.SetRange("No.", Code);

        IsHandled := false;
        OnFilterExtendedTextHeaderFromDoc(RecRelatedVariant, ExtendedTextHeader, IsHandled, LanguageCode, DocDate, RecRef);
        if not IsHandled then
            case RecRef.Number of
                DATABASE::"Sales Header":
                    begin
                        RecRef.SetTable(SalesHeader);
                        case SalesHeader."Document Type" of
                            SalesHeader."Document Type"::"Blanket Order":
                                ExtendedTextHeader.SetRange("Sales Blanket Order", true);
                            SalesHeader."Document Type"::"Credit Memo":
                                ExtendedTextHeader.SetRange("Sales Credit Memo", true);
                            SalesHeader."Document Type"::Invoice:
                                ExtendedTextHeader.SetRange("Sales Invoice", true);
                            SalesHeader."Document Type"::Order:
                                ExtendedTextHeader.SetRange("Sales Order", true);
                            SalesHeader."Document Type"::Quote:
                                ExtendedTextHeader.SetRange("Sales Quote", true);
                            SalesHeader."Document Type"::"Return Order":
                                ExtendedTextHeader.SetRange("Sales Return Order", true);
                        end;
                        LanguageCode := SalesHeader."Language Code";
                        DocDate := SalesHeader."Document Date";
                    end;
                DATABASE::"Sales Invoice Header":
                    begin
                        RecRef.SetTable(SalesInvoiceHeader);
                        ExtendedTextHeader.SetRange("Sales Invoice", true);
                        LanguageCode := SalesInvoiceHeader."Language Code";
                        DocDate := SalesInvoiceHeader."Document Date";
                    end;
                DATABASE::"Sales Cr.Memo Header":
                    begin
                        RecRef.SetTable(SalesCrMemoHeader);
                        ExtendedTextHeader.SetRange("Sales Credit Memo", true);
                        LanguageCode := SalesCrMemoHeader."Language Code";
                        DocDate := SalesCrMemoHeader."Document Date";
                    end;
                DATABASE::"Issued Fin. Charge Memo Header":
                    begin
                        RecRef.SetTable(IssuedFinChargeMemoHeader);
                        ExtendedTextHeader.SetRange("Finance Charge Memo", true);
                        LanguageCode := IssuedFinChargeMemoHeader."Language Code";
                        DocDate := IssuedFinChargeMemoHeader."Document Date";
                    end;
                DATABASE::"Issued Reminder Header":
                    begin
                        RecRef.SetTable(IssuedReminderHeader);
                        ExtendedTextHeader.SetRange(Reminder, true);
                        LanguageCode := IssuedReminderHeader."Language Code";
                        DocDate := IssuedReminderHeader."Document Date";
                    end;
                else
                    exit;
            end;

        OnGetDescriptionByExtendedTextOnBeforeReadExtTextLines(Rec, RecRef, ExtendedTextHeader, LanguageCode, DocDate, RecRelatedVariant);
        if not TransferExtendedText.ReadExtTextLines(ExtendedTextHeader, DocDate, LanguageCode) then
            exit;

        TransferExtendedText.GetTempExtTextLine(TempExtendedTextLine);
        OnGetDescriptionByExtendedTextOnAfterGetTempExtTextLine(Rec, RecRelatedVariant, ExtendedTextHeader, LanguageCode, DocDate, TempExtendedTextLine, Result);
        if not TempExtendedTextLine.FindSet() then
            exit;

        repeat
            if Result <> '' then
                Result += ' ';
            Result += TempExtendedTextLine.Text;
        until TempExtendedTextLine.Next() = 0;
    end;

    local procedure GetDocumentTypeAndLanguageCode(RecRelatedVariant: Variant; var DocumentType: Enum "VAT Clause Document Type"; var LanguageCode: Code[10]) Result: Boolean
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        IssuedReminderHeader: Record "Issued Reminder Header";
        DataTypeManagement: Codeunit "Data Type Management";
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        if not DataTypeManagement.GetRecordRef(RecRelatedVariant, RecRef) then
            exit(false);

        case RecRef.Number of
            database::"Sales Header":
                begin
                    RecRef.SetTable(SalesHeader);
                    if SalesHeader."Document Type" in [SalesHeader."Document Type"::"Credit Memo", SalesHeader."Document Type"::"Return Order"] then
                        DocumentType := DocumentType::"Credit Memo"
                    else
                        DocumentType := DocumentType::Invoice;
                    LanguageCode := SalesHeader."Language Code";
                    Result := true;
                end;
            database::"Sales Invoice Header":
                begin
                    RecRef.SetTable(SalesInvoiceHeader);
                    DocumentType := DocumentType::Invoice;
                    LanguageCode := SalesInvoiceHeader."Language Code";
                    Result := true;
                end;
            database::"Sales Cr.Memo Header":
                begin
                    RecRef.SetTable(SalesCrMemoHeader);
                    DocumentType := DocumentType::"Credit Memo";
                    LanguageCode := SalesCrMemoHeader."Language Code";
                    Result := true;
                end;
            database::"Issued Fin. Charge Memo Header":
                begin
                    RecRef.SetTable(IssuedFinChargeMemoHeader);
                    DocumentType := DocumentType::"Finance Charge Memo";
                    LanguageCode := IssuedFinChargeMemoHeader."Language Code";
                    Result := true;
                end;
            database::"Issued Reminder Header":
                begin
                    RecRef.SetTable(IssuedReminderHeader);
                    DocumentType := DocumentType::Reminder;
                    LanguageCode := IssuedReminderHeader."Language Code";
                    Result := true;
                end;
            else begin
                IsHandled := false;
                OnGetDocumentTypeAndLanguageCode(Rec, RecRelatedVariant, DocumentType, LanguageCode, IsHandled);
                Result := IsHandled;
            end;
        end;
        CompanyInformationMgt.GetLanguageDefault(LanguageCode);
        OnAfterGetDocumentTypeAndLanguageCode(Rec, RecRelatedVariant, RecRef, DocumentType, LanguageCode, Result);
    end;

    local procedure FillDescriptions(NewDescription: Text[250]; NewDescription2: Text[250])
    begin
        if NewDescription <> '' then
            Description := NewDescription;
        if NewDescription2 <> '' then
            "Description 2" := NewDescription2;
    end;

    /// <summary>
    /// Integration event raised after retrieving VAT clause description for custom processing or modification.
    /// Enables customization of VAT clause description based on document type and language context.
    /// </summary>
    /// <param name="VATClause">VAT clause record with description data</param>
    /// <param name="DocumentType">Document type for context-specific processing</param>
    /// <param name="LanguageCode">Language code for localization</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDescription(var VATClause: Record "VAT Clause"; DocumentType: Enum "VAT Clause Document Type"; LanguageCode: Code[10])
    begin
    end;

    /// <summary>
    /// Integration event raised after determining document type and language code from related record context.
    /// Enables custom logic for document type and language determination based on record relationships.
    /// </summary>
    /// <param name="VATClause">VAT clause record being processed</param>
    /// <param name="RecRelatedVariant">Related record variant for context</param>
    /// <param name="RecRef">Record reference for type identification</param>
    /// <param name="DocumentType">Determined document type for VAT clause processing</param>
    /// <param name="LanguageCode">Determined language code for translation</param>
    /// <param name="Result">Whether document type and language code were successfully determined</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDocumentTypeAndLanguageCode(VATClause: Record "VAT Clause"; RecRelatedVariant: Variant; RecRef: RecordRef; var DocumentType: Enum "VAT Clause Document Type"; var LanguageCode: Code[10]; var Result: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after retrieving extended text lines for VAT clause description customization.
    /// Enables modification of extended text content based on document context and requirements.
    /// </summary>
    /// <param name="VATClause">VAT clause record being processed</param>
    /// <param name="RecRelatedVariant">Related record variant for context</param>
    /// <param name="ExtendedTextHeader">Extended text header for filtering</param>
    /// <param name="LanguageCode">Language code for text retrieval</param>
    /// <param name="DocDate">Document date for extended text filtering</param>
    /// <param name="TempExtendedTextLine">Temporary extended text lines for modification</param>
    /// <param name="Result">Resulting description text from extended text processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnGetDescriptionByExtendedTextOnAfterGetTempExtTextLine(VATClause: Record "VAT Clause"; RecRelatedVariant: Variant; var ExtendedTextHeader: Record "Extended Text Header"; LanguageCode: Code[10]; DocDate: Date; var TempExtendedTextLine: Record "Extended Text Line" temporary; var Result: Text)
    begin
    end;

    /// <summary>
    /// Integration event raised when determining document type and language code from related record context.
    /// Enables custom document type and language code determination for unsupported record types.
    /// </summary>
    /// <param name="VATClause">VAT clause record being processed</param>
    /// <param name="RecRelatedVariant">Related record variant for context analysis</param>
    /// <param name="DocumentType">Document type to be determined</param>
    /// <param name="LanguageCode">Language code to be determined</param>
    /// <param name="IsHandled">Set to true if custom logic handles the determination</param>
    [IntegrationEvent(false, false)]
    local procedure OnGetDocumentTypeAndLanguageCode(VATClause: Record "VAT Clause"; RecRelatedVariant: Variant; var DocumentType: Enum "VAT Clause Document Type"; var LanguageCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised when filtering extended text headers based on document context.
    /// Enables custom extended text filtering logic for document-specific requirements.
    /// </summary>
    /// <param name="RecRelatedVariant">Related record variant for filtering context</param>
    /// <param name="ExtendedTextHeader">Extended text header record for filtering</param>
    /// <param name="IsHandled">Set to true if custom filtering logic is applied</param>
    /// <param name="LanguageCode">Language code for extended text filtering</param>
    /// <param name="DocDate">Document date for extended text date filtering</param>
    /// <param name="RecordRef">Record reference for type identification</param>
    [IntegrationEvent(false, false)]
    local procedure OnFilterExtendedTextHeaderFromDoc(RecRelatedVariant: Variant; var ExtendedTextHeader: Record "Extended Text Header"; var IsHandled: Boolean; var LanguageCode: Code[10]; var DocDate: Date; RecordRef: RecordRef)
    begin
    end;

    /// <summary>
    /// Integration event raised before reading extended text lines for VAT clause description processing.
    /// Enables preprocessing of extended text parameters and customization of text retrieval logic.
    /// </summary>
    /// <param name="VATClause">VAT clause record being processed</param>
    /// <param name="RelatedRecordRef">Related record reference for context</param>
    /// <param name="ExtendedTextHeader">Extended text header for processing</param>
    /// <param name="LanguageCode">Language code for text retrieval</param>
    /// <param name="DocDate">Document date for extended text filtering</param>
    /// <param name="RecRelatedVariant">Related record variant for additional context</param>
    [IntegrationEvent(false, false)]
    local procedure OnGetDescriptionByExtendedTextOnBeforeReadExtTextLines(var VATClause: Record "VAT Clause"; var RelatedRecordRef: RecordRef; var ExtendedTextHeader: Record "Extended Text Header"; var LanguageCode: Code[10]; var DocDate: Date; RecRelatedVariant: Variant)
    begin
    end;
}
