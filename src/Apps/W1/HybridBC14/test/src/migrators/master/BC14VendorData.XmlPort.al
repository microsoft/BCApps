// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

xmlport 148903 "BC14 Vendor Data"
{
    Direction = Both;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(BC14Vendor; "BC14 Vendor")
            {
                AutoSave = false;
                XmlName = 'BC14Vendor';

                textelement(No) { }
                textelement(Name) { }
                textelement(Address) { }
                textelement(City) { }
                textelement(PostCode) { }
                textelement(CountryRegionCode) { }
                textelement(PhoneNo) { }
                textelement(EMail) { }
                textelement(VendorPostingGroup) { }
                textelement(GenBusPostingGroup) { }
                textelement(PaymentTermsCode) { }
                textelement(CurrencyCode) { }
                textelement(LanguageCode) { }
                textelement(BlockedValue) { }

                trigger OnBeforeInsertRecord()
                var
                    NewBC14Vendor: Record "BC14 Vendor";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14Vendor.Init();
                    NewBC14Vendor."No." := CopyStr(No, 1, MaxStrLen(NewBC14Vendor."No."));
                    NewBC14Vendor.Name := CopyStr(Name, 1, MaxStrLen(NewBC14Vendor.Name));
                    NewBC14Vendor.Address := CopyStr(Address, 1, MaxStrLen(NewBC14Vendor.Address));
                    NewBC14Vendor.City := CopyStr(City, 1, MaxStrLen(NewBC14Vendor.City));
                    NewBC14Vendor."Post Code" := CopyStr(PostCode, 1, MaxStrLen(NewBC14Vendor."Post Code"));
                    NewBC14Vendor."Country/Region Code" := CopyStr(CountryRegionCode, 1, MaxStrLen(NewBC14Vendor."Country/Region Code"));
                    NewBC14Vendor."Phone No." := CopyStr(PhoneNo, 1, MaxStrLen(NewBC14Vendor."Phone No."));
                    NewBC14Vendor."E-Mail" := CopyStr(EMail, 1, MaxStrLen(NewBC14Vendor."E-Mail"));
                    NewBC14Vendor."Vendor Posting Group" := CopyStr(VendorPostingGroup, 1, MaxStrLen(NewBC14Vendor."Vendor Posting Group"));
                    NewBC14Vendor."Gen. Bus. Posting Group" := CopyStr(GenBusPostingGroup, 1, MaxStrLen(NewBC14Vendor."Gen. Bus. Posting Group"));
                    NewBC14Vendor."Payment Terms Code" := CopyStr(PaymentTermsCode, 1, MaxStrLen(NewBC14Vendor."Payment Terms Code"));
                    NewBC14Vendor."Currency Code" := CopyStr(CurrencyCode, 1, MaxStrLen(NewBC14Vendor."Currency Code"));
                    NewBC14Vendor."Language Code" := CopyStr(LanguageCode, 1, MaxStrLen(NewBC14Vendor."Language Code"));
                    Evaluate(NewBC14Vendor.Blocked, BlockedValue);
                    NewBC14Vendor.Insert();

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
