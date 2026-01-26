// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Address;

report 11111 "Crossborder Services"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Inventory/Intrastat/CrossborderServices.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Crossborder Services';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("VAT Entry"; "VAT Entry")
        {
            DataItemTableView = where("Country/Region Code" = filter(<> ''));
            MaxIteration = 1;
            RequestFilterFields = "Posting Date", "Country/Region Code", "Gen. Prod. Posting Group";
            column(GroupNo; GroupNo)
            {
            }
            column(VAT_Entry_Entry_No_; "Entry No.")
            {
            }
            dataitem(VATEntryCountry; "VAT Entry")
            {
                DataItemTableView = sorting("Country/Region Code", "Posting Date") where("Country/Region Code" = filter(<> ''));
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
                {
                }
                column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
                {
                }
                column(USERID; UserId)
                {
                }
                column(FilterText; FilterText)
                {
                }
                column(HeaderText; HeaderText)
                {
                }
                column(VATEntryCountrySelectionNo; SelectionNo)
                {
                }
                column(VATEntryCountry__Country_Region_Code_; "Country/Region Code")
                {
                }
                column(Country_Name; Country.Name)
                {
                }
                column(SalesToCust; -SalesToCust)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(PurchFromVend; PurchFromVend)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(TotalPurchFromVend; TotalPurchFromVend)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(TotalSalesToCust; -TotalSalesToCust)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(VATEntryCountry_Entry_No_; "Entry No.")
                {
                }
                column(VATEntryCountry__Country_Region_Code_Caption; VATEntryCountry__Country_Region_Code_CaptionLbl)
                {
                }
                column(Country_NameCaption; Country_NameCaptionLbl)
                {
                }
                column(SalesToCustCaption; SalesToCustCaptionLbl)
                {
                }
                column(PurchFromVendCaption; PurchFromVendCaptionLbl)
                {
                }
                column(Crossborder_Services___by_CountryCaption; Crossborder_Services___by_CountryCaptionLbl)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(Total_Caption; Total_CaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Selection = Selection::Both then
                        GroupNo := 1;
                    if not Country.Get("Country/Region Code") then
                        Country.Name := '';
                    SalesToCust := 0;
                    TotalSalesToCust := 0;
                    PurchFromVend := 0;
                    TotalPurchFromVend := 0;

                    if UseAmtsInAddCurr then
                        if Type = Type::Sale then begin
                            SalesToCust := Round("Additional-Currency Base", 1);
                            TotalSalesToCust := Round("Additional-Currency Base", 1);
                        end else begin
                            PurchFromVend := Round("Additional-Currency Base", 1);
                            TotalPurchFromVend := Round("Additional-Currency Base", 1);
                        end
                    else
                        if Type = Type::Sale then begin
                            SalesToCust := Round(Base, 1);
                            TotalSalesToCust := Round(Base, 1);
                        end else begin
                            PurchFromVend := Round(Base, 1);
                            TotalPurchFromVend := Round(Base, 1);
                        end;
                end;

                trigger OnPreDataItem()
                begin
                    CopyFilters("VAT Entry");
                    Clear(SalesToCust);
                    Clear(PurchFromVend);
                    Clear(TotalSalesToCust);
                    Clear(TotalPurchFromVend);
                end;
            }
            dataitem(VATEntryGenProdPostingGroup; "VAT Entry")
            {
                DataItemTableView = sorting("Gen. Prod. Posting Group", "Posting Date") where("Country/Region Code" = filter(<> ''));
                column(VATEntryGenProdPostingGroupSelectionNo; SelectionNo)
                {
                }
                column(VATEntryGenProdPostingGroup__Gen__Prod__Posting_Group_; "Gen. Prod. Posting Group")
                {
                }
                column(GenProductPostingGroup_Description; GenProductPostingGroup.Description)
                {
                }
                column(SalesToCust_Control1160023; -SalesToCust)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(PurchFromVend_Control1160025; PurchFromVend)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(TotalSalesToCust_Control1160035; -TotalSalesToCust)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(TotalPurchFromVend_Control1160036; TotalPurchFromVend)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(VATEntryGenProdPostingGroup_Entry_No_; "Entry No.")
                {
                }
                column(VATEntryGenProdPostingGroup__Gen__Prod__Posting_Group_Caption; VATEntryGenProdPostingGroup__Gen__Prod__Posting_Group_CaptionLbl)
                {
                }
                column(GenProductPostingGroup_DescriptionCaption; GenProductPostingGroup_DescriptionCaptionLbl)
                {
                }
                column(SalesToCust_Control1160023Caption; SalesToCust_Control1160023CaptionLbl)
                {
                }
                column(PurchFromVend_Control1160025Caption; PurchFromVend_Control1160025CaptionLbl)
                {
                }
                column(Crossborder_Services___by_Type_of_ServiceCaption; Crossborder_Services___by_Type_of_ServiceCaptionLbl)
                {
                }
                column(CurrReport_PAGENO_Control1160031Caption; CurrReport_PAGENO_Control1160031CaptionLbl)
                {
                }
                column(Total_Caption_Control1160037; Total_Caption_Control1160037Lbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    // new client
                    if Selection = Selection::Both then
                        GroupNo := 2;
                    if not GenProductPostingGroup.Get("Gen. Prod. Posting Group") then
                        GenProductPostingGroup.Description := '';
                    SalesToCust := 0;
                    TotalSalesToCust := 0;
                    PurchFromVend := 0;
                    TotalPurchFromVend := 0;

                    if UseAmtsInAddCurr then
                        if Type = Type::Sale then begin
                            SalesToCust := Round("Additional-Currency Base", 1);
                            TotalSalesToCust := Round("Additional-Currency Base", 1);
                        end else begin
                            PurchFromVend := Round("Additional-Currency Base", 1);
                            TotalPurchFromVend := Round("Additional-Currency Base", 1);
                        end
                    else
                        if Type = Type::Sale then begin
                            SalesToCust := Round(Base, 1);
                            TotalSalesToCust := Round(Base, 1);
                        end else begin
                            PurchFromVend := Round(Base, 1);
                            TotalPurchFromVend := Round(Base, 1);
                        end;
                end;

                trigger OnPreDataItem()
                begin
                    CopyFilters("VAT Entry");
                end;
            }

            trigger OnPreDataItem()
            begin
                GLSetup.Get();
                if UseAmtsInAddCurr then
                    HeaderText := StrSubstNo(Text1160000, GLSetup."Additional Reporting Currency")
                else
                    if GLSetup."LCY Code" <> '' then
                        HeaderText := StrSubstNo(Text1160000, GLSetup."LCY Code")
                    else
                        HeaderText := '';

                FilterText := TableCaption + ': ' + GetFilters();

                SelectionNo := Selection;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(Selection; Selection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Statistic on';
                        OptionCaption = 'Countries,Type of Services,Both';
                        ToolTip = 'Specifies the type of report that you want to create. Select Countries to list amounts by countries/regions. Select Type of Services to list amounts by the general product posting group. Select Both to create two lists.';
                    }
                    field(UseAmtsInAddCurr; UseAmtsInAddCurr)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in Add. Reporting Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want report amounts to be shown in the additional reporting currency.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
        Crossborder_Services_CaptionLbl = 'Crossborder Services';
    }

    var
        Text1160000: Label 'All amounts are in %1.';
        GLSetup: Record "General Ledger Setup";
        Country: Record "Country/Region";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        Selection: Option Country,"Type of Service",Both;
        HeaderText: Text[100];
        FilterText: Text;
        SalesToCust: Decimal;
        PurchFromVend: Decimal;
        TotalSalesToCust: Decimal;
        TotalPurchFromVend: Decimal;
        UseAmtsInAddCurr: Boolean;
        SelectionNo: Integer;
        GroupNo: Integer;
        VATEntryCountry__Country_Region_Code_CaptionLbl: Label 'Country/Region Code';
        Country_NameCaptionLbl: Label 'Name';
        SalesToCustCaptionLbl: Label 'Sale';
        PurchFromVendCaptionLbl: Label 'Purchase';
        Crossborder_Services___by_CountryCaptionLbl: Label 'Crossborder Services - by Country';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Total_CaptionLbl: Label 'Total:';
        VATEntryGenProdPostingGroup__Gen__Prod__Posting_Group_CaptionLbl: Label 'Type of Service';
        GenProductPostingGroup_DescriptionCaptionLbl: Label 'Description';
        SalesToCust_Control1160023CaptionLbl: Label 'Sale';
        PurchFromVend_Control1160025CaptionLbl: Label 'Purchase';
        Crossborder_Services___by_Type_of_ServiceCaptionLbl: Label 'Crossborder Services - by Type of Service';
        CurrReport_PAGENO_Control1160031CaptionLbl: Label 'Page';
        Total_Caption_Control1160037Lbl: Label 'Total:';
}

