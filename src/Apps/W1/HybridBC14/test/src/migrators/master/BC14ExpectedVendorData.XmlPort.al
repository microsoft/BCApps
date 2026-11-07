// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Purchases.Vendor;

xmlport 148904 "BC14 Expected Vendor Data"
{
    Direction = Import;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(Vendor; Vendor)
            {
                AutoSave = false;
                XmlName = 'Vendor';

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
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    TempVendor.Init();
                    TempVendor."No." := CopyStr(No, 1, MaxStrLen(TempVendor."No."));
                    TempVendor.Name := CopyStr(Name, 1, MaxStrLen(TempVendor.Name));
                    TempVendor.Address := CopyStr(Address, 1, MaxStrLen(TempVendor.Address));
                    TempVendor.City := CopyStr(City, 1, MaxStrLen(TempVendor.City));
                    TempVendor."Post Code" := CopyStr(PostCode, 1, MaxStrLen(TempVendor."Post Code"));
                    TempVendor."Country/Region Code" := CopyStr(CountryRegionCode, 1, MaxStrLen(TempVendor."Country/Region Code"));
                    TempVendor."Phone No." := CopyStr(PhoneNo, 1, MaxStrLen(TempVendor."Phone No."));
                    TempVendor."E-Mail" := CopyStr(EMail, 1, MaxStrLen(TempVendor."E-Mail"));
                    TempVendor."Vendor Posting Group" := CopyStr(VendorPostingGroup, 1, MaxStrLen(TempVendor."Vendor Posting Group"));
                    TempVendor."Gen. Bus. Posting Group" := CopyStr(GenBusPostingGroup, 1, MaxStrLen(TempVendor."Gen. Bus. Posting Group"));
                    TempVendor."Payment Terms Code" := CopyStr(PaymentTermsCode, 1, MaxStrLen(TempVendor."Payment Terms Code"));
                    TempVendor."Currency Code" := CopyStr(CurrencyCode, 1, MaxStrLen(TempVendor."Currency Code"));
                    TempVendor."Language Code" := CopyStr(LanguageCode, 1, MaxStrLen(TempVendor."Language Code"));
                    Evaluate(TempVendor.Blocked, BlockedValue);
                    TempVendor.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempVendor.Reset();
        TempVendor.DeleteAll();
    end;

    procedure GetExpectedVendors(var DestTempVendor: Record Vendor temporary)
    begin
        DestTempVendor.Reset();
        DestTempVendor.DeleteAll();
        if TempVendor.FindSet() then
            repeat
                DestTempVendor := TempVendor;
                DestTempVendor.Insert();
            until TempVendor.Next() = 0;
    end;

    var
        TempVendor: Record Vendor temporary;
        CaptionRow: Boolean;
}
