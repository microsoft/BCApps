// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import.Purchase;

using Microsoft.Purchases.Vendor;

table 6116 "E-Doc. PO Matching Setup"
{
    Access = Internal;
    InherentEntitlements = RID;
    InherentPermissions = RID;

    fields
    {
        field(1; Id; Integer)
        {
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; "PO Matching Config. Receipt"; Enum "E-Doc. PO M. Config. Receipt")
        {
            DataClassification = CustomerContent;
        }
        field(3; "Vendor No."; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = Vendor."No.";
        }
        field(4; "Receive G/L Account Lines"; Boolean)
        {
            DataClassification = CustomerContent;
        }
    }
    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Returns the setup applicable to the provided vendor
    /// </summary>
    /// <param name="VendorNo"></param>
    /// <returns></returns>
    procedure GetSetup(VendorNo: Code[20]): Record "E-Doc. PO Matching Setup"
    var
        EDocPOMatchingSetup: Record "E-Doc. PO Matching Setup";
    begin
        EDocPOMatchingSetup.SetRange("Vendor No.", VendorNo);
        if EDocPOMatchingSetup.FindFirst() then
            exit(EDocPOMatchingSetup);
        // If there is no specific setup for the vendor, return the global setup
        exit(GetSetup())
    end;

    /// <summary>
    /// Returns the setup applicable if there is no specific override
    /// </summary>
    /// <returns></returns>
    procedure GetSetup() EDocPOMatchingSetup: Record "E-Doc. PO Matching Setup"
    begin
        EDocPOMatchingSetup.SetFilter("Vendor No.", '');
        if EDocPOMatchingSetup.FindFirst() then
            exit(EDocPOMatchingSetup);
        EDocPOMatchingSetup."PO Matching Config. Receipt" := "E-Doc. PO M. Config. Receipt"::"Always ask";
        EDocPOMatchingSetup."Receive G/L Account Lines" := true;
        exit(EDocPOMatchingSetup);
    end;

}