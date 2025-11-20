// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Foundation.Company;
using Microsoft.Service.History;
using Microsoft.Utilities;

report 5916 "Service Certificate of Supply"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Document/ServiceCertificateofSupply.rdlc';
    Caption = 'Certificate of Supply';

    dataset
    {
        dataitem(CertificateOfSupply; "Certificate of Supply")
        {
            RequestFilterFields = "Document No.";
            dataitem("Integer"; System.Utilities.Integer)
            {
                DataItemTableView = sorting(Number);
                MaxIteration = 1;
                column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
                {
                }
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
                {
                }
                column(COMPANYADDRESS; CompanyInfo.Address)
                {
                }
                column(COMPANYADDRESS2; CompanyInfo."Address 2")
                {
                }
                column(COMPANYCITY; CompanyInfo.City)
                {
                }
                column(COMPANYCOUNTRYCODE; CompanyInfo."Country/Region Code")
                {
                }
                column(Quantity_of_the_object_of_the_supply_Caption; Quantity_of_the_object_of_the_supply_Lbl)
                {
                }
                column(Standard_commercial_description___in_the_case_of_vehicles__including_vehicle_identification_number_Caption; Standard_commercial_description___in_the_case_of_vehicles__including_vehicle_identification_number_Lbl)
                {
                }
                column(Date_the_object_of_the_supply_was_received_in_the_Member_State; Date_the_object_of_the_supply_was_received_in_the_Member_State_of_entry_Lbl)
                {
                }
                column(Date_the_transportation_ended_if_the_customer_transported_the_object_of_the_supply_himself_or_herself_Caption; Date_the_transportation_ended_if_the_customer_transported_the_object_of_the_supply_himself_or_herself_Lbl)
                {
                }
                column(in_atCaption; in_atLbl)
                {
                }
                column(Member_State_and_place_of_entry_as_part_of_the_transport_or_dispatch_of_the_object_Caption; Member_State_and_place_of_entry_as_part_of_the_transport_or_dispatch_of_the_object_Lbl)
                {
                }
                column(Date_of_issue_of_the_certificate_Caption; Date_of_issue_of_the_certificate_Lbl)
                {
                }
                column(Signature_of_the_customer_or_of_the_authorised_representative_as_well_as_the_signatory_s_name_in_capitals_Caption; Signature_of_the_customer_or_of_the_authorised_representative_as_well_as_the_signatory_s_name_in_capitals_Lbl)
                {
                }
                column(Reference_Document_Caption; Reference_Document_Lbl)
                {
                }
                column(Shipment_Method_Caption; Shipment_Method_Lbl)
                {
                }
                column(Vehicle_Registration_No_Caption; Vehicle_Registration_No_Lbl)
                {
                }
                column(Certification_of_the_entry_of_the_object_of_an_intra___Community_supply_into_another_Caption; Certification_of_the_entry_of_the_object_of_an_intra___Community_supply_into_another_Lbl)
                {
                }
                column(EU_Member_State__Entry_Certificate_Caption; EU_Member_State__Entry_Certificate_Lbl)
                {
                }
                column(Name_and_address_of_the_customer_of_the_intra_Community_supply__if_applicable__E_Mail_address_Caption; Name_and_address_of_the_customer_of_the_intra_Community_supply__if_applicable__E_Mail_address_Lbl)
                {
                }
                column(I_as_the_customer_hereby_certify_my_receipt_the_entry_of_the_following_object_of_an_intra___Community_supplyCaption; I_as_the_customer_hereby_certify_my_receipt_the_entry_of_the_following_object_of_an_intra___Community_supplyLbl)
                {
                }
                column(on_Caption; onLbl)
                {
                }
                column(Received_Caption; receivedLbl)
                {
                }
                column(delete_As_Appropriate_Caption; deleteAsAppropriateLbl)
                {
                }
                column(No; TempServiceShipmentHeader."No.")
                {
                }
                column(Bill_to_Name; TempServiceShipmentHeader."Bill-to Name")
                {
                }
                column(Bill_to_Address; TempServiceShipmentHeader."Bill-to Address")
                {
                }
                column(Bill_to_Address2; TempServiceShipmentHeader."Bill-to Address 2")
                {
                }
                column(Bill_to_City; TempServiceShipmentHeader."Bill-to City")
                {
                }
                column(Bill_To_CountryRegion_Code; TempServiceShipmentHeader."Bill-to Country/Region Code")
                {
                }
                column(EMail; TempServiceShipmentHeader."E-Mail")
                {
                }
                column(Ship_to_Address; TempServiceShipmentHeader."Ship-to Address")
                {
                }
                column(Ship_to_Address2; TempServiceShipmentHeader."Ship-to Address 2")
                {
                }
                column(Ship_to_City; TempServiceShipmentHeader."Ship-to City")
                {
                }
                column(Ship_to_Country_Region_Code; TempServiceShipmentHeader."Ship-to Country/Region Code")
                {
                }
                column(Ship_to_Name; TempServiceShipmentHeader."Ship-to Name")
                {
                }
                column(Shipment_Method_Code; CertificateOfSupply."Shipment Method Code")
                {
                }
                column(Vehicle_Registration_No; CertificateOfSupply."Vehicle Registration No.")
                {
                }
                column(PrintLineDetails; PrintLineDetails)
                {
                }
                dataitem("<Integer2>"; System.Utilities.Integer)
                {
                    DataItemTableView = sorting(Number) order(ascending) where(Number = filter(1 ..));
                    column(Item_No_Caption; TempServiceShipmentLine.FieldCaption("No."))
                    {
                    }
                    column(Decription_Caption; TempServiceShipmentLine.FieldCaption(Description))
                    {
                    }
                    column(Quantity_Caption; TempServiceShipmentLine.FieldCaption(Quantity))
                    {
                    }
                    column(Unit_of_Measure_Caption; TempServiceShipmentLine.FieldCaption("Unit of Measure"))
                    {
                    }
                    column(Line_No; TempServiceShipmentLine."Line No.")
                    {
                    }
                    column(Item_No; TempServiceShipmentLine."No.")
                    {
                    }
                    column(Description; TempServiceShipmentLine.Description)
                    {
                    }
                    column(Quantity; TempServiceShipmentLine.Quantity)
                    {
                    }
                    column(Unit_of_Measure; TempServiceShipmentLine."Unit of Measure Code")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then begin
                            if not TempServiceShipmentLine.FindSet() then
                                CurrReport.Break()
                        end else
                            if TempServiceShipmentLine.Next() = 0 then
                                CurrReport.Break();
                    end;

                    trigger OnPreDataItem()
                    begin
                        TempServiceShipmentLine.SetFilter(Quantity, '<>%1', 0);
                    end;
                }

                trigger OnPostDataItem()
                begin
                    if not IsReportInPreviewMode() then
                        CertificateOfSupply.SetPrintedTrue();
                end;
            }

            trigger OnAfterGetRecord()
            var
                Language: Codeunit System.Globalization.Language;
            begin
                Clear(TempServiceShipmentHeader);
                TempServiceShipmentLine.Reset();
                TempServiceShipmentLine.DeleteAll();
                CurrReport.Language := Language.GetLanguageIdOrDefault(GetLanguageCode(CertificateOfSupply));
                CurrReport.FormatRegion := Language.GetFormatRegionOrDefault(GetFormatRegionCode(CertificateOfSupply));
                SetSource(CertificateOfSupply);
                if PrintLineDetails then
                    GetLines(CertificateOfSupply);
            end;

            trigger OnPreDataItem()
            var
                ServiceShipmentHeader: Record "Service Shipment Header";
                CertificateOfSupply2: Record "Certificate of Supply";
#if not CLEAN25
                CertificateOfSupplyReport: Report Microsoft.Inventory.Reports."Certificate of Supply";
#endif
            begin
                "Document Type" := "Document Type"::"Service Shipment";
                if CreateCertificatesofSupply then begin
                    CopyFilter("Document No.", ServiceShipmentHeader."No.");
                    OnCertificateOfSupplyOnPreDataItemOnAfterSetFilters(CertificateOfSupply, ServiceShipmentHeader);
#if not CLEAN25
                    CertificateOfSupplyReport.RunOnCertificateOfSupplyOnPreDataItemOnAfterFilterForServiceShipmentHeader(CertificateOfSupply, ServiceShipmentHeader);
#endif
                    if ServiceShipmentHeader.FindSet() then
                        repeat
                            ServiceShipmentHeader.InitCertificateOfSupply(CertificateOfSupply2);
                            CertificateOfSupply2.SetRequired(ServiceShipmentHeader."No.")
                        until ServiceShipmentHeader.Next() = 0;
                end;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                field(PrintLineDetails; PrintLineDetails)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Print Line Details';
                    ToolTip = 'Specifies if you want to information from the lines on the shipment document on the certificate of supply.';
                }
                field(CreateCertificatesofSupply; CreateCertificatesofSupply)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Certificates of Supply if Not Already Created';
                    ToolTip = 'Specifies if you want to create a certificate of supply, when you sell goods to a customer in another EU country/region.';
                }
            }
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
        CompanyInfo.Get();
        PrintLineDetails := true;
        CreateCertificatesofSupply := false;
    end;

    var
        CompanyInfo: Record "Company Information";
        PrintLineDetails: Boolean;
        CreateCertificatesofSupply: Boolean;

    protected var
        TempServiceShipmentHeader: Record "Service Shipment Header" temporary;
        TempServiceShipmentLine: Record "Service Shipment Line" temporary;

        Quantity_of_the_object_of_the_supply_Lbl: Label '(Quantity of the object of the supply)';
        Standard_commercial_description___in_the_case_of_vehicles__including_vehicle_identification_number_Lbl: Label '(Standard commercial description - in the case of vehicles, including vehicle identification number)';
        Date_the_object_of_the_supply_was_received_in_the_Member_State_of_entry_Lbl: Label '(Date the object of the supply was received in the Member State of entry if the supplying trader transported or dispatched the object of the supply or if the customer dispatched the object of the supply)';
        Date_the_transportation_ended_if_the_customer_transported_the_object_of_the_supply_himself_or_herself_Lbl: Label '(Date the transportation ended if the customer transported the object of the supply himself or herself)';
        in_atLbl: Label 'in/at 1)';
        Member_State_and_place_of_entry_as_part_of_the_transport_or_dispatch_of_the_object_Lbl: Label '(Member State and place of entry as part of the transport or dispatch of the object)';
        Date_of_issue_of_the_certificate_Lbl: Label '(Date of issue of the certificate)';
        Signature_of_the_customer_or_of_the_authorised_representative_as_well_as_the_signatory_s_name_in_capitals_Lbl: Label '(Signature of the customer or of the authorised representative as well as the signatory''s name in capitals)';
        Reference_Document_Lbl: Label 'Reference Document Shipment';
        Vehicle_Registration_No_Lbl: Label 'Vehicle Registration No.';
        Shipment_Method_Lbl: Label 'Shipment Method';
        Certification_of_the_entry_of_the_object_of_an_intra___Community_supply_into_another_Lbl: Label 'Certification of the entry of the object of an intra - Community supply into another ';
        EU_Member_State__Entry_Certificate_Lbl: Label 'EU Member State (Entry Certificate)';
        Name_and_address_of_the_customer_of_the_intra_Community_supply__if_applicable__E_Mail_address_Lbl: Label '(Name and address of the customer of the intra-Community supply, if applicable, Email-address)';
        I_as_the_customer_hereby_certify_my_receipt_the_entry_of_the_following_object_of_an_intra___Community_supplyLbl: Label 'I as the customer hereby certify my receipt/the entry of the following object of an intra - Community supply';
        onLbl: Label 'on';
        receivedLbl: Label 'received/arrived 1)';
        deleteAsAppropriateLbl: Label '1) Delete as appropriate';

    local procedure SetSource(CertificateOfSupply: Record "Certificate of Supply")
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetSource(CertificateOfSupply, IsHandled);
        if IsHandled then
            exit;

        ServiceShipmentHeader.Get(CertificateOfSupply."Document No.");
        SetSourceService(ServiceShipmentHeader);
    end;

    local procedure SetSourceService(ServiceShipmentHeader: Record "Service Shipment Header")
    begin
        TempServiceShipmentHeader := ServiceShipmentHeader;
    end;

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit System.EMail."Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody());
    end;

    local procedure GetLines(CertificateOfSupply: Record "Certificate of Supply")
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetLines(CertificateOfSupply, IsHandled);
        if IsHandled then
            exit;

        ServiceShipmentHeader.Get(CertificateOfSupply."Document No.");
        GetServiceLines(ServiceShipmentHeader."No.");
        TempServiceShipmentLine.FindSet();
    end;

    local procedure GetServiceLines(ServiceShipmentHeaderNo: Code[20])
    var
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        ServiceShipmentLine.SetRange("Document No.", ServiceShipmentHeaderNo);
        if ServiceShipmentLine.FindSet() then
            repeat
                TempServiceShipmentLine := ServiceShipmentLine;
                TempServiceShipmentLine.Insert();
            until ServiceShipmentLine.Next() = 0;
    end;

    local procedure GetLanguageCode(CertificateOfSupply: Record "Certificate of Supply") Result: Code[10]
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetLanguageCode(CertificateOfSupply, Result, IsHandled);
        if IsHandled then
            exit;

        ServiceShipmentHeader.Get(CertificateOfSupply."Document No.");
        exit(ServiceShipmentHeader."Language Code");
    end;

    local procedure GetFormatRegionCode(CertificateOfSupply: Record "Certificate of Supply") Result: Text[80]
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetFormatRegion(CertificateOfSupply, Result, IsHandled);
        if IsHandled then
            exit;

        ServiceShipmentHeader.Get(CertificateOfSupply."Document No.");
        exit(ServiceShipmentHeader."Format Region");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetLanguageCode(CertificateOfSupply: Record "Certificate of Supply"; var Result: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetFormatRegion(CertificateOfSupply: Record "Certificate of Supply"; var Result: Text[80]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeGetLines(CertificateOfSupply: Record "Certificate of Supply"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSetSource(CertificateOfSupply: Record "Certificate of Supply"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCertificateOfSupplyOnPreDataItemOnAfterSetFilters(var CertificateOfSupply: Record "Certificate of Supply"; var ServiceShipmentHeader: Record "Service Shipment Header")
    begin
    end;
}

