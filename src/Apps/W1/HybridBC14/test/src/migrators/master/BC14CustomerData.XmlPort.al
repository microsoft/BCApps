// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

/// <summary>
/// Loads BC14 Customer buffer rows from a CSV resource. CSV column order must match
/// the textelement order below; the first row is treated as a header and skipped.
/// </summary>
xmlport 148901 "BC14 Customer Data"
{
    Caption = 'BC14 Customer buffer data for import/export';
    Direction = Both;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(BC14Customer; "BC14 Customer")
            {
                AutoSave = false;
                XmlName = 'BC14Customer';

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
                var
                    NewBC14Customer: Record "BC14 Customer";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14Customer.Init();
                    NewBC14Customer."No." := CopyStr(No, 1, MaxStrLen(NewBC14Customer."No."));
                    NewBC14Customer.Name := CopyStr(Name, 1, MaxStrLen(NewBC14Customer.Name));
                    NewBC14Customer.Address := CopyStr(Address, 1, MaxStrLen(NewBC14Customer.Address));
                    NewBC14Customer."Address 2" := CopyStr(Address2, 1, MaxStrLen(NewBC14Customer."Address 2"));
                    NewBC14Customer.City := CopyStr(City, 1, MaxStrLen(NewBC14Customer.City));
                    NewBC14Customer."Post Code" := CopyStr(PostCode, 1, MaxStrLen(NewBC14Customer."Post Code"));
                    NewBC14Customer."Country/Region Code" := CopyStr(CountryRegionCode, 1, MaxStrLen(NewBC14Customer."Country/Region Code"));
                    NewBC14Customer."Phone No." := CopyStr(PhoneNo, 1, MaxStrLen(NewBC14Customer."Phone No."));
                    NewBC14Customer."E-Mail" := CopyStr(EMail, 1, MaxStrLen(NewBC14Customer."E-Mail"));
                    NewBC14Customer."Home Page" := CopyStr(HomePage, 1, MaxStrLen(NewBC14Customer."Home Page"));
                    NewBC14Customer."Customer Posting Group" := CopyStr(CustomerPostingGroup, 1, MaxStrLen(NewBC14Customer."Customer Posting Group"));
                    NewBC14Customer."Gen. Bus. Posting Group" := CopyStr(GenBusPostingGroup, 1, MaxStrLen(NewBC14Customer."Gen. Bus. Posting Group"));
                    NewBC14Customer."Payment Terms Code" := CopyStr(PaymentTermsCode, 1, MaxStrLen(NewBC14Customer."Payment Terms Code"));
                    NewBC14Customer."Currency Code" := CopyStr(CurrencyCode, 1, MaxStrLen(NewBC14Customer."Currency Code"));
                    NewBC14Customer."Language Code" := CopyStr(LanguageCode, 1, MaxStrLen(NewBC14Customer."Language Code"));
                    Evaluate(NewBC14Customer."Credit Limit (LCY)", CreditLimitLCY);
                    Evaluate(NewBC14Customer.Blocked, BlockedValue);
                    NewBC14Customer.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
    end;

    var
        CaptionRow: Boolean;
}
