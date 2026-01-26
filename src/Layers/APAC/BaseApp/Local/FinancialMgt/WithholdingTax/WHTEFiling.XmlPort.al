// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;

xmlport 16630 "WHT-EFiling"
{
    Caption = 'WHT-EFiling';
    UseRequestPage = true;

    schema
    {
        textelement(CompanyInformation)
        {
            textattribute(CompanyInfo)
            {
            }
            textelement(FType)
            {
            }
            textelement(VATRegistrationNo)
            {
            }
            textelement(BranchCode)
            {
            }
            textelement(ReturnPeriod)
            {
            }
            tableelement("temp wht entry - efiling"; "Temp WHT Entry - EFiling")
            {
                XmlName = 'TempWHTEntryEFiling';
                textelement(ScheduleNo)
                {
                }
                textelement(FType1)
                {
                }
                textelement(TIN)
                {
                }
                textelement(Branchcode1)
                {
                }
                textelement(ReturnPeriod1)
                {
                }
                textelement(SeqNo)
                {
                }
                textelement(PayeeTIN)
                {
                }
                textelement(PayeeBranchCode)
                {
                }
                textelement(RegName)
                {
                }
                textelement(LastName)
                {
                }
                textelement(FirstName)
                {
                }
                textelement(MiddleName)
                {
                }
                fieldelement(WHTRevenuType; "Temp WHT Entry - EFiling"."WHT Revenue Type")
                {
                }
                fieldelement(BaseLCY; "Temp WHT Entry - EFiling"."Base (LCY)")
                {
                }
                fieldelement(WHT; "Temp WHT Entry - EFiling"."WHT %")
                {
                }
                fieldelement(AmountLCY; "Temp WHT Entry - EFiling"."Amount (LCY)")
                {
                }
                tableelement("temp wht entry - efiling3"; "Temp WHT Entry - EFiling")
                {
                    XmlName = 'TempWHTEntryEFiling3';
                    textelement(ScheduleNo1)
                    {
                    }
                    textelement(FType2)
                    {
                    }
                    textelement(TIN1)
                    {
                    }
                    textelement(Branchcode2)
                    {
                    }
                    textelement(ReturnPeriod2)
                    {
                    }
                    fieldelement(WHT; "Temp WHT Entry - EFiling"."WHT %")
                    {
                    }
                    fieldelement(AmountLCY; "Temp WHT Entry - EFiling"."Amount (LCY)")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        ScheduleNo := 'D3';
                        IncomePymt := "Temp WHT Entry - EFiling3"."Base (LCY)";
                        TIN := "Company Information"."VAT Registration No.";
                        Vend.Get("Temp WHT Entry - EFiling3"."Bill-to/Pay-to No.");
                        PayeeTIN := Vend."VAT Registration No.";
                        PayeeBranchCode := PayeeBranchCode;
                        RegName := Vend.Name;
                        TempWHTEntry.Reset();
                        TempWHTEntry.CopyFilters("Temp WHT Entry - EFiling3");
                        IncomePymt := 0;
                        if TempWHTEntry.Find('-') then
                            repeat
                                IncomePymt := IncomePymt + TempWHTEntry."Amount (LCY)";
                            until TempWHTEntry.Next() = 0;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    ScheduleNo := 'D3';
                    ScheduleNo1 := 'D3';
                    IncomePymt := "Temp WHT Entry - EFiling"."Base (LCY)";
                    TIN := "Company Information"."VAT Registration No.";
                    TIN1 := "Company Information"."VAT Registration No.";
                    // Vend.GET("Temp WHT Entry - EFiling"."Bill-to/Pay-to No.");
                    if Vend.Get(VendID) then;
                    PayeeTIN := Vend."VAT Registration No.";
                    PayeeBranchCode := PayeeBranchCode;
                    RegName := Vend.Name;
                    TempWHTEntry.CopyFilters("Temp WHT Entry - EFiling");
                    IncomePymt := 0;
                    if TempWHTEntry.Find('-') then
                        repeat
                            IncomePymt := IncomePymt + TempWHTEntry."Base (LCY)";
                        until TempWHTEntry.Next() = 0;
                end;

                trigger OnPreXmlItem()
                begin
                    WHTEntry1.SetCurrentKey("Bill-to/Pay-to No.", "WHT Revenue Type", "WHT Prod. Posting Group");
                    WHTEntry1.SetFilter("Applies-to Entry No.", '<>0');
                    WHTEntry1.SetRange("Transaction Type", WHTEntry1."Transaction Type"::Purchase);
                    WHTEntry1.SetFilter("Posting Date", ReturnPeriod);
                    WHTEntry1.SetFilter("Bill-to/Pay-to No.", VendID);
                    if WHTEntry1.FindFirst() then
                        REPORT.RunModal(REPORT::"E-Filing", false, false, WHTEntry1);
                end;
            }
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

    trigger OnPostXmlPort()
    begin
        TempWHTEntry.Reset();
        if TempWHTEntry.Find('-') then
            TempWHTEntry.DeleteAll();
    end;

    trigger OnPreXmlPort()
    begin
        FType := 'H1604E';
        FType1 := 'H1604E';
        FType2 := 'H1604E';
    end;

    var
        "Company Information": Record "Company Information";
        TempWHTEntry: Record "Temp WHT Entry - EFiling";
        WHTEntry1: Record "WHT Entry";
        Vend: Record Vendor;
        IncomePymt: Decimal;
        VendID: Code[20];

    [Scope('OnPrem')]
    procedure InitVariables(VendorIDFilter: Code[20]; ReturnPeriodFilter: Text[30]; BranchCodeFilter: Text[3]; PayeeBranchCodeFilter: Text[3])
    begin
        VendID := VendorIDFilter;
        ReturnPeriod := ReturnPeriodFilter;
        ReturnPeriod1 := ReturnPeriodFilter;
        ReturnPeriod2 := ReturnPeriodFilter;
        BranchCode := BranchCodeFilter;
        Branchcode1 := BranchCodeFilter;
        PayeeBranchCode := PayeeBranchCodeFilter;
    end;
}

