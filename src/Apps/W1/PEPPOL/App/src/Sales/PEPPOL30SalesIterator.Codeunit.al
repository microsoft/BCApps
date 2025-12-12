// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Sales.Document;

codeunit 37213 "PEPPOL30 Sales Iterator" implements "PEPPOL Posted Document Iterator"
{

    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetNextPostedHeaderAsSalesHeader(var PostedRecRef: RecordRef; Position: Integer; var SalesHeader: Record "Sales Header") Found: Boolean
    var
        PEPPOL30DocumentConverter: Codeunit "PEPPOL30 Common";
    begin
        if Position = 1 then
            Found := PostedRecRef.Find('-')
        else
            Found := PostedRecRef.Next() <> 0;

        if Found then
            PEPPOL30DocumentConverter.ConvertPostedHeaderToSalesHeader(PostedRecRef, SalesHeader);

        exit(Found);
    end;

    procedure GetNextPostedLineAsSalesLine(var PostedLineRecRef: RecordRef; Position: Integer; var SalesLine: Record "Sales Line") Found: Boolean
    var
        PEPPOL30DocumentConverter: Codeunit "PEPPOL30 Common";
    begin
        if Position = 1 then
            Found := PostedLineRecRef.Find('-')
        else
            Found := PostedLineRecRef.Next() <> 0;

        if Found then
            PEPPOL30DocumentConverter.ConvertPostedLineToSalesLine(PostedLineRecRef, SalesLine);

        exit(Found);
    end;

}