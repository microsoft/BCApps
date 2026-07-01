#if not CLEAN29
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import.Purchase;

enum 6113 "E-Doc. PO M. Configuration"
{
    Access = Internal;
    Extensible = false;
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by the per-line "Receipt on Invoice" field on Purchase Line and the "Receipt on Invoice Policy" field on Vendor.';
    ObsoleteTag = '29.0';
    value(0; "Always ask")
    {
        Caption = 'Always ask';
    }
    value(1; "Always receive at posting")
    {
        Caption = 'Always receive at posting';
    }
    value(2; "Never receive at posting")
    {
        Caption = 'Never receive at posting';
    }
    value(3; "Receive at posting only for certain vendors")
    {
        Caption = 'Receive at posting only for certain vendors';
    }
    value(4; "Receive at posting except for certain vendors")
    {
        Caption = 'Receive at posting except for certain vendors';
    }
}
#endif