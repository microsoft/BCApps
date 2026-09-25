// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Message;

codeunit 6249 "E-Doc. Payment Occ. Runner"
{
    Access = Internal;
    TableNo = "E-Doc. Payment Occurrence";
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        EDocPaymentOccurrenceMgt: Codeunit "E-Doc. Payment Occurrence Mgt.";
    begin
        EDocPaymentOccurrenceMgt.NotifyPaymentOccurrence(Rec);
    end;
}