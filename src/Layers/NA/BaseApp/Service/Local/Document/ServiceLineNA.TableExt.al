// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Finance.SalesTax;

tableextension 10014 "Service Line NA" extends "Service Line"
{
    fields
    {
        modify("Tax Area Code")
        {
            trigger OnAfterValidate()
            var
                TaxArea: Record "Tax Area";
                HeaderTaxArea: Record "Tax Area";
            begin
                GetServHeader();
                if "Tax Area Code" <> '' then begin
                    TaxArea.Get("Tax Area Code");
                    ServHeader.TestField("Tax Area Code");
                    HeaderTaxArea.Get(ServHeader."Tax Area Code");
                    if TaxArea."Country/Region" <> HeaderTaxArea."Country/Region" then
                        Error(
                          Text1020003,
                          TaxArea.FieldCaption("Country/Region"),
                          TaxArea.TableCaption(),
                          TableCaption,
                          ServHeader.TableCaption());
                    if TaxArea."Use External Tax Engine" <> HeaderTaxArea."Use External Tax Engine" then
                        Error(
                          Text1020003,
                          TaxArea.FieldCaption("Use External Tax Engine"),
                          TaxArea.TableCaption(),
                          TableCaption,
                          ServHeader.TableCaption());
                end;
            end;
        }
    }

    var
        Text1020003: Label 'The %1 field in the %2 used on the %3 must match the %1 field in the %2 used on the %4.';
}
