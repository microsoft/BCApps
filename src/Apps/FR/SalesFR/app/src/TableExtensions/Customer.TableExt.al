// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.SalesFR;

using Microsoft.Sales.Customer;

tableextension 10800 Customer extends Customer
{
    fields
    {

        field(10806; "SIREN No. FR"; Code[9])
        {
            Caption = 'SIREN No.';
            DataClassification = CustomerContent;
        }
    }

    var
        SirenNoTemplateTxt: Label '%1: %2', Locked = true;

    procedure GetSIRENNoWithCaptionFR(): Text
    begin
        exit(StrSubstNo(SirenNoTemplateTxt, Rec.FieldCaption("Siren No. FR"), Rec."Siren No. FR"));
    end;
}
