// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Document;

using Microsoft.Inventory.History;

report 5850 "Copy Invt. Document"
{
    Caption = 'Copy Invt. Document';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DocType2; DocType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document Type';
                        ToolTip = 'Specifies the type of the related document to copy from.';

                        trigger OnValidate()
                        begin
                            DocNo := '';
                            ValidateDocNo();
                        end;
                    }
                    field(DocNo2; DocNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the number of the related document.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            LookupDocNo();
                        end;

                        trigger OnValidate()
                        begin
                            ValidateDocNo();
                        end;
                    }
                    field(IncludeHeader2; IncludeHeader)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Header';
                        ToolTip = 'Specifies if you want to copy information from the document header you are copying.';

                        trigger OnValidate()
                        begin
                            ValidateIncludeHeader();
                        end;
                    }
                    field(RecalculateLines2; RecalculateLines)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Recalculate Lines';
                        ToolTip = 'Specifies that lines are recalculate and inserted on the document you are creating. The batch job retains the item numbers and item quantities but recalculates the amounts on the lines based on the customer information on the new document header.';

                        trigger OnValidate()
                        begin
                            if not IncludeHeader then
                                RecalculateLines := true;
                        end;
                    }
                    field(CopyAsCorrection2; CopyAsCorrection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Copy as Correction';
                        ToolTip = 'Specifies that new document will be marked as Correction.';
                        Editable = IncludeHeader;
                    }
                    field(CopyItemTracking2; CopyItemTracking)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Copy Item Tracking values';
                        ToolTip = 'Specifies that Item Tracking data will be copied to new document lines.';
                        Editable = not CopyItemTrackingNotEditable;
                    }
                    field(AutoFillAppliesFields2; AutoFillAppliesFields)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Specify appl. entries';
                        ToolTip = 'Specifies that apply to/from numbers will be copied to new document lines.';

                        trigger OnValidate()
                        begin
                            ValidateAutoFillApplies();
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if DocNo <> '' then begin
                case DocType of
                    DocType::Receipt:
                        if FromInvtDocHeader.Get(FromInvtDocHeader."Document Type"::Receipt, DocNo) then
                            ;
                    DocType::Shipment:
                        if FromInvtDocHeader.Get(FromInvtDocHeader."Document Type"::Shipment, DocNo) then
                            ;
                    DocType::"Posted Receipt":
                        if FromInvtRcptHeader.Get(DocNo) then
                            FromInvtDocHeader.TransferFields(FromInvtRcptHeader);
                    DocType::"Posted Shipment":
                        if FromInvtShptHeader.Get(DocNo) then
                            FromInvtDocHeader.TransferFields(FromInvtShptHeader);
                end;
                if FromInvtDocHeader."No." = '' then
                    DocNo := '';
            end;
            ValidateDocNo();

            ValidateAutoFillApplies();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin

        CheckInputParameters();

        CopyInvtDocMgt.SetProperties(IncludeHeader, RecalculateLines, false, false, AutoFillAppliesFields);
        CopyInvtDocMgt.CopyAsCorrection(CopyAsCorrection);
        CopyInvtDocMgt.SetCopyItemTracking(CopyItemTracking);
        CopyInvtDocMgt.CopyItemDoc(DocType, DocNo, InvtDocHeader);
        OnAfterOnPreReport(InvtDocHeader, DocType, DocNo);
    end;

    var
        InvtDocHeader: Record "Invt. Document Header";
        FromInvtDocHeader: Record "Invt. Document Header";
        FromInvtRcptHeader: Record "Invt. Receipt Header";
        FromInvtShptHeader: Record "Invt. Shipment Header";
        CopyInvtDocMgt: Codeunit "Copy Invt. Document Mgt.";
        DocType: Enum "Invt. Doc. Document Type From";
        DocNo: Code[20];
        IncludeHeader: Boolean;
        RecalculateLines: Boolean;
        AutoFillAppliesFields: Boolean;
        CopyItemTracking: Boolean;
        CopyAsCorrection: Boolean;
        CopyItemTrackingNotEditable: Boolean;
        ConvertInvtDocumentTypeFromErr: Label 'Value %1 cannot be converted to enum Invt. Document Type.', Comment = '%1 = document type enum value';

    procedure SetInvtDocHeader(var NewInvtDocHeader: Record "Invt. Document Header")
    begin
        InvtDocHeader := NewInvtDocHeader;
    end;

    local procedure ValidateDocNo()
    begin
        if DocNo = '' then
            FromInvtDocHeader.Init()
        else
            if FromInvtDocHeader."No." = '' then begin
                FromInvtDocHeader.Init();
                case DocType of
                    DocType::Receipt,
                    DocType::Shipment:
                        FromInvtDocHeader.Get(DocType, DocNo);
                    DocType::"Posted Receipt":
                        begin
                            FromInvtRcptHeader.Get(DocNo);
                            FromInvtDocHeader.TransferFields(FromInvtRcptHeader);
                        end;
                    DocType::"Posted Shipment":
                        begin
                            FromInvtShptHeader.Get(DocNo);
                            FromInvtDocHeader.TransferFields(FromInvtShptHeader);
                        end;
                end;
            end;
        FromInvtDocHeader."No." := '';

        IncludeHeader := true;
        ValidateIncludeHeader();
    end;

    local procedure LookupDocNo()
    begin
        case DocType of
            DocType::Receipt,
            DocType::Shipment:
                begin
                    FromInvtDocHeader.FilterGroup := 2;
                    FromInvtDocHeader.SetRange("Document Type", ConvertInvtDocumentTypeFrom(DocType));
                    if InvtDocHeader."Document Type" = DocType then
                        FromInvtDocHeader.SetFilter("No.", '<>%1', InvtDocHeader."No.");
                    FromInvtDocHeader.FilterGroup := 0;
                    FromInvtDocHeader."Document Type" := ConvertInvtDocumentTypeFrom(DocType);
                    FromInvtDocHeader."No." := DocNo;
                    case DocType of
                        DocType::Receipt:
                            if PAGE.RunModal(PAGE::"Invt. Receipts", FromInvtDocHeader, FromInvtDocHeader."No.") = ACTION::LookupOK then
                                DocNo := FromInvtDocHeader."No.";
                        DocType::Shipment:
                            if PAGE.RunModal(PAGE::"Invt. Shipments", FromInvtDocHeader, FromInvtDocHeader."No.") = ACTION::LookupOK then
                                DocNo := FromInvtDocHeader."No.";
                    end;
                end;
            DocType::"Posted Receipt":
                begin
                    FromInvtRcptHeader."No." := DocNo;
                    if PAGE.RunModal(0, FromInvtRcptHeader) = ACTION::LookupOK then
                        DocNo := FromInvtRcptHeader."No.";
                end;
            DocType::"Posted Shipment":
                begin
                    FromInvtShptHeader."No." := DocNo;
                    if PAGE.RunModal(0, FromInvtShptHeader) = ACTION::LookupOK then
                        DocNo := FromInvtShptHeader."No.";
                end;
        end;

        OnLookupDocNoOnBeforeValidateDocNo(InvtDocHeader, DocType, DocNo);
        ValidateDocNo();
    end;

    local procedure ValidateIncludeHeader()
    begin
        RecalculateLines := not IncludeHeader;
        CopyAsCorrection := false;
    end;

    local procedure ValidateAutoFillApplies()
    begin
        if AutoFillAppliesFields then begin
            CopyItemTrackingNotEditable := true;
            CopyItemTracking := true;
        end
        else
            CopyItemTrackingNotEditable := false;
    end;

    local procedure ConvertInvtDocumentTypeFrom(InvtDocumentTypeFrom: Enum "Invt. Doc. Document Type From"): Enum "Invt. Doc. Document Type"
    var
        IsHandled: Boolean;
    begin
        case InvtDocumentTypeFrom of
            "Invt. Doc. Document Type From"::Receipt:
                exit("Invt. Doc. Document Type"::Receipt);
            "Invt. Doc. Document Type From"::Shipment:
                exit("Invt. Doc. Document Type"::Shipment);
            else begin
                IsHandled := false;
                OnConvertInvtDocumentTypeFromOnCaseElse(InvtDocumentTypeFrom, IsHandled);
                if not IsHandled then
                    error(ConvertInvtDocumentTypeFromErr, InvtDocumentTypeFrom);
            end;
        end;
    end;

    local procedure CheckInputParameters()
    var
        UpdateAutoFillAppliesFields: Boolean;
    begin
        if not AutoFillAppliesFields then
            exit;

        case DocType of
            DocType::Receipt, DocType::Shipment:
                UpdateAutoFillAppliesFields := true;

            DocType::"Posted Receipt":
                begin
                    if InvtDocHeader."Document Type" = InvtDocHeader."Document Type"::Receipt then
                        UpdateAutoFillAppliesFields := (InvtDocHeader.Correction or CopyAsCorrection) = FromInvtRcptHeader.Correction;

                    if InvtDocHeader."Document Type" = InvtDocHeader."Document Type"::Shipment then
                        UpdateAutoFillAppliesFields := (InvtDocHeader.Correction or CopyAsCorrection) <> FromInvtRcptHeader.Correction;
                end;

            DocType::"Posted Shipment":
                begin
                    if InvtDocHeader."Document Type" = InvtDocHeader."Document Type"::Receipt then
                        UpdateAutoFillAppliesFields := (InvtDocHeader.Correction or CopyAsCorrection) <> FromInvtRcptHeader.Correction;

                    if InvtDocHeader."Document Type" = InvtDocHeader."Document Type"::Shipment then
                        UpdateAutoFillAppliesFields := (InvtDocHeader.Correction or CopyAsCorrection) = FromInvtRcptHeader.Correction;
                end;
        end;

        if UpdateAutoFillAppliesFields then
            AutoFillAppliesFields := false;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnLookupDocNoOnBeforeValidateDocNo(var InvtDocumentHeader: Record "Invt. Document Header"; InvtDocDocumentTypeFrom: Enum "Invt. Doc. Document Type From"; var FromDocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnConvertInvtDocumentTypeFromOnCaseElse(InvtDocDocumentTypeFrom: Enum "Invt. Doc. Document Type From"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnPreReport(var InvtDocumentHeader: Record "Invt. Document Header"; DocType: Enum "Invt. Doc. Document Type From"; DocNo: Code[20])
    begin
    end;
}

