// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
report 11001 "Intrastat - Item List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Intrastat/IntrastatItemList.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Intrastat - Item List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Tariff Number"; "Tariff Number")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(CompInfoName; UpperCase(CompanyInfo.Name))
            {
            }
            column(CompInfoCompanyNo; UpperCase(CompanyInfo."Company No."))
            {
            }
            column(CompInfoSpecialAgreement; UpperCase(CompanyInfo."Special Agreement"))
            {
            }
            column(No_TariffNumber; "No.")
            {
            }
            column(Description1_TariffNumber; UpperCase(CopyStr(Description, 1, 110)))
            {
            }
            column(Description2_TariffNumber; UpperCase(CopyStr(Description, 111, 90)))
            {
            }
            column(CompanyNoCaption; CompanyNoCaptionLbl)
            {
            }
            column(SpecialAgreementCaption; SpecialAgreementCaptionLbl)
            {
            }
            column(ItemListCaption; ItemListCaptionLbl)
            {
            }
            column(ImportExportCaption; ImportExportCaptionLbl)
            {
            }
            column(StandCaption; StandCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(ItemNoCaption; ItemNoCaptionLbl)
            {
            }
            column(ItemDescriptionCaption; ItemDescriptionCaptionLbl)
            {
            }
            column(ItemNumberCaption; ItemNumberCaptionLbl)
            {
            }
            column(ComentsCaption; ComentsCaptionLbl)
            {
            }
            dataitem(Item; Item)
            {
                DataItemLink = "Tariff No." = field("No.");
                DataItemTableView = sorting("No.");
                column(No_Item; "No.")
                {
                }
                column(Description_Item; UpperCase(Description))
                {
                }
                column(TariffNo_Item; "Tariff No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    "Tariff No." := CopyStr(DelChr("Tariff No."), 1, 4) + ' ' +
                      CopyStr(DelChr("Tariff No."), 5, 2) + ' ' +
                      CopyStr(DelChr("Tariff No."), 7, 2);
                end;
            }

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
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

    var
        CompanyInfo: Record "Company Information";
        CompanyNoCaptionLbl: Label 'COMPANY NO';
        SpecialAgreementCaptionLbl: Label 'SPECIAL AGREEMENT';
        ItemListCaptionLbl: Label 'I T E M  L I S T';
        ImportExportCaptionLbl: Label '(IMPORT/EXPORT)';
        StandCaptionLbl: Label 'STAND', Comment = 'Translate stand and uppercase the result';
        CurrReportPageNoCaptionLbl: Label 'PAGE', Comment = 'Translate page and uppercase the result';
        ItemNoCaptionLbl: Label 'ITEM NO.';
        ItemDescriptionCaptionLbl: Label 'ITEM DESCRIPTION';
        ItemNumberCaptionLbl: Label 'ITEM NUMBER';
        ComentsCaptionLbl: Label 'COMMENTS', Comment = 'Translate comments and uppercase the result';
}

