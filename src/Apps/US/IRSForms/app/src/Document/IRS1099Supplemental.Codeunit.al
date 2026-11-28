// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

codeunit 10040 "IRS 1099 Supplemental"
{
    Access = Internal;

    var
        UnsupportedScopeErr: Label 'Supplemental lines are supported for tax years 2026 and later on forms MISC and NEC within a single calendar year. Reporting period: %1, form: %2.', Comment = '%1 = period, %2 = form';
        MappingErr: Label 'The setup for supplemental box %1 does not meet the reporting requirements. Check its box number, parent form box, value type, and XML element on the IRS 1099 Supplemental Boxes page. Use the supported setup for standard boxes, or leave XML Element Name blank for custom boxes.', Comment = '%1 = supplemental box';
        TypedValueErr: Label 'The values for supplemental box %1 do not match its value type. Amount lines cannot contain occupation codes, and Occupation Codes lines cannot contain an amount. Clear the incompatible values before changing the supplemental box.', Comment = '%1 = supplemental box';
        UnsupportedOccupationCodeErr: Label 'Occupation code %1 on supplemental box %2 is not supported. Enter a three-character Treasury tipped occupation code supported for the reporting year.', Comment = '%1 = occupation code, %2 = supplemental box';
        AmountErr: Label 'Supplemental box %1: amount %2 must be between zero and the amount %3 on the parent document line, and must not exceed the maximum amount allowed by the IRIS XML schema.', Comment = '%1 = supplemental box, %2 = supplemental amount, %3 = parent amount';
        MissingParentErr: Label 'A document line for form box %1 is required before you can add supplemental box %2.', Comment = '%1 = parent box, %2 = supplemental box';
        NoChoicesErr: Label 'No supplemental boxes are available for this document. Check the setup for its reporting year and form on the IRS 1099 Supplemental Boxes page, and add any missing parent document lines. Boxes already added cannot be selected again.';
        MissingCodesErr: Label 'Supplemental box %1: positive cash tips require one or two valid Treasury tipped occupation codes.', Comment = '%1 = cash-tip box';
        UnsupportedMappingErr: Label 'Supplemental box %1 contains values that cannot be reported in IRIS XML. Correct the box setup on the IRS 1099 Supplemental Boxes page or remove its values before reporting.', Comment = '%1 = supplemental box';
        UnsupportedMappingValueTypeErr: Label 'The value type %1 for supplemental box %2 in the tax-year mapping resource is not supported.', Comment = '%1 = JSON value type, %2 = supplemental box';
        RestorationValidationErr: Label 'Cannot recreate document %1 for vendor %2, form %3, period %4. %5 Correct the saved supplemental lines on the source document before recreating it.', Comment = '%1 = source document ID, %2 = vendor, %3 = form, %4 = period, %5 = validation detail';
        DocumentValidationErr: Label 'Document %1: %2', Comment = '%1 = document ID, %2 = validation detail';
        ExcludedParentTxt: Label 'Not reported because the parent document line is not included in 1099 reporting. Your entered values have been kept.';
        ZeroTipsTxt: Label 'Saved occupation codes are not reported because cash tips are excluded or round to zero. The codes are kept and will be used if reportable cash tips are entered again.';
        SameDocumentErr: Label 'Select a different source document to copy supplemental lines.';
        NoSupplementalLinesErr: Label 'Document %1 has no supplemental lines to copy.', Comment = '%1 = source document ID';

    procedure IsFormBoxAmountReportable(FormNo: Code[20]; FormBoxNo: Code[20]; Amount: Decimal; MinimumAmount: Decimal; HasBackupWithholding: Boolean): Boolean
    begin
        if Amount < 0 then
            exit(false);
        if ((FormNo = 'NEC') and (FormBoxNo = 'NEC-04')) or
           ((FormNo = 'MISC') and (FormBoxNo = 'MISC-04'))
        then
            exit(Amount > 0);
        if Amount >= MinimumAmount then
            exit(true);
        if not HasBackupWithholding or (Amount = 0) then
            exit(false);
        case FormNo of
            'NEC':
                exit(FormBoxNo in ['NEC-01', 'NEC-03', 'NEC-04']);
            'MISC':
                exit(FormBoxNo in ['MISC-01', 'MISC-02', 'MISC-03', 'MISC-04', 'MISC-05', 'MISC-06',
                    'MISC-08', 'MISC-09', 'MISC-10', 'MISC-12', 'MISC-15']);
        end;
        exit(false);
    end;

    procedure RecalculateIncludeIn1099(DocumentID: Integer)
    var
        DocLine: Record "IRS 1099 Form Doc. Line";
        HasBackupWithholding: Boolean;
        IncludeIn1099: Boolean;
    begin
        DocLine.SetRange("Document ID", DocumentID);
        DocLine.SetFilter("Form Box No.", '%1|%2', 'NEC-04', 'MISC-04');
        DocLine.SetFilter(Amount, '>0');
        HasBackupWithholding := not DocLine.IsEmpty();
        DocLine.SetRange("Form Box No.");
        DocLine.SetRange(Amount);
        if DocLine.FindSet(true) then
            repeat
                IncludeIn1099 := IsFormBoxAmountReportable(DocLine."Form No.", DocLine."Form Box No.",
                    DocLine.Amount, DocLine."Minimum Reportable Amount", HasBackupWithholding);
                if DocLine."Include In 1099" <> IncludeIn1099 then begin
                    DocLine."Include In 1099" := IncludeIn1099;
                    DocLine.Modify();
                end;
            until DocLine.Next() = 0;
    end;

    procedure RecalculateBufferIncludeIn1099(var TempBuffer: Record "IRS 1099 Vend. Form Box Buffer" temporary)
    var
        TempWithholding: Record "IRS 1099 Vend. Form Box Buffer" temporary;
    begin
        TempWithholding.Copy(TempBuffer, true);
        TempWithholding.Reset();
        TempWithholding.SetRange("Buffer Type", TempWithholding."Buffer Type"::Amount);
        TempWithholding.SetFilter("Form Box No.", '%1|%2', 'NEC-04', 'MISC-04');
        TempWithholding.SetFilter("Reporting Amount", '>0');
        TempBuffer.Reset();
        TempBuffer.SetRange("Buffer Type", TempBuffer."Buffer Type"::Amount);
        if TempBuffer.FindSet() then
            repeat
                TempWithholding.SetRange("Period No.", TempBuffer."Period No.");
                TempWithholding.SetRange("Vendor No.", TempBuffer."Vendor No.");
                TempWithholding.SetRange("Form No.", TempBuffer."Form No.");
                TempBuffer."Include In 1099" := IsFormBoxAmountReportable(TempBuffer."Form No.", TempBuffer."Form Box No.",
                    TempBuffer."Reporting Amount", TempBuffer."Minimum Reportable Amount", not TempWithholding.IsEmpty());
                TempBuffer.Modify();
            until TempBuffer.Next() = 0;
    end;

    procedure ValidateSupplementalLines(DocumentID: Integer)
    var
        ValidationError: ErrorInfo;
    begin
        ValidationError := GetSupplementalValidationError(DocumentID);
        if ValidationError.Message <> '' then
            RaiseDocumentValidationError(DocumentID, ValidationError);
    end;

    local procedure GetSupplementalValidationError(DocumentID: Integer) ValidationError: ErrorInfo
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
        CodesSupplLine: Record "IRS 1099 Doc. Suppl. Line";
        SupplBox: Record "IRS 1099 Suppl. Box";
        HelperIRIS: Codeunit "Helper IRIS";
        MappingResource: JsonObject;
        SupplementalMappings: JsonObject;
        FormMappings: JsonArray;
        ParentBoxNo: Code[20];
        ElementName: Text[100];
        ValueType: Enum "IRS 1099 Supplemental Type";
    begin
        ValidationError := ErrorInfo.Create('', false);
        DocHeader.Get(DocumentID);
        SupplLine.SetRange("Document ID", DocumentID);
        if SupplLine.FindSet() then begin
            MappingResource := HelperIRIS.GetAmtXmlElementsFileContent(DocHeader."Period No.");
            SupplementalMappings := MappingResource.GetObject('SupplementalMappings', true);
            FormMappings := SupplementalMappings.GetArray(DocHeader."Form No.", true);
            repeat
                ValidationError := GetLineValidationError(SupplLine);
                if ValidationError.Message <> '' then
                    exit(ValidationError);
                SupplBox.Get(DocHeader."Period No.", DocHeader."Form No.", SupplLine."Supplemental Box No.");
                ValidateSupplBoxSetup(SupplBox, SupplBox.CurrentCompany(), FormMappings);
                if (SupplBox."Parent Form Box No." <> SupplLine."Parent Form Box No.") or
                   (SupplBox."Value Type" <> SupplLine."Value Type")
                then
                    Error(MappingErr, SupplLine."Supplemental Box No.");
                if HasValues(SupplLine) and
                   not GetMapping(FormMappings, SupplLine."Supplemental Box No.", ParentBoxNo, ElementName, ValueType)
                then begin
                    ValidationError.Message := StrSubstNo(UnsupportedMappingErr, SupplLine."Supplemental Box No.");
                    exit(ValidationError);
                end;
                if (SupplBox."XML Element Name" = 'CashTipsAmt') and (SupplLine.Amount > 0) then begin
                    CodesSupplLine.SetRange("Document ID", DocumentID);
                    CodesSupplLine.SetRange("Parent Form Box No.", SupplLine."Parent Form Box No.");
                    CodesSupplLine.SetRange("Value Type", CodesSupplLine."Value Type"::"Occupation Codes");
                    CodesSupplLine.SetFilter("Occupation Code 1", '<>%1', '');
                    if CodesSupplLine.IsEmpty() then begin
                        CodesSupplLine.SetRange("Occupation Code 1");
                        CodesSupplLine.SetFilter("Occupation Code 2", '<>%1', '');
                        if CodesSupplLine.IsEmpty() then begin
                            ValidationError.Message := StrSubstNo(MissingCodesErr, SupplLine."Supplemental Box No.");
                            exit(ValidationError);
                        end;
                    end;
                    CodesSupplLine.Reset();
                end;
            until SupplLine.Next() = 0;
        end;
    end;

    procedure IsReportable(var SupplLine: Record "IRS 1099 Doc. Suppl. Line"): Boolean
    var
        ParentDocLine: Record "IRS 1099 Form Doc. Line";
        TipsSupplLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        GetParent(SupplLine, ParentDocLine);
        if not ParentDocLine."Include In 1099" then
            exit(false);
        if SupplLine."Value Type" = SupplLine."Value Type"::Amount then
            exit(SupplLine.Amount > 0);
        TipsSupplLine.SetRange("Document ID", SupplLine."Document ID");
        TipsSupplLine.SetRange("Parent Form Box No.", SupplLine."Parent Form Box No.");
        TipsSupplLine.SetFilter("Supplemental Box No.", '%1|%2', 'NEC-01B', 'MISC-13A');
        TipsSupplLine.SetFilter(Amount, '>0');
        exit(not TipsSupplLine.IsEmpty());
    end;

    procedure RoundAmount(Amount: Decimal): Decimal
    begin
        exit(Round(Amount, 0.01));
    end;

    procedure IsStatementReportable(var SupplLine: Record "IRS 1099 Doc. Suppl. Line"): Boolean
    var
        TipsSupplLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        if not IsReportable(SupplLine) then
            exit(false);
        if SupplLine."Value Type" <> SupplLine."Value Type"::"Occupation Codes" then
            exit(true);
        TipsSupplLine.SetRange("Document ID", SupplLine."Document ID");
        TipsSupplLine.SetRange("Parent Form Box No.", SupplLine."Parent Form Box No.");
        TipsSupplLine.SetFilter("Supplemental Box No.", '%1|%2', 'NEC-01B', 'MISC-13A');
        TipsSupplLine.SetFilter(Amount, '>0');
        TipsSupplLine.CalcSums(Amount);
        exit(RoundAmount(TipsSupplLine.Amount) > 0);
    end;

    procedure GetExclusionExplanation(var SupplLine: Record "IRS 1099 Doc. Suppl. Line"): Text
    var
        ParentDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        if SupplLine."Supplemental Box No." = '' then
            exit('');
        GetParent(SupplLine, ParentDocLine);
        if not ParentDocLine."Include In 1099" then
            exit(ExcludedParentTxt);
        if (SupplLine."Value Type" = SupplLine."Value Type"::"Occupation Codes") and not IsStatementReportable(SupplLine) then
            exit(ZeroTipsTxt);
        exit('');
    end;

    procedure CopySupplLinesToTemp(DocumentID: Integer; var TempSupplLine: Record "IRS 1099 Doc. Suppl. Line" temporary)
    var
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        SupplLine.SetRange("Document ID", DocumentID);
        if SupplLine.FindSet() then
            repeat
                TempSupplLine := SupplLine;
                TempSupplLine.Insert();
            until SupplLine.Next() = 0;
    end;

    procedure CopyFromDocument(SourceDocumentID: Integer; TargetDocumentID: Integer)
    var
        SourceDocHeader: Record "IRS 1099 Form Doc. Header";
        TargetDocHeader: Record "IRS 1099 Form Doc. Header";
        SourceSupplLine: Record "IRS 1099 Doc. Suppl. Line";
        TargetSupplLine: Record "IRS 1099 Doc. Suppl. Line";
        TempSupplLine: Record "IRS 1099 Doc. Suppl. Line" temporary;
    begin
        if SourceDocumentID = TargetDocumentID then
            Error(SameDocumentErr);
        SourceDocHeader.Get(SourceDocumentID);
        TargetDocHeader.LockTable();
        TargetDocHeader.Get(TargetDocumentID);
        TargetDocHeader.TestField(Status, TargetDocHeader.Status::Open);
        SourceSupplLine.SetRange("Document ID", SourceDocHeader.ID);
        if not SourceSupplLine.FindSet() then
            Error(NoSupplementalLinesErr, SourceDocumentID);
        repeat
            TempSupplLine := SourceSupplLine;
            TempSupplLine."Document ID" := TargetDocumentID;
            // Validate copied lines against the target setup before removing existing lines.
            TempSupplLine.Insert(true);
        until SourceSupplLine.Next() = 0;

        TargetSupplLine.SetRange("Document ID", TargetDocumentID);
        TargetSupplLine.DeleteAll(true);
        if TempSupplLine.FindSet() then
            repeat
                TargetSupplLine := TempSupplLine;
                TargetSupplLine.Insert(true);
            until TempSupplLine.Next() = 0;
        ValidateSupplementalLines(TargetDocumentID);
    end;

    procedure RestoreSupplLinesFromTemp(OldDocumentID: Integer; NewDocumentID: Integer; var TempSupplLine: Record "IRS 1099 Doc. Suppl. Line" temporary)
    var
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
        DocHeader: Record "IRS 1099 Form Doc. Header";
        ValidationError: ErrorInfo;
    begin
        TempSupplLine.SetRange("Document ID", OldDocumentID);
        if TempSupplLine.FindSet() then
            repeat
                SupplLine := TempSupplLine;
                SupplLine."Document ID" := NewDocumentID;
                // Preserve the saved parent/type rather than resolving mutable setup again.
                SupplLine.Insert();
            until TempSupplLine.Next() = 0;
        TempSupplLine.SetRange("Document ID");
        ValidationError := GetSupplementalValidationError(NewDocumentID);
        if ValidationError.Message <> '' then begin
            DocHeader.Get(NewDocumentID);
            ValidationError.Message := StrSubstNo(RestorationValidationErr, OldDocumentID,
                DocHeader."Vendor No.", DocHeader."Form No.", DocHeader."Period No.", ValidationError.Message);
            ValidationError.DataClassification := DataClassification::CustomerContent;
            Error(ValidationError);
        end;
    end;

    local procedure HasValues(SupplLine: Record "IRS 1099 Doc. Suppl. Line"): Boolean
    begin
        exit((SupplLine.Amount <> 0) or (SupplLine."Occupation Code 1" <> '') or (SupplLine."Occupation Code 2" <> ''));
    end;

    procedure ValidateSupplBoxSetup(var SupplBox: Record "IRS 1099 Suppl. Box")
    begin
        ValidateSupplBoxSetup(SupplBox, SupplBox.CurrentCompany());
    end;

    procedure ValidateSupplBoxSetup(SupplBox: Record "IRS 1099 Suppl. Box"; TargetCompany: Text)
    var
        HelperIRIS: Codeunit "Helper IRIS";
        MappingResource: JsonObject;
        SupplementalMappings: JsonObject;
        FormMappings: JsonArray;
    begin
        MappingResource := HelperIRIS.GetAmtXmlElementsFileContent(SupplBox."Period No.");
        SupplementalMappings := MappingResource.GetObject('SupplementalMappings', true);
        FormMappings := SupplementalMappings.GetArray(SupplBox."Form No.", true);
        ValidateSupplBoxSetup(SupplBox, TargetCompany, FormMappings);
    end;

    local procedure ValidateSupplBoxSetup(SupplBox: Record "IRS 1099 Suppl. Box"; TargetCompany: Text; FormMappings: JsonArray)
    var
        FormBox: Record "IRS 1099 Form Box";
        ExpectedParent: Code[20];
        ExpectedElement: Text[100];
        ExpectedType: Enum "IRS 1099 Supplemental Type";
    begin
        ValidateSupplPeriodAndForm(SupplBox."Period No.", SupplBox."Form No.", TargetCompany);
        SupplBox.TestField("No.");
        SupplBox.TestField("Parent Form Box No.");
        FormBox.ChangeCompany(TargetCompany);
        FormBox.Get(SupplBox."Period No.", SupplBox."Form No.", SupplBox."Parent Form Box No.");
        if FormBox.Get(SupplBox."Period No.", SupplBox."Form No.", SupplBox."No.") then
            Error(MappingErr, SupplBox."No.");
        if GetMapping(FormMappings, SupplBox."No.", ExpectedParent, ExpectedElement, ExpectedType) then begin
            if (SupplBox."Parent Form Box No." <> ExpectedParent) or
               (SupplBox."XML Element Name" <> ExpectedElement) or
               (SupplBox."Value Type" <> ExpectedType)
            then
                Error(MappingErr, SupplBox."No.");
        end else
            if (SupplBox."XML Element Name" <> '') or
               (SupplBox."No." in ['NEC-01B', 'NEC-01C', 'NEC-01D', 'MISC-13A', 'MISC-13B', 'MISC-14'])
            then
                Error(MappingErr, SupplBox."No.");
    end;

    procedure ValidateSupplPeriodAndForm(PeriodNo: Code[20]; FormNo: Code[20])
    begin
        ValidateSupplPeriodAndForm(PeriodNo, FormNo, CompanyName());
    end;

    local procedure ValidateSupplPeriodAndForm(PeriodNo: Code[20]; FormNo: Code[20]; TargetCompany: Text)
    var
        ReportingPeriod: Record "IRS Reporting Period";
    begin
        ReportingPeriod.ChangeCompany(TargetCompany);
        ReportingPeriod.Get(PeriodNo);
        if (Date2DMY(ReportingPeriod."Starting Date", 3) < 2026) or
           (Date2DMY(ReportingPeriod."Ending Date", 3) <> Date2DMY(ReportingPeriod."Starting Date", 3)) or
           not (FormNo in ['MISC', 'NEC'])
        then
            Error(UnsupportedScopeErr, PeriodNo, FormNo);
    end;

    procedure GetMapping(TaxYear: Text; FormNo: Code[20]; BoxNo: Code[20]; var ParentBoxNo: Code[20]; var ElementName: Text[100]; var ValueType: Enum "IRS 1099 Supplemental Type"): Boolean
    var
        HelperIRIS: Codeunit "Helper IRIS";
        MappingResource: JsonObject;
        SupplementalMappings: JsonObject;
        FormMappings: JsonArray;
    begin
        MappingResource := HelperIRIS.GetAmtXmlElementsFileContent(TaxYear);
        SupplementalMappings := MappingResource.GetObject('SupplementalMappings', true);
        FormMappings := SupplementalMappings.GetArray(FormNo, true);
        exit(GetMapping(FormMappings, BoxNo, ParentBoxNo, ElementName, ValueType));
    end;

    local procedure GetMapping(FormMappings: JsonArray; BoxNo: Code[20]; var ParentBoxNo: Code[20]; var ElementName: Text[100]; var ValueType: Enum "IRS 1099 Supplemental Type"): Boolean
    var
        Mapping: JsonObject;
        MappingToken: JsonToken;
        ValueTypeText: Text;
        MappingErrorInfo: ErrorInfo;
    begin
        Clear(ParentBoxNo);
        Clear(ElementName);
        ValueType := ValueType::Amount;
        foreach MappingToken in FormMappings do begin
            Mapping := MappingToken.AsObject();
            if Mapping.GetText('FormBoxNo') = BoxNo then begin
                ParentBoxNo := CopyStr(Mapping.GetText('ParentFormBoxNo'), 1, MaxStrLen(ParentBoxNo));
                ElementName := CopyStr(Mapping.GetText('XmlElementName'), 1, MaxStrLen(ElementName));
                ValueTypeText := Mapping.GetText('ValueType');
                case ValueTypeText of
                    'Amount':
                        ValueType := ValueType::Amount;
                    'OccupationCodes':
                        ValueType := ValueType::"Occupation Codes";
                    else
                        begin
                            MappingErrorInfo.ErrorType := ErrorType::Internal;
                            MappingErrorInfo.Message := StrSubstNo(UnsupportedMappingValueTypeErr, ValueTypeText, BoxNo);
                            MappingErrorInfo.DataClassification := DataClassification::SystemMetadata;
                            Error(MappingErrorInfo);
                        end;
                end;
                exit(ElementName <> '');
            end;
        end;
        exit(false);
    end;

    procedure ValidateLine(var SupplLine: Record "IRS 1099 Doc. Suppl. Line")
    var
        ValidationError: ErrorInfo;
    begin
        ValidationError := GetLineValidationError(SupplLine);
        if ValidationError.Message <> '' then
            RaiseDocumentValidationError(SupplLine."Document ID", ValidationError);
    end;

    local procedure GetLineValidationError(var SupplLine: Record "IRS 1099 Doc. Suppl. Line") ValidationError: ErrorInfo
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        DocLine: Record "IRS 1099 Form Doc. Line";
    begin
        ValidationError := ErrorInfo.Create('', false);
        DocHeader.Get(SupplLine."Document ID");
        ValidateSupplPeriodAndForm(DocHeader."Period No.", DocHeader."Form No.");
        ValidationError := GetTypedValuesValidationError(SupplLine, SupplLine."Value Type");
        if ValidationError.Message <> '' then
            exit(ValidationError);
        ValidationError := GetParentValidationError(SupplLine, DocLine);
        if ValidationError.Message <> '' then
            exit(ValidationError);
        if (SupplLine.Amount < 0) or (SupplLine.Amount > 999999999999999.99) or
           (SupplLine.Amount > DocLine.Amount)
        then
            ValidationError.Message := StrSubstNo(AmountErr, SupplLine."Supplemental Box No.", SupplLine.Amount, DocLine.Amount);
    end;

    procedure ValidateTypedValues(SupplLine: Record "IRS 1099 Doc. Suppl. Line"; ValueType: Enum "IRS 1099 Supplemental Type")
    var
        ValidationError: ErrorInfo;
    begin
        ValidationError := GetTypedValuesValidationError(SupplLine, ValueType);
        if ValidationError.Message <> '' then begin
            ValidationError.DataClassification := DataClassification::CustomerContent;
            Error(ValidationError);
        end;
    end;

    local procedure GetTypedValuesValidationError(SupplLine: Record "IRS 1099 Doc. Suppl. Line"; ValueType: Enum "IRS 1099 Supplemental Type") ValidationError: ErrorInfo
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        HelperIRIS: Codeunit "Helper IRIS";
        OccupationCodes: List of [Text];
    begin
        ValidationError := ErrorInfo.Create('', false);
        case ValueType of
            ValueType::Amount:
                if (SupplLine."Occupation Code 1" <> '') or (SupplLine."Occupation Code 2" <> '') then begin
                    ValidationError.Message := StrSubstNo(TypedValueErr, SupplLine."Supplemental Box No.");
                    exit(ValidationError);
                end;
            ValueType::"Occupation Codes":
                if SupplLine.Amount <> 0 then begin
                    ValidationError.Message := StrSubstNo(TypedValueErr, SupplLine."Supplemental Box No.");
                    exit(ValidationError);
                end;
        end;
        if (SupplLine."Occupation Code 1" = '') and (SupplLine."Occupation Code 2" = '') then
            exit;

        DocHeader.Get(SupplLine."Document ID");
        OccupationCodes := HelperIRIS.GetOccupationCodes(DocHeader."Period No.");
        ValidationError := GetOccupationCodeValidationError(SupplLine."Occupation Code 1", SupplLine."Supplemental Box No.", OccupationCodes);
        if ValidationError.Message <> '' then
            exit(ValidationError);
        exit(GetOccupationCodeValidationError(SupplLine."Occupation Code 2", SupplLine."Supplemental Box No.", OccupationCodes));
    end;

    local procedure GetOccupationCodeValidationError(OccupationCode: Text[3]; BoxNo: Code[20]; OccupationCodes: List of [Text]) ValidationError: ErrorInfo
    begin
        ValidationError := ErrorInfo.Create('', false);
        if (OccupationCode <> '') and not OccupationCodes.Contains(OccupationCode) then
            ValidationError.Message := StrSubstNo(UnsupportedOccupationCodeErr, OccupationCode, BoxNo);
    end;

    procedure GetParent(var SupplLine: Record "IRS 1099 Doc. Suppl. Line"; var DocLine: Record "IRS 1099 Form Doc. Line")
    var
        ValidationError: ErrorInfo;
    begin
        ValidationError := GetParentValidationError(SupplLine, DocLine);
        if ValidationError.Message <> '' then
            RaiseDocumentValidationError(SupplLine."Document ID", ValidationError);
    end;

    local procedure GetParentValidationError(var SupplLine: Record "IRS 1099 Doc. Suppl. Line"; var DocLine: Record "IRS 1099 Form Doc. Line") ValidationError: ErrorInfo
    begin
        ValidationError := ErrorInfo.Create('', false);
        DocLine.Reset();
        DocLine.SetRange("Document ID", SupplLine."Document ID");
        DocLine.SetRange("Form Box No.", SupplLine."Parent Form Box No.");
        if not DocLine.FindFirst() then
            ValidationError.Message := StrSubstNo(MissingParentErr, SupplLine."Parent Form Box No.", SupplLine."Supplemental Box No.");
    end;

    local procedure RaiseDocumentValidationError(DocumentID: Integer; ValidationError: ErrorInfo)
    begin
        ValidationError.Message := StrSubstNo(DocumentValidationErr, DocumentID, ValidationError.Message);
        ValidationError.DataClassification := DataClassification::CustomerContent;
        Error(ValidationError);
    end;

    procedure FilterAvailableSupplBoxes(var SupplBox: Record "IRS 1099 Suppl. Box"; DocumentID: Integer)
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        DocLine: Record "IRS 1099 Form Doc. Line";
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        DocHeader.Get(DocumentID);
        DocHeader.TestField(Status, DocHeader.Status::Open);
        ValidateSupplPeriodAndForm(DocHeader."Period No.", DocHeader."Form No.");
        SupplBox.Reset();
        SupplBox.ClearMarks();
        SupplBox.SetRange("Period No.", DocHeader."Period No.");
        SupplBox.SetRange("Form No.", DocHeader."Form No.");
        if SupplBox.FindSet() then
            repeat
                DocLine.SetRange("Document ID", DocumentID);
                DocLine.SetRange("Form Box No.", SupplBox."Parent Form Box No.");
                if not DocLine.IsEmpty() then
                    if not SupplLine.Get(DocumentID, SupplBox."No.") then begin
                        ValidateSupplBoxSetup(SupplBox);
                        SupplBox.Mark(true);
                    end;
            until SupplBox.Next() = 0;
        SupplBox.MarkedOnly(true);
        if SupplBox.IsEmpty() then
            Error(NoChoicesErr);
    end;
}
