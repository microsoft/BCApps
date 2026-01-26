// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

enum 10721 "SII Exemption Code"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "E1 Exempt on account of Article 20") { Caption = 'E1 Exempt on account of Article 20'; }
    value(2; "E2 Exempt on account of Article 21") { Caption = 'E2 Exempt on account of Article 21'; }
    value(3; "E3 Exempt on account of Article 22") { Caption = 'E3 Exempt on account of Article 22'; }
    value(4; "E4 Exempt under Articles 23 and 24") { Caption = 'E4 Exempt under Articles 23 and 24'; }
    value(5; "E5 Exempt on account of Article 25") { Caption = 'E5 Exempt on account of Article 25'; }
    value(6; "E6 Exempt on other grounds") { Caption = 'E6 Exempt on other grounds'; }
}
