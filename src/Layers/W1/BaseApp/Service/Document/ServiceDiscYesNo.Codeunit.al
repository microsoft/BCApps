// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using System.Utilities;

codeunit 5951 "Service-Disc. (Yes/No)"
{
    TableNo = "Service Line";

    trigger OnRun()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        ServiceLine.Copy(Rec);
        if ConfirmManagement.GetResponseOrDefault(Text000, true) then
            CODEUNIT.Run(CODEUNIT::"Service-Calc. Discount", ServiceLine);
        Rec := ServiceLine;
    end;

    var
        ServiceLine: Record "Service Line";

#pragma warning disable AA0074
        Text000: Label 'Do you want to calculate the invoice discount and/or payment discount on lines?';
#pragma warning restore AA0074
}

