// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.SalesOrderAgent;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using System.Globalization;
using System.Utilities;

report 4414 "SOA Sample Order"
{
    Caption = 'Sample Order';
    DefaultRenderingLayout = WordLayout;
    UsageCategory = None;
    ApplicationArea = All;
    InherentEntitlements = X;
    InherentPermissions = X;

    dataset
    {
        dataitem(Header; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            column(CompanyName; CompanyInformation.Name)
            {
            }
            column(CompanyAddress; CompanyInformation.Address)
            {
            }
            column(CompanyCity; CompanyAddressLine())
            {
            }
            column(CompanyPhone; CompanyInformation."Phone No.")
            {
            }
            column(CompanyEmail; CompanyInformation."E-Mail")
            {
            }
            column(DocNo; DocumentNo)
            {
            }
            column(DocDate; Format(Today(), 0, 4))
            {
            }
            column(SenderName; SenderName)
            {
            }
            column(SenderEmail; SenderEmail)
            {
            }
            column(SenderCompany; SenderCompany)
            {
            }
            column(SenderAddress; SenderAddress)
            {
            }
            column(SenderCity; SenderCity)
            {
            }
            column(SenderPhone; SenderPhone)
            {
            }
            dataitem(Item; Item)
            {
                DataItemTableView = sorting("No.");

                column(ItemNo; "No.")
                {
                }
                column(ItemDescription; Description)
                {
                }
                column(ItemQuantity; LineQuantity)
                {
                }
                column(ItemUnitOfMeasure; "Base Unit of Measure")
                {
                }
                column(ExpectedDate; Format(ExpectedDate, 0, 4))
                {
                }

                trigger OnPreDataItem()
                begin
                    SetRange(Blocked, false);
                    SetRange("Sales Blocked", false);
                    SetRange("Location Filter", LocationCode);
                    if ItemNoFilter <> '' then
                        SetFilter("No.", ItemNoFilter)
                    else
                        SetRange("No.", '');
                end;

                trigger OnAfterGetRecord()
                begin
                    ItemCount += 1;
                    if ItemCount > MaxItems then
                        CurrReport.Break();

                    LineQuantity := SampleLineQuantity();
                end;
            }
            dataitem(Fallback; Integer)
            {
                DataItemTableView = sorting(Number);

                column(FallbackItemDescription; FallbackItemDescription)
                {
                }
                column(FallbackItemQuantity; FallbackItemQuantity)
                {
                }
                column(FallbackExpectedDate; Format(ExpectedDate, 0, 4))
                {
                }

                trigger OnPreDataItem()
                begin
                    if ItemCount > 0 then
                        CurrReport.Break();
                    SetRange(Number, 1, 2);
                end;

                trigger OnAfterGetRecord()
                begin
                    case Number of
                        1:
                            begin
                                FallbackItemDescription := CopyStr(FallbackItem1DescTok, 1, MaxStrLen(FallbackItemDescription));
                                FallbackItemQuantity := 5;
                            end;
                        2:
                            begin
                                FallbackItemDescription := CopyStr(FallbackItem2DescTok, 1, MaxStrLen(FallbackItemDescription));
                                FallbackItemQuantity := 2;
                            end;
                    end;
                end;
            }

            trigger OnPreDataItem()
            begin
                ItemCount := 0;
            end;
        }
    }

    rendering
    {
        layout(WordLayout)
        {
            Type = Word;
            LayoutFile = './src/Integration/SOASampleOrder.docx';
        }
    }

    var
        CompanyInformation: Record "Company Information";
        SOACreateTaskImpl: Codeunit "SOA Create Task Impl";
        LanguageMgt: Codeunit Language;
        LanguageCode: Code[10];
        LocationCode: Code[10];
        FallbackItemDescription: Text[100];
        SenderName: Text[250];
        SenderEmail: Text[250];
        SenderCompany: Text[250];
        SenderAddress: Text[250];
        SenderCity: Text[250];
        SenderPhone: Text[250];
        DocumentNo: Text[20];
        ItemNoFilter: Text;
        FallbackItemQuantity: Decimal;
        LineQuantity: Decimal;
        ExpectedDate: Date;
        ItemCount: Integer;
        MaxItems: Integer;
        FallbackItem1DescTok: Label 'ATHENS Mobile Pedestal', Locked = true;
        FallbackItem2DescTok: Label 'LONDON Swivel Chair, blue', Locked = true;

    trigger OnInitReport()
    begin
        MaxItems := 5;
        CompanyInformation.Get();
        DocumentNo := CopyStr('RFQ-' + Format(Today(), 0, '<Year4><Month,2><Day,2>'), 1, MaxStrLen(DocumentNo));
        ExpectedDate := CalcDate('<CW+1W>', Today());
    end;

    trigger OnPreReport()
    begin
        if LanguageCode <> '' then
            CurrReport.Language := LanguageMgt.GetLanguageIdOrDefault(LanguageCode);
    end;

    local procedure CompanyAddressLine(): Text
    begin
        exit(CompanyInformation."Post Code" + ' ' + CompanyInformation.City);
    end;

    internal procedure SetSender(NewSenderCompany: Text[250]; NewSenderName: Text[250]; NewSenderAddress: Text[250]; NewSenderCity: Text[250]; NewSenderPhone: Text[250]; NewSenderEmail: Text[250])
    begin
        SenderCompany := NewSenderCompany;
        SenderName := NewSenderName;
        SenderAddress := NewSenderAddress;
        SenderCity := NewSenderCity;
        SenderPhone := NewSenderPhone;
        SenderEmail := NewSenderEmail;
    end;

    internal procedure SetLocationCode(NewLocationCode: Code[10])
    begin
        LocationCode := NewLocationCode;
    end;

    internal procedure SetLanguageCode(NewLanguageCode: Code[10])
    begin
        LanguageCode := NewLanguageCode;
    end;

    internal procedure SetItemFilter(NewItemNoFilter: Text)
    begin
        ItemNoFilter := NewItemNoFilter;
    end;

    local procedure SampleLineQuantity(): Integer
    begin
        exit(SOACreateTaskImpl.GetSampleLineQuantity(Item, LocationCode));
    end;
}