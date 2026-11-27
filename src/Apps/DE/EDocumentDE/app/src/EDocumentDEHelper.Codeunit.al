// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.CRM.Team;
using Microsoft.eServices.EDocument;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using System.Reflection;

// Translation keyword reference (Leitweg-ID specification terminology):
//   E-Invoice Routing No. = Leitweg-ID
//   coarse routing         = Grobadressierung
//   fine routing           = Feinadressierung
//   check digit            = Prüfziffer
//   state code             = Bundesland-Code
//   federal code           = Bund-Code

codeunit 11038 "E-Document DE Helper"
{
    Access = Public;

    /// <summary>
    /// Checks whether the given routing number (Leitweg-ID) is structurally valid.
    /// </summary>
    /// <param name="RoutingNo">The routing number to validate.</param>
    /// <returns>True if the routing number passes all structural validation rules; otherwise, false.</returns>
    procedure IsValidRoutingNo(RoutingNo: Text[50]): Boolean
    begin
        exit(TryValidateRoutingNo(RoutingNo));
    end;

    /// <summary>
    /// Determines whether the source document has a routing number (Leitweg-ID) available.
    /// First checks the document's Buyer Reference field for a valid routing number,
    /// then falls back to the bill-to customer's E-Invoice Routing No.
    /// </summary>
    /// <param name="SourceDocumentHeader">A RecordRef pointing to a supported document header (Sales Header, Sales Invoice Header, Sales Cr.Memo Header, Service Header, Service Invoice Header, or Service Cr.Memo Header).</param>
    /// <returns>True if a routing number is found on the document or on the bill-to customer; otherwise, false.</returns>
    procedure HasRoutingNo(SourceDocumentHeader: RecordRef): Boolean
    begin
        exit(GetBuyerRoutingNo(SourceDocumentHeader) <> '');
    end;

    /// <summary>
    /// Gets the routing number (Leitweg-ID) of the buyer.
    /// Uses the document's Buyer Reference when it is a structurally valid routing number,
    /// otherwise the bill-to customer's E-Invoice Routing No.
    /// </summary>
    /// <param name="SourceDocumentHeader">A RecordRef pointing to a supported document header.</param>
    /// <returns>The routing number, or empty text if neither the document nor the bill-to customer has one.</returns>
    internal procedure GetBuyerRoutingNo(SourceDocumentHeader: RecordRef): Text
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        BuyerReferenceFieldRef: FieldRef;
        CustomerNoFieldRef: FieldRef;
        BuyerReferenceValue: Text;
    begin
        if not IsSupportedDocumentType(SourceDocumentHeader) then
            exit('');

        BuyerReferenceFieldRef := SourceDocumentHeader.Field(SalesInvoiceHeader.FieldNo("Buyer Reference"));
        BuyerReferenceValue := BuyerReferenceFieldRef.Value();
        if (BuyerReferenceValue <> '') and (StrLen(BuyerReferenceValue) <= 50) then
            if IsValidRoutingNo(CopyStr(BuyerReferenceValue, 1, 50)) then
                exit(BuyerReferenceValue);

        CustomerNoFieldRef := SourceDocumentHeader.Field(SalesInvoiceHeader.FieldNo("Bill-to Customer No."));
        Customer.SetLoadFields("E-Invoice Routing No.");
        if Customer.Get(Format(CustomerNoFieldRef.Value)) then
            exit(Customer."E-Invoice Routing No.");

        exit('');
    end;

    /// <summary>
    /// Gets the e-mail address of the buyer. The XRechnung and ZUGFeRD exports write it as buyer contact e-mail (BT-58),
    /// and it is one of the sources for the buyer electronic address (BT-49).
    /// The address is resolved the same way as when the document is e-mailed to the bill-to customer:
    /// e-mail parameters of the document, the "Send To Email" of the bill-to customer's document layouts
    /// (only when an e-mail body layout is set up for the usage), the document's Sell-to E-Mail and the bill-to customer's E-Mail.
    /// </summary>
    /// <param name="RecordVariant">A supported document header record, or a RecordRef pointing to one.</param>
    /// <returns>The e-mail address, or empty text if none of the sources yield a value.</returns>
    internal procedure GetBuyerEMail(RecordVariant: Variant): Text[250]
    var
        TempBodyReportSelections: Record "Report Selections" temporary;
        ReportSelections: Record "Report Selections";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DataTypeManagement: Codeunit "Data Type Management";
        SourceDocumentHeader: RecordRef;
        DocumentRecordVariant: Variant;
        ReportUsage: Enum "Report Selection Usage";
        BillToCustomerNo: Code[20];
    begin
        if not DataTypeManagement.GetRecordRef(RecordVariant, SourceDocumentHeader) then
            exit('');
        if not IsSupportedDocumentType(SourceDocumentHeader) then
            exit('');

        BillToCustomerNo := SourceDocumentHeader.Field(SalesInvoiceHeader.FieldNo("Bill-to Customer No.")).Value();
        ReportUsage := GetBuyerEMailReportUsage(SourceDocumentHeader);
        if RecordVariant.IsRecordRef() then
            GetDocumentRecordVariant(SourceDocumentHeader, DocumentRecordVariant)
        else
            DocumentRecordVariant := RecordVariant;

        ReportSelections.FindEmailBodyUsageForCust(ReportUsage, BillToCustomerNo, TempBodyReportSelections);
        exit(ReportSelections.GetEmailAddressExt(ReportUsage.AsInteger(), DocumentRecordVariant, BillToCustomerNo, TempBodyReportSelections));
    end;

    /// <summary>
    /// Gets the buyer electronic address (BT-49) and its scheme identifier (BT-49-1).
    /// Sources in this order: the buyer e-mail (scheme EM), the routing number (Leitweg-ID, scheme 0204),
    /// and the bill-to customer's GLN (scheme 0088) when the customer uses GLN in electronic documents.
    /// Subscribers to OnAfterGetBuyerElectronicAddress can provide a different address or scheme.
    /// </summary>
    /// <param name="RecordVariant">A supported document header record, or a RecordRef pointing to one.</param>
    /// <param name="EDocumentService">The E-Document Service that is used for the export. Passed on to OnAfterGetBuyerElectronicAddress.</param>
    /// <param name="EndpointID">Returns the buyer electronic address.</param>
    /// <param name="SchemeID">Returns the scheme identifier of the buyer electronic address.</param>
    /// <returns>True if a buyer electronic address was found; otherwise, false.</returns>
    internal procedure GetBuyerElectronicAddress(RecordVariant: Variant; EDocumentService: Record "E-Document Service"; var EndpointID: Text; var SchemeID: Text): Boolean
    var
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DataTypeManagement: Codeunit "Data Type Management";
        SourceDocumentHeader: RecordRef;
        BuyerEMail: Text;
        RoutingNo: Text;
    begin
        Clear(EndpointID);
        Clear(SchemeID);
        if not DataTypeManagement.GetRecordRef(RecordVariant, SourceDocumentHeader) then
            exit(false);
        if not IsSupportedDocumentType(SourceDocumentHeader) then
            exit(false);

        BuyerEMail := GetBuyerEMail(RecordVariant);
        RoutingNo := GetBuyerRoutingNo(SourceDocumentHeader);
        if not SetElectronicAddress(BuyerEMail, EMailSchemeIDTok, EndpointID, SchemeID) then
            SetElectronicAddress(RoutingNo, RoutingNoSchemeIDTok, EndpointID, SchemeID);

        if EndpointID = '' then begin
            Customer.SetLoadFields(GLN, "Use GLN in Electronic Document");
            if Customer.Get(Format(SourceDocumentHeader.Field(SalesInvoiceHeader.FieldNo("Bill-to Customer No.")).Value())) then
                if Customer."Use GLN in Electronic Document" then
                    SetElectronicAddress(Customer.GLN, GLNSchemeIDTok, EndpointID, SchemeID);
        end;

        OnAfterGetBuyerElectronicAddress(SourceDocumentHeader, EDocumentService, EndpointID, SchemeID);
        exit(EndpointID <> '');
    end;

    /// <summary>
    /// Checks that a buyer electronic address (BT-49) can be resolved for the given document and raises an error if not.
    /// XRechnung requires the buyer electronic address (PEPPOL-EN16931-R010). Uses GetBuyerElectronicAddress,
    /// so the check resolves the address the same way as the export.
    /// </summary>
    /// <param name="EDocumentService">The E-Document Service that is used for the export.</param>
    /// <param name="SourceDocumentHeader">A RecordRef pointing to a supported document header.</param>
    internal procedure CheckBuyerElectronicAddressMandatory(EDocumentService: Record "E-Document Service"; SourceDocumentHeader: RecordRef)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        RecordVariant: Variant;
        EndpointID: Text;
        SchemeID: Text;
    begin
        if not IsSupportedDocumentType(SourceDocumentHeader) then
            exit;

        RecordVariant := SourceDocumentHeader;
        if GetBuyerElectronicAddress(RecordVariant, EDocumentService, EndpointID, SchemeID) then
            exit;

        Error(
            MissingBuyerElectronicAddressErr,
            SourceDocumentHeader.Field(SalesInvoiceHeader.FieldNo("No.")).Value(),
            SourceDocumentHeader.Field(SalesInvoiceHeader.FieldNo("Bill-to Customer No.")).Value());
    end;

    local procedure SetElectronicAddress(Value: Text; ValueSchemeID: Text; var EndpointID: Text; var SchemeID: Text): Boolean
    begin
        if Value = '' then
            exit(false);
        EndpointID := Value;
        SchemeID := ValueSchemeID;
        exit(true);
    end;

    local procedure GetBuyerEMailReportUsage(SourceDocumentHeader: RecordRef): Enum "Report Selection Usage"
    var
        SalesHeader: Record "Sales Header";
        ServiceHeader: Record "Service Header";
    begin
        case SourceDocumentHeader.Number() of
            Database::"Sales Cr.Memo Header",
            Database::"Service Cr.Memo Header":
                exit("Report Selection Usage"::"S.Cr.Memo");
            Database::"Sales Header":
                begin
                    SourceDocumentHeader.SetTable(SalesHeader);
                    if SalesHeader."Document Type" in [SalesHeader."Document Type"::"Credit Memo", SalesHeader."Document Type"::"Return Order"] then
                        exit("Report Selection Usage"::"S.Cr.Memo");
                end;
            Database::"Service Header":
                begin
                    SourceDocumentHeader.SetTable(ServiceHeader);
                    if ServiceHeader."Document Type" = ServiceHeader."Document Type"::"Credit Memo" then
                        exit("Report Selection Usage"::"S.Cr.Memo");
                end;
        end;
        exit("Report Selection Usage"::"S.Invoice");
    end;

    local procedure GetDocumentRecordVariant(SourceDocumentHeader: RecordRef; var DocumentRecordVariant: Variant)
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        case SourceDocumentHeader.Number() of
            Database::"Sales Header":
                begin
                    SourceDocumentHeader.SetTable(SalesHeader);
                    DocumentRecordVariant := SalesHeader;
                end;
            Database::"Sales Invoice Header":
                begin
                    SourceDocumentHeader.SetTable(SalesInvoiceHeader);
                    DocumentRecordVariant := SalesInvoiceHeader;
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    SourceDocumentHeader.SetTable(SalesCrMemoHeader);
                    DocumentRecordVariant := SalesCrMemoHeader;
                end;
            Database::"Service Header":
                begin
                    SourceDocumentHeader.SetTable(ServiceHeader);
                    DocumentRecordVariant := ServiceHeader;
                end;
            Database::"Service Invoice Header":
                begin
                    SourceDocumentHeader.SetTable(ServiceInvoiceHeader);
                    DocumentRecordVariant := ServiceInvoiceHeader;
                end;
            Database::"Service Cr.Memo Header":
                begin
                    SourceDocumentHeader.SetTable(ServiceCrMemoHeader);
                    DocumentRecordVariant := ServiceCrMemoHeader;
                end;
        end;
    end;

    /// <summary>
    /// Raised after the buyer electronic address (BT-49) has been resolved. Use it to provide a different
    /// buyer electronic address, for example a Peppol participant identifier with another scheme.
    /// </summary>
    /// <param name="SourceDocumentHeader">The document header the address is resolved for.</param>
    /// <param name="EDocumentService">The E-Document Service that is used for the export.</param>
    /// <param name="EndpointID">The resolved buyer electronic address. Can be changed.</param>
    /// <param name="SchemeID">The scheme identifier of the buyer electronic address. Can be changed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetBuyerElectronicAddress(SourceDocumentHeader: RecordRef; EDocumentService: Record "E-Document Service"; var EndpointID: Text; var SchemeID: Text)
    begin
    end;

    /// <summary>
    /// Validates the structure of a routing number (Leitweg-ID) and raises an error if it is invalid.
    /// Validates the overall length, segment count, coarse routing (Grobadressierung), optional fine routing (Feinadressierung), and check digit (Prüfziffer) using Mod 97-10.
    /// </summary>
    /// <param name="RoutingNo">The routing number to validate. An empty value is accepted without error.</param>
    procedure ValidateRoutingNo(RoutingNo: Text[50])
    var
        Parts: List of [Text];
        CoarseRouting: Text;
        FineRouting: Text;
        CheckDigitText: Text;
    begin
        if RoutingNo = '' then
            exit;

        if (StrLen(RoutingNo) < 5) or (StrLen(RoutingNo) > 46) then
            Error(OverallLengthErr, StrLen(RoutingNo));

        Parts := RoutingNo.Split('-');
        if not (Parts.Count() in [2, 3]) then
            Error(SegmentCountErr);

        CoarseRouting := Parts.Get(1);
        if Parts.Count() = 3 then
            FineRouting := Parts.Get(2);
        CheckDigitText := Parts.Get(Parts.Count());

        ValidateCoarseRouting(CoarseRouting);
        if FineRouting <> '' then
            ValidateFineRouting(FineRouting);
        ValidateCheckDigitFormat(CheckDigitText);
        ValidateCheckDigitMod97(CoarseRouting, FineRouting, CheckDigitText);
    end;

    local procedure ValidateCoarseRouting(CoarseRouting: Text)
    var
        TypeHelper: Codeunit "Type Helper";
        StateCode: Integer;
        StateCodeText: Text;
        i: Integer;
    begin
        if CoarseRouting = '' then
            Error(CoarseDigitsErr, CoarseRouting);

        for i := 1 to StrLen(CoarseRouting) do
            if not TypeHelper.IsDigit(CoarseRouting[i]) then
                Error(CoarseDigitsErr, CoarseRouting);

        if not (StrLen(CoarseRouting) in [2, 3, 5, 8, 9, 12]) then
            Error(CoarseLengthErr, StrLen(CoarseRouting));

        StateCodeText := CopyStr(CoarseRouting, 1, 2);
        Evaluate(StateCode, StateCodeText);
        if not ((StateCode in [1 .. 16]) or (StateCode = 99)) then
            Error(StateCodeErr, StateCodeText);
    end;

    local procedure ValidateFineRouting(FineRouting: Text)
    begin
        if (StrLen(FineRouting) < 1) or (StrLen(FineRouting) > 30) then
            Error(FineRoutingLengthErr, FineRouting);

        if not IsAlphanumOnly(FineRouting) then
            Error(FineRoutingCharsErr, FineRouting);
    end;

    local procedure ValidateCheckDigitFormat(CheckDigitText: Text)
    var
        TypeHelper: Codeunit "Type Helper";
        i: Integer;
    begin
        if StrLen(CheckDigitText) <> 2 then
            Error(CheckDigitFormatErr, CheckDigitText);

        for i := 1 to StrLen(CheckDigitText) do
            if not TypeHelper.IsDigit(CheckDigitText[i]) then
                Error(CheckDigitFormatErr, CheckDigitText);
    end;

    local procedure ValidateCheckDigitMod97(CoarseRouting: Text; FineRouting: Text; CheckDigitText: Text)
    var
        FullNumeric: Text;
    begin
        FullNumeric := ConvertToNumericString(CoarseRouting + FineRouting + CheckDigitText);
        if ComputeMod97(FullNumeric) <> 1 then
            Error(CheckDigitVerifyErr);
    end;

    local procedure ConvertToNumericString(Input: Text): Text
    var
        TypeHelper: Codeunit "Type Helper";
        UpperInput: Text;
        Result: Text;
        Ch: Char;
        i: Integer;
    begin
        UpperInput := UpperCase(Input);
        for i := 1 to StrLen(UpperInput) do begin
            Ch := UpperInput[i];
            if TypeHelper.IsLatinLetter(Ch) then
                Result += Format(Ch - 55) // A=65 → 10, B=66 → 11, ..., Z=90 → 35
            else
                Result += Format(Ch - 48); // '0'=48 → 0, '1'=49 → 1, etc.
        end;
        exit(Result);
    end;

    local procedure ComputeMod97(NumericString: Text): Integer
    var
        Remainder: Integer;
        DigitValue: Integer;
        i: Integer;
    begin
        Remainder := 0;
        for i := 1 to StrLen(NumericString) do begin
            Evaluate(DigitValue, CopyStr(NumericString, i, 1));
            Remainder := (Remainder * 10 + DigitValue) mod 97;
        end;
        exit(Remainder);
    end;

    local procedure IsAlphanumOnly(Input: Text): Boolean
    var
        TypeHelper: Codeunit "Type Helper";
        Ch: Char;
        i: Integer;
    begin
        if Input = '' then
            exit(false);
        for i := 1 to StrLen(Input) do begin
            Ch := Input[i];
            if not (TypeHelper.IsDigit(Ch) or TypeHelper.IsLatinLetter(Ch)) then
                exit(false);
        end;
        exit(true);
    end;

    local procedure IsSupportedDocumentType(SourceDocumentHeader: RecordRef): Boolean
    begin
        exit(SourceDocumentHeader.Number() in
            [Database::"Sales Header",
            Database::"Sales Invoice Header",
            Database::"Sales Cr.Memo Header",
            Database::"Service Header",
            Database::"Service Invoice Header",
            Database::"Service Cr.Memo Header"]);
    end;

    /// <summary>
    /// Resolves the Buyer Reference (BT-10) value using a priority chain.
    /// Priority 1: Document Buyer Reference field — accepted only if it is a structurally valid Leitweg-ID.
    /// Priority 2: Bill-to Customer E-Invoice Routing No.
    /// Priority 3a: Document Buyer Reference if explicitly set but not a valid Leitweg-ID (preserves user intent and migration data).
    /// Priority 3b: Your Reference.
    /// </summary>
    /// <param name="DocumentBuyerReference">The Buyer Reference value stored on the document header.</param>
    /// <param name="BillToCustomerNo">The Bill-to Customer No. used to look up the customer's E-Invoice Routing No.</param>
    /// <param name="YourReference">The Your Reference value stored on the document header.</param>
    /// <returns>The resolved Buyer Reference value, or empty text if none of the sources yield a value.</returns>
    internal procedure GetBuyerReferenceValue(DocumentBuyerReference: Text[100]; BillToCustomerNo: Code[20]; YourReference: Text[35]): Text
    var
        Customer: Record Customer;
    begin
        // Priority 1: Document Buyer Reference — only if it is a structurally valid Leitweg-ID
        if (DocumentBuyerReference <> '') then
            if (StrLen(DocumentBuyerReference) <= 50) then
                if IsValidRoutingNo(CopyStr(DocumentBuyerReference, 1, 50)) then
                    exit(DocumentBuyerReference);

        // Priority 2: Bill-to Customer E-Invoice Routing No.
        Customer.SetLoadFields("E-Invoice Routing No.");
        if Customer.Get(BillToCustomerNo) then
            if Customer."E-Invoice Routing No." <> '' then
                exit(Customer."E-Invoice Routing No.");

        // Priority 3a: Document Buyer Reference if explicitly set but not a valid Leitweg-ID
        //   (preserves explicit user intent and old migration data)
        if DocumentBuyerReference <> '' then
            exit(DocumentBuyerReference);

        // Priority 3b: Your Reference
        exit(YourReference);
    end;

    /// <summary>
    /// Checks whether a Buyer Reference (BT-10) can be resolved for the given document and raises an error if not.
    /// Only runs when the E-Document Service has "Buyer Reference Mandatory" enabled and the document is a supported type.
    /// Uses GetBuyerReferenceValue to resolve the reference via the same priority chain used during export.
    /// </summary>
    /// <param name="EDocumentService">The E-Document Service record. Must have "Buyer Reference Mandatory" set to true for the check to run.</param>
    /// <param name="SourceDocumentHeader">A RecordRef pointing to a supported document header.</param>
    internal procedure CheckBuyerReferenceMandatory(EDocumentService: Record "E-Document Service"; SourceDocumentHeader: RecordRef)
    begin
        if not EDocumentService."Buyer Reference Mandatory" then
            exit;
        CheckBuyerReferenceMandatory(SourceDocumentHeader);
    end;

    /// <summary>
    /// Checks whether a Buyer Reference (BT-10) can be resolved for the given document and raises an error if not,
    /// regardless of the E-Document Service setting. XRechnung always requires the Buyer Reference (BR-DE-15).
    /// </summary>
    /// <param name="SourceDocumentHeader">A RecordRef pointing to a supported document header.</param>
    internal procedure CheckBuyerReferenceMandatory(SourceDocumentHeader: RecordRef)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        BuyerReferenceFieldRef: FieldRef;
        CustomerNoFieldRef: FieldRef;
        YourReferenceFieldRef: FieldRef;
        DocumentNoFieldRef: FieldRef;
        BuyerReference: Text[100];
        BillToCustomerNo: Code[20];
        YourReference: Text[35];
        BuyerReferenceValue: Text;
        MissingBuyerReferenceErr: Label 'Buyer Reference is mandatory for document %1.', Comment = '%1 = Document No.';
    begin
        if not IsSupportedDocumentType(SourceDocumentHeader) then
            exit;
        BuyerReferenceFieldRef := SourceDocumentHeader.Field(SalesInvoiceHeader.FieldNo("Buyer Reference"));
        CustomerNoFieldRef := SourceDocumentHeader.Field(SalesInvoiceHeader.FieldNo("Bill-to Customer No."));
        YourReferenceFieldRef := SourceDocumentHeader.Field(SalesInvoiceHeader.FieldNo("Your Reference"));
        BuyerReference := BuyerReferenceFieldRef.Value();
        BillToCustomerNo := CustomerNoFieldRef.Value();
        YourReference := YourReferenceFieldRef.Value();
        BuyerReferenceValue := GetBuyerReferenceValue(BuyerReference, BillToCustomerNo, YourReference);
        if BuyerReferenceValue = '' then begin
            DocumentNoFieldRef := SourceDocumentHeader.Field(SalesInvoiceHeader.FieldNo("No."));
            Error(MissingBuyerReferenceErr, DocumentNoFieldRef.Value());
        end;
    end;

    /// <summary>
    /// Checks that the seller contact (BG-6) can be fully supplied from the source that the export uses,
    /// so that BR-DE-2 (group present), BR-DE-5 (BT-41 name), BR-DE-6 (BT-42 telephone) and
    /// BR-DE-7 (BT-43 e-mail) are satisfied.
    /// When a salesperson is assigned to the document, the salesperson supplies all three terms and must
    /// therefore have Name, Phone No. and E-Mail. Otherwise they come from Company Information.
    /// The Company Information E-Mail is not checked here: it is the same field that supplies the seller
    /// electronic address (BT-34), which CheckCompanyInfoMandatory already requires in the format codeunits.
    /// </summary>
    /// <param name="SourceDocumentHeader">A RecordRef pointing to a supported document header.</param>
    internal procedure CheckSellerContactMandatory(SourceDocumentHeader: RecordRef)
    var
        CompanyInformation: Record "Company Information";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        SalespersonCode: Code[20];
    begin
        if not IsSupportedDocumentType(SourceDocumentHeader) then
            exit;

        SalespersonCode := GetSalespersonCode(SourceDocumentHeader);
        if SalespersonCode <> '' then begin
            SalespersonPurchaser.SetLoadFields(Name, "Phone No.", "E-Mail");
            if SalespersonPurchaser.Get(SalespersonCode) then begin
                if SalespersonPurchaser.Name = '' then
                    SalespersonPurchaser.FieldError(Name, SellerContactReasonErr);
                if SalespersonPurchaser."Phone No." = '' then
                    SalespersonPurchaser.FieldError("Phone No.", SellerContactReasonErr);
                if SalespersonPurchaser."E-Mail" = '' then
                    SalespersonPurchaser.FieldError("E-Mail", SellerContactReasonErr);
                exit;
            end;
        end;

        CompanyInformation.SetLoadFields("Contact Person", "Phone No.");
        CompanyInformation.Get();
        if CompanyInformation."Contact Person" = '' then
            CompanyInformation.FieldError("Contact Person", SellerContactReasonErr);
        if CompanyInformation."Phone No." = '' then
            CompanyInformation.FieldError("Phone No.", SellerContactReasonErr);
    end;

    local procedure GetSalespersonCode(SourceDocumentHeader: RecordRef): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        SalespersonCodeFieldRef: FieldRef;
        SalespersonFieldNo: Integer;
    begin
        SalespersonFieldNo := SalesInvoiceHeader.FieldNo("Salesperson Code");
        if SourceDocumentHeader.Number() in
            [Database::"Service Header", Database::"Service Invoice Header", Database::"Service Cr.Memo Header"]
        then
            SalespersonFieldNo := ServiceInvoiceHeader.FieldNo("Salesperson Code");

        SalespersonCodeFieldRef := SourceDocumentHeader.Field(SalespersonFieldNo);
        exit(SalespersonCodeFieldRef.Value());
    end;

    /// <summary>
    /// Tells whether a signed amount is reported as a charge or as an allowance.
    /// </summary>
    /// <param name="SignedAmount">The signed amount of the allowance/charge.</param>
    /// <returns>True for a charge, false for an allowance.</returns>
    internal procedure IsCharge(SignedAmount: Decimal): Boolean
    begin
        exit(SignedAmount >= 0);
    end;

    /// <summary>
    /// Gets the amount to report for a signed allowance/charge amount. The e-document formats report allowances with a
    /// positive amount and distinguish them from charges through the charge indicator.
    /// </summary>
    /// <param name="SignedAmount">The signed amount of the allowance/charge.</param>
    /// <returns>The absolute amount.</returns>
    internal procedure GetReportedAmount(SignedAmount: Decimal): Decimal
    begin
        exit(Abs(SignedAmount));
    end;

    [TryFunction]
    local procedure TryValidateRoutingNo(RoutingNo: Text[50])
    begin
        ValidateRoutingNo(RoutingNo);
    end;

    var
        OverallLengthErr: Label 'The E-Invoice Routing No. must be between 5 and 46 characters long. Current length: %1.', Comment = '%1 = actual length';
        SegmentCountErr: Label 'The E-Invoice Routing No. must consist of 2 or 3 segments separated by hyphens (-).';
        CoarseDigitsErr: Label 'The coarse routing segment must contain only digits (0-9). Found: "%1".', Comment = '%1 = coarse routing value';
        CoarseLengthErr: Label 'The coarse routing segment must be 2, 3, 5, 8, 9, or 12 digits long. Current length: %1.', Comment = '%1 = actual length';
        StateCodeErr: Label 'The coarse routing segment must start with a valid German state code (01-16) or federal code (99). Found: "%1".', Comment = '%1 = two-digit state code';
        FineRoutingLengthErr: Label 'The fine routing segment must be between 1 and 30 characters long. Found: "%1".', Comment = '%1 = fine routing value';
        FineRoutingCharsErr: Label 'The fine routing segment must contain only letters (A-Z) and digits (0-9). Found: "%1".', Comment = '%1 = fine routing value';
        CheckDigitFormatErr: Label 'The check digit must be exactly 2 digits. Found: "%1".', Comment = '%1 = check digit value';
        CheckDigitVerifyErr: Label 'The check digit verification failed (Mod 97-10). The E-Invoice Routing No. may contain a typo.';
        SellerContactReasonErr: Label 'must be filled in. It is required for the seller contact (BG-6) of the electronic document';
        MissingBuyerElectronicAddressErr: Label 'The buyer electronic address (BT-49) is missing for document %1. Specify an e-mail address for the document or for bill-to customer %2, or specify an E-Invoice Routing No. (Leitweg-ID) for the customer.', Comment = '%1 = Document No., %2 = Bill-to Customer No.';
        EMailSchemeIDTok: Label 'EM', Locked = true;
        RoutingNoSchemeIDTok: Label '0204', Locked = true;
        GLNSchemeIDTok: Label '0088', Locked = true;
}