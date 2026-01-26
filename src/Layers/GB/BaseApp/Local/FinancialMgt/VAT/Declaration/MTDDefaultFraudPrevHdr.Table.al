#if not CLEANSCHEMA28 
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

table 10537 "MTD-Default Fraud Prev. Hdr"
{
    Caption = 'HMRC Default Fraud Prevention Header';
    ObsoleteReason = 'Moved to extension Making Tax Digital';
    ObsoleteState = Removed;
    ObsoleteTag = '28.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Header; Code[100])
        {
            Caption = 'Header';
            DataClassification = SystemMetadata;
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(3; Value; Text[250])
        {
            Caption = 'Value';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(Key1; Header)
        {
            Clustered = true;
        }
    }
}
 
#endif