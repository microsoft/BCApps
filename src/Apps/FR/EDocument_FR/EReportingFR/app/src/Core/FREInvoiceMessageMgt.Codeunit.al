// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Message;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Receivables;
using Microsoft.Utilities;
using System.Utilities;

codeunit 10975 "FR E-Invoice Message Mgt."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    Permissions = tabledata "FR E-Invoice Message" = rimd,
                  tabledata "FR E-Invoice Message VAT" = rid;

    internal procedure AcceptInvoice(EDocument: Record "E-Document")
    begin
        if not ResolveFrenchService(EDocument) then
            Error(FrenchServiceNotFoundErr, EDocument."Entry No");
        CheckBuyerResponseAllowed(EDocument);
        CreateAndSendMessage(EDocument, "FR E-Invoice Message Type"::Accepted, CreateGuid(), 0, '', Today(), 0, 0, '', '');
    end;

    internal procedure RefuseInvoice(EDocument: Record "E-Document"; ReasonCode: Code[20]; ReasonDescription: Text[500])
    begin
        if not ResolveFrenchService(EDocument) then
            Error(FrenchServiceNotFoundErr, EDocument."Entry No");
        CheckBuyerResponseAllowed(EDocument);
        CreateAndSendMessage(EDocument, "FR E-Invoice Message Type"::Refused, CreateGuid(), 0, '', Today(), 0, 0, ReasonCode, ReasonDescription);
    end;

    internal procedure ProcessApplication(DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        EDocPaymentOccurrenceMgt: Codeunit "E-Doc. Payment Occurrence Mgt.";
    begin
        EDocPaymentOccurrenceMgt.ProcessApplication(DetailedCustLedgEntry);
    end;

    internal procedure ProcessUnapplication(OldDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; NewDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        EDocPaymentOccurrenceMgt: Codeunit "E-Doc. Payment Occurrence Mgt.";
    begin
        EDocPaymentOccurrenceMgt.ProcessUnapplication(OldDetailedCustLedgEntry, NewDetailedCustLedgEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. Payment Occurrence Mgt.", 'OnAfterCreatePaymentOccurrence', '', false, false)]
    local procedure OnAfterCreatePaymentOccurrence(var EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence")
    begin
        CreatePaymentLifecycleMessage(EDocPaymentOccurrence);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Classification Eval. Data", 'OnCreateEvaluationDataOnAfterClassifyTablesToNormal', '', false, false)]
    local procedure ClassifyDataSensitivity()
    var
        DataClassificationEvalData: Codeunit "Data Classification Eval. Data";
    begin
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"FR E-Invoice Message");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"FR E-Invoice Message VAT");
    end;

    local procedure CreatePaymentLifecycleMessage(EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence")
    var
        CollectedMessage: Record "FR E-Invoice Message";
        EDocument: Record "E-Document";
        OriginalOccurrence: Record "E-Doc. Payment Occurrence";
    begin
        EDocument.Get(EDocPaymentOccurrence."E-Document Entry No.");
        if not ResolveEligibleFrenchService(EDocument) then
            exit;

        if EDocPaymentOccurrence.Type = EDocPaymentOccurrence.Type::Applied then begin
            if not IsCollectedReportingRequired(EDocument, EDocPaymentOccurrence."Detailed Ledger Entry No.") then
                exit;

            CreateAndSendMessage(
                EDocument, "FR E-Invoice Message Type"::Collected, EDocPaymentOccurrence."Source Occurrence ID",
                EDocPaymentOccurrence.Amount, EDocPaymentOccurrence."Currency Code", EDocPaymentOccurrence."Event Date",
                EDocPaymentOccurrence."Detailed Ledger Entry No.", 0, '', '');
            exit;
        end;

        if not OriginalOccurrence.Get(EDocPaymentOccurrence."Original Occurrence Entry No.") then
            exit;
        CollectedMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        CollectedMessage.SetRange(Type, CollectedMessage.Type::Collected);
        CollectedMessage.SetRange("Source Occurrence ID", OriginalOccurrence."Source Occurrence ID");
        if not CollectedMessage.FindFirst() then
            exit;

        CreateAndSendMessage(
            EDocument, "FR E-Invoice Message Type"::"Negative Collected", EDocPaymentOccurrence."Source Occurrence ID",
            -CollectedMessage.Amount, EDocPaymentOccurrence."Currency Code", EDocPaymentOccurrence."Event Date",
            EDocPaymentOccurrence."Detailed Ledger Entry No.", CollectedMessage."Entry No.", '', '');
    end;

    local procedure CreateAndSendMessage(EDocument: Record "E-Document"; MessageType: Enum "FR E-Invoice Message Type"; SourceOccurrenceID: Guid; Amount: Decimal; CurrencyCode: Code[10]; EventDate: Date; DetailedLedgerEntryNo: Integer; OriginalEntryNo: Integer; ReasonCode: Code[20]; ReasonDescription: Text[500])
    var
        FREInvoiceMessage: Record "FR E-Invoice Message";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        FREInvoiceMessageBuilder: Codeunit "FR E-Invoice Message Builder";
        TempBlob: Codeunit "Temp Blob";
    begin
        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange("Source Occurrence ID", SourceOccurrenceID);
        FREInvoiceMessage.SetRange(Type, MessageType);
        if FREInvoiceMessage.FindFirst() then begin
            if FREInvoiceMessage."E-Document Message Entry No." <> 0 then
                exit;
            FREInvoiceMessage.Delete(true);
        end;

        FREInvoiceMessage.Init();
        FREInvoiceMessage."E-Document Entry No." := EDocument."Entry No";
        FREInvoiceMessage.Type := MessageType;
        FREInvoiceMessage."Source Occurrence ID" := SourceOccurrenceID;
        FREInvoiceMessage."Original Entry No." := OriginalEntryNo;
        FREInvoiceMessage.Amount := Amount;
        FREInvoiceMessage."Currency Code" := CurrencyCode;
        FREInvoiceMessage."Event Date" := EventDate;
        FREInvoiceMessage."Detailed Ledger Entry No." := DetailedLedgerEntryNo;
        FREInvoiceMessage."Reason Code" := ReasonCode;
        FREInvoiceMessage."Reason Description" := ReasonDescription;
        FREInvoiceMessage."Created At" := CurrentDateTime();
        case MessageType of
            MessageType::Collected:
                FreezeSenderPlatform(EDocument, FREInvoiceMessage);
            MessageType::"Negative Collected":
                CopySenderPlatform(FREInvoiceMessage, OriginalEntryNo);
        end;
        FREInvoiceMessage.Insert();

        case MessageType of
            MessageType::Collected:
                CreateCollectedVATBreakdown(EDocument, FREInvoiceMessage);
            MessageType::"Negative Collected":
                CreateReversalVATBreakdown(FREInvoiceMessage, OriginalEntryNo);
        end;

        FREInvoiceMessageBuilder.BuildMessage(EDocument, FREInvoiceMessage, TempBlob);
        FREInvoiceMessage."E-Document Message Entry No." := EDocumentMessageAPI.CreateMessage(
            EDocument, "E-Document Message Type"::"FR Invoice Lifecycle", GetResponseType(MessageType), TempBlob);
        FREInvoiceMessage.Modify();
        EDocumentMessageAPI.QueueMessage(FREInvoiceMessage."E-Document Message Entry No.");
    end;

    local procedure FreezeSenderPlatform(EDocument: Record "E-Document"; var FREInvoiceMessage: Record "FR E-Invoice Message")
    var
        CompanyInformation: Record "Company Information";
        EDocumentService: Record "E-Document Service";
    begin
        EDocumentService.Get(EDocument.Service);
        FREInvoiceMessage."Sender Platform ID" := EDocumentService."FR Sender Platform ID";
        FREInvoiceMessage."Sender Platform Scheme" := EDocumentService."FR Sender Platform Scheme";
        FREInvoiceMessage."Sender Platform Name" := EDocumentService."FR Sender Platform Name";
        if FREInvoiceMessage."Sender Platform ID" = '' then
            exit;

        EDocument.TestField("Document Date");
        EDocument.TestField("Clearance Date");
        EDocumentService.TestField("FR Sender Platform Scheme");
        EDocumentService.TestField("FR Sender Platform Name");
        CompanyInformation.Get();
        CompanyInformation.TestField("Registration No.");
        CompanyInformation.TestField(Name);
        FREInvoiceMessage."Invoice Issue Date" := EDocument."Document Date";
        FREInvoiceMessage."Invoice Receipt At" := EDocument."Clearance Date";
        FREInvoiceMessage."Invoice Issuer ID" := NormalizeSIREN(CompanyInformation."Registration No.");
        FREInvoiceMessage."Invoice Issuer Scheme" := SIRENSchemeTok;
        FREInvoiceMessage."Invoice Issuer Name" := CompanyInformation.Name;
    end;

    local procedure CopySenderPlatform(var FREInvoiceMessage: Record "FR E-Invoice Message"; OriginalEntryNo: Integer)
    var
        OriginalFREInvoiceMessage: Record "FR E-Invoice Message";
    begin
        OriginalFREInvoiceMessage.Get(OriginalEntryNo);
        FREInvoiceMessage."Sender Platform ID" := OriginalFREInvoiceMessage."Sender Platform ID";
        FREInvoiceMessage."Sender Platform Scheme" := OriginalFREInvoiceMessage."Sender Platform Scheme";
        FREInvoiceMessage."Sender Platform Name" := OriginalFREInvoiceMessage."Sender Platform Name";
        FREInvoiceMessage."Invoice Issue Date" := OriginalFREInvoiceMessage."Invoice Issue Date";
        FREInvoiceMessage."Invoice Receipt At" := OriginalFREInvoiceMessage."Invoice Receipt At";
        FREInvoiceMessage."Invoice Issuer ID" := OriginalFREInvoiceMessage."Invoice Issuer ID";
        FREInvoiceMessage."Invoice Issuer Scheme" := OriginalFREInvoiceMessage."Invoice Issuer Scheme";
        FREInvoiceMessage."Invoice Issuer Name" := OriginalFREInvoiceMessage."Invoice Issuer Name";
    end;

    local procedure CreateCollectedVATBreakdown(EDocument: Record "E-Document"; var FREInvoiceMessage: Record "FR E-Invoice Message")
    var
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        AmountByVATKey: Dictionary of [Text, Decimal];
        VATCategoryByKey: Dictionary of [Text, Text];
        VATRateByKey: Dictionary of [Text, Decimal];
        VATKeys: List of [Text];
        CurrencyCode: Code[10];
        VATCategoryCode: Text;
        VATKey: Text;
        EligibleGrossAmount: Decimal;
        GrossAmount: Decimal;
        TotalGrossAmount: Decimal;
        VATRate: Decimal;
    begin
        CurrencyCode := ResolveCurrencyCode(FREInvoiceMessage."Currency Code");
        FindInvoiceVATEntries(VATEntry, EDocument, FREInvoiceMessage."Detailed Ledger Entry No.");
        VATEntry.SetLoadFields(
            "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Source Currency Code",
            "Source Currency VAT Base", "Source Currency VAT Amount", Base, Amount,
            "VAT Calculation Type", "Tax Jurisdiction Code", "Unrealized Amount", "Unrealized Base");
        VATPostingSetup.SetLoadFields("VAT %", "Tax Category");
        if VATEntry.FindSet() then
            repeat
                GrossAmount := GetVATEntryGrossAmount(VATEntry, CurrencyCode);
                TotalGrossAmount += GrossAmount;
                if IsVATEntryReportable(VATEntry) then begin
                    VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
                    VATRate := VATPostingSetup."VAT %";
                    VATCategoryCode := VATPostingSetup."Tax Category";
                    VATKey := GetVATAllocationKey(VATRate, VATCategoryCode);
                    AddVATAllocationBasis(
                        AmountByVATKey, VATRateByKey, VATCategoryByKey, VATKeys,
                        VATKey, VATRate, VATCategoryCode, GrossAmount);
                    EligibleGrossAmount += GrossAmount;
                end;
            until VATEntry.Next() = 0;

        if (VATKeys.Count() = 0) or (EligibleGrossAmount = 0) or (TotalGrossAmount = 0) then
            RaiseInternalError(StrSubstNo(VATBreakdownErr, EDocument."Document No."));

        FREInvoiceMessage.Amount := Round(
            FREInvoiceMessage.Amount * EligibleGrossAmount / TotalGrossAmount,
            GetAmountRoundingPrecision(CurrencyCode));
        FREInvoiceMessage.Modify();
        InsertAllocatedVATAmounts(
            FREInvoiceMessage, AmountByVATKey, VATRateByKey, VATCategoryByKey,
            VATKeys, EligibleGrossAmount, CurrencyCode);
    end;

    local procedure FindInvoiceVATEntries(var VATEntry: Record "VAT Entry"; EDocument: Record "E-Document"; DetailedLedgerEntryNo: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.Get(DetailedLedgerEntryNo);
        CustLedgerEntry.Get(DetailedCustLedgEntry."Cust. Ledger Entry No.");
        VATEntry.SetRange(Type, VATEntry.Type::Sale);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", EDocument."Document No.");
        VATEntry.SetRange("Posting Date", EDocument."Posting Date");
        VATEntry.SetRange("Transaction No.", CustLedgerEntry."Transaction No.");
    end;

    local procedure GetVATEntryGrossAmount(VATEntry: Record "VAT Entry"; CurrencyCode: Code[10]): Decimal
    var
        VATEntryCurrencyErrorInfo: ErrorInfo;
        GrossAmount: Decimal;
    begin
        case true of
            VATEntry."Source Currency Code" = CurrencyCode:
                GrossAmount := -(VATEntry."Source Currency VAT Base" + VATEntry."Source Currency VAT Amount");
            VATEntry."Source Currency Code" = '':
                GrossAmount := -(VATEntry.Base + VATEntry.Amount)
            else
                VATEntryCurrencyErrorInfo.ErrorType(ErrorType::Internal);
                VATEntryCurrencyErrorInfo.Message(StrSubstNo(VATEntryCurrencyErr, VATEntry."Entry No.", CurrencyCode));
                VATEntryCurrencyErrorInfo.DataClassification := DataClassification::SystemMetadata;
                Error(VATEntryCurrencyErrorInfo);
        end;

        if (GrossAmount = 0) and IsVATEntryReportable(VATEntry) then
            GrossAmount := -(VATEntry."Unrealized Base" + VATEntry."Unrealized Amount");

        exit(GrossAmount);
    end;

    local procedure IsVATEntryReportable(VATEntry: Record "VAT Entry"): Boolean
    begin
        exit(
            (VATEntry.GetUnrealizedVATType() > 0) and
            ((VATEntry."Unrealized Amount" <> 0) or (VATEntry."Unrealized Base" <> 0)));
    end;

    local procedure GetVATAllocationKey(VATRate: Decimal; VATCategoryCode: Text): Text
    begin
        exit(StrSubstNo('%1|%2', Format(VATRate, 0, 9), VATCategoryCode));
    end;

    local procedure AddVATAllocationBasis(var AmountByVATKey: Dictionary of [Text, Decimal]; var VATRateByKey: Dictionary of [Text, Decimal]; var VATCategoryByKey: Dictionary of [Text, Text]; var VATKeys: List of [Text]; VATKey: Text; VATRate: Decimal; VATCategoryCode: Text; GrossAmount: Decimal)
    begin
        if AmountByVATKey.ContainsKey(VATKey) then begin
            AmountByVATKey.Set(VATKey, AmountByVATKey.Get(VATKey) + GrossAmount);
            exit;
        end;

        AmountByVATKey.Add(VATKey, GrossAmount);
        VATRateByKey.Add(VATKey, VATRate);
        VATCategoryByKey.Add(VATKey, VATCategoryCode);
        InsertVATKeySorted(VATKeys, VATKey);
    end;

    local procedure InsertVATKeySorted(var VATKeys: List of [Text]; VATKey: Text)
    var
        ExistingVATKey: Text;
        Index: Integer;
    begin
        for Index := 1 to VATKeys.Count() do begin
            VATKeys.Get(Index, ExistingVATKey);
            if VATKey < ExistingVATKey then begin
                VATKeys.Insert(Index, VATKey);
                exit;
            end;
        end;
        VATKeys.Add(VATKey);
    end;

    local procedure InsertAllocatedVATAmounts(FREInvoiceMessage: Record "FR E-Invoice Message"; AmountByVATKey: Dictionary of [Text, Decimal]; VATRateByKey: Dictionary of [Text, Decimal]; VATCategoryByKey: Dictionary of [Text, Text]; VATKeys: List of [Text]; EligibleGrossAmount: Decimal; CurrencyCode: Code[10])
    var
        FREInvoiceMessageVAT: Record "FR E-Invoice Message VAT";
        AllocatedAmount: Decimal;
        RemainingAmount: Decimal;
        RoundingPrecision: Decimal;
        VATKey: Text;
        LineNo: Integer;
    begin
        RoundingPrecision := GetAmountRoundingPrecision(CurrencyCode);
        RemainingAmount := FREInvoiceMessage.Amount;
        foreach VATKey in VATKeys do begin
            LineNo += 10000;
            if LineNo div 10000 = VATKeys.Count() then
                AllocatedAmount := RemainingAmount
            else begin
                AllocatedAmount := Round(
                    FREInvoiceMessage.Amount * AmountByVATKey.Get(VATKey) / EligibleGrossAmount,
                    RoundingPrecision);
                RemainingAmount -= AllocatedAmount;
            end;
            InsertVATBreakdown(
                FREInvoiceMessageVAT, FREInvoiceMessage."Entry No.", LineNo,
                VATRateByKey.Get(VATKey), VATCategoryByKey.Get(VATKey), AllocatedAmount, CurrencyCode);
        end;
    end;

    local procedure CreateReversalVATBreakdown(FREInvoiceMessage: Record "FR E-Invoice Message"; OriginalEntryNo: Integer)
    var
        OriginalMessageVAT: Record "FR E-Invoice Message VAT";
        ReversalMessageVAT: Record "FR E-Invoice Message VAT";
    begin
        OriginalMessageVAT.SetRange("Message Entry No.", OriginalEntryNo);
        if not OriginalMessageVAT.FindSet() then
            RaiseInternalError(StrSubstNo(OriginalVATBreakdownErr, OriginalEntryNo));

        repeat
            InsertVATBreakdown(
                ReversalMessageVAT, FREInvoiceMessage."Entry No.", OriginalMessageVAT."Line No.",
                OriginalMessageVAT."VAT %", OriginalMessageVAT."VAT Category Code",
                -OriginalMessageVAT.Amount, OriginalMessageVAT."Currency Code");
        until OriginalMessageVAT.Next() = 0;
    end;

    local procedure RaiseInternalError(ErrorMessage: Text)
    var
        InternalErrorInfo: ErrorInfo;
    begin
        InternalErrorInfo.ErrorType := ErrorType::Internal;
        InternalErrorInfo.Message := ErrorMessage;
        InternalErrorInfo.DataClassification := DataClassification::SystemMetadata;
        Error(InternalErrorInfo);
    end;

    local procedure InsertVATBreakdown(var FREInvoiceMessageVAT: Record "FR E-Invoice Message VAT"; MessageEntryNo: Integer; LineNo: Integer; VATRate: Decimal; VATCategoryCode: Text; Amount: Decimal; CurrencyCode: Code[10])
    begin
        FREInvoiceMessageVAT.Init();
        FREInvoiceMessageVAT."Message Entry No." := MessageEntryNo;
        FREInvoiceMessageVAT."Line No." := LineNo;
        FREInvoiceMessageVAT."VAT %" := VATRate;
        FREInvoiceMessageVAT."VAT Category Code" := CopyStr(VATCategoryCode, 1, MaxStrLen(FREInvoiceMessageVAT."VAT Category Code"));
        FREInvoiceMessageVAT.Amount := Amount;
        FREInvoiceMessageVAT."Currency Code" := CurrencyCode;
        FREInvoiceMessageVAT.Insert();
    end;

    local procedure GetAmountRoundingPrecision(CurrencyCode: Code[10]): Decimal
    var
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        if CurrencyCode = GeneralLedgerSetup."LCY Code" then
            exit(GeneralLedgerSetup."Amount Rounding Precision");

        Currency.Get(CurrencyCode);
        Currency.TestField("Amount Rounding Precision");
        exit(Currency."Amount Rounding Precision");
    end;

    local procedure NormalizeSIREN(RegistrationNo: Text): Code[9]
    var
        NormalizedSIREN: Text;
    begin
        NormalizedSIREN := DelChr(RegistrationNo, '=', ' .-/');
        if (StrLen(NormalizedSIREN) <> 9) or (DelChr(NormalizedSIREN, '=', '0123456789') <> '') then
            Error(InvalidSIRENErr, RegistrationNo);
        exit(CopyStr(NormalizedSIREN, 1, 9));
    end;

    local procedure ResolveCurrencyCode(CurrencyCode: Code[10]): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if CurrencyCode <> '' then
            exit(CurrencyCode);

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("LCY Code");
        exit(GeneralLedgerSetup."LCY Code");
    end;

    local procedure ResolveEligibleFrenchService(var EDocument: Record "E-Document"): Boolean
    var
        EDocumentService: Record "E-Document Service";
        EDocumentServiceStatus: Record "E-Document Service Status";
    begin
        EDocumentServiceStatus.SetRange("E-Document Entry No", EDocument."Entry No");
        EDocumentServiceStatus.SetFilter(Status, '%1|%2', EDocumentServiceStatus.Status::Approved, EDocumentServiceStatus.Status::Cleared);
        if EDocument.Service <> '' then begin
            EDocumentServiceStatus.SetRange("E-Document Service Code", EDocument.Service);
            if EDocumentServiceStatus.FindFirst() then
                if IsSupportedFrenchService(EDocumentServiceStatus."E-Document Service Code", EDocumentService) then
                    exit(true);
            EDocumentServiceStatus.SetRange("E-Document Service Code");
        end;

        if EDocumentServiceStatus.FindSet() then
            repeat
                if IsSupportedFrenchService(EDocumentServiceStatus."E-Document Service Code", EDocumentService) then begin
                    EDocument.Service := EDocumentService.Code;
                    exit(true);
                end;
            until EDocumentServiceStatus.Next() = 0;

        exit(false);
    end;

    local procedure ResolveFrenchService(var EDocument: Record "E-Document"): Boolean
    var
        EDocumentService: Record "E-Document Service";
        EDocumentServiceStatus: Record "E-Document Service Status";
    begin
        if IsSupportedFrenchService(EDocument.Service, EDocumentService) then
            exit(true);

        EDocumentServiceStatus.SetRange("E-Document Entry No", EDocument."Entry No");
        if EDocumentServiceStatus.FindSet() then
            repeat
                if IsSupportedFrenchService(EDocumentServiceStatus."E-Document Service Code", EDocumentService) then begin
                    EDocument.Service := EDocumentService.Code;
                    exit(true);
                end;
            until EDocumentServiceStatus.Next() = 0;

        exit(false);
    end;

    local procedure IsSupportedFrenchService(ServiceCode: Code[20]; var EDocumentService: Record "E-Document Service"): Boolean
    begin
        if not EDocumentService.Get(ServiceCode) then
            exit(false);
        exit(EDocumentService."Document Format" in [EDocumentService."Document Format"::"Peppol BIS 3.0 FR", EDocumentService."Document Format"::"Factur-X FR"]);
    end;

    local procedure IsCollectedReportingRequired(EDocument: Record "E-Document"; DetailedLedgerEntryNo: Integer): Boolean
    var
        VATEntry: Record "VAT Entry";
    begin
        FindInvoiceVATEntries(VATEntry, EDocument, DetailedLedgerEntryNo);
        VATEntry.SetLoadFields("VAT Calculation Type", "Tax Jurisdiction Code", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Unrealized Amount", "Unrealized Base");
        if VATEntry.FindSet() then
            repeat
                if IsVATEntryReportable(VATEntry) then
                    exit(true);
            until VATEntry.Next() = 0;

        exit(false);
    end;

    local procedure CheckBuyerResponseAllowed(EDocument: Record "E-Document")
    var
        FREInvoiceMessage: Record "FR E-Invoice Message";
    begin
        EDocument.TestField(Direction, EDocument.Direction::Incoming);
        EDocument.TestField("Document Type", EDocument."Document Type"::"Purchase Invoice");
        EDocument.TestField(Service);

        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetFilter(Type, '%1|%2', FREInvoiceMessage.Type::Accepted, FREInvoiceMessage.Type::Refused);
        if not FREInvoiceMessage.IsEmpty() then
            Error(AlreadyRespondedErr, EDocument."Document No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"E-Document", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure DeleteFREInvoiceMessages(var Rec: Record "E-Document"; RunTrigger: Boolean)
    var
        FREInvoiceMessage: Record "FR E-Invoice Message";
    begin
        FREInvoiceMessage.SetRange("E-Document Entry No.", Rec."Entry No");
        FREInvoiceMessage.DeleteAll(true);
    end;

    local procedure GetResponseType(MessageType: Enum "FR E-Invoice Message Type"): Enum "E-Doc. Response Type"
    begin
        case MessageType of
            MessageType::Accepted:
                exit("E-Doc. Response Type"::Accepted);
            MessageType::Refused:
                exit("E-Doc. Response Type"::Refused);
            else
                exit("E-Doc. Response Type"::None);
        end;
    end;

    var
        SIRENSchemeTok: Label '0002', Locked = true;
        AlreadyRespondedErr: Label 'Invoice %1 already has a buyer response.', Comment = '%1 = invoice number';
        FrenchServiceNotFoundErr: Label 'A supported French service could not be found for E-Document %1.', Comment = '%1 = E-Document entry number';
        VATBreakdownErr: Label 'A reportable VAT breakdown could not be determined for posted sales invoice %1.', Comment = '%1 = posted sales invoice number';
        VATEntryCurrencyErr: Label 'VAT entry %1 does not contain amounts in lifecycle currency %2.', Comment = '%1 = VAT entry number, %2 = currency code';
        OriginalVATBreakdownErr: Label 'The VAT breakdown for original French invoice message %1 does not exist.', Comment = '%1 = French invoice message entry number';
        InvalidSIRENErr: Label 'Company registration number %1 cannot be normalized to a nine-digit SIREN.', Comment = '%1 = company registration number';
}