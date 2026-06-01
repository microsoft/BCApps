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
    ReplicateData = false;

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
    /// Sets the current record to the setup applicable to the provided vendor
    /// </summary>
    /// <param name="VendorNo"></param>
    /// <returns></returns>
    procedure GetSetup(VendorNo: Code[20])
    begin
        Clear(Rec);
        Rec.SetRange("Vendor No.", VendorNo);
        if Rec.FindFirst() then
            exit;
        // If there is no specific setup for the vendor, set to the global setup
        GetSetup();
    end;

    /// <summary>
    /// Sets the current record to the setup applicable if there is no specific override
    /// </summary>
    /// <returns></returns>
    procedure GetSetup()
    begin
        Clear(Rec);
        Rec.SetFilter("Vendor No.", '');
        if Rec.FindFirst() then
            exit;
        Rec."PO Matching Config. Receipt" := "E-Doc. PO M. Config. Receipt"::"Always ask";
        Rec."Receive G/L Account Lines" := true;
    end;

}