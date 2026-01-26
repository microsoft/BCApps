// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

enum 10710 "SII ID Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "02-VAT Registration No.") { Caption = '02-VAT Registration No.'; }
    value(2; "03-Passport") { Caption = '03-Passport'; }
    value(3; "04-ID Document") { Caption = '04-ID Document'; }
    value(4; "05-Certificate Of Residence") { Caption = '05-Certificate Of Residence'; }
    value(5; "06-Other Probative Document") { Caption = '06-Other Probative Document'; }
    value(6; "07-Not On The Census") { Caption = '07-Not On The Census'; }
}
