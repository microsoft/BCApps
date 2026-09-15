// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Sales.Customer;

/// <summary>
/// Loads the expected target Customer rows from a CSV resource into a temporary
/// Customer record set. Tests call SetSource + Import then GetExpectedCustomers
/// to retrieve the expected rows for comparison against the actual migrated data.
/// </summary>
xmlport 148902 "BC14 Expected Customer Data"
{
    Caption = 'Expected Customer data for BC14 migration tests';
    Direction = Import;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(Customer; Customer)
            {
                AutoSave = false;
                XmlName = 'Customer';

                textelement(No) { }
                textelement(Name) { }
                textelement(Address) { }
                textelement(Address2) { }
                textelement(City) { }
                textelement(PostCode) { }
                textelement(CountryRegionCode) { }
                textelement(PhoneNo) { }
                textelement(EMail) { }
                textelement(HomePage) { }
                textelement(CustomerPostingGroup) { }
                textelement(GenBusPostingGroup) { }
                textelement(PaymentTermsCode) { }
                textelement(CurrencyCode) { }
                textelement(LanguageCode) { }
                textelement(CreditLimitLCY) { }
                textelement(BlockedValue) { }

                trigger OnBeforeInsertRecord()
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    TempCustomer.Init();
                    TempCustomer."No." := CopyStr(No, 1, MaxStrLen(TempCustomer."No."));
                    TempCustomer.Name := CopyStr(Name, 1, MaxStrLen(TempCustomer.Name));
                    TempCustomer.Address := CopyStr(Address, 1, MaxStrLen(TempCustomer.Address));
                    TempCustomer."Address 2" := CopyStr(Address2, 1, MaxStrLen(TempCustomer."Address 2"));
                    TempCustomer.City := CopyStr(City, 1, MaxStrLen(TempCustomer.City));
                    TempCustomer."Post Code" := CopyStr(PostCode, 1, MaxStrLen(TempCustomer."Post Code"));
                    TempCustomer."Country/Region Code" := CopyStr(CountryRegionCode, 1, MaxStrLen(TempCustomer."Country/Region Code"));
                    TempCustomer."Phone No." := CopyStr(PhoneNo, 1, MaxStrLen(TempCustomer."Phone No."));
                    TempCustomer."E-Mail" := CopyStr(EMail, 1, MaxStrLen(TempCustomer."E-Mail"));
                    TempCustomer."Home Page" := CopyStr(HomePage, 1, MaxStrLen(TempCustomer."Home Page"));
                    TempCustomer."Customer Posting Group" := CopyStr(CustomerPostingGroup, 1, MaxStrLen(TempCustomer."Customer Posting Group"));
                    TempCustomer."Gen. Bus. Posting Group" := CopyStr(GenBusPostingGroup, 1, MaxStrLen(TempCustomer."Gen. Bus. Posting Group"));
                    TempCustomer."Payment Terms Code" := CopyStr(PaymentTermsCode, 1, MaxStrLen(TempCustomer."Payment Terms Code"));
                    TempCustomer."Currency Code" := CopyStr(CurrencyCode, 1, MaxStrLen(TempCustomer."Currency Code"));
                    TempCustomer."Language Code" := CopyStr(LanguageCode, 1, MaxStrLen(TempCustomer."Language Code"));
                    Evaluate(TempCustomer."Credit Limit (LCY)", CreditLimitLCY);
                    Evaluate(TempCustomer.Blocked, BlockedValue);
                    TempCustomer.Insert();

                    // We never want the source xmlport row to actually persist; we only use
                    // the iteration to fill the temporary record set.
                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempCustomer.Reset();
        TempCustomer.DeleteAll();
    end;

    procedure GetExpectedCustomers(var DestTempCustomer: Record Customer temporary)
    begin
        DestTempCustomer.Reset();
        DestTempCustomer.DeleteAll();
        if TempCustomer.FindSet() then
            repeat
                DestTempCustomer := TempCustomer;
                DestTempCustomer.Insert();
            until TempCustomer.Next() = 0;
    end;

    var
        TempCustomer: Record Customer temporary;
        CaptionRow: Boolean;
}
