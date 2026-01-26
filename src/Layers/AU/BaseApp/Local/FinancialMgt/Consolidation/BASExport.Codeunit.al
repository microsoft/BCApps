// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
codeunit 11604 "BAS Export"
{
    TableNo = "VAT Report Header";

    trigger OnRun()
    var
        BASManagement: Codeunit "BAS Management";
    begin
        BASManagement.ExportBASReport(
          Rec, BASManagement.SaveBASTemplateToServerFile(Rec."BAS ID No.", Rec."BAS Version No."));
        Rec.Status := Rec.Status::Accepted;
        Rec.Modify();
    end;
}

