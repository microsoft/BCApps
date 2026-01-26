// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;

report 12194 "Declaration of Intent Report"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/VAT/Reporting/DeclarationofIntentReport.rdlc';
    Caption = 'Declaration of Intent Report';

    dataset
    {
        dataitem(VATExemption; "VAT Exemption")
        {
            column(FiscalCode_Value; FiscalCode)
            {
            }
            column(CeilingTypePhone_Value; CeilingTypeFixed)
            {
            }
            column(CompanyInfoName; CompanyInformation.Name)
            {
            }
            column(VATRegNo_Value; CompanyInformation."VAT Registration No.")
            {
            }
            column(CompanyInfoPhoneNo_Value; CompanyInformation."Phone No.")
            {
            }
            column(CompanyInfoEmail_Value; CompanyInformation."E-Mail")
            {
            }
            column(VATExemptStartingDate_Year_Value; Date2DMY("VAT Exempt. Starting Date", 3))
            {
            }
            column(DateToday_Day_Value; Date2DMY(Today, 1))
            {
            }
            column(DateToday_Month_Value; Date2DMY(Today, 2))
            {
            }
            column(DateToday_Year_Value; Date2DMY(Today, 3))
            {
            }
            column(AmountToDeclare_Value; AmountToDeclare)
            {
            }
            column(DescriptionOfGoods_Value; CopyStr(DescriptionOfGoods, 1, 50))
            {
            }
            column(AnnualVATSubmitted; AnnualVATDeclSubmitted)
            {
            }
            column(Exports; ExportFlags[2])
            {
            }
            column(IntraCommunitydisposals; ExportFlags[3])
            {
            }
            column(DisposalsSanMarino; ExportFlags[4])
            {
            }
            column(AssimilatedOperations; ExportFlags[5])
            {
            }
            column(ExtraordinaryOperations; ExportFlags[6])
            {
            }
            column(SigningCompanyOfficialsDateofBirth_Day_Value; Date2DMY(SigningCompanyOfficials."Date of Birth", 1))
            {
            }
            column(SigningCompanyOfficialsDateofBirth_Month_Value; Date2DMY(SigningCompanyOfficials."Date of Birth", 2))
            {
            }
            column(SigningCompanyOfficialsDateofBirth_Year_Value; Date2DMY(SigningCompanyOfficials."Date of Birth", 3))
            {
            }
            column(SigningCompanyOfficialsFiscalCode_Value; SigningCompanyOfficials."Fiscal Code")
            {
            }
            column(SigningCompanyOfficialsAppointmentCode_Value; SigningCompanyOfficials."Appointment Code")
            {
            }
            column(SigningCompanyOfficialsBirthCity_Value; SigningCompanyOfficials."Birth City")
            {
            }
            column(SigningCompanyOfficialsBirthCounty_Value; CopyStr(SigningCompanyOfficials."Birth County", 1, 3))
            {
            }
            column(SigningCompanyOfficialsLastName_Value; SigningCompanyOfficials."Last Name")
            {
            }
            column(SigningCompanyOfficialsFirstName_Value; SigningCompanyOfficials."First Name")
            {
            }
            column(SigningCompanyOfficialsGender_Value; CopyStr(Format(SigningCompanyOfficials.Gender), 1, 1))
            {
            }
            column(SupplementaryReturn_Value; SupplementaryReturn)
            {
            }
            column(TaxAuthorityReceiptsNo_Value; TaxAuthorityReceiptsNo)
            {
            }
            column(TaxAuthorityDocNo_Value; TaxAuthorityDocNo)
            {
            }
            column(VendorFiscalCode_Value; VendorFiscalCode)
            {
            }
            column(VendorGender_Value; VendorGender)
            {
            }
            column(VendorLastName; VendorName)
            {
            }
            column(VendorFirstName; VendorFirstName)
            {
            }
            column(VendoRVATRegNo_Value; VendorVATRegNo)
            {
            }
            column(VendorTaxRepresentativeVATRegNo_Value; VendorTaxRepresentativeVATRegNo)
            {
            }
            column(VATExemptIntRegistryNo_Value; "VAT Exempt. Int. Registry No.")
            {
            }
            column(DeclarationOfIntent1_Caption; DeclarationOfIntent1Lbl)
            {
            }
            column(DeclarationOfIntent2_Caption; DeclarationOfIntent2Lbl)
            {
            }
            column(DeclarantNumber_Caption; DeclarantNumberLbl)
            {
            }
            column(DeclarantYear_Caption; DeclarantYearLbl)
            {
            }
            column(DeclarantAttributes_Caption; DeclarantAttributesLbl)
            {
            }
            column(SupplierNumber_Caption; SupplierNumberLbl)
            {
            }
            column(SupplierYear_Caption; SupplierYearLbl)
            {
            }
            column(SupplierAttributes_Caption; SupplierAttributesLbl)
            {
            }
            column(DeclaringData_Caption; DeclaringDataLbl)
            {
            }
            column(DeclFiscalCode_Caption; DeclFiscalCodeLbl)
            {
            }
            column(DeclVATRegNo_Caption; DeclVATRegNoLbl)
            {
            }
            column(CompanyName_Caption; CompanyNameLbl)
            {
            }
            column(Name_Caption; NameLbl)
            {
            }
            column(Gender_Caption; GenderLbl)
            {
            }
            column(BirthDate_Caption; BirthDateLbl)
            {
            }
            column(BirthCity_Caption; BirthCityLbl)
            {
            }
            column(BirthProvince_Caption; BirthProvinceLbl)
            {
            }
            column(Day_Caption; DayLbl)
            {
            }
            column(Month_Caption; MonthLbl)
            {
            }
            column(Year_Caption; YearLbl)
            {
            }
            column(RepresentativeData1_Caption; RepresentativeData1Lbl)
            {
            }
            column(SigningCompOfficialFiscalCode_Caption; SigningCompOfficialFiscalCodeLbl)
            {
            }
            column(CompanyFiscalCode_Caption; CompanyFiscalCodeLbl)
            {
            }
            column(SigningCompOfficialAppCode_Caption; SigningCompOfficialAppCodeLbl)
            {
            }
            column(SigningCompOfficialLastName_Caption; SigningCompOfficialLastNameLbl)
            {
            }
            column(SigningCompOfficialName_Caption; SigningCompOfficialNameLbl)
            {
            }
            column(SigningCompOfficialGender_Caption; SigningCompOfficialGenderLbl)
            {
            }
            column(SigningCompOfficialDateofBirth_Caption; SigningCompOfficialDateofBirthLbl)
            {
            }
            column(SigningCompOfficialTownofBirth_Caption; SigningCompOfficialTownofBirthLbl)
            {
            }
            column(SigningCompOfficialProvinceofBirth_Caption; SigningCompOfficialProvinceofBirthLbl)
            {
            }
            column(ContactInfo_Caption; ContactInfoLbl)
            {
            }
            column(ContactInfoPhone_Caption; ContactInfoPhoneLbl)
            {
            }
            column(ContactInfoEmail_Caption; ContactInfoEmailLbl)
            {
            }
            column(ContactInfoPhoneNum_Caption; ContactInfoPhoneNumLbl)
            {
            }
            column(Statement_Caption; StatementLbl)
            {
            }
            column(FinStatement_Caption; FinStatementLbl)
            {
            }
            column(TaxAuthority_Caption; TaxAuthorityLbl)
            {
            }
            column(Declaration_Caption; DeclarationLbl)
            {
            }
            column(Imports_Caption; ImportsLbl)
            {
            }
            column(Intent_Caption; IntentLbl)
            {
            }
            column(WithoutApplication_Caption; WithoutApplicationLbl)
            {
            }
            column(DescOfGoods_Caption; DescOfGoodsLbl)
            {
            }
            column(StatementsReffersTo_Caption; StatementsReffersToLbl)
            {
            }
            column(OneOperationUpTo_Caption; OneOperationUpToLbl)
            {
            }
            column(OperationsUpTo_Caption; OperationsUpToLbl)
            {
            }
            column(DeclRecipient_Caption; DeclRecipientLbl)
            {
            }
            column(Customs_Caption; CustomsLbl)
            {
            }
            column(OtherParty_Caption; OtherPartyLbl)
            {
            }
            column(VendorFiscalCode_Caption; VendorFiscalCodeLbl)
            {
            }
            column(VendorLastName_Caption; VendorLastNameLbl)
            {
            }
            column(VendorVatRegNo_Caption; VendorVatRegNoLbl)
            {
            }
            column(VendorName_Caption; VendorNameLbl)
            {
            }
            column(VendorGender_Caption; VendorGenderLbl)
            {
            }
            column(Signature_Caption; SignatureLbl)
            {
            }
            column(FrameworkA_Caption; FrameworkALbl)
            {
            }
            column(Operations_Caption; OperationsLbl)
            {
            }
            column(Commitment_Caption; CommitmentLbl)
            {
            }
            column(Typo_Caption; TypoLbl)
            {
            }
            column(Fixed_Caption; FixedLbl)
            {
            }
            column(Mobile_Caption; MobileLbl)
            {
            }
            column(AnnualVATReturn_Caption; AnnualVATReturnLbl)
            {
            }
            column(Exports_Caption; ExportsLbl)
            {
            }
            column(IntraCommunitySupplies_Caption; IntraCommunitySuppliesLbl)
            {
            }
            column(DeparturesToSanMarino_Caption; DeparturesToSanMarinoLbl)
            {
            }
            column(SimilarOperations_Caption; SimilarOperationsLbl)
            {
            }
            column(ExtraTrans_Caption; ExtraTransLbl)
            {
            }
            column(IntermFiscalCode_Caption; IntermFiscalCodeLbl)
            {
            }
            column(CommitmentDate_Caption; CommitmentDateLbl)
            {
            }
            column(DealerSignature_Caption; DealerSignatureLbl)
            {
            }
            column(CustomAuthorityFlagValue; CustomAuthorityFlag)
            {
            }
            column(IntentFlagValue; IntentFlag)
            {
            }
            column(ImportsFlagValue; ImportsFlag)
            {
            }

            trigger OnAfterGetRecord()
            begin
                Vendor.Get("No.");

                FiscalCode := CompanyInformation.GetTaxCode();
                VendorTaxRepresentativeVATRegNo := GetVendorTaxRepresentativeNo(CompanyInformation."Tax Representative No.");
                SigningCompanyOfficials.Get(SigningCompanyOfficialNo);
                GetVendorName();
                GetRecipientData();
                AnnualVATDeclSubmitted := ExportFlags[1];
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        CompanyInformation.Get();
    end;

    var
        CompanyInformation: Record "Company Information";
        SigningCompanyOfficials: Record "Company Officials";
        Vendor: Record Vendor;
        CeilingTypeFixed: Boolean;
        DescriptionOfGoods: Text[100];
        AmountToDeclare: Decimal;
        ExportFlags: array[6] of Boolean;
        FiscalCode: Text[20];
        SupplementaryReturn: Boolean;
        SigningCompanyOfficialNo: Code[20];
        TaxAuthorityReceiptsNo: Text[17];
        TaxAuthorityDocNo: Text[6];
        VendorTaxRepresentativeVATRegNo: Code[20];
        VendorFiscalCode: Text[20];
        VendorGender: Code[1];
        VendorFirstName: Text;
        VendorName: Text;
        VendorVATRegNo: Text[20];
        AnnualVATDeclSubmitted: Boolean;
        CustomAuthorityFlag: Text[10];
        IntentFlag: Text[10];
        ImportsFlag: Text[10];
        DeclarationOfIntent1Lbl: Label 'DECLARATION OF INTENT';
        DeclarationOfIntent2Lbl: Label 'PURCHASE OR IMPORT OF GOODS AND SERVICES WITHOUT  VALUE ADDED TAX';
        DeclarantNumberLbl: Label 'Number';
        DeclarantYearLbl: Label 'Year';
        DeclarantAttributesLbl: Label 'Attributed by the declarant';
        SupplierNumberLbl: Label 'Number';
        SupplierYearLbl: Label 'Year';
        SupplierAttributesLbl: Label 'Attributed by the supplier or provider';
        DeclaringDataLbl: Label 'DECLARATION DATA';
        DeclFiscalCodeLbl: Label 'Fiscal Code';
        DeclVATRegNoLbl: Label 'VAT Registration No.';
        CompanyNameLbl: Label 'Surname or company''s name';
        NameLbl: Label 'Name';
        GenderLbl: Label 'Sex (M/F)';
        BirthDateLbl: Label 'Date of birth';
        BirthCityLbl: Label 'City of birth';
        BirthProvinceLbl: Label 'County (initials)';
        DayLbl: Label 'day';
        MonthLbl: Label 'month';
        YearLbl: Label 'year';
        RepresentativeData1Lbl: Label 'SIGNING COMPANY OFFICIAL DATA';
        SigningCompOfficialFiscalCodeLbl: Label 'Fiscal Code';
        SigningCompOfficialDateofBirthLbl: Label 'Date of birth';
        CompanyFiscalCodeLbl: Label 'VAT Registration No.';
        SigningCompOfficialAppCodeLbl: Label 'Appointment Code';
        SigningCompOfficialLastNameLbl: Label 'Surname or company''s name';
        SigningCompOfficialNameLbl: Label 'Name';
        SigningCompOfficialGenderLbl: Label 'Sex (M/F)';
        SigningCompOfficialTownofBirthLbl: Label 'Birth City';
        SigningCompOfficialProvinceofBirthLbl: Label 'County (initials)';
        ContactInfoLbl: Label 'CONTACT INFORMATION';
        ContactInfoPhoneLbl: Label 'Phone No.';
        ContactInfoEmailLbl: Label 'E-Mail';
        ContactInfoPhoneNumLbl: Label 'prefix      number';
        StatementLbl: Label 'STATEMENTS', Comment = 'Should be transalted';
        FinStatementLbl: Label 'Statements';
        TaxAuthorityLbl: Label 'Tax Authority No.';
        DeclarationLbl: Label 'DECLARATION', Comment = 'Should be transalted';
        ImportsLbl: Label 'IMPORTS', Comment = 'Should be transalted';
        IntentLbl: Label 'I intent to avail myself of the option of making purchases of all subjects who conduct sales export or related operations';
        WithoutApplicationLbl: Label 'without application of VAT in the year';
        DescOfGoodsLbl: Label 'and ask to buy or import';
        StatementsReffersToLbl: Label 'The statement refers to:';
        OneOperationUpToLbl: Label 'one operation for an amount up to EUR';
        OperationsUpToLbl: Label 'operations up to an amount of EUR';
        DeclRecipientLbl: Label 'DECLARATION RECIPIENT';
        CustomsLbl: Label 'Customs';
        OtherPartyLbl: Label 'Other party';
        VendorFiscalCodeLbl: Label 'Fiscal Code';
        VendorLastNameLbl: Label 'Surname or company''s name';
        VendorVatRegNoLbl: Label 'VAT Registration No.';
        VendorNameLbl: Label 'Name';
        VendorGenderLbl: Label 'Sex (M/F)';
        SignatureLbl: Label 'SIGNATURE', Comment = 'Should be transalted';
        FrameworkALbl: Label 'SECTION A';
        OperationsLbl: Label 'Plafond Operations';
        CommitmentLbl: Label 'COMMITMENT TO ELECTRONIC TRANSMISSION';
        TypoLbl: Label 'Type';
        FixedLbl: Label 'Landline';
        MobileLbl: Label 'Cellular';
        AnnualVATReturnLbl: Label 'Submitted annual VAT return ';
        ExportsLbl: Label 'Exports';
        IntraCommunitySuppliesLbl: Label 'Intra-community supplies';
        DeparturesToSanMarinoLbl: Label 'Departures to San Marino';
        SimilarOperationsLbl: Label 'Similar operations';
        ExtraTransLbl: Label 'Extraordinary transactions';
        IntermFiscalCodeLbl: Label 'Intermediary tax code';
        CommitmentDateLbl: Label 'Date';
        DealerSignatureLbl: Label 'Intermediary signature';

    local procedure GetVendorTaxRepresentativeNo(VendorTaxRepresentativeNo: Code[20]): Code[20]
    var
        VendorTaxRepresentative: Record Vendor;
    begin
        if VendorTaxRepresentative.Get(VendorTaxRepresentativeNo) then
            exit(VendorTaxRepresentative.GetTaxCode());
        exit(VendorTaxRepresentative."VAT Registration No."); // B-57
    end;

    local procedure GetVendorGender(): Code[1]
    begin
        if Vendor.Gender = Vendor.Gender::Male then
            exit('M'); // B-46

        exit('F'); // B-46
    end;

    local procedure GetVendorName()
    begin
        if Vendor."Last Name" <> '' then begin
            VendorFirstName := Vendor."First Name";
            VendorName := Vendor."Last Name";
            VendorGender := GetVendorGender();
        end else begin
            VendorName := Vendor.Name;
            VendorFirstName := '';
            VendorGender := '';
        end;
    end;

    local procedure GetRecipientData()
    begin
        if Vendor.IsCustomAuthorityVendor() then begin
            VendorFiscalCode := '';
            VendorVATRegNo := '';
            CustomAuthorityFlag := 'X';
            IntentFlag := '';
            ImportsFlag := 'X';
        end else begin
            VendorFiscalCode := Vendor.GetTaxCode();
            VendorVATRegNo := Vendor."VAT Registration No.";
            CustomAuthorityFlag := '';
            IntentFlag := 'X';
            ImportsFlag := '';
        end;
    end;

    [Scope('OnPrem')]
    procedure Initialize(DescriptionOfGoodsValue: Text[100]; SigningCompanyOfficialNoValue: Code[20]; AmountToDeclareValue: Decimal; CeilingTypeValue: Option "Fixed",Mobile; ExportFlagsValue: array[6] of Boolean; SupplementaryReturnValue: Boolean; TaxAuthorityReceiptsNoValue: Text[17]; TaxAuthorityDocNoValue: Text[6])
    var
        counter: Integer;
    begin
        DescriptionOfGoods := DescriptionOfGoodsValue;
        SigningCompanyOfficialNo := SigningCompanyOfficialNoValue;
        AmountToDeclare := AmountToDeclareValue;
        CeilingTypeFixed := CeilingTypeValue = CeilingTypeValue::Fixed;
        for counter := 1 to 6 do
            ExportFlags[counter] := ExportFlagsValue[counter];
        SupplementaryReturn := SupplementaryReturnValue; // B-8
        TaxAuthorityReceiptsNo := TaxAuthorityReceiptsNoValue;
        TaxAuthorityDocNo := TaxAuthorityDocNoValue;
    end;
}

